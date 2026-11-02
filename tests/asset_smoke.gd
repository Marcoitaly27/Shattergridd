extends SceneTree
## Existing native resources only. RAM wrappers/clip tracks are structural fixtures.

const Match = preload("res://scenes/main.tscn")
const Piece = preload("res://scenes/pieces/placeholder_piece.tscn")
const Wrapper = preload("res://scenes/assets/CHR_VisualWrapper_Template.tscn")
const EnvironmentWrapper = preload("res://scenes/assets/ENV_VisualWrapper_Template.tscn")
const Config = preload("res://scripts/visuals/animation_config.gd")
const Validator = preload("res://scripts/visuals/asset_validation.gd")
const Stone = preload("res://resources/visuals/MAT_StoneSurface_Template.tres")
const Warden = preload("res://scenes/pieces/characters/warden.tscn")
const Witch = preload("res://scenes/pieces/characters/witch.tscn")
const Wyrm = preload("res://scenes/pieces/characters/wyrm.tscn")
var checks: int = 0
var failures: int = 0
var scene: Node3D
var game: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _setup()
	await _test_replacement()
	await _dispose()
	await _test_materials_and_proxies()
	await _test_collision_isolation()
	await _test_pair_variant()
	for impact_time in [0.20, 0.36]:
		await _setup()
		await _test_authored(impact_time)
		await _dispose()
	await _setup()
	_test_missing_marker()
	await _dispose()
	await _setup()
	await _test_core_swap()
	await _dispose()
	await _setup()
	await _test_environment()
	await _test_debug()
	await _dispose()
	await _setup()
	await _test_authored_restart()
	await _dispose()
	print("Asset smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _setup() -> void:
	scene = Match.instantiate() as Node3D
	root.add_child(scene)
	load("res://tests/legacy_fixture.gd").configure(scene)
	game = scene.get_node("GameManager")
	await physics_frame
	await process_frame


func _dispose() -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _test_replacement() -> void:
	var attacker: Node3D = scene.get_node("Pieces/Ash_03")
	var victim: Node3D = scene.get_node("Pieces/Slate_01")
	game.board_state.move_piece(victim, Vector2i(2, 6))
	victim.position = game.battlefield.position_for_cell(victim.grid_coordinate)
	var definition: Resource = attacker.character_definition
	var coordinate: Vector2i = attacker.grid_coordinate
	var id: StringName = attacker.piece_id
	var statuses: RefCounted = attacker.statuses
	var moves: Array = game.valid_destinations(attacker)
	_expect(attacker.replace_visual(Witch), "An existing different silhouette can replace one live visual")
	_expect(attacker.character_definition == definition and attacker.statuses == statuses and attacker.piece_id == id,
		"Replacing art preserves the complete gameplay definition, ID and status instance")
	_expect(attacker.grid_coordinate == coordinate and game.board_state.piece_at(coordinate) == attacker,
		"Replacing art preserves coordinates and occupancy")
	_expect(game.valid_destinations(attacker) == moves and attacker.get_capture_behavior() == definition.capture_behavior,
		"Replacing art preserves movement and capture eligibility/behavior")
	await physics_frame
	_expect(scene.get_node("Interaction").cell_at_screen(scene.get_node("Camera3D").unproject_position(attacker.get_pick_point())) == coordinate,
		"Replacement refreshes usable picking")
	game.handle_cell_clicked(coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	_expect(not attacker.replace_visual(Warden), "Visual replacement is locked during an action")
	game.capture_director.accelerate()
	await _finish()
	_expect(game.current_player == 1 and game.completed_turns == [1, 0], "A replaced visual completes a capture and one turn")
	_expect(attacker.statuses.has(&"blood_step"), "Executioner gameplay ability survives a Witch-shaped visual")


func _pack_wrapper(impact_time: float = -1, metal: bool = false, collision: bool = false) -> PackedScene:
	var root_model := Wrapper.instantiate() as Node3D
	# Copy existing native nodes into a RAM-only fixture. Reassigning the owners
	# inside an instanced PackedScene would serialize its children twice in Godot.
	var source := Warden.instantiate() as Node3D
	var model := Node3D.new()
	model.name = "ExistingPrototype"
	for child in source.find_children("*", "", true, false):
		child.owner = null
	for child in source.get_children():
		source.remove_child(child)
		model.add_child(child)
	source.free()
	root_model.get_node("AssetRoot").add_child(model)
	if collision:
		var body := RigidBody3D.new()
		body.name = "ImportedCollision"
		var shape := CollisionShape3D.new()
		shape.shape = root_model.get_node("InteractionProxy").shape
		body.add_child(shape)
		root_model.add_child(body)
	if metal:
		model.find_children("*", "MeshInstance3D", true, false)[0].material_override = load("res://materials/world/iron.tres")
	if impact_time >= 0:
		var player := AnimationPlayer.new()
		player.name = "AnimationPlayer"
		root_model.add_child(player)
		var clip := Animation.new()
		clip.length = 0.65
		var rotation := clip.add_track(Animation.TYPE_VALUE)
		clip.track_set_path(rotation, NodePath("AssetRoot:rotation:y"))
		clip.track_insert_key(rotation, 0.0, 0.0)
		clip.track_insert_key(rotation, 0.15, 0.10)
		clip.track_insert_key(rotation, 0.65, 0.0)
		var events := clip.add_track(Animation.TYPE_METHOD)
		clip.track_set_path(events, NodePath("."))
		for entry in [[0.03, &"anticipation"], [0.10, &"swing"], [impact_time, &"impact"],
				[impact_time + 0.02, &"impact"], [0.55, &"recovery"]]:
			clip.track_insert_key(events, entry[0], {"method": &"report_animation_event", "args": [entry[1]]})
		var library := AnimationLibrary.new()
		library.add_animation(&"capture_fixture", clip)
		player.add_animation_library(&"", library)
	for child in root_model.find_children("*", "", true, false):
		child.owner = root_model
	var packed := PackedScene.new()
	_expect(packed.pack(root_model) == OK, "Existing-resource wrapper fixture packs in RAM")
	root_model.free()
	return packed


func _test_materials_and_proxies() -> void:
	var definition: Resource = load("res://resources/characters/warden.tres").duplicate()
	definition.model_scene = _pack_wrapper(-1, true)
	definition.prototype_visual = false
	definition.picking_mode = 1
	definition.team_material_mode = 2
	definition.team_surface_names = [&"Ash Statue"] as Array[StringName]
	definition.visual_scale = Vector3.ONE * 0.9
	definition.visual_offset = Vector3(0, 0.02, 0)
	var a := Piece.instantiate() as Node3D
	var b := Piece.instantiate() as Node3D
	a.character_definition = definition
	b.character_definition = definition
	b.army = 1
	root.add_child(a)
	root.add_child(b)
	_expect(a.get_node("PickBody").get_child_count() == 1, "Production wrapper uses one authored simple proxy, not rendered triangles")
	_expect(a.get_node("Visuals/Model").scale.is_equal_approx(Vector3.ONE * 0.9), "Correction scale is isolated on the model")
	_expect(a.get_node("Visuals/Model").position == definition.visual_offset and a.grid_coordinate == Vector2i.ZERO,
		"Visual offset never changes logical position")
	var meshes := a.get_node("Visuals/Model/AssetRoot").find_children("*", "MeshInstance3D", true, false)
	var iron: Material = load("res://materials/world/iron.tres")
	_expect(meshes[0].get_active_material(0) == iron, "Named stone overrides preserve an authored non-stone material")
	var original: StandardMaterial3D = definition.team_materials[0]
	var color_before := original.albedo_color
	a.get_node("Visuals").set_instance_tint(Color(0.6, 0.8, 0.7))
	_expect(meshes[1].get_active_material(0) != original and original.albedo_color == color_before,
		"Per-instance tint duplicates only the material and never mutates shared resources")
	var other := b.get_node("Visuals/Model/AssetRoot").find_children("*", "MeshInstance3D", true, false)
	_expect(other[1].get_active_material(0) == definition.team_materials[1], "Another army's material remains untouched")
	_expect(Validator.inspect_piece(a).is_empty(), "Correct wrapper scale/proxy/material setup has no integration warnings")
	definition.picking_mode = 0
	a.character_definition = definition
	_expect(a.get_node("PickBody").get_child_count() == 1 and a.get_node("PickBody").get_child(0).shape is BoxShape3D,
		"Bounds mode uses one simple collider regardless of the visual's mesh count")
	definition.visual_scale = Vector3(20, 20, 20)
	_expect(not Validator.inspect_piece(a).is_empty(), "Extreme source scale is a development warning, not an identity change")
	definition.visual_scale = Vector3.ONE
	var surface: Resource = Stone.duplicate()
	var ash: StandardMaterial3D = surface.build_material(Color(0.9, 0.85, 0.75))
	var slate: StandardMaterial3D = surface.build_material(Color(0.7, 0.77, 0.8))
	_expect(ash != slate and ash.albedo_color != slate.albedo_color and ash.roughness >= 0.9, "PBR factory builds separate restrained stone variants")
	_expect(not ash.normal_enabled and not ash.ao_enabled and not ash.heightmap_enabled and not ash.emission_enabled,
		"Missing optional maps remain disabled rather than populated with fake textures")
	surface.packed_orm = load("res://materials/world/stone_roughness.tres")
	var packed: StandardMaterial3D = surface.build_material()
	_expect(packed.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		and packed.metallic_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		and packed.ao_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_RED, "Packed glTF ORM uses R/G/B correctly")
	a.queue_free()
	b.queue_free()
	await process_frame


func _test_collision_isolation() -> void:
	var definition: Resource = load("res://resources/characters/warden.tres").duplicate()
	definition.model_scene = _pack_wrapper(-1, false, true)
	definition.picking_mode = 0
	var piece := Piece.instantiate() as Node3D
	piece.character_definition = definition
	root.add_child(piece)
	var body: RigidBody3D = piece.get_node("Visuals/Model/ImportedCollision")
	_expect(body.freeze and body.collision_layer == 0 and body.get_child(0).disabled,
		"Imported source collision is made inert; it cannot fall or intercept board picking")
	_expect(piece.get_node("PickBody").collision_layer == 2, "Only the simple gameplay proxy is interactive")
	_expect(Validator.inspect_piece(piece).any(func(message: String) -> bool: return message.contains("collision")),
		"Source collision is still reported for cleanup at import time")
	piece.queue_free()
	await process_frame


func _test_pair_variant() -> void:
	var definition: Resource = load("res://resources/characters/warden.tres").duplicate()
	definition.paired_model_scene = load("res://scenes/pieces/characters/hunter.tscn")
	var a := Piece.instantiate() as Node3D
	var b := Piece.instantiate() as Node3D
	a.character_definition = definition
	b.character_definition = definition
	b.reflected_member = 1
	root.add_child(a)
	root.add_child(b)
	_expect(a.character_definition == b.character_definition
		and a.get_node("Visuals/Model").scene_file_path != b.get_node("Visuals/Model").scene_file_path,
		"A reflected model variant changes art, not the shared character choice")
	_expect(b.get_node("Visuals/Model").scale == Vector3.ONE, "Paired art uses no negative skeleton scale")
	a.queue_free()
	b.queue_free()
	await process_frame


func _configure_authored(impact_time: float) -> Node3D:
	var attacker: Node3D = scene.get_node("Pieces/Ash_03")
	var definition: Resource = attacker.character_definition.duplicate()
	definition.model_scene = _pack_wrapper(impact_time)
	definition.picking_mode = 1
	var config := Config.new()
	config.player_path = NodePath("AnimationPlayer")
	config.states = {&"capture_attack": &"capture_fixture"}
	config.hit_pause = 0.05
	definition.animation_config = config
	attacker.character_definition = definition
	var victim: Node3D = scene.get_node("Pieces/Slate_01")
	game.board_state.move_piece(victim, Vector2i(2, 6))
	victim.position = game.battlefield.position_for_cell(victim.grid_coordinate)
	return attacker


func _test_authored(impact_time: float) -> void:
	var attacker := _configure_authored(impact_time)
	var visuals: Node3D = attacker.get_node("Visuals")
	var victim: Node3D = scene.get_node("Pieces/Slate_01")
	_expect(visuals.authored_capture_ready() and Validator.inspect_piece(attacker).is_empty(), "Valid event-track clip selects the authored animation path")
	_expect(attacker.get_capture_behavior().sequence_name == "Authored capture", "CaptureDirector needs no character/model branch")
	var player: AnimationPlayer = visuals.get_node("Model/AnimationPlayer")
	player.speed_scale = 0.7
	var positions: Array[float] = []
	var shattered: Array[bool] = []
	var canonical: Transform3D = scene.get_node("Camera3D").global_transform
	game.capture_director.cue_emitted.connect(func(event: StringName, _a: Node3D, _v: Node3D) -> void:
		if event == &"impact":
			positions.append(player.current_animation_position)
			_expect(game.board_state.piece_at(victim.grid_coordinate) == victim, "Impact event precedes authoritative shatter"))
	game.capture_director.victim_shattered.connect(func(_a: Node3D, _v: Node3D) -> void: shattered.append(true))
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	await _finish()
	_expect(positions.size() == 1 and absf(positions[0] - impact_time) < 0.04, "Authored marker time drives the actual impact, including changed timings")
	_expect(shattered.size() == 1 and game.current_player == 1 and game.completed_turns == [1, 0], "Duplicate impact markers cannot destroy twice or advance twice")
	_expect(attacker.statuses.has(&"blood_step") and game.board_state.piece_at(Vector2i(2, 6)) == attacker, "Authored animation preserves capture movement and ability resolution")
	_expect(player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE and is_equal_approx(player.speed_scale, 0.7),
		"Manual cinematic clock restores the animation player's previous processing and speed")
	_expect(scene.get_node("Camera3D").global_transform == canonical and not visuals.presentation_locked, "Camera and visual replacement lock restore after authored capture")
	_expect(root.get_node("SoundManager").trace.any(func(entry: Dictionary) -> bool: return entry.cue == &"capture.executioner.impact"), "Authored impact reaches the existing character audio profile")


func _test_missing_marker() -> void:
	var attacker := _configure_authored(0.20)
	var player: AnimationPlayer = attacker.get_node("Visuals/Model/AnimationPlayer")
	var clip := player.get_animation(&"capture_fixture")
	clip.remove_track(1)
	_expect(not attacker.get_node("Visuals").authored_capture_ready()
		and attacker.get_capture_behavior() == attacker.character_definition.capture_behavior,
		"A missing impact marker safely preserves the existing procedural fallback")
	_expect(not Validator.inspect_piece(attacker).is_empty(), "Missing authored timing is reported as a development warning")
	var unsafe := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(unsafe, NodePath("../../:position"))
	clip.track_insert_key(unsafe, 0.0, Vector3.ONE)
	_expect(not attacker.request_visual_animation(&"capture_attack"), "Animation tracks cannot target the gameplay Piece outside the model")


func _test_core_swap() -> void:
	var attacker: Node3D = scene.get_node("Pieces/Ash_03")
	var core: Node3D = scene.get_node("Pieces/Slate_04")
	_expect(core.replace_visual(Wyrm) and core.character_definition.is_core_objective, "A low creature-shaped visual does not change Core identity")
	game.board_state.move_piece(core, Vector2i(3, 6))
	core.position = game.battlefield.position_for_cell(core.grid_coordinate)
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(core.grid_coordinate)
	game.capture_director.accelerate()
	await _finish()
	_expect(game.winner == 0 and game.phase == game.Phase.GAME_OVER, "Destroying a visually replaced Core still produces victory")


func _test_environment() -> void:
	var old := scene.get_node("VisualWorld/Landmarks/RuinedChapel") as Node3D
	var position := old.position
	var parent := old.get_parent()
	parent.remove_child(old)
	old.queue_free()
	var wrapper := EnvironmentWrapper.instantiate() as Node3D
	wrapper.name = "RuinedChapel"
	wrapper.position = position
	wrapper.model_scene = load("res://scenes/world/modules/draconic_relic.tscn")
	parent.add_child(wrapper)
	_expect(wrapper.validation_warnings().is_empty() and wrapper.position == position, "A background module can be replaced through an independent wrapper")
	_expect(wrapper.find_children("*", "CollisionObject3D", true, false).is_empty(), "Decorative replacement adds no collision")
	wrapper.replace_asset(load("res://scenes/world/modules/abandoned_gallows.tscn"))
	game.handle_cell_clicked(Vector2i(0, 7))
	game.handle_cell_clicked(Vector2i(0, 6))
	await _finish()
	_expect(game.current_player == 1 and game.debug_validate_state(false).is_empty(), "Environment swaps preserve movement, occupancy and turn flow")


func _test_debug() -> void:
	game.handle_cell_clicked(Vector2i(0, 0))
	var key := InputEventKey.new()
	key.keycode = KEY_F7
	key.pressed = true
	root.push_input(key, true)
	var overlay: Node = scene.get_node("DebugOverlay")
	_expect(overlay.panel.visible and overlay.text.text.contains("ASSET INSPECTOR") and overlay.text.text.contains("PROTOTYPE"),
		"F7 provides development-only asset inspection without gameplay labels")


func _test_authored_restart() -> void:
	var attacker := _configure_authored(0.36)
	current_scene = scene
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(Vector2i(2, 6))
	var deadline := Time.get_ticks_msec() + 4000
	while attacker.get_node("Visuals").animation._saved.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not attacker.replace_visual(Warden), "An actively sampled imported clip cannot be hot-swapped")
	var old_id := scene.get_instance_id()
	game.restart_match()
	while (current_scene == null or current_scene.get_instance_id() == old_id) and Time.get_ticks_msec() < deadline:
		await process_frame
	scene = current_scene
	game = scene.get_node("GameManager")
	_expect(game.can_accept_input() and scene.get_node("Pieces").get_child_count() == 16, "Restart during authored playback creates a fresh playable army")
	_expect(scene.get_node("Camera3D").position == Vector3(14, 22, 19) and root.get_node("SoundManager")._cinematics.is_empty(),
		"Authored cancellation cleans animation, camera and audio ownership")


func _finish() -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not game.is_moving, "Replacement/capture action finishes without hanging")


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
