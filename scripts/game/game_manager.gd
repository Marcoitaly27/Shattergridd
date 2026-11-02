extends Node
## Owns the local match loop. Input and presentation subscribe to its state.

signal turn_changed(player: int)
signal selection_changed(piece: Node3D)
signal move_finished

const BoardState = preload("res://scripts/board/board_state.gd")
const TemporaryCapture = preload("res://scripts/game/temporary_capture.gd")
const MOVE_DURATION: float = 0.24

var board_state: RefCounted
var current_player: int = 0
var selected_piece: Node3D
var is_moving: bool = false
var _capture := TemporaryCapture.new()

@onready var battlefield: Node3D = $"../Battlefield"
@onready var pieces: Node3D = $"../Pieces"


func _ready() -> void:
	board_state = BoardState.new(battlefield.board_dimensions)
	for piece in pieces.get_children():
		if not board_state.register_piece(piece):
			push_error("Invalid or duplicate starting coordinate for %s" % piece.name)
			continue
		piece.position = battlefield.position_for_cell(piece.grid_coordinate)


func valid_destinations(piece: Node3D) -> Array[Vector2i]:
	if not is_instance_valid(piece) or piece.army != current_player or is_moving:
		return []
	if board_state.piece_at(piece.grid_coordinate) != piece:
		return []
	if piece.movement_behavior == null or not piece.movement_behavior.has_method("get_destinations"):
		return []
	# Filter rule results at the boundary so later behaviors cannot bypass occupancy.
	var result: Array[Vector2i] = []
	for cell in piece.movement_behavior.get_destinations(piece.grid_coordinate, piece.army, board_state):
		if not board_state.contains(cell) or cell == piece.grid_coordinate or result.has(cell):
			continue
		var occupant: Node3D = board_state.piece_at(cell)
		if occupant == null or occupant.army != piece.army:
			result.append(cell)
	return result


func handle_cell_clicked(cell: Vector2i) -> void:
	if is_moving:
		return
	if not board_state.contains(cell):
		clear_selection()
		return
	if selected_piece != null and valid_destinations(selected_piece).has(cell):
		_start_move(cell)
		return
	var occupant: Node3D = board_state.piece_at(cell)
	if occupant != null and occupant.army == current_player:
		_select(occupant)
	else:
		clear_selection()


func clear_selection() -> void:
	if is_instance_valid(selected_piece):
		selected_piece.set_selected(false)
	selected_piece = null
	battlefield.clear_highlights()
	selection_changed.emit(null)


func _select(piece: Node3D) -> void:
	clear_selection()
	selected_piece = piece
	piece.set_selected(true)
	battlefield.show_destinations(valid_destinations(piece), board_state)
	selection_changed.emit(piece)


func _start_move(destination: Vector2i) -> void:
	var mover := selected_piece
	var captured: Node3D = board_state.piece_at(destination)
	if not board_state.move_piece(mover, destination):
		return
	# Commit occupancy and lock interaction before presentation begins.
	is_moving = true
	clear_selection()
	if captured != null:
		_capture.remove_placeholder(captured)
	var animation: Tween = mover.animate_to(battlefield.position_for_cell(destination), MOVE_DURATION)
	await animation.finished
	current_player = 1 - current_player
	is_moving = false
	turn_changed.emit(current_player)
	move_finished.emit()
