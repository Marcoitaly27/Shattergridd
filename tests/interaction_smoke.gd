extends SceneTree
## Tests logical rules, actual physics picking, input routing, tweens and turn flow.

const BoardState = preload("res://scripts/board/board_state.gd")
const AdjacentMovement = preload("res://scripts/movement/adjacent_movement.gd")
const PieceScene = preload("res://scenes/pieces/placeholder_piece.tscn")

var checks: int = 0
var failures: int = 0
var scene: Node3D
var game: Node
var board: Node3D
var interaction: Node
var camera: Camera3D


class DifferentMovement extends Resource:
	func get_destinations(origin: Vector2i, _army: int, _board: RefCounted) -> Array[Vector2i]:
		return [origin + Vector2i(0, -2), origin + Vector2i(1, 0), Vector2i(-100, 0), origin]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_logical_rules()
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	game = scene.get_node("GameManager")
	board = scene.get_node("Battlefield")
	interaction = scene.get_node("Interaction")
	camera = scene.get_node("Camera3D")
	await _settle()
	var ash: Node3D = scene.get_node("Pieces/Ash_01")
	var ash_two: Node3D = scene.get_node("Pieces/Ash_02")
	var slate: Node3D = scene.get_node("Pieces/Slate_01")
	var label: Label = scene.get_node("Interface/Panel/Margin/Rows/Turn")
	_expect(game.current_player == 0 and label.text == "PLAYER 1 TURN", "Player 1 starts and UI agrees")

	# Use actual physics rays across the board, including edge tiles and piece bodies.
	for row in range(1, 7):
		for column in range(8):
			var cell := Vector2i(column, row)
			_expect(interaction.cell_at_screen(camera.unproject_position(board.position_for_cell(cell))) == cell,
				"Ray picks tile %s" % cell)
	for piece in scene.get_node("Pieces").get_children():
		var screen := camera.unproject_position(piece.global_position + Vector3(0, 1.0, 0))
		_expect(interaction.cell_at_screen(screen) == piece.grid_coordinate, "Ray picks %s by its body" % piece.name)

	await _click_cell(slate.grid_coordinate)
	_expect(game.selected_piece == null, "Inactive player's piece cannot be selected")
	await _click_cell(ash.grid_coordinate)
	_expect(game.selected_piece == ash and ash.get_node("SelectionRing").visible, "Mouse selects Player 1 piece")
	_expect(_hint_count() == 2, "Corner piece shows two unoccupied neighboring destinations")
	_expect(not board.get_node("Tiles/Tile_1_7/MoveHint").visible, "Friendly occupied tile is not a destination")
	await _click_cell(ash_two.grid_coordinate)
	_expect(game.selected_piece == ash_two and not ash.get_node("SelectionRing").visible,
		"Clicking friendly piece changes selection without moving")
	_expect(game.current_player == 0 and ash_two.grid_coordinate == Vector2i(1, 7), "Selection does not consume a turn")
	await _click_cell(Vector2i(4, 4))
	_expect(game.selected_piece == null and _hint_count() == 0, "Invalid destination clears selection")
	_expect(ash_two.grid_coordinate == Vector2i(1, 7) and game.current_player == 0, "Invalid destination does not move or change turns")

	await _click_cell(ash.grid_coordinate)
	await _click_screen(Vector2(2, 2))
	_expect(game.selected_piece == null and _hint_count() == 0, "Click outside the battlefield clears selection")
	await _click_cell(ash.grid_coordinate)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await _settle()
	_expect(game.selected_piece == null and _hint_count() == 0, "Escape clears selection")
	await _click_cell(ash.grid_coordinate)
	await _click_screen(camera.unproject_position(ash.position), MOUSE_BUTTON_RIGHT)
	_expect(game.selected_piece == null, "Right mouse cancels selection")

	# Movement resource can be replaced without changing manager or input code.
	var original_rule: Resource = ash.movement_behavior
	ash.movement_behavior = DifferentMovement.new()
	_expect(game.valid_destinations(ash) == [Vector2i(0, 5)], "Per-piece rule replacement and boundary filtering")
	ash.movement_behavior = original_rule

	await _click_cell(ash_two.grid_coordinate)
	var start := ash_two.position
	await _click_cell(Vector2i(0, 6))
	_expect(game.is_moving and game.current_player == 0, "Turn stays locked until tween completes")
	_expect(ash_two.grid_coordinate == Vector2i(0, 6), "Logical coordinate commits before animation")
	_expect(game.board_state.piece_at(Vector2i(1, 7)) == null, "Source occupancy cleared")
	_expect(game.board_state.piece_at(Vector2i(0, 6)) == ash_two, "Destination occupancy assigned")
	_expect(ash_two.position.distance_to(board.position_for_cell(Vector2i(0, 6))) > 0.1,
		"Movement is animated rather than teleported")
	_expect(ash_two.position.distance_to(start) < 1.0, "Tween starts near the original tile")
	_expect(game.selected_piece == null and _hint_count() == 0, "Move clears selection and highlights")
	game.handle_cell_clicked(ash.grid_coordinate)
	_expect(game.selected_piece == null, "Additional input is ignored during a move")
	await _finish_move()
	_expect(game.current_player == 1 and label.text == "PLAYER 2 TURN", "Successful diagonal move switches to Player 2")
	_expect(ash_two.position.is_equal_approx(board.position_for_cell(Vector2i(0, 6))), "Tween lands exactly at tile top")
	await _click_cell(ash_two.grid_coordinate)
	_expect(game.selected_piece == null, "Player 1 cannot select after turn switches")
	await _click_cell(slate.grid_coordinate)
	_expect(game.selected_piece == slate, "Player 2 can select own piece")
	await _click_cell(Vector2i(0, 1))
	await _finish_move()
	_expect(game.current_player == 0 and slate.grid_coordinate == Vector2i(0, 1), "Player 2 moves and hands turn back")

	# Put the enemy in reach as a fixture; the tested capture uses normal mouse input.
	_expect(game.board_state.move_piece(slate, Vector2i(1, 5)), "Prepare nearby enemy fixture")
	slate.position = board.position_for_cell(Vector2i(1, 5))
	await _settle()
	await _click_cell(ash_two.grid_coordinate)
	_expect(board.get_node("Tiles/Tile_1_5/MoveHint").visible, "Enemy destination is highlighted")
	var attack_edge: MeshInstance3D = board.get_node("Tiles/Tile_1_5/MoveHint").get_child(0)
	_expect(attack_edge.material_override == preload("res://materials/attack_hint.tres"), "Enemy move uses restrained attack color")
	await _click_cell(slate.grid_coordinate)
	await _finish_move()
	_expect(not is_instance_valid(slate), "Temporary capture removes enemy placeholder")
	_expect(game.board_state.piece_at(Vector2i(1, 5)) == ash_two and game.board_state.piece_at(Vector2i(0, 6)) == null,
		"Capture updates both occupancy cells")
	_expect(scene.get_node("Pieces").get_child_count() == 15, "One enemy removed, other pieces retained")
	_expect(game.current_player == 1 and label.text == "PLAYER 2 TURN", "Capture consumes exactly one turn")
	var next_slate: Node3D = scene.get_node("Pieces/Slate_08")
	await _click_cell(next_slate.grid_coordinate)
	await _click_cell(Vector2i(7, 1))
	await _finish_move()
	_expect(game.current_player == 0 and next_slate.grid_coordinate == Vector2i(7, 1), "Alternating turns continue after a capture")
	_expect(_hint_count() == 0 and game.selected_piece == null, "No stale highlights after subsequent move")
	print("Interaction smoke: %d checks, %d failures" % [checks, failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _test_logical_rules() -> void:
	var state := BoardState.new(Vector2i(5, 3))
	var mover := PieceScene.instantiate()
	mover.grid_coordinate = Vector2i(2, 1)
	var ally := PieceScene.instantiate()
	ally.grid_coordinate = Vector2i(1, 1)
	var enemy := PieceScene.instantiate()
	enemy.army = 1
	enemy.grid_coordinate = Vector2i(3, 1)
	_expect(state.register_piece(mover), "Register piece on non-8x8 logical board")
	var rule := AdjacentMovement.new()
	_expect(rule.get_destinations(mover.grid_coordinate, mover.army, state).size() == 8, "Temporary rule allows all eight neighbors")
	_expect(state.register_piece(ally) and state.register_piece(enemy), "Register friendly and enemy occupants")
	_expect(not state.register_piece(mover), "Duplicate registration rejected")
	var destinations := rule.get_destinations(mover.grid_coordinate, mover.army, state)
	_expect(not destinations.has(ally.grid_coordinate) and destinations.has(enemy.grid_coordinate), "Allies blocked and enemies attackable")
	_expect(not destinations.has(Vector2i(4, 1)) and not destinations.has(mover.grid_coordinate), "No long move or zero-length move")
	_expect(rule.get_destinations(Vector2i(0, 0), 0, BoardState.new()).size() == 3, "Corner movement stays on board")
	_expect(not state.contains(Vector2i(5, 2)) and not state.contains(Vector2i(4, 3)), "Custom board dimensions respected")
	_expect(not state.move_piece(mover, ally.grid_coordinate), "State rejects friendly destination")
	_expect(not state.move_piece(mover, Vector2i(-1, 1)), "State rejects out-of-bounds destination")
	_expect(mover.grid_coordinate == Vector2i(2, 1) and state.piece_at(Vector2i(2, 1)) == mover,
		"Rejected moves preserve coordinates and occupancy")
	_expect(state.move_piece(mover, enemy.grid_coordinate), "State accepts enemy destination")
	_expect(state.piece_at(Vector2i(2, 1)) == null and state.piece_at(Vector2i(3, 1)) == mover,
		"Logical capture replaces occupant atomically")
	mover.free()
	ally.free()
	enemy.free()


func _click_cell(cell: Vector2i) -> void:
	var point: Vector3 = board.position_for_cell(cell)
	if game.board_state.piece_at(cell) != null:
		point.y += 1.0
	await _click_screen(camera.unproject_position(point))


func _click_screen(position: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await _settle()


func _settle() -> void:
	await physics_frame
	await process_frame


func _finish_move() -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not game.is_moving, "Move animation completes within two seconds")


func _hint_count() -> int:
	var count := 0
	for tile in board.get_node("Tiles").get_children():
		if tile.get_node("MoveHint").visible:
			count += 1
	return count


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
