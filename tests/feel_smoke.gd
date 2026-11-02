extends SceneTree
## Hover, exact previews, status/threat presentation, guarded actions and desktop UI.

const Match = preload("res://scenes/main.tscn")
const BloodStep = preload("res://resources/statuses/blood_step.tres")
const Terror = preload("res://resources/statuses/terrified.tres")
const DebugOverlay = preload("res://scripts/debug/debug_overlay.gd")
var checks: int = 0
var failures: int = 0
var scene: Node3D
var game: Node
var interaction: Node
var ui: CanvasLayer
var camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _setup()
	await _test_hover_and_previews()
	await _test_threat_and_input()
	await _test_resolutions()
	await _test_debug_and_idle_cost()
	await _dispose()
	await _setup()
	await _test_victory_pause()
	await _dispose()
	print("Feel smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _setup() -> void:
	scene = Match.instantiate() as Node3D
	root.add_child(scene)
	game = scene.get_node("GameManager")
	interaction = scene.get_node("Interaction")
	ui = scene.get_node("Interface")
	camera = scene.get_node("Camera3D")
	await physics_frame
	await process_frame


func _dispose() -> void:
	scene.queue_free()
	await process_frame


func _place(piece: Node3D, cell: Vector2i) -> void:
	_expect(game.board_state.move_piece(piece, cell), "Fixture coordinate is available")
	piece.position = game.battlefield.position_for_cell(cell)


func _verify_preview() -> void:
	var legal: Array[Vector2i] = game.valid_destinations(game.selected_piece)
	var shown: Array[Vector2i] = []
	for tile in game.battlefield.get_node("Tiles").get_children():
		if tile.get_node("MoveHint").visible:
			shown.append(tile.get_meta("grid_coordinate"))
	_expect(shown.size() == legal.size(), "No extra or missing legal highlights")
	for cell in shown:
		_expect(legal.has(cell) and game.selected_destinations.has(cell), "Every displayed destination uses the authoritative resolver")


func _test_hover_and_previews() -> void:
	var attacker: Node3D = scene.get_node("Pieces/Ash_03")
	var enemy: Node3D = scene.get_node("Pieces/Slate_01")
	_place(enemy, Vector2i(2, 6))
	await physics_frame
	interaction.update_hover(camera.unproject_position(attacker.get_pick_point()))
	_expect(interaction.hover_kind == &"selectable" and attacker.get_node("HoverRing").visible, "Selectable statue has subtle hover response")
	_expect(game.action_state_name() == "TURN_IDLE", "Hover does not select or move a statue")
	game.handle_cell_clicked(attacker.grid_coordinate)
	_expect(game.action_state_name() == "PIECE_SELECTED" and ui.info_panel.visible, "Selection state and information panel agree")
	_expect(ui.info_text.text.contains("POWER") and ui.info_text.text.contains("1 tile in any of 8")
		and ui.info_text.text.contains("Blood Step") and ui.info_text.text.contains("STATUS"), "Information comes from current role, movement, ability and status data")
	_verify_preview()
	interaction.update_hover(camera.unproject_position(enemy.get_pick_point()))
	_expect(interaction.hover_kind == &"capture" and enemy.get_node("HoverRing").visible, "Legal enemy target has capture hover")
	_expect(ui.hover_text.text.contains("CAPTURE") and not game.capture_director.active, "Hover previews a capture without beginning a cinematic")
	var marks: Array[Node] = game.battlefield.get_node("TargetMarks").get_children()
	_expect(marks.any(func(mark: Node) -> bool: return mark.get_meta("kind") == &"capture"), "Capture has a shape cue in addition to color")
	attacker.apply_status(BloodStep, 0, 1)
	_expect(attacker.get_node("StatusMarker").visible and attacker.get_node("StatusMarker").text == "B", "Blood Step marker appears on the correct piece")
	_expect(ui.info_text.text.contains("ends with owner turn"), "Selected status timing is readable")
	_verify_preview()
	marks = game.battlefield.get_node("TargetMarks").get_children()
	_expect(marks.any(func(mark: Node) -> bool: return mark.get_meta("kind") == &"ability"), "Status-derived destinations have the bonus symbol")
	attacker.apply_status(Terror, 0, 1)
	_verify_preview()
	interaction.update_hover(camera.unproject_position(enemy.get_pick_point()))
	_expect(interaction.hover_kind == &"unavailable" and not game.valid_destinations(attacker).has(enemy.grid_coordinate), "Terror removes capture from both preview and action eligibility")
	_expect(not enemy.get_node("HoverRing").visible and ui.info_text.text.contains("cannot capture"), "Enemy capture hover clears and status explanation updates")
	var coordinate: Vector2i = attacker.grid_coordinate
	game.handle_cell_clicked(enemy.grid_coordinate)
	_expect(not game.capture_director.active and attacker.grid_coordinate == coordinate and game.selected_piece == null,
		"An unhighlighted enemy cannot be captured")
	_expect(ui.feedback_text.text.contains("Terrified") or ui._feedback_queue.any(func(message: String) -> bool: return message.contains("Terrified")), "Rejected actions receive a reason")
	attacker.statuses.expire(1)
	_expect(not attacker.get_node("StatusMarker").visible, "Expired statuses remove their markers")
	game.handle_cell_clicked(attacker.grid_coordinate)
	_verify_preview()
	game.handle_cell_clicked(attacker.grid_coordinate)
	_expect(game.selected_piece == null and not ui.info_panel.visible, "Clicking a selected statue deselects it")
	_expect(scene.get_node("Pieces/Ash_01/ArmyMark").get_child_count() == 1
		and scene.get_node("Pieces/Slate_01/ArmyMark").get_child_count() == 2, "Army identity includes different pedestal geometry")


func _test_threat_and_input() -> void:
	var enemy: Node3D = scene.get_node("Pieces/Slate_01")
	var core: Node3D = scene.get_node("Pieces/Ash_04")
	game.refresh_tactics()
	_expect(game.threatened_cores.has(core) and core.get_node("ThreatRing").visible, "Core threat uses actual enemy capture destinations")
	_expect(ui.threat_text.text.contains("PLAYER 1 CORE THREATENED"), "Threat has a persistent textual warning")
	enemy.apply_status(Terror, 0, 1)
	_expect(not game.threatened_cores.has(core), "Capture-blocking statuses also suppress false Core warnings")
	enemy.statuses.expire(1)
	_expect(game.threatened_cores.has(core), "Threat returns when capture eligibility returns")
	var mover: Node3D = scene.get_node("Pieces/Ash_01")
	game.handle_cell_clicked(mover.grid_coordinate)
	_expect(game.valid_destinations(mover).has(Vector2i(0, 6)), "A threatened Core imposes no check-style response rule")
	game.handle_cell_clicked(Vector2i(0, 6))
	_expect(game.phase == game.Phase.MOVING and not game.can_accept_input(), "Movement holds the authoritative input lock")
	game.handle_cell_clicked(core.grid_coordinate)
	_expect(game.selected_piece == null and not game.capture_director.start(mover, enemy), "Selection and direct capture startup are blocked during movement")
	var started := Time.get_ticks_msec()
	while game.is_moving and Time.get_ticks_msec() - started < 4000:
		await process_frame
	_expect(game.current_player == 1 and game.completed_turns == [1, 0], "Movement resolves one turn")
	var turns: Array = game.completed_turns.duplicate()
	game._finish_normal_move()
	game._advance_turn()
	_expect(game.completed_turns == turns and game.current_player == 1, "Repeated finish/advance callbacks cannot advance twice")
	_expect(game.debug_validate_state(false).is_empty(), "Completed action has consistent occupancy and positions")
	var original := mover.position
	mover.position += Vector3(0.15, 0, 0)
	_expect(not game.debug_validate_state(false).is_empty(), "Debug validation catches position corruption without per-frame logging")
	mover.position = original


func _test_resolutions() -> void:
	game.handle_cell_clicked(Vector2i(0, 0)) # select Player 2 statue for panel layout
	for size in [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1920, 1080)]:
		root.size = size
		await process_frame
		await process_frame
		var viewport := root.get_visible_rect()
		var rect: Rect2 = ui.info_panel.get_global_rect()
		_expect(viewport.encloses(rect), "Information panel stays within desktop viewport %s" % size)
		_expect(viewport.encloses(ui.get_node("Panel").get_global_rect()), "Turn panel stays within desktop viewport")
		for y in range(8):
			for x in range(8):
				var point: Vector3 = game.battlefield.position_for_cell(Vector2i(x, y))
				var screen := camera.unproject_position(point)
				_expect(viewport.has_point(screen), "All tile centers remain framed after resizing")
				_expect(not rect.has_point(screen), "Information panel does not cover a playable tile center")
		var director: Node = scene.get_node("CameraDirector")
		var canonical := camera.global_transform
		director.save_strategic_state()
		var core: Node3D = scene.get_node("Pieces/Ash_04")
		var local_bounds: AABB = core.get_visual_bounds()
		local_bounds.position -= core.global_position
		for origin in [Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 7), Vector2i(7, 7)]:
			for step in [Vector2i(1 if origin.x == 0 else -1, 0), Vector2i(0, 1 if origin.y == 0 else -1),
					Vector2i(1 if origin.x == 0 else -1, 1 if origin.y == 0 else -1)]:
				var a: Vector3 = game.battlefield.to_global(game.battlefield.position_for_cell(origin))
				var b: Vector3 = game.battlefield.to_global(game.battlefield.position_for_cell(origin + step))
				var bounds_a := AABB(a + local_bounds.position, local_bounds.size)
				var bounds_b := AABB(b + local_bounds.position, local_bounds.size)
				var bounds := bounds_a.merge(bounds_b)
				var pose: Transform3D = director.calculate_pose(a, b, bounds, core.get_capture_behavior(), 1)
				_expect(pose.origin.y >= 3.0 and director._fits(bounds, pose, viewport.size.x / viewport.size.y),
					"Large statues fit corner/edge/directional capture framing after resizing")
		director.restore_strategic_state()
		_expect(camera.global_transform == canonical, "Camera restores exactly after resized framing checks")
	root.size = Vector2i(960, 666)
	game.clear_selection()
	await process_frame


