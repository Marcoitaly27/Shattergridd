extends Resource
## Coordinates are authored for Player 1; formation data reflects the opposing row.

@export var slot_id: StringName
@export var category: StringName
@export var paired: bool = false
@export var left_coordinate: Vector2i
@export var mirrored_coordinate: Vector2i
## Empty permits every character of this category, including future sidegrades.
@export var allowed_character_ids: Array[StringName] = []


func accepts(character: Resource) -> bool:
	return character != null and character.deployment_category == category \
		and character.is_core_objective == (category == &"core") \
		and (allowed_character_ids.is_empty() or allowed_character_ids.has(character.character_id))


func coordinates() -> Array[Vector2i]:
	var result: Array[Vector2i] = [left_coordinate]
	if paired:
		result.append(mirrored_coordinate)
	return result
