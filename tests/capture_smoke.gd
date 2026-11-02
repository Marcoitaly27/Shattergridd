extends SceneTree
## Real timeline completion, authoritative event order, statuses and restart safety.

const BoardState = preload("res://scripts/board/board_state.gd")
const MovementResolver = preload("res://scripts/movement/movement_resolver.gd")
const PieceScene = preload("res://scenes/pieces/placeholder_piece.tscn")
const BLOOD: Resource = preload("res://resources/statuses/blood_step.tres")
const TERROR: Resource = preload("res://resources/statuses/terrified.tres")
var checks: int = 0
var failures: int = 0
var fixture: Node3D
var game: Node
var director: Node
var camera: Camera3D
var attacker: Node3D
var victim: Node3D


class OrthogonalMovement extends Resource:
	func get_destinations(origin: Vector2i, _army: int, _board: RefCounted) -> Array[Vector2i]:
		return [origin + Vector2i.LEFT, origin + Vector2i.RIGHT, origin + Vector2i.UP, origin + Vector2i.DOWN]


func _initialize() -> void:
	create_timer(45.0).timeout.connect(func() -> void:
		push_error("Capture suite timed out before completing")
		quit(1))
	_run.call_deferred()


func _run() -> void:
	_test_status_rules()
	_test_terror_radius()
	for archetype in ["warden", "hunter", "executioner", "witch", "wyrm", "core"]:
		await _test_sequence(archetype)
	await _test_core_victory()
	await _test_obstructed_camera()
	await _test_blood_step_turns()
	await _test_repeated_captures()
	await _test_restart(false)
	await _test_restart(true)
	await _test_victory_restart()
	print("Capture smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _setup(archetype: String, victim_archetype: String = "warden", cell: Vector2i = Vector2i(3, 3), target: Vector2i = Vector2i(4, 3)) -> void:
	fixture = load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(fixture)
	game = fixture.get_node("GameManager")
	director = fixture.get_node("CaptureDirector")
	camera = fixture.get_node("Camera3D")
	attacker = fixture.get_node("Pieces/Ash_01")
	victim = fixture.get_node("Pieces/Slate_01")
	for piece in fixture.get_node("Pieces").get_children():
		if piece != attacker and piece != victim:
			piece.get_parent().remove_child(piece)
			piece.queue_free()
	attacker.character_definition = load("res://resources/characters/%s.tres" % archetype)
	victim.character_definition = load("res://resources/characters/%s.tres" % victim_archetype)
	game.board_state = BoardState.new()
	attacker.grid_coordinate = cell
	victim.grid_coordinate = target
	attacker.position = game.battlefield.position_for_cell(cell)
	victim.position = game.battlefield.position_for_cell(target)
	_expect(game.board_state.register_piece(attacker) and game.board_state.register_piece(victim), "Capture fixture registers pieces")
	await process_frame


func _dispose() -> void:
	if is_instance_valid(fixture):
		if current_scene == fixture:
			current_scene = null
		fixture.queue_free()
	await process_frame


func _test_sequence(archetype: String) -> void:
	await _setup(archetype)
	var original := camera.global_transform
	var original_fov := camera.fov
	var visual_pose: Transform3D = attacker.get_node("Visuals").transform
	var events: Array[StringName] = []
	var timestamps: Dictionary = {}
	var start_time := Time.get_ticks_msec()
	var target_cell: Vector2i = victim.grid_coordinate
	var origin: Vector2i = attacker.grid_coordinate
	director.cue_emitted.connect(func(event: StringName, a: Node3D, v: Node3D) -> void:
		events.append(event)
		timestamps[event] = Time.get_ticks_msec()
		_expect(game.is_moving and not game.can_accept_input(), "Every presentation event holds the gameplay lock")
		_expect(game.current_player == 0, "Turn cannot advance during a cinematic")
		if event == &"camera_ready":
			_expect(camera.global_position.y >= 3.0 and camera.global_transform != original, "Camera moves closer and stays above geometry")
			_expect(_camera_contains(a.get_visual_bounds()) and _camera_contains(v.get_visual_bounds()), "Both complete statues fit cinematic framing")
		if event == &"impact":
			_expect(v.visible and game.board_state.piece_at(target_cell) == v, "Impact precedes visual removal and occupancy replacement")
			_expect(not a.statuses.has(&"blood_step"), "Capture bonuses are not applied by the animation")
		if event == &"camera_restored":
			_expect(camera.global_transform == original and camera.fov == original_fov, "Strategic transform and FOV restore exactly")
			_expect(not a.statuses.has(&"blood_step"), "Abilities still wait until capture resolves"))
	director.victim_shattered.connect(func(a: Node3D, v: Node3D) -> void:
		_expect(not v.visible and game.board_state.piece_at(target_cell) == a, "Shatter commits occupancy and hides the victim")
		_expect(game.board_state.piece_at(origin) == null, "Shatter clears the source tile")
		var effect: Node3D = fixture.get_node("Effects").get_child(0)
		_expect(effect.fragment_count >= 5 and effect.fragment_count <= 12, "Temporary fragment count is bounded")
		for fragment in effect.get_children():
			if fragment is RigidBody3D:
				_expect(fragment.gravity_scale > 1 and fragment.collision_mask == 1, "Heavy debris uses native gravity and tile collisions"))
	game.capture_resolved.connect(func(a: Node3D, _v: Node3D) -> void:
		_expect(camera.global_transform == original and not director.active, "Resolution waits for camera and director completion")
		if archetype == "executioner":
			_expect(a.statuses.has(&"blood_step"), "Successful Executioner capture grants per-piece Blood Step"))
	game.handle_cell_clicked(origin)
	_expect(game.valid_destinations(attacker).has(target_cell), "Capture obeys the character movement rule")
	game.handle_cell_clicked(target_cell)
	_expect(director.active and game.selected_piece == null, "Capture starts a unique locked sequence")
	_expect(game.board_state.piece_at(target_cell) == victim and victim.visible, "Victim is not removed on the capture click")
	game.handle_cell_clicked(origin)
	_expect(game.selected_piece == null and not director.start(attacker, victim), "Selection and nested captures are blocked")
	await _finish()
	var duration := float(Time.get_ticks_msec() - start_time) / 1000.0
	_expect(duration >= 1.5 and duration <= 2.65, "Normal capture duration stays short: %s %.2fs" % [archetype, duration])
	_expect(events.has(&"impact") and events.has(&"debris") and events.has(&"camera_restored"), "Impact, fracture and restoration actually execute")
	_expect(events.find(&"impact") < events.find(&"debris") and events.find(&"debris") < events.find(&"camera_restored"), "Capture event order")
	if archetype == "hunter":
		_expect(timestamps[&"impact"] - timestamps[&"strike_passed"] >= 100, "Hunter destruction is delayed after the strike")
	if archetype == "witch":
		_expect(events.has(&"wither") and attacker.position.is_equal_approx(game.battlefield.position_for_cell(target_cell)), "Witch uses Wither and settles afterward")
	if archetype == "wyrm":
		_expect(events.has(&"predatory_lunge") and events.has(&"wyrm_impact"), "Wyrm uses non-human lunge and maul cues")
	if archetype == "core":
		_expect(events.has(&"core_force"), "Core uses invisible defensive force")
	_expect(game.current_player == 1 and game.completed_turns == [1, 0], "Capture advances exactly one turn")
	_expect(attacker.global_position.is_equal_approx(game.battlefield.to_global(game.battlefield.position_for_cell(target_cell))), "Attacker finishes centered on captured tile")
	_expect(attacker.get_node("Visuals").transform == visual_pose, "Prototype pose and facing do not accumulate drift")
	_expect(not is_instance_valid(victim) and game.can_accept_input(), "Victim is freed and input unlocks after completion")
	_expect(director._context == null and director._timeline == null, "Director releases capture and tween references")
	_expect(is_equal_approx(Engine.time_scale, 1.0), "Local hit pause never changes global time")
	_test_edge_framing()
	await _dispose()


func _test_edge_framing() -> void:
	# Analytical camera placement is also exercised at all corner attack directions.
	var camera_director: Node = fixture.get_node("CameraDirector")
	camera_director.save_strategic_state()
	for origin in [Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 7), Vector2i(7, 7)]:
		var step := Vector2i(1 if origin.x == 0 else -1, 1 if origin.y == 0 else -1)
		var a: Vector3 = game.battlefield.to_global(game.battlefield.position_for_cell(origin))
		var v: Vector3 = game.battlefield.to_global(game.battlefield.position_for_cell(origin + step))
		var bounds := AABB(a - Vector3(0.7, 0, 0.7), Vector3(1.4, 1.9, 1.4)).merge(AABB(v - Vector3(0.7, 0, 0.7), Vector3(1.4, 1.9, 1.4)))
		var pose: Transform3D = camera_director.calculate_pose(a, v, bounds, attacker.get_capture_behavior(), origin.x * 17 + origin.y)
		camera.global_transform = pose
		camera.fov = camera_director.CINEMATIC_FOV
		_expect(pose.origin.y >= 3 and _camera_contains(bounds), "Corner camera is above platform and frames both actors")
	camera_director.restore_strategic_state()


