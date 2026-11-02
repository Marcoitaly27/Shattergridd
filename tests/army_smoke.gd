extends SceneTree
## Data rejection, future sidegrades and the real builder/match/restart scene flow.

const Rules = preload("res://scripts/army/army_rules.gd")
const Slot = preload("res://scripts/army/deployment_slot.gd")
const BoardState = preload("res://scripts/board/board_state.gd")
var checks: int = 0
var failures: int = 0
var session: Node

class SidegradeMovement extends Resource:
	func get_destinations(origin: Vector2i, _army: int, _board: RefCounted) -> Array[Vector2i]:
		return [origin + Vector2i(0, -2)]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	session = root.get_node("MatchSession")
	_test_data()
	await _test_scene_flow()
	print("Army smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _plan(loadouts: Array, formation: Resource = session.FORMATION,
		catalog: Resource = session.CATALOG) -> Dictionary:
	return Rules.new().plan_match(formation, loadouts, catalog, session.collection, Vector2i(8, 8))


func _rejected(loadouts: Array, label: String, formation: Resource = session.FORMATION,
		catalog: Resource = session.CATALOG) -> void:
	var plan := _plan(loadouts, formation, catalog)
	_expect(not plan.errors.is_empty() and plan.pieces.is_empty(), label)


func _test_data() -> void:
	_expect(session.CATALOG.validation_errors().is_empty(), "All current character definitions are valid")
	_expect(session.CATALOG.characters.size() == 7, "Requested seven-character roster is available")
	for character in session.CATALOG.characters:
		_expect(character.character_id != &"" and character.title != "" and character.gameplay_description != "",
			"Character identity and preview are data")
		_expect(session.collection.is_unlocked(character) and session.collection.is_visible(character),
			"Every current prototype is available")
		_expect(character.movement_behavior != null and character.capture_behavior != null, "Behavior references survived migration")
	var loadouts: Array = session.get_loadouts()
	_expect(loadouts[0] != loadouts[1], "Players have independent loadout resources")
	var plan := _plan(loadouts)
	_expect(plan.errors.is_empty() and plan.pieces.size() == 16, "Current configuration plans exactly sixteen statues")
	for player in range(2):
		var cores := 0
		for entry in plan.pieces:
			if entry.army == player and entry.character.is_core_objective:
				cores += 1
		_expect(cores == 1, "Each army has one Core objective")
		for slot in session.FORMATION.slots:
			var matches: Array = plan.pieces.filter(func(entry: Dictionary) -> bool:
				return entry.army == player and entry.slot_id == slot.slot_id)
			_expect(matches.size() == (2 if slot.paired else 1), "One choice deploys the configured number of members")
			if slot.paired:
				_expect(matches[0].character == matches[1].character, "Both members use the same character definition")
				_expect(matches[0].coordinate.x + matches[1].coordinate.x == 6 and matches[0].coordinate.y == matches[1].coordinate.y,
					"Prototype pairs occupy reflected board positions")
	loadouts[0].set_character(&"special", &"elf")
	_expect(loadouts[1].character_for(&"special") == &"witch" and session.DEFAULT_LOADOUT.character_for(&"special") == &"witch",
		"Editing one player does not mutate the other player or the default resource")
	_expect(session.get_loadouts()[0].character_for(&"special") == &"witch", "Editing snapshots does not change the session")
	for invalid in [&"hunter", &"core", &"missing_id"]:
		loadouts = session.get_loadouts()
		loadouts[0].set_character(&"guard", invalid)
		_rejected(loadouts, "Category, Core and unknown-ID violations are rejected")
	loadouts = session.get_loadouts()
	loadouts[0].selections.erase(&"core")
	_rejected(loadouts, "Missing Core selection is rejected")
	loadouts = session.get_loadouts()
	loadouts[0].set_character(&"unknown_slot", &"witch")
	_rejected(loadouts, "Unknown slot keys are rejected")
	_rejected([loadouts[0]], "A missing player is rejected")
	_rejected([null, null], "Null loadouts are rejected")
	loadouts = session.get_loadouts()
	var formation: Resource = session.FORMATION.duplicate(true)
	formation.slots[0].left_coordinate = Vector2i(-1, 7)
	_rejected(loadouts, "Out-of-board deployment is rejected", formation)
	formation = session.FORMATION.duplicate(true)
	formation.slots[0].mirrored_coordinate = formation.slots[0].left_coordinate
	_rejected(loadouts, "Duplicate member positions are rejected", formation)
	formation = session.FORMATION.duplicate(true)
	formation.slots[0].mirrored_coordinate = Vector2i(6, 6)
	_rejected(loadouts, "Pair geometry must reflect across the Core column", formation)
	formation = session.FORMATION.duplicate(true)
	formation.slots[0].left_coordinate = Vector2i(0, 3)
	formation.slots[0].mirrored_coordinate = Vector2i(0, 4)
	_rejected(loadouts, "Opponent army overlap is rejected", formation)
	formation = session.FORMATION.duplicate(true)
	formation.slots[1].slot_id = formation.slots[0].slot_id
	_rejected(loadouts, "Duplicate slot IDs are rejected", formation)
	formation = session.FORMATION.duplicate(true)
	formation.slots[3].paired = true
	formation.slots[3].mirrored_coordinate = Vector2i(3, 6)
	_rejected(loadouts, "A paired Core is rejected", formation)
	formation = session.FORMATION.duplicate(true)
	formation.board_dimensions = Vector2i(9, 8)
	_rejected(loadouts, "Board/formation dimension mismatch is rejected", formation)
	formation = session.FORMATION.duplicate(true)
	formation.slots[0].allowed_character_ids = [&"not_the_warden"] as Array[StringName]
	_rejected(loadouts, "Optional per-slot restrictions are enforced", formation)
	# SPECIAL is not permanently forced into one asymmetric position or eight pieces.
	formation = session.FORMATION.duplicate(true)
	formation.slots[4].paired = true
	formation.slots[4].left_coordinate = Vector2i(2, 6)
	formation.slots[4].mirrored_coordinate = Vector2i(4, 6)
	var expanded := _plan(loadouts, formation)
	_expect(expanded.errors.is_empty() and expanded.pieces.size() == 18, "A future SPECIAL pair is configurable without spawn changes")
	var catalog: Resource = session.CATALOG.duplicate()
	catalog.characters = session.CATALOG.characters.duplicate()
	var sidegrade: Resource = session.CATALOG.find_character(&"warden").duplicate()
	sidegrade.character_id = &"test_guard_sidegrade"
	sidegrade.movement_behavior = SidegradeMovement.new()
	sidegrade.unlocked_by_default = false
	sidegrade.hidden_until_unlocked = true
	sidegrade.unlock_condition_id = &"test_discovery"
	catalog.characters.append(sidegrade)
	_expect(not session.collection.is_unlocked(sidegrade) and not session.collection.is_visible(sidegrade), "Hidden locked characters are omitted from collection UI")
	loadouts[0].set_character(&"guard", sidegrade.character_id)
	_rejected(loadouts, "Unlock availability is enforced outside the UI", session.FORMATION, catalog)
	sidegrade.hidden_until_unlocked = false
	_expect(session.collection.is_visible(sidegrade) and not session.collection.is_unlocked(sidegrade), "Visible locked characters are distinct from hidden characters")
	session.collection.unlock(sidegrade.character_id)
	session.collection.unlock(sidegrade.character_id)
	_expect(session.collection.is_unlocked(sidegrade) and session.collection.unlocked_character_ids.count(sidegrade.character_id) == 1,
		"Unlocking reveals availability without stacking or modifying definition defaults")
	var future := _plan(loadouts, session.FORMATION, catalog)
	_expect(future.errors.is_empty(), "A new character with an existing category/archetype needs only data registration")
	_expect(future.pieces.filter(func(entry: Dictionary) -> bool: return entry.character == sidegrade).size() == 2,
		"A new Guard choice fills both members")
	_expect(sidegrade.archetype_id == &"warden" and sidegrade.character_id != &"warden", "Character identity differs from cinematic family")
	_expect(sidegrade.movement_behavior.get_destinations(Vector2i(3, 5), 0, BoardState.new()) == [Vector2i(3, 3)],
		"A sidegrade can carry different movement without controller edits")
	var alternate_core: Resource = session.CATALOG.find_character(&"core").duplicate()
	alternate_core.character_id = &"test_alternate_core"
	catalog.characters.append(alternate_core)
	loadouts[0].set_character(&"core", alternate_core.character_id)
	_expect(_plan(loadouts, session.FORMATION, catalog).errors.is_empty(), "Registry supports multiple Core definitions but deploys only one per army")
	catalog.characters.append(alternate_core)
	_rejected(loadouts, "Duplicate character IDs are rejected", session.FORMATION, catalog)
	session.collection.unlocked_character_ids.clear()
	# Invalid session updates must not partially replace the last valid snapshots.
	loadouts = session.get_loadouts()
	loadouts[0].set_character(&"special", &"elf")
	_expect(session.configure_loadouts(loadouts).is_empty(), "Two independently valid loadouts can be confirmed")
	loadouts[0].set_character(&"guard", &"witch")
	_expect(not session.configure_loadouts(loadouts).is_empty() and session.get_loadouts()[0].character_for(&"special") == &"elf"
		and session.get_loadouts()[0].character_for(&"guard") == &"warden",
		"Invalid configuration cannot erase the previous confirmed loadouts")


