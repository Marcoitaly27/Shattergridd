extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func run() -> void:
	var scene: Node3D = load('res://scenes/main.tscn').instantiate()
	root.add_child(scene)
	await physics_frame
	await process_frame
	var court: Node3D = scene.get_node('VisualWorld/GroundedCourtyard')
	check(court.find_children('*', 'CollisionObject3D', true, false).is_empty(), 'Court must not intercept picking')
	check(not scene.get_node('VisualWorld').has_node('FloatingArchitecture'), 'No suspended architecture')
	var board: Node3D = scene.get_node('Battlefield')
	var camera: Camera3D = scene.get_node('Camera3D')
	var interaction: Node = scene.get_node('Interaction')
	# Remove statue picking bodies to test every actual tile surface, including occupied rows.
	for piece in scene.get_node('Pieces').get_children():
		check(absf(piece.position.y - board.position_for_cell(piece.grid_coordinate).y) < 0.001, 'Statue rests on its tile')
		for body in piece.find_children('*', 'CollisionObject3D', true, false):
			body.collision_layer = 0
	await physics_frame
	for y in range(8):
		for x in range(8):
			var cell := Vector2i(x,y)
			check(interaction.cell_at_screen(camera.unproject_position(board.position_for_cell(cell))) == cell, 'Pick tile %s' % cell)
			check(board.position_for_cell(cell).y > 0.1, 'Tile and hints above courtyard')
	var cells: Array[Vector2i] = []
	for y in range(8):
		for x in range(8):
			cells.append(Vector2i(x,y))
	board.show_destinations(cells, scene.get_node('GameManager').board_state)
	for cell in cells:
		var hint: Node3D = board.get_node('Tiles/Tile_%d_%d/MoveHint' % [cell.x,cell.y])
		check(hint.visible and hint.get_child(0).global_position.y > 0.12, 'Destination border visible above court')
	board.clear_highlights()
	print('Grounded courtyard: %d checks, %d failures' % [checks, failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