func _test_debug_and_idle_cost() -> void:
	var overlay: CanvasLayer = scene.get_node("DebugOverlay")
	_expect(not overlay.panel.visible and not overlay.is_processing(), "Debug overlay starts hidden with no process work")
	var key := InputEventKey.new()
	key.keycode = KEY_F3
	key.pressed = true
	root.push_input(key, true)
	_expect(overlay.panel.visible and overlay.text.text.contains("TURN_IDLE"), "F3 exposes useful development state")
	root.push_input(key, true)
	_expect(not overlay.panel.visible and not overlay.is_processing(), "F3 disables overlay processing again")
	var disabled := CanvasLayer.new()
	disabled.set_script(DebugOverlay)
	disabled.enabled = false
	scene.add_child(disabled)
	_expect(disabled.panel == null and not disabled.is_processing(), "Debug tools can be completely disabled")
	disabled.queue_free()
	var motion := InputEventMouseMotion.new()
	motion.position = camera.unproject_position(game.battlefield.position_for_cell(Vector2i(3, 3)))
	root.push_input(motion, true)
	await physics_frame
	await process_frame
	var calculations: int = game._movement.calculation_count
	var rays: int = interaction.ray_query_count
	for frame in range(20):
		await physics_frame
	_expect(game._movement.calculation_count == calculations and interaction.ray_query_count == rays,
		"Stationary idle hover performs no repeated raycasts or legal-move calculations")
	print("Idle baseline: %d scene nodes; %d move calculations and %d rays over 20 idle physics frames" % [scene.find_children("*", "", true, false).size(), game._movement.calculation_count - calculations, interaction.ray_query_count - rays])
	await process_frame
	var nodes_before := get_node_count()
	for index in range(12):
		game.handle_cell_clicked(Vector2i(1, 0))
		game.clear_selection()
		await process_frame
	_expect(get_node_count() <= nodes_before + 1, "Repeated selection releases all temporary target markings")