func _test_core_victory() -> void:
	await _setup("executioner", "core", Vector2i(0, 6), Vector2i(0, 7))
	var original := camera.global_transform
	var result: Dictionary = {"shattered": false, "resolved": false}
	director.victim_shattered.connect(func(_a: Node3D, _v: Node3D) -> void:
		result.shattered = true
		_expect(game.winner == -1 and not fixture.get_node("Interface/VictoryScreen").visible, "Core impact does not show premature victory")
		_expect(fixture.get_node("Effects").get_child(0).fragment_count == 12, "Core destruction uses the special bounded fragment count"))
	game.capture_resolved.connect(func(_a: Node3D, _v: Node3D) -> void:
		result.resolved = true
		_expect(result.shattered and camera.global_transform == original and game.winner == -1, "Core resolution follows destruction and exact camera restoration"))
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	await _finish()
	_expect(result.resolved and game.winner == 0 and fixture.get_node("Interface/VictoryScreen").visible, "Victory UI appears after the full Core cinematic")
	_expect(not game.can_accept_input() and game.current_player == 0, "Game-over state blocks further turns")
	game.handle_cell_clicked(attacker.grid_coordinate)
	_expect(game.selected_piece == null, "Game-over cannot select pieces")
	await _dispose()


func _test_obstructed_camera() -> void:
	await _setup("warden", "hunter", Vector2i(0, 0), Vector2i(1, 0))
	var controller: Node = fixture.get_node("CameraDirector")
	controller.save_strategic_state()
	var bounds: AABB = attacker.get_visual_bounds().merge(victim.get_visual_bounds())
	var original: Transform3D = controller.calculate_pose(attacker.global_position, victim.global_position, bounds, attacker.get_capture_behavior(), 0)
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = 2
	obstacle.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 2.3, 1.5)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	obstacle.add_child(collision)
	fixture.add_child(obstacle)
	obstacle.global_position = original.origin.lerp(victim.get_pick_point(), 0.72)
	obstacle.global_position.y = 1.15
	await physics_frame
	await process_frame
	var actors: Array[Node3D] = [attacker, victim]
	var adjusted: Transform3D = controller.calculate_pose(attacker.global_position, victim.global_position, bounds, attacker.get_capture_behavior(), 0, actors)
	_expect(adjusted != original, "Camera avoids an intervening statue instead of hiding the confrontation")
	for actor in actors:
		var ray := PhysicsRayQueryParameters3D.create(adjusted.origin, actor.get_pick_point(), 2)
		var hit := camera.get_world_3d().direct_space_state.intersect_ray(ray)
		_expect(hit.is_empty() or (hit.collider.has_meta("piece") and hit.collider.get_meta("piece") == actor), "Adjusted cinematic view has a clear ray to each actor")
	controller.restore_strategic_state()
	await _dispose()


