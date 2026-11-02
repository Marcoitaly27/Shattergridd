extends Node
## Central playback, bounded lazy pools, scope cleanup and user/mix gain separation.

signal request_observed(cue_id: StringName, outcome: StringName, scope: int)
const Library = preload("res://resources/audio/library.tres")
const Music = preload("res://scripts/audio/music_director.gd")
const BUSES: Array[StringName] = [&"Master", &"Music", &"Ambience", &"SFX", &"Cinematic", &"UI"]
const MAX_2D: int = 8
const MAX_3D: int = 10
const MAX_LOOPS: int = 6
var library: Resource = Library
var music: Node
var scopes: Dictionary = {}
var settings: Dictionary = {}
var trace: Array[Dictionary] = []
var _pool_2d: Array[Node] = []
var _pool_3d: Array[Node] = []
var _loop_pool: Array[Node] = []
var _active: Dictionary = {}
var _loops: Dictionary = {}
var _cooldowns: Dictionary = {}
var _last_variation: Dictionary = {}
var _serial: int = 0
var _rng := RandomNumberGenerator.new()
var _cinematics: Dictionary = {}
var _duck: float = 0.0
var _core_duck: float = 0.0
var _mix_tween: Tween


func _ready() -> void:
	_rng.randomize()
	if BUSES.any(func(bus: StringName) -> bool: return AudioServer.get_bus_index(bus) < 0):
		AudioServer.set_bus_layout(preload("res://default_bus_layout.tres"))
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		settings[bus] = {"volume": db_to_linear(AudioServer.get_bus_volume_db(index)),
			"muted": AudioServer.is_bus_mute(index)}
	music = Music.new()
	music.name = "MusicDirector"
	add_child(music)
	set_process(false)


func begin_scope(scope: int, state: StringName) -> void:
	scopes[scope] = state
	music.request_state(state, scope)


func release_scope(scope: int) -> void:
	for handle in _active.keys():
		if _active[handle].scope == scope:
			stop_voice(handle)
	scopes.erase(scope)
	_cinematics.erase(scope)
	for key in _cooldowns.keys():
		if String(key).begins_with(str(scope) + ":"):
			_cooldowns.erase(key)
	music.release_scope(scope)
	_update_mix(true)


func play_ui(id: StringName) -> int:
	return play_id(id, null, 0, &"ui")


func play_id(id: StringName, position: Variant = null, scope: int = 0,
		channel: StringName = &"world", loop_key: String = "", owner_node: Node = null) -> int:
	var cue: Resource = library.find_cue(id)
	if cue == null:
		_observe(id, &"unassigned", scope)
		return 0
	return play(cue, position, scope, channel, loop_key, owner_node)


func play_profile(profile: Resource, event: StringName, position: Vector3, scope: int,
		channel: StringName = &"world") -> void:
	if profile == null:
		return
	for id in profile.cues_for(event):
		play_id(id, position, scope, channel)


func choose_stream(cue: Resource) -> AudioStream:
	var streams: Array[AudioStream] = cue.streams()
	if streams.is_empty():
		return null
	var choices: Array[int] = []
	for index in range(streams.size()):
		if streams.size() == 1 or index != _last_variation.get(cue.cue_id, -1):
			choices.append(index)
	var chosen: int = choices[_rng.randi_range(0, choices.size() - 1)]
	_last_variation[cue.cue_id] = chosen
	return streams[chosen]


