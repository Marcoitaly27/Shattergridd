extends Resource
## Explicit registry: no gameplay controller needs a roster switch or file scan.

const CharacterDefinition = preload("res://scripts/pieces/character_definition.gd")
const CATEGORIES: Array[StringName] = [&"core", &"guard", &"hunt", &"power", &"special", &"random"]
@export var characters: Array[CharacterDefinition] = []


func find_character(id: StringName) -> Resource:
	for character in characters:
		if character != null and character.character_id == id:
			return character
	return null


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	var ids: Dictionary = {}
	for character in characters:
		if character == null:
			errors.append("Catalog contains an empty definition.")
			continue
		if character.character_id == &"" or ids.has(character.character_id):
			errors.append("Character IDs must be nonempty and unique: %s." % character.character_id)
		ids[character.character_id] = true
		if not CATEGORIES.has(character.deployment_category):
			errors.append("Unknown category for %s." % character.character_id)
		if character.is_core_objective != (character.deployment_category == &"core"):
			errors.append("Core objective/category mismatch for %s." % character.character_id)
		if character.model_scene == null or character.movement_behavior == null:
			errors.append("Missing model or movement for %s." % character.character_id)
	return errors
