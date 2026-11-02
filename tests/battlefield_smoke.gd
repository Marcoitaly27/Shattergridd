extends SceneTree
## Native integration check: scene resources, layout, army identity and camera framing.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	_expect(load(main_path) is PackedScene, "Configured launch scene loads")
	# The launch scene is now the army builder; this suite verifies the battlefield.
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var board := scene.get_node("Battlefield")
	var tiles := board.get_node("Tiles")
	_expect(tiles.get_child_count() == 64, "Exactly 64 tiles")
	var cells: Dictionary = {}
	for tile in tiles.get_children():
		var coordinate: Vector2i = tile.get_meta("grid_coordinate")
		_expect(not cells.has(coordinate), "Tile coordinate is unique")
		cells[coordinate] = tile
		_expect(coordinate.x >= 0 and coordinate.x < 8 and coordinate.y >= 0 and coordinate.y < 8,
			"Tile coordinate is on the 8x8 grid")
		_expect(tile.mesh != null and tile.material_override != null, "Tile has mesh and material")
	var pieces := scene.get_node("Pieces")
	_expect(pieces.get_child_count() == 16, "Exactly 16 placeholders")
	var ids: Dictionary = {}
	var occupied: Dictionary = {}
	var armies := [0, 0]
	for piece in pieces.get_children():
		_expect(not ids.has(piece.piece_id), "Piece identity is unique")
		ids[piece.piece_id] = true
		_expect(not occupied.has(piece.grid_coordinate), "One placeholder per starting tile")
		occupied[piece.grid_coordinate] = true
		armies[piece.army] += 1
		_expect(piece.grid_coordinate.y == (7 if piece.army == 0 else 0), "Armies occupy opposite edges")
		var tile: MeshInstance3D = cells[piece.grid_coordinate]
		_expect(Vector2(tile.position.x, tile.position.z).distance_to(
			Vector2(piece.position.x, piece.position.z)) < 0.001, "Piece centered on tile")
		_expect(absf(piece.position.y - (tile.position.y + 0.12)) < 0.035,
			"Piece rests on tile surface")
		_expect(piece.character_definition != null and piece.get_node_or_null("Visuals/Model") != null,
			"Character definition supplies a replaceable model")
		var meshes := piece.get_node("Visuals/Model").find_children("*", "MeshInstance3D", true, false)
		_expect(meshes.all(func(mesh: MeshInstance3D) -> bool:
			return mesh.material_override == piece.character_definition.team_materials[piece.army]),
			"Army stone palette applies to every prototype part")
	_expect(armies == [8, 8], "Eight pieces per army")
	var camera: Camera3D = scene.get_node("Camera3D")
	_expect(camera.current and camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Active perspective camera")
	# Conservative bounds include the rim, underside and the tops of both armies.
	var viewport_rect := root.get_visible_rect()
	for x in [-6.9, 6.9]:
		for y in [-2.5, 1.8]:
			for z in [-6.9, 6.9]:
				var corner := Vector3(x, y, z)
				_expect(not camera.is_position_behind(corner), "Battlefield is in front of camera")
				_expect(viewport_rect.has_point(camera.unproject_position(corner)), "Whole battlefield fits in frame")
	var environment: Environment = scene.get_node("WorldEnvironment").environment
	_expect(environment != null and environment.fog_enabled, "Native atmosphere configured")
	_expect(scene.get_node("Moonlight").shadow_enabled, "Key light casts shadows")
	_expect(board.get_node("Foundation").get_child_count() > 0, "Suspended stone foundation exists")
	print("Battlefield smoke: %d checks, %d failures" % [checks, failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
