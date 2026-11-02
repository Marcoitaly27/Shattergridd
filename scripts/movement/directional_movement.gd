@tool
extends Resource
## Offsets are authored for Ash. Slate reverses forward, not board coordinates.
@export var summary: String
@export var offsets: Array[Vector2i] = []

func get_destinations(origin: Vector2i, army: int, board: RefCounted) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in offsets:
		var cell := origin + Vector2i(offset.x, offset.y * (1 if army == 0 else -1))
		if not board.contains(cell):
			continue
		var target: Node3D = board.piece_at(cell)
		if target == null or target.army != army:
			result.append(cell)
	return result
