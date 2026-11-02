extends Node
## Authoritative actions and occupancy. Presentation observes signals, never unlocks play.

signal turn_changed(player: int)
signal selection_changed(piece: Node3D)
signal move_finished
signal phase_changed(phase: int)
signal capture_resolved(attacker: Node3D, victim: Node3D)
signal victory(player: int)
signal tactics_changed
signal feedback_requested(message: String, kind: StringName)

enum Phase { READY, MOVING, CAPTURING, GAME_OVER, RESTARTING, RESOLVING }

const BoardState = preload("res://scripts/board/board_state.gd")
const MovementResolver = preload("res://scripts/movement/movement_resolver.gd")
const MOVE_DURATION: float = 0.24
const VICTORY_PAUSE: float = 0.30

var board_state: RefCounted
var current_player: int = 0
var selected_piece: Node3D
var phase: Phase = Phase.READY
var winner: int = -1
var completed_turns: Array[int] = [0, 0]
var interaction_revision: int = 0
var threatened_cores: Array[Node3D] = []
var selected_destinations: Array[Vector2i] = []
var is_moving: bool:
	get:
		return phase in [Phase.MOVING, Phase.CAPTURING, Phase.RESTARTING, Phase.RESOLVING]
var _movement := MovementResolver.new()
var _move_tween: Tween
var _victory_tween: Tween
var _threat_ids: Array[StringName] = []
var _status_feedback: Dictionary = {}

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
			_set_phase(Phase.GAME_OVER)
			return
		piece.position = battlefield.position_for_cell(piece.grid_coordinate)
		piece.status_changed.connect(_on_status_changed)
		piece.status_applied.connect(_on_status_applied)
	capture_director.victim_shattered.connect(_on_victim_shattered)
	capture_director.completed.connect(_on_capture_completed)
	refresh_tactics.call_deferred()


func can_accept_input() -> bool:
	return phase == Phase.READY


func action_state_name() -> String:
	if phase == Phase.READY:
		return "PIECE_SELECTED" if is_instance_valid(selected_piece) else "TURN_IDLE"
	return {Phase.MOVING: "MOVING", Phase.CAPTURING: "CAPTURE_CINEMATIC",
		Phase.RESOLVING: "RESOLVING_ACTION", Phase.GAME_OVER: "VICTORY",
		Phase.RESTARTING: "RESTARTING"}.get(phase, "UNKNOWN")


func valid_destinations(piece: Node3D) -> Array[Vector2i]:
	if not is_instance_valid(piece) or piece.army != current_player or not can_accept_input():
		return []
	if board_state.piece_at(piece.grid_coordinate) != piece:
		return []
	return _movement.destinations(piece, board_state, completed_turns[piece.army])


func interaction_kind(cell: Vector2i) -> StringName:
	if not can_accept_input() or not board_state.contains(cell):
		return &"none"
	var occupant: Node3D = board_state.piece_at(cell)
	if occupant == selected_piece and occupant != null:
		return &"selected"
	if is_instance_valid(selected_piece) and selected_destinations.has(cell):
		return &"capture" if occupant != null else &"move"
	if occupant != null and occupant.army == current_player:
		return &"selectable"
	return &"unavailable" if occupant != null or selected_piece != null else &"normal"


func handle_cell_clicked(cell: Vector2i) -> void:
	if not can_accept_input():
		return
	if not board_state.contains(cell):
		clear_selection()
		return
	if is_instance_valid(selected_piece):
		var legal := valid_destinations(selected_piece)
		if legal.has(cell) and selected_destinations.has(cell):
			_start_move(cell)
			return
		if legal != selected_destinations:
			_refresh_selection_preview()
			feedback_requested.emit("Options changed · choose a marked tile", &"unavailable")
			return
	var occupant: Node3D = board_state.piece_at(cell)
	if occupant == selected_piece and occupant != null:
		clear_selection()
	elif occupant != null and occupant.army == current_player:
		_select(occupant)
	else:
		if occupant != null:
			var blocked_reason := ""
			if is_instance_valid(selected_piece):
				for status in selected_piece.statuses.active(completed_turns[current_player]):
					if status.blocks_capture:
						blocked_reason = status.display_name
			feedback_requested.emit("%s prevents captures" % blocked_reason if not blocked_reason.is_empty()
				else "Enemy statue · select one of your own marked attackers", &"unavailable")
		elif selected_piece != null:
			feedback_requested.emit("Unavailable destination · choose a marked tile", &"unavailable")
		clear_selection()