func play(cue: Resource, position: Variant = null, scope: int = 0,
		channel: StringName = &"world", loop_key: String = "", owner_node: Node = null) -> int:
	if cue == null:
		return 0
	if scope != 0 and not scopes.has(scope):
		_observe(cue.cue_id, &"expired_scope", scope)
		return 0
	var key := "%d:%s" % [scope, loop_key]
	if cue.looping and _loops.has(key):
		return _loops[key]
	if cue.looping and loop_key.is_empty():
		_observe(cue.cue_id, &"loop_key_required", scope)
		return 0
	if cue.streams().is_empty():
		_observe(cue.cue_id, &"missing", scope)
		return 0
	var cooldown := "%d:%s" % [scope, cue.cue_id]
	var now := Time.get_ticks_msec()
	if not cue.looping and now < _cooldowns.get(cooldown, 0):
		_observe(cue.cue_id, &"cooldown", scope)
		return 0
	var count := 0
	for entry in _active.values():
		if entry.cue.cue_id == cue.cue_id:
			count += 1
	if count >= maxi(1, cue.max_instances):
		_observe(cue.cue_id, &"limited", scope)
		return 0
	var positional: bool = cue.positional and channel not in [&"cinematic", &"ui"]
	var player := _take_player(positional, cue.looping, cue.priority)
	if player == null:
		_observe(cue.cue_id, &"pool_full", scope)
		return 0
	var stream := choose_stream(cue)
	_serial += 1
	var handle := _serial
	var duration: float = clampf(cue.max_duration, 0.1, 30.0)
	if stream.get_length() > 0:
		duration = minf(duration, stream.get_length() + 0.2)
	var entry := {"player": player, "cue": cue, "scope": scope, "channel": channel,
		"deadline": now + int(duration * 1000), "loop": cue.looping, "key": key,
		"owner": weakref(owner_node) if owner_node != null else null, "callback": Callable()}
	_active[handle] = entry
	player.set_meta("voice_handle", handle)
	player.stream = stream
	player.bus = cue.bus if AudioServer.get_bus_index(cue.bus) >= 0 else &"SFX"
	player.volume_db = clampf(cue.volume_db, -60.0, 0.0)
	player.pitch_scale = _rng.randf_range(clampf(cue.pitch_range.x, 0.5, 2.0), clampf(maxf(cue.pitch_range.x, cue.pitch_range.y), 0.5, 2.0))
	if positional:
		player.global_position = position if position is Vector3 else Vector3.ZERO
		player.unit_size = maxf(cue.unit_size, 0.1)
		player.max_distance = maxf(cue.max_distance, player.unit_size)
	if cue.looping:
		_loops[key] = handle
		if owner_node != null:
			entry.callback = stop_voice.bind(handle)
			owner_node.tree_exiting.connect(entry.callback, CONNECT_ONE_SHOT)
	else:
		_cooldowns[cooldown] = now + int(maxf(cue.min_interval, 0.0) * 1000)
	player.play()
	_refresh_processing()
	_observe(cue.cue_id, &"playing", scope)
	return handle


func _take_player(positional: bool, looping: bool, priority: int) -> Node:
	var pool: Array[Node] = _loop_pool if looping else (_pool_3d if positional else _pool_2d)
	for player in pool:
		if not _active.has(player.get_meta("voice_handle", 0)) and (player is AudioStreamPlayer3D) == positional:
			return player
	var maximum := MAX_LOOPS if looping else (MAX_3D if positional else MAX_2D)
	if looping and pool.size() >= maximum:
		# An idle slot of the other spatial type must not permanently exhaust a pool.
		for index in range(pool.size()):
			if not _active.has(pool[index].get_meta("voice_handle", 0)):
				var retired: Node = pool[index]
				pool.remove_at(index)
				retired.free()
				break
	if pool.size() >= maximum:
		if not looping:
			var candidate := 0
			var lowest := priority
			for handle in _active:
				var entry: Dictionary = _active[handle]
				if pool.has(entry.player) and entry.cue.priority < lowest:
					candidate = handle
					lowest = entry.cue.priority
			if candidate != 0:
				var reused: Node = _active[candidate].player
				stop_voice(candidate)
				return reused
		return null
	var player: Node = AudioStreamPlayer3D.new() if positional else AudioStreamPlayer.new()
	player.name = "LoopVoice" if looping else "OneShotVoice"
	player.max_polyphony = 1
	add_child(player)
	player.finished.connect(_voice_finished.bind(player))
	pool.append(player)
	return player


func _voice_finished(player: Node) -> void:
	var handle: int = player.get_meta("voice_handle", 0)
	if not _active.has(handle):
		return
	if _active[handle].loop:
		player.play() # Imported gapless loop flags are preferred; this is a safe fallback.
	else:
		stop_voice(handle)


func stop_voice(handle: int) -> void:
	if not _active.has(handle):
		return
	var entry: Dictionary = _active[handle]
	_active.erase(handle)
	if entry.loop:
		_loops.erase(entry.key)
	if entry.owner != null:
		var owner_node: Node = entry.owner.get_ref()
		if is_instance_valid(owner_node) and owner_node.tree_exiting.is_connected(entry.callback):
			owner_node.tree_exiting.disconnect(entry.callback)
	entry.player.stop()
	entry.player.stream = null
	_refresh_processing()


func stop_channel(scope: int, channel: StringName) -> void:
	for handle in _active.keys():
		if _active[handle].scope == scope and _active[handle].channel == channel:
			stop_voice(handle)


