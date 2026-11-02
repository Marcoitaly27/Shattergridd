extends RefCounted
## Logical coordinates and occupancy, independent of meshes, physics and animation.

var dimensions: Vector2i
var _occupants: Dictionary = {}


func _init(size: Vector2i = Vector2i(8, 8)) -> void:
	dimensions = size


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < dimensions.x and cell.y < dimensions.y


func piece_at(cell: Vector2i) -> Node3D:
	return _occupants.get(cell) as Node3D


func register_piece(piece: Node3D) -> bool:
	var cell: Vector2i = piece.grid_coordinate
	if not contains(cell) or _occupants.has(cell):
		return false
	_occupants[cell] = piece
	return true


func move_piece(piece: Node3D, destination: Vector2i) -> bool:
	var origin: Vector2i = piece.grid_coordinate
	if not contains(destination) or origin == destination or piece_at(origin) != piece:
		return false
	var occupant := piece_at(destination)
	if occupant != null and occupant.army == piece.army:
		return false
	_occupants.erase(origin)
	_occupants[destination] = piece
	piece.grid_coordinate = destination
	return true


func remove_piece(piece: Node3D) -> bool:
	if piece_at(piece.grid_coordinate) != piece:
		return false
	_occupants.erase(piece.grid_coordinate)
	return true


func swap_pieces(first: Node3D, second: Node3D) -> bool:
	if first == second or first.army != second.army or piece_at(first.grid_coordinate) != first or piece_at(second.grid_coordinate) != second:
		return false
	var origin: Vector2i = first.grid_coordinate
	_occupants[origin] = second
	_occupants[second.grid_coordinate] = first
	first.grid_coordinate = second.grid_coordinate
	second.grid_coordinate = origin
	return true