func _test_scene_flow() -> void:
	var launch: String = ProjectSettings.get_setting("application/run/main_scene")
	_expect(launch == "res://scenes/ui/army_builder.tscn", "F5 opens the army builder")
	change_scene_to_file(launch)
	await _wait_scene("ArmyBuilder")
	var builder := current_scene
	_expect(builder.selectors.size() == 2 and builder.selectors[0].size() == 5, "Both players have category choices")
	_expect(builder.loadouts[0].character_for(&"special") == &"elf" and builder.loadouts[1].character_for(&"special") == &"witch",
		"Builder reads confirmed choices independently")
	_expect(builder.selectors[0][&"special"].item_count == 2 and builder.selectors[0][&"guard"].item_count == 1,
		"Available choices are filtered by deployment category")
	# Exercise the same signal path as selecting an item with mouse/keyboard.
	_choose(builder, 0, &"special", &"witch")
	_choose(builder, 1, &"special", &"elf")
	_expect(builder.loadouts[0].character_for(&"special") == &"witch" and builder.loadouts[1].character_for(&"special") == &"elf",
		"UI choices update independent loadouts")
	_start_builder(builder)
	await _wait_scene("Shattergrid")
	_check_armies()
	var game: Node = current_scene.get_node("GameManager")
	game.handle_cell_clicked(Vector2i(0, 7))
	_expect(game.valid_destinations(game.selected_piece).has(Vector2i(0, 6)), "Loadout-spawned pieces are selectable")
	game.handle_cell_clicked(Vector2i(0, 6))
	await _wait_move(game)
	_expect(game.current_player == 1, "Player 1 move advances the turn")
	game.handle_cell_clicked(Vector2i(0, 0))
	game.handle_cell_clicked(Vector2i(0, 1))
	await _wait_move(game)
	_expect(game.current_player == 0, "Player 2 can move normally")
	var old_id := current_scene.get_instance_id()
	game.restart_match()
	await _wait_scene("Shattergrid", old_id)
	_check_armies()
	game = current_scene.get_node("GameManager")
	_expect(game.current_player == 0 and game.completed_turns == [0, 0], "Restart clears match state while keeping loadouts")
	current_scene.get_node("Interface/Loadout").pressed.emit()
	await _wait_scene("ArmyBuilder")
	builder = current_scene
	_expect(builder.loadouts[1].character_for(&"special") == &"elf", "Returning to builder retains choices")
	_start_builder(builder)
	await _wait_scene("Shattergrid")
	_check_armies()
	# Abort an active capture by returning to the builder; no old army survives.
	game = _prepare_core_capture()
	_expect(game.capture_director.active, "Capture starts with data-selected Werewolf")
	current_scene.get_node("Interface/Loadout").pressed.emit()
	await _wait_scene("ArmyBuilder")
	_start_builder(current_scene)
	await _wait_scene("Shattergrid")
	_check_armies()
	game = _prepare_core_capture()
	game.capture_director.accelerate()
	await _wait_move(game)
	_expect(game.phase == game.Phase.GAME_OVER and game.winner == 0, "Chosen Core destruction still ends the match")
	_expect(current_scene.get_node("Interface/VictoryScreen").visible, "Victory appears after the capture")
	current_scene.get_node("Interface/VictoryScreen/Center/Result/Margin/Rows/Loadout").pressed.emit()
	await _wait_scene("ArmyBuilder")
	_start_builder(current_scene)
	await _wait_scene("Shattergrid")
	_check_armies()


