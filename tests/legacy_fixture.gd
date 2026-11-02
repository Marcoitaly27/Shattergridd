extends RefCounted
## Historical presentation/interaction regression fixtures, not live match rules.
## Roster smoke exercises current production defaults, protections and abilities.
static func configure(scene: Node, uniform_movement: bool = true) -> void:
	for piece in scene.get_node("Pieces").get_children():
		if piece.character_definition.character_id == &"werewolf":
			piece.character_definition = load("res://resources/characters/executioner.tres")
		piece.shield_spent = true
		piece.ability_spent = true
		if uniform_movement:
			piece.movement_behavior = load("res://resources/characters/temporary_movement.tres")
