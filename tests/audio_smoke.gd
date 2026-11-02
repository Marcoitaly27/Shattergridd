extends SceneTree
## Empty production references plus in-memory engine stream fixtures; no audio files.

const Cue = preload("res://scripts/audio/audio_cue.gd")
const Library = preload("res://scripts/audio/audio_library.gd")
const Event = preload("res://scripts/audio/ambient_event.gd")
const Group = preload("res://scripts/audio/ambient_group.gd")
const Scheduler = preload("res://scripts/audio/ambient_scheduler.gd")
const Match = preload("res://scenes/main.tscn")
const BoardState = preload("res://scripts/board/board_state.gd")
const Destruction = preload("res://scripts/effects/stone_destruction.gd")
var sound: Node
var checks: int = 0
var failures: int = 0
var original_library: Resource
var production_library: Resource
var original_settings: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	sound = root.get_node("SoundManager")
	production_library = sound.library
	original_library = Library.new()
	for cue in production_library.cues:
		var empty: Resource = cue.duplicate()
		empty.variations = [] as Array[AudioStream]
		original_library.cues.append(empty)
	sound.library = original_library
	original_settings = sound.settings.duplicate(true)
	_test_buses_and_empty_data()
	await _test_playback_and_variations()
	await _test_ambience_and_music()
	await _test_movement_and_contacts()
	await _test_capture_events()
	await _test_scene_cleanup()
	sound.settings = original_settings
	sound.library = production_library
	sound._apply_settings()
	# Stop commands are consumed on the audio mix thread, not synchronously here.
	var drained := Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drained:
		await process_frame
	print("Audio smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_buses_and_empty_data() -> void:
	for bus in sound.BUSES:
		_expect(AudioServer.get_bus_index(bus) >= 0, "Required native bus exists: " + String(bus))
	_expect(AudioServer.get_bus_send(AudioServer.get_bus_index(&"Cinematic")) == &"SFX"
		and AudioServer.get_bus_send(AudioServer.get_bus_index(&"UI")) == &"SFX", "SFX controls also cover cinematic/UI child buses")
	var reverb: AudioEffect = AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Cinematic"), 0)
	_expect(reverb is AudioEffectReverb and reverb.wet <= 0.08, "Only the cinematic bus has a restrained outdoor tail")
	_expect(original_library.cues.size() >= 57 and original_library.missing_ids().size() == original_library.cues.size(), "An entirely unassigned library remains a supported configuration")
	for cue in original_library.cues:
		_expect(sound.play(cue) == 0, "Missing optional cue skips playback without creating a player")
	_expect(sound._active.is_empty() and sound.get_child_count() == 1, "No audio-player pool is allocated for missing assets")
	_expect(sound.play_id(&"unregistered.optional") == 0, "An unregistered optional cue also skips safely")
	_expect(sound.trace.size() <= 64 and sound.debug_text().contains("0/%d ready" % original_library.cues.size()), "Missing references are visible in bounded debug data")
	for name in ["warden", "hunter", "executioner", "witch", "wyrm", "core"]:
		var character: Resource = load("res://resources/characters/%s.tres" % name)
		_expect(character.audio_profile != null and not character.audio_profile.cues_for(&"move_start").is_empty(), "Each existing character carries a replaceable movement profile")
		_expect(not character.audio_profile.cues_for(&"impact").is_empty(), "Each existing character has data-driven impact identity")
	for bus in [&"Master", &"Music", &"SFX", &"Ambience"]:
		_expect(sound.set_volume(bus, 0.5), "Linear volume is accepted")
		_expect(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)) - linear_to_db(0.5)) < 0.001, "Linear amplitude converts to the correct decibels")
		_expect(sound.set_volume(bus, 0.0) and AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), "Zero volume mutes without negative infinity")
		sound.set_volume(bus, 0.5)
		sound.set_muted(bus, true)
		_expect(AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), "Explicit mute works independently of volume")
		sound.set_muted(bus, false)
	_expect(not sound.set_volume(&"MissingBus", 0.5) and not sound.set_volume(&"Master", NAN), "Unknown buses and non-finite settings are rejected")
	sound.set_volume(&"Master", 4.0)
	_expect(sound.settings[&"Master"].volume == 1.0, "Out-of-range volume clamps safely")


