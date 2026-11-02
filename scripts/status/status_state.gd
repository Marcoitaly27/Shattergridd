extends RefCounted
## Durations use completed owner turns, independently of animation or wall time.

var _entries: Dictionary = {}


func grant(definition: Resource, starts_after: int, expires_at: int) -> void:
	_entries[definition.status_id] = {"definition": definition, "starts_after": starts_after, "expires_at": expires_at}


func active(completed_owner_turns: int) -> Array[Resource]:
	var result: Array[Resource] = []
	for entry in _entries.values():
		if completed_owner_turns >= entry.starts_after and completed_owner_turns < entry.expires_at:
			result.append(entry.definition)
	return result


func has(status_id: StringName) -> bool:
	return _entries.has(status_id)


func expire(completed_owner_turns: int) -> void:
	for key in _entries.keys():
		if completed_owner_turns >= _entries[key].expires_at:
			_entries.erase(key)


func summary(completed_owner_turns: int) -> String:
	var names: PackedStringArray = []
	for definition in active(completed_owner_turns):
		names.append(definition.display_name)
	return ", ".join(names)