func _test_repeated_captures() -> void:
	await _setup("wyrm", "hunter", Vector2i(2, 2), Vector2i(3, 2))
	var terrified := _add_piece("hunter", 1, Vector2i(4, 2), "terror_target")
	var immune := _add_piece("core", 1, Vector2i(3, 3), "immune_core")
	var distant := _add_piece("hunter", 1, Vector2i(7, 7), "distant")
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	director.accelerate()
	_expect(not terrified.statuses.has(&"terrified"), "Terror is not granted when the capture starts")
	await _finish()
	_expect(terrified.statuses.has(&"terrified") and not immune.statuses.has(&"terrified") and not distant.statuses.has(&"terrified"), "Resolved Terror affects adjacent enemies, excludes Core and distant pieces")
	_expect(game.valid_destinations(terrified).has(Vector2i(4, 1)) and not game.valid_destinations(terrified).has(attacker.grid_coordinate), "Terrified enemy can move but cannot capture")
	game.handle_cell_clicked(terrified.grid_coordinate)
	game.handle_cell_clicked(attacker.grid_coordinate)
	_expect(game.current_player == 1 and game.can_accept_input() and attacker.visible, "A terrified capture click neither starts a capture nor consumes a turn")
	game.handle_cell_clicked(terrified.grid_coordinate)
	game.handle_cell_clicked(Vector2i(4, 1))
	await _finish()
	_expect(not terrified.statuses.has(&"terrified"), "Terror expires at end of affected player's next turn")
	# Four more fast-forwarded captures on this same director; opponents take normal moves.
	var original := camera.global_transform
	for index in range(4):
		var destination: Vector2i = attacker.grid_coordinate + Vector2i(0, -1 if index % 2 == 0 else 1)
		var target := _add_piece("hunter", 1, destination, "repeat_%d" % index)
		game.handle_cell_clicked(attacker.grid_coordinate)
		game.handle_cell_clicked(target.grid_coordinate)
		director.accelerate()
		await _finish()
		_expect(camera.global_transform == original and game.can_accept_input(), "Repeated captures restore camera without drift or lock")
		var next: Vector2i = distant.grid_coordinate + Vector2i(-1 if index % 2 == 0 else 1, 0)
		game.handle_cell_clicked(distant.grid_coordinate)
		game.handle_cell_clicked(next)
		await _finish()
	var cleanup_deadline := Time.get_ticks_msec() + 2800
	while fixture.get_node("Effects").get_child_count() > 0 and Time.get_ticks_msec() < cleanup_deadline:
		await process_frame
	_expect(fixture.get_node("Effects").get_child_count() == 0, "All temporary rigid bodies and dust are cleaned after repeated captures")
	await _dispose()