func _fixture_cue(id: StringName, positional: bool = false, loop: bool = false) -> Resource:
	var cue := Cue.new()
	cue.cue_id = id
	cue.positional = positional
	cue.looping = loop
	cue.min_interval = 0.0
	cue.max_instances = 20
	cue.max_duration = 0.15
	# No generated samples, encoded data or files: this native stream only exercises
	# engine player lifecycle. It is never assigned to production Resources.
	var stream := AudioStreamGenerator.new()
	stream.buffer_length = 0.1
	cue.variations.append(stream)
	return cue


func _clear_voices() -> void:
	for handle in sound._active.keys():
		sound.stop_voice(handle)


func _test_playback_and_variations() -> void:
	var cue := _fixture_cue(&"test.variation")
	var second := AudioStreamGenerator.new()
	cue.variations.append(second)
	cue.variations.append(second)
	var previous: AudioStream
	for index in range(24):
		var chosen: AudioStream = sound.choose_stream(cue)
		_expect(chosen != previous, "Variation selection avoids immediately repeating the same stream")
		previous = chosen
	_expect(cue.streams().size() == 2, "Duplicate/null variation references cannot defeat anti-repeat")
	sound.begin_scope(80, &"match")
	var spatial := _fixture_cue(&"test.spatial", true)
	var handle: int = sound.play(spatial, Vector3(3, 1, -2), 80)
	_expect(handle != 0 and sound._active[handle].player is AudioStreamPlayer3D, "World sound uses the positional player pool")
	_expect(sound._active[handle].player.global_position == Vector3(3, 1, -2), "World sound snapshots the requested origin")
	var cinematic: int = sound.play(spatial, Vector3(40, -30, 0), 80, &"cinematic")
	_expect(cinematic != 0 and sound._active[cinematic].player is AudioStreamPlayer, "Essential cinematic sound stays audible independently of camera position")
	var ui_spatial: int = sound.play(spatial, Vector3.ZERO, 0, &"ui")
	_expect(ui_spatial != 0 and sound._active[ui_spatial].player is AudioStreamPlayer, "UI requests remain non-positional even if cue metadata is authored incorrectly")
	_clear_voices()
	var ui := _fixture_cue(&"test.ui")
	ui.min_interval = 0.4
	handle = sound.play(ui)
	_expect(handle != 0 and sound.play(ui) == 0, "Rapid UI requests are throttled")
	sound._active[handle].player.finished.emit()
	_expect(not sound._active.has(handle), "Natural completion returns a voice and clears the stream")
	ui.min_interval = 0.0
	ui.cue_id = &"test.pool"
	for index in range(30):
		sound.play(ui)
	_expect(sound._active.size() <= sound.MAX_2D and sound._pool_2d.size() <= sound.MAX_2D, "Rapid requests cannot grow the pool without a bound")
	var important := _fixture_cue(&"test.important")
	important.priority = 5
	_expect(sound.play(important) != 0, "Important capture layers can replace lower-priority UI voices")
	var expiry := Time.get_ticks_msec() + 700
	while not sound._active.is_empty() and Time.get_ticks_msec() < expiry:
		await process_frame
	_expect(sound._active.is_empty() and not sound.is_processing(), "A nonterminating source is still reclaimed by its one-shot deadline")
	var loop := _fixture_cue(&"test.loop", true, true)
	var owner_node := Node3D.new()
	root.add_child(owner_node)
	handle = sound.play(loop, Vector3.ZERO, 80, &"ambience", "fire", owner_node)
	_expect(handle != 0 and sound.play(loop, Vector3.ZERO, 80, &"ambience", "fire", owner_node) == handle, "Repeated loop keys are idempotent")
	_expect(sound._loops.size() == 1, "An ambience layer has one active loop")
	owner_node.queue_free()
	await process_frame
	_expect(sound._loops.is_empty() and not sound._active.has(handle), "Destroying an emitter stops its owned loop")
	var ambience := _fixture_cue(&"test.bounded_loop", false, true)
	for index in range(12):
		sound.play(ambience, null, 80, &"ambience", "layer_%d" % index)
	_expect(sound._loops.size() == sound.MAX_LOOPS and sound._loop_pool.size() == sound.MAX_LOOPS,
		"Loop requests remain bounded even when an idle slot must change spatial type")
	sound.begin_cinematic(80)
	await create_timer(0.25).timeout
	_expect(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Ambience")) < linear_to_db(sound.settings[&"Ambience"].volume) - 2.5,
		"Cinematic ducking reduces ambience without muting it")
	sound.set_volume(&"Ambience", 0.37)
	sound.set_volume(&"Music", 0.25)
	sound.set_muted(&"Music", true)
	sound.core_release(80)
	await create_timer(0.25).timeout
	_expect(sound._core_duck > 0.9, "Core destruction has an additional restrained reduction")
	sound.end_cinematic(80)
	await create_timer(0.85).timeout
	_expect(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Ambience")) - linear_to_db(0.37)) < 0.001,
		"Ducking restores current user settings, including changes made while ducked")
	_expect(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")) - linear_to_db(0.25)) < 0.001
		and AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")), "Music gain and explicit mute survive ducking without being overwritten")
	sound.set_muted(&"Music", false)
	sound.begin_cinematic(80)
	sound.release_scope(80)
	_expect(sound._duck == 0.0 and sound._core_duck == 0.0 and sound._active.is_empty(), "Leaving a scope immediately clears mix state and its voices")
	_expect(sound.play(spatial, Vector3.ZERO, 80) == 0, "Late requests from a departed scene cannot play")


func _test_ambience_and_music() -> void:
	var library := Library.new()
	library.cues.append(_fixture_cue(&"event.a"))
	library.cues.append(_fixture_cue(&"event.b"))
	for state in ["match", "army_setup", "victory"]:
		library.cues.append(_fixture_cue(StringName("music." + state), false, true))
	sound.library = library
	var scheduler := Scheduler.new()
	root.add_child(scheduler)
	var group := Group.new()
	group.category = &"test_events"
	for id in [&"event.a", &"event.b"]:
		var event := Event.new()
		event.cue_id = id
		event.weight = 1.0 if id == &"event.a" else 4.0
		group.events.append(event)
	var previous: StringName
	for index in range(20):
		var chosen: Resource = scheduler.choose(group)
		_expect(chosen != null and chosen.cue_id != previous, "Weighted ambient selection avoids immediate repetition")
		previous = chosen.cue_id
	scheduler.groups = [group] as Array[Resource]
	scheduler.start(90)
	_expect(scheduler._timers.has(&"test_events") and scheduler._timers[&"test_events"].time_left >= group.min_interval - 1.0,
		"Ambient scheduling respects long configured intervals")
	scheduler.set_category_enabled(&"test_events", false)
	_expect(scheduler._timers[&"test_events"].is_stopped(), "Ambient categories can be disabled")
	scheduler.queue_free()
	sound.begin_scope(90, &"match")
	await create_timer(0.08).timeout
	sound.music.request_state(&"army_setup", 90, 0.12)
	sound.music.request_state(&"victory", 90, 0.12)
	sound.music.request_state(&"match", 90, 0.12)
	await create_timer(0.3).timeout
	_expect(sound.music._channels.size() == 2 and sound.music.active_count() == 1, "Rapid music transitions converge to one track using two bounded channels")
	var active_streams: Array = sound.music._channels.map(func(player: AudioStreamPlayer) -> AudioStream: return player.stream)
	sound.music.request_state(&"match", 90, 0.1)
	_expect(sound.music._channels.map(func(player: AudioStreamPlayer) -> AudioStream: return player.stream) == active_streams,
		"Requesting the same music state does not restart or stack tracks")
	sound.music.request_state(&"unassigned", 90, 0.1)
	await create_timer(0.2).timeout
	_expect(sound.music.active_count() == 0, "Missing music states fade to intentional silence")
	sound.release_scope(90)
	sound.library = original_library


func _test_movement_and_contacts() -> void:
	var scene := Match.instantiate() as Node3D
	root.add_child(scene)
	load("res://tests/legacy_fixture.gd").configure(scene)
	await physics_frame
	var game: Node = scene.get_node("GameManager")
	var mover: Node3D = scene.get_node("Pieces/Ash_01")
	var origin := mover.global_position
	var events: Array[StringName] = []
	game.movement_cue.connect(func(event: StringName, piece: Node3D) -> void:
		events.append(event)
		var expected: Vector3 = origin if event == &"move_start" else game.battlefield.position_for_cell(Vector2i(0, 6))
		_expect(piece.global_position.is_equal_approx(expected), "Movement audio uses actual start/settle positions"))
	game.handle_cell_clicked(mover.grid_coordinate)
	game.handle_cell_clicked(Vector2i(0, 6))
	var deadline := Time.get_ticks_msec() + 4000
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(events == [&"move_start", &"move_end"], "Normal movement exposes exactly start and settle hooks")
	var landed: Array[Vector3] = []
	var effect := Destruction.new()
	scene.get_node("Effects").add_child(effect)
	effect.fragment_contact.connect(func(position: Vector3, _strength: float) -> void: landed.append(position))
	scene.get_node("MatchAudio")._on_destruction(effect)
	effect.spawn(AABB(Vector3(0, 0.14, 0), Vector3(0.8, 0.8, 0.8)), null, Vector3.FORWARD, false, false, 41)
	var void_contacts: Array[Vector3] = []
	var into_void := Destruction.new()
	scene.get_node("Effects").add_child(into_void)
	into_void.fragment_contact.connect(func(position: Vector3, _strength: float) -> void: void_contacts.append(position))
	into_void.spawn(AABB(Vector3(50, 0.14, 50), Vector3(0.8, 0.8, 0.8)), null, Vector3.FORWARD, false, false, 41)
	await create_timer(0.7).timeout
	_expect(not landed.is_empty() and landed.size() <= 2, "Real platform contacts produce at most two chunk events")
	_expect(void_contacts.is_empty(), "Fragments outside the platform produce no invented landing events")
	scene.queue_free()
	await process_frame


func _test_capture_events() -> void:
	for name in ["warden", "hunter", "executioner", "witch", "wyrm", "core"]:
		var scene := Match.instantiate() as Node3D
		root.add_child(scene)
		load("res://tests/legacy_fixture.gd").configure(scene)
		await physics_frame
		var game: Node = scene.get_node("GameManager")
		var attacker: Node3D = scene.get_node("Pieces/Ash_01")
		var victim: Node3D = scene.get_node("Pieces/Slate_01")
		attacker.character_definition = load("res://resources/characters/%s.tres" % name)
		attacker.grid_coordinate = Vector2i(3, 3)
		victim.grid_coordinate = Vector2i(4, 3)
		game.board_state = BoardState.new()
		for piece in scene.get_node("Pieces").get_children():
			piece.position = game.battlefield.position_for_cell(piece.grid_coordinate)
			game.board_state.register_piece(piece)
		var received: Array[StringName] = []
		var observe := func(id: StringName, _outcome: StringName, scope: int) -> void:
			if scope == scene.get_instance_id():
				received.append(id)
		sound.request_observed.connect(observe)
		var exact_impact: Array[bool] = []
		game.capture_director.cue_emitted.connect(func(event: StringName, _a: Node3D, _v: Node3D) -> void:
			if event == &"impact":
				exact_impact.append(received.has(StringName("capture.%s.impact" % name))))
		game.handle_cell_clicked(attacker.grid_coordinate)
		game.handle_cell_clicked(victim.grid_coordinate)
		game.capture_director.accelerate()
		var deadline := Time.get_ticks_msec() + 5000
		while game.is_moving and Time.get_ticks_msec() < deadline:
			await process_frame
		_expect(exact_impact == [true], "Impact audio is requested synchronously from the visual event: " + name)
		for id in [&"capture.start", &"capture.fracture", &"capture.break", &"capture.debris", &"capture.end"]:
			_expect(received.has(id), "Capture pipeline exposes audio hook " + String(id))
		_expect(game.current_player == 1 and game.completed_turns == [1, 0], "Audio observers do not change capture turn resolution")
		_expect(not sound._cinematics.has(scene.get_instance_id()), "Normal completion releases cinematic mix ownership")
		sound.request_observed.disconnect(observe)
		scene.queue_free()
		await process_frame
	_expect(sound.scopes.is_empty() and sound._loops.is_empty(), "Repeated capture fixtures leave no audio scopes or loops")


func _test_scene_cleanup() -> void:
	# Populate only RAM fixtures, so real loop ownership is tested as well as silence.
	for id in [&"ambience.wind", &"ambience.world", &"environment.fire"]:
		original_library.find_cue(id).variations.append(AudioStreamGenerator.new())
	change_scene_to_file("res://scenes/main.tscn")
	await _wait_scene("Shattergrid")
	var scene := current_scene
	load("res://tests/legacy_fixture.gd").configure(scene)
	var game: Node = scene.get_node("GameManager")
	var attacker: Node3D = scene.get_node("Pieces/Ash_03")
	var victim: Node3D = scene.get_node("Pieces/Slate_04")
	_expect(game.board_state.move_piece(victim, Vector2i(3, 6)), "Prepare Core capture fixture")
	victim.position = game.battlefield.position_for_cell(victim.grid_coordinate)
	var scope: int = scene.get_instance_id()
	_expect(sound._loops.size() == 4, "Configured wind/world and the two fires create exactly four layers")
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	game.capture_director.accelerate()
	var deadline := Time.get_ticks_msec() + 5000
	while game.phase == game.Phase.CAPTURING and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(sound.trace.any(func(entry: Dictionary) -> bool: return entry.cue == &"core.release"), "Core destruction requests its dedicated profile treatment")
	_expect(sound._cinematics.get(scope) == &"core_pause", "Core ambience remains receded during the existing victory pause")
	var old_scope := scope
	game.restart_match()
	await _wait_scene("Shattergrid", old_scope)
	_expect(not sound.scopes.has(old_scope) and sound.scopes.size() == 1 and sound._cinematics.is_empty(), "Rematch replaces, rather than stacks, match audio ownership")
	_expect(sound._active.size() == 4 and sound._loops.size() == 4 and sound._loop_pool.size() <= sound.MAX_LOOPS,
		"Rematch recreates exactly four layers using the same bounded pool")
	current_scene.get_node("GameManager").return_to_loadout()
	await _wait_scene("ArmyBuilder")
	_expect(sound.scopes.size() == 1 and sound.music.state == &"army_setup" and sound._loops.is_empty(), "Returning to setup cleans all match sound state")
	_expect(sound.debug_text().contains("3/%d ready" % original_library.cues.size()), "Debug distinguishes assigned fixtures from unassigned references")
	current_scene.queue_free()
	current_scene = null
	await process_frame
	_expect(sound.scopes.is_empty(), "Closing setup releases its audio context")


func _wait_scene(expected: String, old: int = -1) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.name == expected and current_scene.get_instance_id() != old:
			await physics_frame
			return
	_expect(false, "Audio scene transition completes: " + expected)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