func _choose(builder: Node, player: int, slot_id: StringName, character_id: StringName) -> void:
	var options: OptionButton = builder.selectors[player][slot_id]
	for index in range(options.item_count):
		if options.get_item_metadata(index) == character_id:
			options.select(index)
			options.item_selected.emit(index)
			return
	_expect(false, "Requested character exists in selector")


func _start_builder(builder: Node) -> void:
	_expect(not builder.start_button.disabled, "Valid loadouts enable Start Match")
	builder.start_button.pressed.emit()
	# A second press in the same frame must not create another match.
	builder.start_button.pressed.emit()


func _check_armies() -> void:
	var scene := current_scene
	var pieces: Array[Node] = scene.get_node("Pieces").get_children()
	_expect(pieces.size() == 16, "Start/restart/return never duplicates armies")
	_expect(scene.get_node("Effects").get_child_count() == 0, "New match has no stale capture effects")
	var ids: Dictionary = {}
	for piece in pieces:
		_expect(not ids.has(piece.piece_id), "Every reflected instance has a unique identity")
		ids[piece.piece_id] = true
		_expect(scene.get_node("GameManager").board_state.piece_at(piece.grid_coordinate) == piece, "Spawned coordinates register in occupancy")
		_expect(piece.get_movement_behavior() == piece.character_definition.movement_behavior
			and piece.get_capture_behavior() == piece.character_definition.capture_behavior, "Movement and cinematic behavior come from selected data")
	for player in range(2):
		var owned: Array = pieces.filter(func(piece: Node3D) -> bool: return piece.army == player)
		_expect(owned.size() == 8 and owned.filter(func(piece: Node3D) -> bool: return piece.character_definition.is_core_objective).size() == 1,
			"Each deployed army has one Core and eight statues")
		for slot in session.FORMATION.slots:
			var members: Array = owned.filter(func(piece: Node3D) -> bool: return piece.deployment_slot_id == slot.slot_id)
			_expect(members.size() == (2 if slot.paired else 1), "Configured pairs/singletons spawn correctly")
			if members.size() == 2:
				_expect(members[0].character_definition == members[1].character_definition and members[0].statuses != members[1].statuses,
					"Pairs share definitions but never share per-piece status state")
	var special_a: Node3D = scene.get_node("Pieces/Ash_08")
	var special_b: Node3D = scene.get_node("Pieces/Slate_08")
	_expect(special_a.character_definition.character_id == &"witch" and special_b.character_definition.character_id == &"elf",
		"Players deploy their own Special choices")
	_expect(special_b.character_definition.active_ability == &"exchange", "Elf has Veil Exchange")
	_expect(scene.get_node("Pieces/Ash_03").character_definition.post_capture_effect == load("res://resources/abilities/wolf_blood_step.tres"), "Werewolf has night-gated Blood Step")


