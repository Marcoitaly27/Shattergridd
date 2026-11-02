extends Resource
## One character ID per slot choice, not one choice per reflected statue.

@export var selections: Dictionary = {}


func character_for(slot_id: StringName) -> StringName:
	return StringName(selections.get(slot_id, &""))


func set_character(slot_id: StringName, character_id: StringName) -> void:
	selections[slot_id] = character_id


func copy() -> Resource:
	var result := (get_script() as Script).new() as Resource
	result.selections = selections.duplicate()
	return result
