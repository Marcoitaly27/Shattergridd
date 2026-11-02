extends Resource

@export var display_name: String = "Terror"
@export_multiline var description: String = "Capture: adjacent enemies cannot capture through their next turn. Empty moves allowed; Cores immune."
const TERROR: Resource = preload("res://resources/statuses/terrified.tres")


func apply(attacker: Node3D, board: RefCounted, completed_turns: Array[int]) -> void:
	for row in range(-1, 2):
		for column in range(-1, 2):
			if row == 0 and column == 0:
				continue
			var target: Node3D = board.piece_at(attacker.grid_coordinate + Vector2i(column, row))
			if target == null or target.army == attacker.army:
				continue
			var completed: int = completed_turns[target.army]
			target.apply_status(TERROR, completed, completed + 1)
