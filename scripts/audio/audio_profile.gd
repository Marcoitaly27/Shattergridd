extends Resource
## Event -> layered cue IDs. A shared movement fallback avoids duplicated mappings.

@export var profile_id: StringName
@export var movement_profile: Resource
@export var events: Dictionary = {}


func cues_for(event: StringName, depth: int = 0) -> Array[StringName]:
	var result: Array[StringName] = []
	if events.has(event):
		result.assign(events[event])
	elif movement_profile != null and depth < 3:
		result.assign(movement_profile.cues_for(event, depth + 1))
	return result