func clear_selection() -> void:
	if is_instance_valid(selected_piece):
		selected_piece.set_selected(false)
	selected_piece = null
	selected_destinations.clear()
	battlefield.clear_highlights()
	interaction_revision += 1
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
	if is_instance_valid(_victory_tween):
		_victory_tween.kill()
	capture_director.abort()
	_reload_match.call_deferred(scene_path)


func _select(piece: Node3D) -> void:
	clear_selection()
	selected_piece = piece
	piece.set_selected(true)
	_refresh_selection_preview()
	selection_changed.emit(piece)


func _refresh_selection_preview() -> void:
	if not is_instance_valid(selected_piece):
		clear_selection()
		return
	selected_destinations = valid_destinations(selected_piece)
	var ability_cells: Array[Vector2i] = []
	for status in selected_piece.statuses.active(completed_turns[selected_piece.army]):
		for offset in status.extra_destinations:
			var cell: Vector2i = selected_piece.grid_coordinate + offset
			if selected_destinations.has(cell) and not ability_cells.has(cell):
				ability_cells.append(cell)
	battlefield.show_destinations(selected_destinations, board_state, ability_cells)
	interaction_revision += 1


func _start_move(destination: Vector2i) -> void:
	var mover := selected_piece
	var victim: Node3D = board_state.piece_at(destination)
	if victim != null:
		_set_phase(Phase.CAPTURING)
		clear_selection()
		if not capture_director.start(mover, victim):
			_set_phase(Phase.READY)
			feedback_requested.emit("Capture unavailable · select the statue again", &"unavailable")
		return
	if not board_state.move_piece(mover, destination):
		feedback_requested.emit("Destination unavailable", &"unavailable")
		_refresh_selection_preview()
		return
	_set_phase(Phase.MOVING)
	clear_selection()
	_move_tween = mover.animate_to(battlefield.position_for_cell(destination), MOVE_DURATION)
	_move_tween.finished.connect(_finish_normal_move, CONNECT_ONE_SHOT)


func _finish_normal_move() -> void:
	# Late/repeated callbacks cannot resolve an action or advance a second turn.
	if phase != Phase.MOVING:
		return
	_move_tween = null
	_set_phase(Phase.RESOLVING)
	_advance_turn()


func _on_victim_shattered(attacker: Node3D, victim: Node3D) -> void:
	if phase != Phase.CAPTURING:
		return
	if not is_instance_valid(attacker) or not is_instance_valid(victim) \
			or board_state.piece_at(victim.grid_coordinate) != victim \
			or not board_state.move_piece(attacker, victim.grid_coordinate):
		push_error("Capture occupancy changed while gameplay was locked")
		restart_match()


func _on_capture_completed(attacker: Node3D, victim: Node3D) -> void:
	if phase != Phase.CAPTURING:
		return
	_set_phase(Phase.RESOLVING)
	var victim_was_core: bool = victim.character_definition != null and victim.character_definition.is_core_objective
	var effect: Resource = attacker.character_definition.post_capture_effect if attacker.character_definition != null else null
	_status_feedback.clear()
	if effect != null and effect.has_method("apply"):
		effect.apply(attacker, board_state, completed_turns)
	for name in _status_feedback:
		var count: int = _status_feedback[name]
		feedback_requested.emit("%s · %d %s" % [name, count, "statue" if count == 1 else "statues"], &"status")
	capture_resolved.emit(attacker, victim)
	victim.queue_free()
	if phase != Phase.RESOLVING:
		return
	if victim_was_core:
		winner = attacker.army
		refresh_tactics()
		if OS.is_debug_build():
			debug_validate_state()
		_victory_tween = create_tween()
		_victory_tween.tween_interval(VICTORY_PAUSE)
		_victory_tween.tween_callback(_present_victory)
	else:
		_advance_turn()


