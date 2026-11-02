extends Node
## Two channels only. Missing tracks fade out cleanly; repeated states never stack.

var state: StringName = &"none"
var scope: int = 0
var _channels: Array[AudioStreamPlayer] = []
var _cues: Array[Resource] = []
var _gains: Array[float] = []
var _tweens: Array[Tween] = []
var _generation: int = 0
var _desired: Resource


func request_state(next_state: StringName, next_scope: int, fade: float = 1.0) -> void:
	var manager := get_parent()
	var cue: Resource = manager.library.find_cue(StringName("music." + String(next_state)))
	state = next_state
	scope = next_scope
	if cue == _desired:
		return
	_desired = cue
	_generation += 1
	for tween in _tweens:
		if is_instance_valid(tween):
			tween.kill()
	_tweens.clear()
	if cue == null or cue.streams().is_empty():
		if next_state != &"none":
			manager._observe(StringName("music." + String(next_state)), &"missing", next_scope)
		for index in range(_channels.size()):
			_fade(index, 0.0, fade, true)
		return
	if _channels.is_empty():
		for index in range(2):
			var player := AudioStreamPlayer.new()
			player.bus = &"Music"
			player.max_polyphony = 1
			add_child(player)
			player.finished.connect(_finished.bind(index))
			_channels.append(player)
			_cues.append(null)
			_gains.append(0.0)
	var incoming := 0 if _gains[0] <= _gains[1] else 1
	var outgoing := 1 - incoming
	_fade(outgoing, 0.0, fade, true)
	if _channels[incoming].playing:
		var replace := create_tween()
		replace.tween_method(_set_gain.bind(incoming), _gains[incoming], 0.0, 0.08)
		replace.tween_callback(_start.bind(incoming, cue, maxf(fade - 0.08, 0.05), _generation))
		_tweens.append(replace)
	else:
		_start(incoming, cue, fade, _generation)


func _start(index: int, cue: Resource, fade: float, generation: int) -> void:
	if generation != _generation:
		return
	_channels[index].stop()
	_cues[index] = cue
	_channels[index].stream = get_parent().choose_stream(cue)
	_set_gain(0.0, index)
	_channels[index].play()
	_fade(index, 1.0, fade, false)


func _fade(index: int, target: float, duration: float, stop: bool) -> void:
	var tween := create_tween()
	tween.tween_method(_set_gain.bind(index), _gains[index], target, maxf(duration, 0.01))
	if stop:
		tween.tween_callback(_stop.bind(index, _generation))
	_tweens.append(tween)


func _set_gain(value: float, index: int) -> void:
	_gains[index] = clampf(value, 0.0, 1.0)
	var base: float = _cues[index].volume_db if _cues[index] != null else -20.0
	_channels[index].volume_db = base + linear_to_db(maxf(_gains[index], 0.0001))


func _stop(index: int, generation: int) -> void:
	if generation != _generation:
		return
	_channels[index].stop()
	_channels[index].stream = null
	_cues[index] = null
	_gains[index] = 0.0


func _finished(index: int) -> void:
	if _cues[index] != null and _cues[index] == _desired:
		_channels[index].play()


func release_scope(leaving: int) -> void:
	if scope == leaving:
		request_state(&"none", 0, 0.35)


func active_count() -> int:
	return _channels.filter(func(player: AudioStreamPlayer) -> bool: return player.playing).size()