func _test_restart(after_impact: bool) -> void:
	await _setup("warden")
	current_scene = fixture
	var old_id := fixture.get_instance_id()
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	if after_impact:
		var deadline := Time.get_ticks_msec() + 3000
		while victim.visible and Time.get_ticks_msec() < deadline:
			await process_frame
		_expect(not victim.visible, "Restart fixture reaches destruction phase")
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	root.push_input(restart, true)
	await _wait_reload(old_id)
	_expect(fixture.get_node("Pieces").get_child_count() == 16 and game.current_player == 0 and game.can_accept_input(), "Restart resets pieces, turn and input lock")
	_expect(fixture.get_node("Effects").get_child_count() == 0 and not director.active, "Restart cleans debris and director state")
	_expect(camera.position == Vector3(14, 22, 19), "Restart restores the strategic camera")
	await _dispose()


func _test_victory_restart() -> void:
	await _setup("hunter", "core")
	current_scene = fixture
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	director.accelerate()
	await _finish()
	var old_id := fixture.get_instance_id()
	fixture.get_node("Interface/VictoryScreen/Center/Result/Margin/Rows/Restart").pressed.emit()
	await _wait_reload(old_id)
	_expect(game.winner == -1 and not fixture.get_node("Interface/VictoryScreen").visible, "Victory button restarts a fresh match")
	await _dispose()


