extends Resource
## Temporary rule. Future characters can supply a different movement resource
## implementing get_destinations(origin, army, board) without changing interaction.

@export var summary: String = "1 tile in any of 8 directions. Friendly tiles blocked."

func get_destinations(origin: Vector2i, army: int, board: RefCounted) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for row_offset in range(-1, 2):
		for column_offset in range(-1, 2):
			if row_offset == 0 and column_offset == 0:
				continue
			var cell := origin + Vector2i(column_offset, row_offset)
			if not board.contains(cell):
				continue
			var occupant: Node3D = board.piece_at(cell)
			if occupant == null or occupant.army != army:
				destinations.append(cell)
	return destinations