func _present_victory() -> void:
	if phase != Phase.RESOLVING or winner < 0:
		return
	_victory_tween = null
	_set_phase(Phase.GAME_OVER)
	victory.emit(winner)
	move_finished.emit()


func _advance_turn() -> void:
	if phase != Phase.RESOLVING or winner >= 0:
		return
	completed_turns[current_player] += 1
	for piece in pieces.get_children():
		if not piece.is_queued_for_deletion() and piece.army == current_player:
			piece.statuses.expire(completed_turns[current_player])
	current_player = 1 - current_player
	_set_phase(Phase.READY)
	refresh_tactics()
	if OS.is_debug_build():
		debug_validate_state()
	turn_changed.emit(current_player)
	move_finished.emit()


func _on_status_changed(piece: Node3D) -> void:
	piece.refresh_status_indicators(completed_turns[piece.army])
	if can_accept_input():
		if selected_piece == piece:
			_refresh_selection_preview()
		refresh_tactics()


func _on_status_applied(_piece: Node3D, definition: Resource) -> void:
	if phase == Phase.RESOLVING:
		_status_feedback[definition.display_name] = _status_feedback.get(definition.display_name, 0) + 1
	else:
		feedback_requested.emit(definition.display_name, &"status")


func refresh_tactics() -> void:
	threatened_cores.clear()
	var active: Array[Node3D] = []
	for piece in pieces.get_children():
		if not piece.is_queued_for_deletion() and board_state.piece_at(piece.grid_coordinate) == piece:
			active.append(piece)
			piece.refresh_status_indicators(completed_turns[piece.army])
			piece.set_threatened(false)
	var cores: Array[Node3D] = []
	for piece in active:
		if piece.character_definition != null and piece.character_definition.is_core_objective:
			cores.append(piece)
	for enemy in active:
		var legal := _movement.destinations(enemy, board_state, completed_turns[enemy.army])
		for core in cores:
			if core.army != enemy.army and legal.has(core.grid_coordinate) and not threatened_cores.has(core):
				threatened_cores.append(core)
	var next_ids: Array[StringName] = []
	for core in threatened_cores:
		core.set_threatened(true)
		next_ids.append(core.piece_id)
		if not _threat_ids.has(core.piece_id):
			feedback_requested.emit("PLAYER %d CORE THREATENED" % (core.army + 1), &"threat")
	_threat_ids = next_ids
	interaction_revision += 1
	tactics_changed.emit()


func debug_validate_state(report: bool = true) -> Array[String]:
	var issues: Array[String] = []
	var seen: Dictionary = {}
	for piece in pieces.get_children():
		if piece.is_queued_for_deletion():
			continue
		if seen.has(piece.grid_coordinate) or board_state.piece_at(piece.grid_coordinate) != piece:
			issues.append("Duplicate/mismatched occupancy: %s" % piece.name)
		seen[piece.grid_coordinate] = true
		if piece.position.distance_to(battlefield.position_for_cell(piece.grid_coordinate)) > 0.02:
			issues.append("Piece is not centered on its logical tile: %s" % piece.name)
	if selected_piece != null:
		if not is_instance_valid(selected_piece):
			issues.append("Selected piece has already been destroyed")
		elif board_state.piece_at(selected_piece.grid_coordinate) != selected_piece:
			issues.append("Selected piece is no longer in occupancy")
	if report and not issues.is_empty():
		push_error("Action invariant failed: %s" % "; ".join(issues))
	return issues


func _set_phase(value: Phase) -> void:
	phase = value
	interaction_revision += 1
	phase_changed.emit(value)


func _reload_match(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not change match scene: %s" % error_string(error))
