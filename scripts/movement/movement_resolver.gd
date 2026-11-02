extends RefCounted
## Compose character movement with active status modifiers before final validation.

var calculation_count: int = 0
const Actions = preload("res://scripts/game/character_actions.gd")

func destinations(piece: Node3D, board: RefCounted, completed_owner_turns: int) -> Array[Vector2i]:
	calculation_count += 1
	var candidates: Array[Vector2i] = []
	var behavior: Resource = piece.get_movement_behavior()
	if behavior != null and behavior.has_method("get_destinations"):
		candidates.assign(behavior.get_destinations(piece.grid_coordinate, piece.army, board))
	var cannot_capture := false
	for status in piece.statuses.active(completed_owner_turns):
		cannot_capture = cannot_capture or status.blocks_capture
		for offset in status.extra_destinations:
			var destination: Vector2i = piece.grid_coordinate + offset
			if not status.requires_clear_path or Actions.clear_path(piece.grid_coordinate, destination, board):
				candidates.append(destination)
	var result: Array[Vector2i] = []
	for cell in candidates:
		if not board.contains(cell) or cell == piece.grid_coordinate or result.has(cell):
			continue
		var occupant: Node3D = board.piece_at(cell)
		if occupant != null and (occupant.army == piece.army or cannot_capture):
			continue
		result.append(cell)
	return result