func _test_status_rules() -> void:
	var board := BoardState.new()
	var resolver := MovementResolver.new()
	var executioner := PieceScene.instantiate() as Node3D
	executioner.character_definition = load("res://resources/characters/executioner.tres")
	executioner.grid_coordinate = Vector2i(3, 3)
	executioner.movement_behavior = OrthogonalMovement.new()
	board.register_piece(executioner)
	var other := PieceScene.instantiate() as Node3D
	other.grid_coordinate = Vector2i(4, 4)
	other.army = 1
	board.register_piece(other)
	executioner.character_definition.post_capture_effect.apply(executioner, board, [0, 0] as Array[int])
	_expect(executioner.statuses.has(&"blood_step") and resolver.destinations(executioner, board, 0).size() == 4, "Blood Step is pending until owner's next turn")
	_expect(resolver.destinations(executioner, board, 1).size() == 8 and resolver.destinations(executioner, board, 1).has(other.grid_coordinate), "Blood Step adds exactly four diagonals, including enemy destinations")
	_expect(not other.statuses.has(&"blood_step"), "Bonus belongs only to its earning piece")
	executioner.apply_status(TERROR, 1, 2)
	_expect(not resolver.destinations(executioner, board, 1).has(other.grid_coordinate)
		and resolver.destinations(executioner, board, 1).has(Vector2i(2, 2)), "Terror blocks Blood Step captures while preserving bonus empty moves")
	executioner.statuses.expire(1)
	_expect(executioner.statuses.has(&"blood_step"), "Blood Step survives the earning turn")
	executioner.character_definition.post_capture_effect.apply(executioner, board, [1, 0] as Array[int])
	executioner.statuses.expire(2)
	_expect(executioner.statuses.active(2).size() == 1, "Recapture refreshes rather than stacking Blood Step")
	executioner.statuses.expire(3)
	_expect(not executioner.statuses.has(&"blood_step"), "Blood Step expires after the next owner turn")
	board.move_piece(other, Vector2i(3, 2))
	executioner.apply_status(TERROR, 0, 1)
	executioner.apply_status(TERROR, 0, 1)
	_expect(executioner.statuses.active(0).size() == 1 and not resolver.destinations(executioner, board, 0).has(other.grid_coordinate), "Terror refreshes one status and prohibits enemy capture")
	_expect(resolver.destinations(executioner, board, 0).has(Vector2i(2, 3)), "Terror preserves empty legal moves")
	var core := PieceScene.instantiate() as Node3D
	core.character_definition = load("res://resources/characters/core.tres")
	_expect(not core.apply_status(TERROR, 0, 1) and not core.statuses.has(&"terrified"), "Core is completely immune to Terror")
	executioner.free()
	other.free()
	core.free()


func _test_terror_radius() -> void:
	var board := BoardState.new()
	var caster := PieceScene.instantiate() as Node3D
	caster.character_definition = load("res://resources/characters/wyrm.tres")
	caster.grid_coordinate = Vector2i(3, 3)
	board.register_piece(caster)
	var targets: Array[Node3D] = []
	var index := 0
	for row in range(-1, 2):
		for column in range(-1, 2):
			if row == 0 and column == 0:
				continue
			var target := PieceScene.instantiate() as Node3D
			target.grid_coordinate = caster.grid_coordinate + Vector2i(column, row)
			target.army = 0 if index == 1 else 1
			if index == 0:
				target.character_definition = load("res://resources/characters/core.tres")
			board.register_piece(target)
			targets.append(target)
			index += 1
	caster.character_definition.post_capture_effect.apply(caster, board, [0, 0] as Array[int])
	for target in targets:
		var expected: bool = target.army == 1 and not target.character_definition.is_core_objective
		_expect(target.statuses.has(&"terrified") == expected, "Terror covers all eight neighbor directions with team/Core filtering")
	_expect(not caster.statuses.has(&"terrified"), "Wyrm does not Terrify itself")
	caster.character_definition.post_capture_effect.apply(caster, board, [0, 1] as Array[int])
	for target in targets:
		if target.statuses.has(&"terrified"):
			target.statuses.expire(1)
			_expect(target.statuses.active(1).size() == 1, "Reapplication refreshes Terror without stacking")
			target.statuses.expire(2)
			_expect(not target.statuses.has(&"terrified"), "Refreshed Terror expires at its new owner-turn boundary")
		target.free()
	caster.free()


