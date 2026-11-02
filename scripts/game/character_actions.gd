extends RefCounted
## Target generation is pure gameplay; buttons, cinematics and meshes do not own it.

static func clear_path(origin: Vector2i, destination: Vector2i, board: RefCounted) -> bool:
	var difference := destination - origin
	var step := Vector2i(signi(difference.x), signi(difference.y))
	var distance := maxi(absi(difference.x), absi(difference.y))
	for index in range(1, distance):
		if board.piece_at(origin + step * index) != null:
			return false
	return true

static func targets(piece: Node3D, board: RefCounted, completed_turns: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var kind: StringName = piece.character_definition.active_ability
	if kind == &"flight":
		if not piece.statuses.active(completed_turns).any(func(status: Resource) -> bool: return status.status_id == &"flight_ready"):
			return result
		for y in range(board.dimensions.y):
			for x in range(board.dimensions.x):
				var cell := Vector2i(x, y)
				if board.piece_at(cell) == null:
					result.append(cell)
		return result
	if piece.ability_spent:
		return result
	if kind == &"bow":
		if piece.statuses.active(completed_turns).any(func(status: Resource) -> bool: return status.blocks_capture):
			return result
		for offset in [Vector2i(-2, -2), Vector2i(0, -2), Vector2i(2, -2), Vector2i(-2, 0), Vector2i(2, 0)]:
			var cell: Vector2i = piece.grid_coordinate + Vector2i(offset.x, offset.y * (1 if piece.army == 0 else -1))
			var target: Node3D = board.piece_at(cell)
			if board.contains(cell) and target != null and target.army != piece.army and clear_path(piece.grid_coordinate, cell, board):
				result.append(cell)
	elif kind == &"exchange":
		for y in range(-1, 2):
			for x in range(-1, 2):
				if x == 0 and y == 0:
					continue
				var cell: Vector2i = piece.grid_coordinate + Vector2i(x, y)
				var target: Node3D = board.piece_at(cell)
				if target != null and target.army == piece.army and not target.character_definition.is_core_objective:
					result.append(cell)
	return result
