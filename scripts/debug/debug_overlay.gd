extends CanvasLayer
## F3 diagnostics exist only in debug builds and do no work while hidden/disabled.

@export var enabled: bool = true
var panel: PanelContainer
var text: Label
var _age: float = 0.0

@onready var game: Node = $"../GameManager"
@onready var interaction: Node = $"../Interaction"


func _ready() -> void:
	set_process(false)
	if not enabled or not OS.is_debug_build():
		set_process_unhandled_key_input(false)
		return
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(18, 128)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.022, 0.025, 0.94)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	text = Label.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size", 14)
	panel.add_child(text)
	panel.hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if enabled and panel != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		panel.visible = not panel.visible
		set_process(panel.visible)
		if panel.visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not enabled:
		panel.hide()
		set_process(false)
		return
	_age += delta
	if _age >= 0.25:
		_age = 0.0
		_refresh()


func _refresh() -> void:
	var selected := "None"
	if is_instance_valid(game.selected_piece):
		selected = "%s %s" % [game.selected_piece.piece_id, game.selected_piece.grid_coordinate]
	var active := 0
	for piece in game.pieces.get_children():
		if not piece.is_queued_for_deletion():
			active += 1
	text.text = "DEVELOPMENT · F3\nFPS %d · %s\nPlayer %d · completed %s\nSelected %s\nHover %s · %s\nPieces %d · effects %d\nCinematic %s · camera %s\nNodes %d · draw calls %d\nMove calculations %d · pick rays %d" % [
		Engine.get_frames_per_second(), game.action_state_name(), game.current_player + 1, game.completed_turns,
		selected, interaction.hovered_cell, interaction.hover_kind, active, $"../Effects".get_child_count(),
		"ACTIVE" if game.capture_director.active else "idle", "cinematic" if game.capture_director.active else "strategic",
		get_tree().get_node_count(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		game._movement.calculation_count, interaction.ray_query_count]