func _test_blood_step_turns() -> void:
	await _setup("executioner", "hunter")
	attacker.movement_behavior = OrthogonalMovement.new()
	var spare := _add_piece("hunter", 0, Vector2i(0, 0), "spare_ally")
	var opponent := _add_piece("hunter", 1, Vector2i(7, 7), "opponent")
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	var fast := InputEventKey.new()
	fast.keycode = KEY_SPACE
	fast.pressed = true
	root.push_input(fast, true)
	_expect(director.playback_speed == 8, "Debug Space accelerates the timeline without skipping events")
	await _finish()
	game.handle_cell_clicked(opponent.grid_coordinate)
	game.handle_cell_clicked(Vector2i(6, 7))
	await _finish()
	var diagonal: Vector2i = attacker.grid_coordinate + Vector2i(1, 1)
	var enemy := _add_piece("hunter", 1, diagonal, "blood_step_target")
	_expect(game.current_player == 0 and game.valid_destinations(attacker).has(diagonal), "Earned Blood Step enables next-turn diagonal capture")
	game.handle_cell_clicked(attacker.grid_coordinate)
	_expect(fixture.get_node("Interface/Panel/Margin/Rows/Status").text.contains("Blood Step"), "Active Blood Step is visible in the selected-piece UI")
	game.handle_cell_clicked(enemy.grid_coordinate)
	director.accelerate()
	await _finish()
	_expect(attacker.statuses.active(game.completed_turns[0]).size() == 1, "A second successful capture renews one future Blood Step")
	game.handle_cell_clicked(opponent.grid_coordinate)
	game.handle_cell_clicked(Vector2i(5, 7))
	await _finish()
	game.handle_cell_clicked(spare.grid_coordinate)
	game.handle_cell_clicked(Vector2i(0, 1))
	await _finish()
	_expect(not attacker.statuses.has(&"blood_step"), "Bonus expires after next owner turn even if another piece acts")
	await _dispose()


func _add_piece(archetype: String, army: int, cell: Vector2i, id: String) -> Node3D:
	var piece := PieceScene.instantiate() as Node3D
	piece.character_definition = load("res://resources/characters/%s.tres" % archetype)
	piece.army = army
	piece.piece_id = StringName(id)
	piece.grid_coordinate = cell
	fixture.get_node("Pieces").add_child(piece)
	piece.position = game.battlefield.position_for_cell(cell)
	_expect(game.board_state.register_piece(piece), "Additional fixture piece registers on an empty tile")
	return piece


func _finish() -> void:
	var deadline := Time.get_ticks_msec() + 4500
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not game.is_moving, "Movement/cinematic completes and releases lock")
	await process_frame


func _wait_reload(old_id: int) -> void:
	var deadline := Time.get_ticks_msec() + 2500
	while (current_scene == null or current_scene.get_instance_id() == old_id) and Time.get_ticks_msec() < deadline:
		await process_frame
	fixture = current_scene
	_expect(is_instance_valid(fixture) and fixture.get_instance_id() != old_id, "Restart replaces the previous match")
	game = fixture.get_node("GameManager")
	director = fixture.get_node("CaptureDirector")
	camera = fixture.get_node("Camera3D")


func _camera_contains(bounds: AABB) -> bool:
	for index in range(8):
		var corner := bounds.get_endpoint(index)
		if camera.is_position_behind(corner) or not root.get_visible_rect().has_point(camera.unproject_position(corner)):
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