func set_loop_gain(handle: int, offset_db: float) -> void:
	if _active.has(handle) and _active[handle].loop and is_finite(offset_db):
		_active[handle].player.volume_db = clampf(_active[handle].cue.volume_db + offset_db, -60, 0)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for handle in _active.keys():
		if not _active[handle].loop and now >= _active[handle].deadline:
			stop_voice(handle)


func _refresh_processing() -> void:
	set_process(_active.values().any(func(entry: Dictionary) -> bool: return not entry.loop))


func set_volume(bus: StringName, linear: float) -> bool:
	if not settings.has(bus) or not is_finite(linear):
		return false
	settings[bus].volume = clampf(linear, 0.0, 1.0)
	_apply_settings()
	return true


func set_muted(bus: StringName, muted: bool) -> bool:
	if not settings.has(bus):
		return false
	settings[bus].muted = muted
	_apply_settings()
	return true


func _apply_settings() -> void:
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		var volume: float = settings[bus].volume
		var offset := (-3.0 * _duck - 2.0 * _core_duck) if bus == &"Ambience" else (-4.0 * _duck - _core_duck if bus == &"Music" else 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)) + offset)
		AudioServer.set_bus_mute(index, settings[bus].muted or volume <= 0.0)


func begin_cinematic(scope: int) -> void:
	if not scopes.has(scope):
		return
	_cinematics[scope] = &"capture"
	_update_mix()


func core_release(scope: int) -> void:
	if _cinematics.has(scope):
		_cinematics[scope] = &"core"
		_update_mix()


func end_cinematic(scope: int, core_pause: bool = false) -> void:
	stop_channel(scope, &"cinematic")
	if core_pause and _cinematics.has(scope):
		_cinematics[scope] = &"core_pause"
	else:
		_cinematics.erase(scope)
	_update_mix()


func _update_mix(immediate: bool = false) -> void:
	if is_instance_valid(_mix_tween):
		_mix_tween.kill()
	var target := 0.0 if _cinematics.is_empty() else 1.0
	var core := 1.0 if _cinematics.values().any(func(state: StringName) -> bool: return state in [&"core", &"core_pause"]) else 0.0
	if immediate:
		_duck = target
		_core_duck = core
		_apply_settings()
		return
	_mix_tween = create_tween().set_parallel(true)
	var duration := 0.18 if target > _duck or core > _core_duck else 0.75
	_mix_tween.tween_method(_set_duck, _duck, target, duration)
	_mix_tween.tween_method(_set_core_duck, _core_duck, core, duration)


func _set_duck(value: float) -> void:
	_duck = value
	_apply_settings()


func _set_core_duck(value: float) -> void:
	_core_duck = value
	_apply_settings()


func _observe(id: StringName, outcome: StringName, scope: int) -> void:
	trace.append({"cue": id, "outcome": outcome, "scope": scope, "time": Time.get_ticks_msec()})
	if trace.size() > 64:
		trace.pop_front()
	request_observed.emit(id, outcome, scope)


func metrics() -> Dictionary:
	var bus_db: Dictionary = {}
	for bus in BUSES:
		bus_db[bus] = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
	return {"active_players": _active.size() + music.active_count(), "loops": _loops.size(),
		"pooled_players": _pool_2d.size() + _pool_3d.size() + _loop_pool.size() + music._channels.size(),
		"music_state": music.state, "contexts": scopes.values(), "cinematics": _cinematics.values(),
		"bus_db": bus_db, "volumes": settings.duplicate(true), "missing": library.missing_ids().size()}


func debug_text() -> String:
	var missing: int = library.missing_ids().size()
	var last := "none" if trace.is_empty() else "%s · %s" % [trace.back().cue, trace.back().outcome]
	var data := metrics()
	return "AUDIO %d active / %d pooled / %d ambience loops\nAssets %d/%d ready · Music %s · %s\nCinematic %s · mix %.2f / %.2f\nVolumes M %.0f%% / Music %.0f%% / SFX %.0f%% / Amb %.0f%%\nBus dB Music %.1f / Amb %.1f / Cine %.1f / UI %.1f\nF4 test confirm · Last: %s" % [
		data.active_players, data.pooled_players, _loops.size(), library.cues.size() - missing, library.cues.size(),
		music.state, scopes.values(), _cinematics.values(), _duck, _core_duck,
		settings[&"Master"].volume * 100, settings[&"Music"].volume * 100,
		settings[&"SFX"].volume * 100, settings[&"Ambience"].volume * 100,
		data.bus_db[&"Music"], data.bus_db[&"Ambience"], data.bus_db[&"Cinematic"], data.bus_db[&"UI"],
		last]
