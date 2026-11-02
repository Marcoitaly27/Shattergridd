extends Node
## Ray queries run in the physics step, not while input may lock the physics space.

var _pending_clicks: Array[Vector2] = []

@onready var camera: Camera3D = $"../Camera3D"
@onready var game: Node = $"../GameManager"


func _unhandled_input(event: InputEvent) -> void:
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
		return
	var clicks := _pending_clicks.duplicate()
	_pending_clicks.clear()
	for screen_position in clicks:
		game.handle_cell_clicked(cell_at_screen(screen_position))


func cell_at_screen(screen_position: Vector2) -> Vector2i:
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