func _test_victory_pause() -> void:
	var attacker: Node3D = scene.get_node("Pieces/Ash_03")
	var victim: Node3D = scene.get_node("Pieces/Slate_04")
	_place(victim, Vector2i(3, 6))
	var canonical := camera.global_transform
	var times: Dictionary = {}
	game.capture_resolved.connect(func(_a: Node3D, _v: Node3D) -> void: times["resolved"] = Time.get_ticks_msec())
	game.victory.connect(func(_player: int) -> void: times["victory"] = Time.get_ticks_msec())
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	game.capture_director.accelerate()
	var deadline := Time.get_ticks_msec() + 6000
	while game.phase == game.Phase.CAPTURING and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(game.phase == game.Phase.RESOLVING and not game.can_accept_input(), "Core capture enters a locked atmospheric pause")
	_expect(camera.global_transform == canonical and not game.capture_director.active and not ui.victory_screen.visible,
		"Pause begins after exact camera return and before victory presentation")
	game.handle_cell_clicked(Vector2i(0, 7))
	_expect(game.selected_piece == null, "No action can begin in the victory pause")
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(times.has("victory") and times["victory"] - times.get("resolved", 0) >= 200, "Victory is visibly delayed after cinematic resolution")
	_expect(game.phase == game.Phase.GAME_OVER and ui.victory_screen.visible and game.winner == 0, "Solemn victory and rematch controls appear")
	game._present_victory()
	game._advance_turn()
	_expect(game.completed_turns == [0, 0] and not game.can_accept_input(), "Repeated victory/turn callbacks cannot resume play")
	_expect(ui.get_node("VictoryScreen/Center/Result/Margin/Rows/Restart").text == "REMATCH", "Victory offers rematch")


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
