extends RefCounted
## Durations use completed owner turns, independently of animation or wall time.

signal changed
signal granted(definition: Resource)
var _entries: Dictionary = {}


func grant(definition: Resource, starts_after: int, expires_at: int) -> void:
	_entries[definition.status_id] = {"definition": definition, "starts_after": starts_after, "expires_at": expires_at}
	changed.emit()
	granted.emit(definition)


func active(completed_owner_turns: int) -> Array[Resource]:
	var result: Array[Resource] = []
	for entry in _entries.values():
		if completed_owner_turns >= entry.starts_after and completed_owner_turns < entry.expires_at:
			result.append(entry.definition)
	return result


func has(status_id: StringName) -> bool:
	return _entries.has(status_id)


func remove(status_id: StringName) -> void:
	if _entries.erase(status_id):
		changed.emit()


func expire(completed_owner_turns: int) -> void:
	var removed := false
	for key in _entries.keys():
		if completed_owner_turns >= _entries[key].expires_at:
			_entries.erase(key)
			removed = true
	if removed:
		changed.emit()


func describe(completed_owner_turns: int) -> String:
	var lines: PackedStringArray = []
	for entry in _entries.values():
		if completed_owner_turns >= entry.expires_at:
			continue
		var timing := "next owner turn" if completed_owner_turns < entry.starts_after else "ends with owner turn"
		lines.append("%s · %s\n%s" % [entry.definition.display_name, timing, entry.definition.description])
	return "\n".join(lines) if not lines.is_empty() else "None"


func markers(completed_owner_turns: int) -> String:
	var result: PackedStringArray = []
	for entry in _entries.values():
		if completed_owner_turns < entry.expires_at:
			result.append(entry.definition.marker_text + ("·" if completed_owner_turns < entry.starts_after else ""))
	return " ".join(result)


func summary(completed_owner_turns: int) -> String:
	var names: PackedStringArray = []
	for definition in active(completed_owner_turns):
		names.append(definition.display_name)
	return ", ".join(names)
