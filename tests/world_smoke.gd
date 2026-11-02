extends SceneTree
## World replacement, budgets, cinematic clearance and playable-surface invariants.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	await physics_frame
	await process_frame
	var world: Node3D = scene.get_node("VisualWorld")
	_expect(world.get_node_or_null("FloatingArchitecture") != null, "Replaceable architectural shell exists")
	_expect(world.get_node_or_null("DistantSettlement") != null, "Distant settlement exists")
	_expect(world.find_children("*", "CollisionObject3D", true, false).is_empty(), "Visual world adds no physics bodies")
	_expect(world.find_children("*", "CollisionShape3D", true, false).is_empty(), "No unnecessary scenery collision shapes")
	var geometry := world.find_children("*", "GeometryInstance3D", true, false)
	var batches := world.find_children("*", "MultiMeshInstance3D", true, false)
	_expect(geometry.size() < 80 and batches.size() >= 8, "Scenery uses a small geometry-node budget and shared batches")
	var instance_count := 0
	var lowest_y := 0.0
	for batch_node in batches:
		var batch := batch_node as MultiMeshInstance3D
		instance_count += batch.multimesh.instance_count
		var transforms: Array[Transform3D] = batch.get_meta("placement_transforms")
		_expect(transforms.size() == batch.multimesh.instance_count, "CPU placement data matches the render instance count")
		for index in range(batch.multimesh.instance_count):
			var bounds := batch.global_transform * transforms[index] * batch.multimesh.mesh.get_aabb()
			if DisplayServer.get_name() != "headless":
				_expect(batch.multimesh.get_instance_transform(index).is_equal_approx(transforms[index]), "Rendered MultiMesh transforms match the validated placements")
			lowest_y = minf(lowest_y, bounds.position.y)
			_expect(bounds.end.y < 0, "Batched ruins and arena shell stay below the play plane")
	_expect(instance_count >= 100, "Many distant forms share few mesh nodes")
	_expect(lowest_y < -40, "World has a lower mist layer far below the floating arena")
	var architecture: Node3D = world.get_node("FloatingArchitecture")
	var hanging: MultiMeshInstance3D = architecture.get_node("HangingFoundation")
	_expect(hanging.multimesh.instance_count >= 6, "Arena has a broken deep underside")
	var lights := world.find_children("*", "OmniLight3D", true, false)
	_expect(lights.size() == 2, "Only two local fire lights")
	for light_node in lights:
		var light := light_node as OmniLight3D
		_expect(not light.shadow_enabled and light.omni_range <= 4.0, "Local lights have bounded range and no extra shadow maps")
	for node in world.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var bounds := mesh.global_transform * mesh.mesh.get_aabb()
		_expect(bounds.end.y < 1.5, "All decorative geometry stays below cinematic camera clearance")
	var chapel: Node3D = world.get_node("Landmarks/RuinedChapel")
	_expect(chapel.global_position.y < -20 and Vector2(chapel.position.x, chapel.position.z).length() > 25,
		"Church is a distant lower landmark, not a foreground obstruction")
	_expect(world.get_node_or_null("Landmarks/AbandonedExecutionSquare") != null, "Abandoned execution structure is present without bodies")
	_expect(world.get_node_or_null("Landmarks/BrokenDraconicRelic") != null, "One static draconic storytelling relic")
	var environment: Environment = scene.get_node("WorldEnvironment").environment
	_expect(environment.fog_enabled and environment.fog_height < -10 and environment.fog_height_density > 0,
		"Native fog is concentrated below the arena")
	_expect(environment.fog_density < 0.01 and environment.background_mode == Environment.BG_SKY,
		"Restrained distance fog and native sky")
	var source: Environment = load("res://environments/suspended_sanctum.tres")
	var presentation: Node = scene.get_node("DayNightPresentation")
	var day_energy := environment.ambient_light_energy
	var turn_snapshot: Array = scene.get_node("GameManager").completed_turns.duplicate()
	_expect(environment != source, "Each match owns its atmospheric parameters")
	presentation._apply(true, false)
	_expect(environment.ambient_light_energy < day_energy and environment.background_energy_multiplier < 1,
		"Night darkens background and fill without hiding the tactical board")
	_expect(source.ambient_light_energy == day_energy and source.background_energy_multiplier == 1,
		"Night presentation cannot mutate the shared daylight source")
	_expect(environment.sky == source.sky, "The immutable sky is shared without per-frame panorama rebakes")
	_expect(scene.get_node("GameManager").completed_turns == turn_snapshot and not scene.get_node("GameManager").is_night,
		"Presentation changes cannot advance turns or transform gameplay state")
	presentation._apply(false, false)
	_expect(environment.ambient_light_energy == day_energy and environment.background_energy_multiplier == 1,
		"Daylight presentation restores after a night preview")
	var camera: Camera3D = scene.get_node("Camera3D")
	_expect(exp(-camera.position.length() * environment.fog_density) > 0.85, "Board-distance transmission remains high")
	var game: Node = scene.get_node("GameManager")
	var interaction: Node = scene.get_node("Interaction")
	for piece in scene.get_node("Pieces").get_children():
		_expect(interaction.cell_at_screen(camera.unproject_position(piece.get_pick_point())) == piece.grid_coordinate,
			"Scenery does not intercept character picking")
	for cell in [Vector2i(0, 1), Vector2i(7, 1), Vector2i(0, 6), Vector2i(7, 6)]:
		var point: Vector3 = game.battlefield.position_for_cell(cell)
		_expect(interaction.cell_at_screen(camera.unproject_position(point)) == cell, "Edge tiles remain pickable")
	for label in ["pale_stone", "dark_stone", "ash_statue", "slate_statue"]:
		var material := load("res://materials/%s.tres" % label) as StandardMaterial3D
		_expect(material.roughness >= 0.9 and material.roughness_texture != null, "Matte stone has restrained roughness variation")
	# Removing the entire visual world must not disable any game rule or move.
	world.queue_free()
	await process_frame
	game.handle_cell_clicked(Vector2i(0, 7))
	game.handle_cell_clicked(Vector2i(0, 6))
	var deadline := Time.get_ticks_msec() + 1500
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(game.current_player == 1 and game.board_state.piece_at(Vector2i(0, 6)) != null,
		"Gameplay still works after the whole visual world is removed")
	print("World smoke: %d checks, %d failures; %d geometry nodes, %d batches, %d shared instances" % [checks, failures, geometry.size(), batches.size(), instance_count])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
