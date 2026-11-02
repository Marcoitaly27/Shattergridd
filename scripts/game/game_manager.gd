extends Node
## Authoritative turns, occupancy and resolution; cinematic presentation is external.

signal turn_changed(player: int)
signal selection_changed(piece: Node3D)
signal move_finished
signal phase_changed(phase: int)
signal capture_resolved(attacker: Node3D, victim: Node3D)
signal victory(player: int)

enum Phase { READY, MOVING, CAPTURING, GAME_OVER, RESTARTING }

const BoardState = preload("res://scripts/board/board_state.gd")
const MovementResolver = preload("res://scripts/movement/movement_resolver.gd")
const MOVE_DURATION: float = 0.24

var board_state: RefCounted
var current_player: int = 0
var selected_piece: Node3D
var phase: Phase = Phase.READY
var winner: int = -1
var completed_turns: Array[int] = [0, 0]
var is_moving: bool:
	get:
		return phase in [Phase.MOVING, Phase.CAPTURING, Phase.RESTARTING]
var _movement := MovementResolver.new()
var _move_tween: Tween

@onready var battlefield: Node3D = $"../Battlefield"
@onready var pieces: Node3D = $"../Pieces"
@onready var capture_director: Node = $"../CaptureDirector"


func _ready() -> void:
	board_state = BoardState.new(battlefield.board_dimensions)
	var deployment := get_node_or_null("../ArmyDeployment")
	if deployment != null and not deployment.validation_errors.is_empty():
		_set_phase(Phase.GAME_OVER)
		return
	for piece in pieces.get_children():
		if not board_state.register_piece(piece):
			push_error("Invalid or duplicate starting coordinate for %s" % piece.name)
			continue
		piece.position = battlefield.position_for_cell(piece.grid_coordinate)
	capture_director.victim_shattered.connect(_on_victim_shattered)
	capture_director.completed.connect(_on_capture_completed)


func can_accept_input() -> bool:
	return phase == Phase.READY


func valid_destinations(piece: Node3D) -> Array[Vector2i]:
	if not is_instance_valid(piece) or piece.army != current_player or not can_accept_input():
		return []
	if board_state.piece_at(piece.grid_coordinate) != piece:
		return []
	return _movement.destinations(piece, board_state, completed_turns[piece.army])


func handle_cell_clicked(cell: Vector2i) -> void:
	if not can_accept_input():
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


func restart_match() -> void:
	_leave_match("res://scenes/main.tscn")


func return_to_loadout() -> void:
	_leave_match("res://scenes/ui/army_builder.tscn")


func _leave_match(scene_path: String) -> void:
	if phase == Phase.RESTARTING:
		return
	_set_phase(Phase.RESTARTING)
	clear_selection()
	if is_instance_valid(_move_tween):
		_move_tween.kill()
	capture_director.abort()
	_reload_match.call_deferred(scene_path)


func _select(piece: Node3D) -> void:
	clear_selection()
	selected_piece = piece
	piece.set_selected(true)
	battlefield.show_destinations(valid_destinations(piece), board_state)
	selection_changed.emit(piece)


func _start_move(destination: Vector2i) -> void:
	var mover := selected_piece
	var victim: Node3D = board_state.piece_at(destination)
	if victim != null:
		_set_phase(Phase.CAPTURING)
		clear_selection()
		if not capture_director.start(mover, victim):
			_set_phase(Phase.READY)
		return
	if not board_state.move_piece(mover, destination):
		return
	_set_phase(Phase.MOVING)
	clear_selection()
	_move_tween = mover.animate_to(battlefield.position_for_cell(destination), MOVE_DURATION)
	_move_tween.finished.connect(_finish_normal_move, CONNECT_ONE_SHOT)


func _finish_normal_move() -> void:
	_move_tween = null
	_advance_turn()


func _on_victim_shattered(attacker: Node3D, victim: Node3D) -> void:
	if phase != Phase.CAPTURING:
		return
	# The victim remains authoritative until the destruction event, not the click.
	if board_state.piece_at(victim.grid_coordinate) != victim or not board_state.move_piece(attacker, victim.grid_coordinate):
		push_error("Capture occupancy changed while gameplay was locked")
		restart_match()


func _on_capture_completed(attacker: Node3D, victim: Node3D) -> void:
	if phase != Phase.CAPTURING:
		return
	var victim_was_core: bool = victim.character_definition != null and victim.character_definition.is_core_objective
	var effect: Resource = attacker.character_definition.post_capture_effect if attacker.character_definition != null else null
	if effect != null and effect.has_method("apply"):
		effect.apply(attacker, board_state, completed_turns)
	capture_resolved.emit(attacker, victim)
	victim.queue_free()
	if victim_was_core:
		winner = attacker.army
		_set_phase(Phase.GAME_OVER)
		victory.emit(winner)
		move_finished.emit()
	else:
		_advance_turn()


func _advance_turn() -> void:
	completed_turns[current_player] += 1
	for piece in pieces.get_children():
		if not piece.is_queued_for_deletion() and piece.army == current_player:
			piece.statuses.expire(completed_turns[current_player])
	current_player = 1 - current_player
	_set_phase(Phase.READY)
	turn_changed.emit(current_player)
	move_finished.emit()


func _set_phase(value: Phase) -> void:
	phase = value
	phase_changed.emit(value)


func _reload_match(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not restart match: %s" % error_string(error))