func _prepare_core_capture() -> Node:
	var game: Node = current_scene.get_node("GameManager")
	var attacker: Node3D = current_scene.get_node("Pieces/Ash_03")
	var victim: Node3D = current_scene.get_node("Pieces/Slate_04")
	attacker.set_night(true)
	for piece in current_scene.get_node("Pieces").get_children():
		piece.ability_spent = true # This fixture isolates Core cinematic/scene flow.
	attacker.grid_coordinate = Vector2i(3, 3)
	victim.grid_coordinate = Vector2i(4, 3)
	game.board_state = BoardState.new(game.battlefield.board_dimensions)
	for piece in current_scene.get_node("Pieces").get_children():
		piece.position = game.battlefield.position_for_cell(piece.grid_coordinate)
		game.board_state.register_piece(piece)
	game.handle_cell_clicked(attacker.grid_coordinate)
	game.handle_cell_clicked(victim.grid_coordinate)
	return game


func _wait_scene(expected_name: String, previous_id: int = -1) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.name == expected_name and current_scene.get_instance_id() != previous_id:
			await physics_frame
			return
	_expect(false, "Scene transition completes: " + expected_name)


func _wait_move(game: Node) -> void:
	var deadline := Time.get_ticks_msec() + 6000
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not game.is_moving, "Move/capture finishes without a stuck phase")


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
