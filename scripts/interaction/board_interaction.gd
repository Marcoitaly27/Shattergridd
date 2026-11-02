extends Node
## Ray queries run in the physics step, not while input may lock the physics space.

signal hover_changed(cell: Vector2i, kind: StringName, piece: Node3D)
var _pending_clicks: Array[Vector2] = []
var hovered_cell: Vector2i = Vector2i(-1, -1)
var hover_kind: StringName = &"none"
var _hovered_piece: Node3D
var _pointer_position: Vector2 = Vector2(-100, -100)
var _last_position: Vector2 = Vector2.INF
var _last_revision: int = -1
var ray_query_count: int = 0

@onready var camera: Camera3D = $"../Camera3D"
@onready var game: Node = $"../GameManager"


func _ready() -> void:
	get_viewport().size_changed.connect(func() -> void:
		_last_position = Vector2.INF
		_last_revision = -1
		_pointer_position = get_viewport().get_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_pointer_position = event.position
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_pending_clicks.clear()
			game.restart_match()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_SPACE and OS.is_debug_build() and game.capture_director.active:
			game.capture_director.accelerate()
			get_viewport().set_input_as_handled()
			return
	if not game.can_accept_input():
		_pending_clicks.clear()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_pending_clicks.clear()
		game.clear_selection()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pending_clicks.append(event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_pending_clicks.clear()
			game.clear_selection()
			get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not game.can_accept_input():
		_pending_clicks.clear()
		_clear_hover()
		return
	var clicks := _pending_clicks.duplicate()
	_pending_clicks.clear()
	for screen_position in clicks:
		game.handle_cell_clicked(cell_at_screen(screen_position))
	var over_ui := get_viewport().gui_get_hovered_control() != null
	if over_ui:
		_clear_hover()
		_last_position = Vector2.INF
	elif _last_position != _pointer_position or _last_revision != game.interaction_revision:
		update_hover(_pointer_position)


func update_hover(screen_position: Vector2) -> void:
	_last_position = screen_position
	_last_revision = game.interaction_revision
	if not game.can_accept_input():
		_clear_hover()
		return
	var cell := cell_at_screen(screen_position)
	var kind: StringName = game.interaction_kind(cell)
	var piece: Node3D = game.board_state.piece_at(cell)
	if cell == hovered_cell and kind == hover_kind and piece == _hovered_piece:
		return
	_clear_hover(false)
	hovered_cell = cell
	hover_kind = kind
	_hovered_piece = piece
	if piece != null and kind in [&"selectable", &"capture"]:
		piece.set_hovered(true, kind == &"capture")
	game.battlefield.set_hover(cell, kind)
	hover_changed.emit(cell, kind, piece)


func _clear_hover(notify: bool = true) -> void:
	if is_instance_valid(_hovered_piece):
		_hovered_piece.set_hovered(false)
	var had_hover := hover_kind != &"none"
	_hovered_piece = null
	hovered_cell = Vector2i(-1, -1)
	hover_kind = &"none"
	game.battlefield.set_hover(hovered_cell, &"none")
	if notify and had_hover:
		hover_changed.emit(hovered_cell, &"none", null)


func cell_at_screen(screen_position: Vector2) -> Vector2i:
	ray_query_count += 1
	var origin := camera.project_ray_origin(screen_position)
	var end := origin + camera.project_ray_normal(screen_position) * camera.far
	var query := PhysicsRayQueryParameters3D.create(origin, end, 3)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector2i(-1, -1)
	var collider: CollisionObject3D = hit.collider
	if collider.has_meta("piece"):
		var piece: Node3D = collider.get_meta("piece")
		return piece.grid_coordinate
	return collider.get_meta("grid_coordinate", Vector2i(-1, -1))
