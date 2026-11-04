extends SceneTree
var failures: int = 0
var checks: int = 0
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
	var cathedral: Node3D = scene.get_node('ruined cathedral 3d model')
	check(cathedral.find_children('*','CollisionObject3D',true,false).is_empty(),'Scenery has no gameplay collision')
	var camera: Camera3D = scene.get_node('Camera3D')
	var board: Node3D = scene.get_node('Battlefield')
	var input: Node = scene.get_node('Interaction')
	var results: Array = []
	for y in range(8):
		for x in range(8):
			var cell := Vector2i(x,y)
			results.append(input.cell_at_screen(camera.unproject_position(board.position_for_cell(cell))))
	cathedral.hide()
	await physics_frame
	for y in range(8):
		for x in range(8):
			check(input.cell_at_screen(camera.unproject_position(board.position_for_cell(Vector2i(x,y)))) == results[y*8+x], 'Cathedral preserves board picking')
	print('Cathedral smoke: %d checks, %d failures' % [checks,failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
