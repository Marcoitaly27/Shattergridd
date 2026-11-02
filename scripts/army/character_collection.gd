extends Resource
## In-memory availability only. No currency, save file or unlock-condition logic.

@export var unlocked_character_ids: Array[StringName] = []


func is_unlocked(character: Resource) -> bool:
	return character != null and (character.unlocked_by_default or unlocked_character_ids.has(character.character_id))


func is_visible(character: Resource) -> bool:
	return character != null and (not character.hidden_until_unlocked or is_unlocked(character))


func unlock(character_id: StringName) -> void:
	if not unlocked_character_ids.has(character_id):
		unlocked_character_ids.append(character_id)
