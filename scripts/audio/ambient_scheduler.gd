extends Node
## Rare categories have independent timers; missing-only groups schedule no work.

const WorldEvents = preload("res://resources/audio/world_events.tres")
const Bell = preload("res://resources/audio/bell.tres")
var groups: Array[Resource] = [WorldEvents, Bell]
var scope: int = 0
var _timers: Dictionary = {}
var _enabled: Dictionary = {}
var _last: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func start(owner_scope: int) -> void:
	scope = owner_scope
	_rng.randomize()
	for group in groups:
		set_category_enabled(group.category, group.enabled)


func set_category_enabled(category: StringName, enabled: bool) -> void:
	_enabled[category] = enabled
	if _timers.has(category):
		_timers[category].stop()
	for group in groups:
		if group.category == category and enabled:
			_schedule(group)


func available(group: Resource) -> Array[Resource]:
	var choices: Array[Resource] = []
	var manager := get_node("/root/SoundManager")
	for entry in group.events:
		var cue: Resource = manager.library.find_cue(entry.cue_id) if entry != null else null
		if cue != null and entry.weight > 0.0 and not cue.streams().is_empty():
			choices.append(entry)
	return choices


func choose(group: Resource) -> Resource:
	var choices := available(group)
	if choices.size() > 1:
		choices = choices.filter(func(entry: Resource) -> bool: return entry.cue_id != _last.get(group.category, &""))
	if choices.is_empty():
		return null
	var total := 0.0
	for entry in choices:
		total += entry.weight
	var value := _rng.randf() * total
	for entry in choices:
		value -= entry.weight
		if value <= 0:
			_last[group.category] = entry.cue_id
			return entry
	return choices.back()


func _schedule(group: Resource) -> void:
	if not _enabled.get(group.category, false) or available(group).is_empty():
		return
	if not _timers.has(group.category):
		var timer := Timer.new()
		timer.one_shot = true
		timer.timeout.connect(_trigger.bind(group))
		add_child(timer)
		_timers[group.category] = timer
	var minimum := maxf(group.min_interval, 1.0)
	_timers[group.category].start(_rng.randf_range(minimum, maxf(group.max_interval, minimum)))


func _trigger(group: Resource) -> void:
	if not _enabled.get(group.category, false):
		return
	var event := choose(group)
	if event != null:
		get_node("/root/SoundManager").play_id(event.cue_id, event.position if event.has_position else null, scope, &"ambience")
	_schedule(group)
