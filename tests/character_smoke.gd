extends SceneTree
## Prototype identity, footprint, model replacement and native picking contracts.

const CharacterDefinition = preload("res://scripts/pieces/character_definition.gd")
const PieceScene = preload("res://scenes/pieces/placeholder_piece.tscn")
const ARCHETYPES := ["core", "warden", "hunter", "executioner", "witch", "wyrm"]
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var camera: Camera3D = scene.get_node("Camera3D")
	var player_types := [{}, {}]
	var model_paths: Dictionary = {}
	var bounds_by_type: Dictionary = {}
	for piece in scene.get_node("Pieces").get_children():
		var definition: Resource = piece.character_definition
		_expect(definition is CharacterDefinition, "Typed character definition")
		var id: String = definition.archetype_id
		_expect(ARCHETYPES.has(id), "Prototype archetype is known")
		player_types[piece.army][id] = true
		model_paths[definition.model_scene.resource_path] = true
		_expect(not definition.lore_description.is_empty(), "Lore belongs to the archetype")
		_expect(piece.get_display_name() == definition.display_name, "Display name comes from data")
		_expect(piece.get_movement_behavior() == definition.movement_behavior, "Movement comes from data")
		_expect(absf(piece.get_node("Visuals").rotation.y - (0 if piece.army == 0 else PI)) < 0.001,
			"Armies face one another")
		var model: Node3D = piece.get_node("Visuals/Model")
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		_expect(meshes.size() >= 4 and meshes.size() <= 10, "Simple silhouette, not detailed primitive sculpting")
		var bounds := _model_bounds(model, meshes)
		bounds_by_type[id] = bounds
		_expect(bounds.position.x >= -0.7275 and bounds.end.x <= 0.7275,
			"Statue fits within tile width: %s" % id)
		_expect(bounds.position.z >= -0.7275 and bounds.end.z <= 0.7275,
			"Statue fits within tile depth: %s" % id)
		_expect(bounds.position.y >= -0.001, "Statue rests above its tile")
		var picking: StaticBody3D = piece.get_node("PickBody")
		_expect(picking.get_child_count() == meshes.size(), "Compound picking follows each primitive")
		_expect(picking.collision_layer == 2 and picking.get_meta("piece") == piece,
			"Picking body keeps per-instance identity")
		for mesh_node in meshes:
			var mesh := mesh_node as MeshInstance3D
			_expect(mesh.mesh is PrimitiveMesh, "Godot-native prototype geometry")
			_expect(mesh.material_override == definition.team_materials[piece.army], "Correct team stone")
			var b := mesh.mesh.get_aabb()
			for index in range(8):
				var point := mesh.global_transform * b.get_endpoint(index)
				_expect(not camera.is_position_behind(point) and root.get_visible_rect().has_point(camera.unproject_position(point)),
					"Actual statue bounds fit gameplay camera")
	_expect(player_types[0].size() == 6 and player_types[1].size() == 6, "Both armies display all six prototypes")
	_expect(model_paths.size() == 6, "Each archetype has its own replacement scene")
	_expect(bounds_by_type["core"].size.y > bounds_by_type["warden"].size.y, "Core is monumental and tall")
	_expect(bounds_by_type["witch"].size.y > bounds_by_type["hunter"].size.y, "Witch is taller than Hunter")
	_expect(bounds_by_type["warden"].size.x > bounds_by_type["hunter"].size.x, "Warden is broader than Hunter")
	_expect(bounds_by_type["wyrm"].size.y < 0.8 and bounds_by_type["wyrm"].size.z > bounds_by_type["wyrm"].size.y,
		"Wyrm reads horizontally and stays low")

	# Replace a live model without losing per-instance identity, team or coordinate.
	var replacement := PieceScene.instantiate() as Node3D
	replacement.piece_id = &"replacement_probe"
	replacement.army = 1
	replacement.grid_coordinate = Vector2i(2, 3)
	replacement.position = Vector3(20, 0, 0)
	root.add_child(replacement)
	var old_body := replacement.get_node("PickBody")
	replacement.character_definition = load("res://resources/characters/wyrm.tres")
	_expect(replacement.piece_id == &"replacement_probe" and replacement.army == 1
		and replacement.grid_coordinate == Vector2i(2, 3), "Model swap preserves piece identity and state")
	_expect(replacement.get_display_name() == "Wyrm" and replacement.get_node("PickBody") != old_body,
		"Live model replacement refreshes name and picking")
	var imported_style := replacement.character_definition.duplicate() as Resource
	var authored_materials: Array[Material] = []
	imported_style.team_materials = authored_materials
	replacement.character_definition = imported_style
	var meshes := replacement.get_node("Visuals/Model").find_children("*", "MeshInstance3D", true, false)
	_expect(meshes.all(func(mesh: MeshInstance3D) -> bool:
		return mesh.material_override == preload("res://materials/ash_statue.tres")),
		"Opting out of team override preserves authored model materials")
	_expect(load("res://resources/characters/wyrm.tres").team_materials.size() == 2,
		"Per-instance replacement does not mutate shared character data")
	replacement.queue_free()
	scene.queue_free()
	await process_frame
	print("Character smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _model_bounds(model: Node3D, meshes: Array[Node]) -> AABB:
	var result := AABB()
	var started := false
	for mesh_node in meshes:
		var mesh := mesh_node as MeshInstance3D
		var local := model.global_transform.affine_inverse() * mesh.global_transform
		var bounds := local * mesh.mesh.get_aabb()
		result = result.merge(bounds) if started else bounds
		started = true
	return result


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
