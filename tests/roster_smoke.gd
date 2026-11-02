extends SceneTree
## Actual roster rules and multi-turn ability interactions, independent of art.
const Match = preload("res://scenes/main.tscn")
const Piece = preload("res://scenes/pieces/placeholder_piece.tscn")
const Board = preload("res://scripts/board/board_state.gd")
const Actions = preload("res://scripts/game/character_actions.gd")
var checks := 0
var failures := 0
var scene: Node3D
var game: Node

func _initialize() -> void:
	create_timer(75).timeout.connect(func() -> void: push_error("Roster timeout"); quit(1))
	_run.call_deferred()

func _run() -> void:
	await _setup()
	_test_catalog()
	_test_movement()
	await _dispose()
	await _test_shield()
	await _test_rescue()
	await _test_bow()
	await _test_cycle_and_wolf()
	await _test_flight()
	await _test_bow_core_and_restart()
	await _test_bonus_edges()
	await _test_exchange()
	await _test_restart()
	print("Roster smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _setup() -> void:
	scene = Match.instantiate()
	root.add_child(scene)
	game = scene.get_node("GameManager")
	for piece in scene.get_node("Pieces").get_children():
		piece.get_parent().remove_child(piece)
		piece.queue_free()
	game.board_state = Board.new()
	await process_frame

func _dispose() -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame

func _spawn(id: String, army: int, cell: Vector2i) -> Node3D:
	var piece := Piece.instantiate() as Node3D
	piece.character_definition = load("res://resources/characters/%s.tres" % id)
	piece.army = army
	piece.grid_coordinate = cell
	piece.position = game.battlefield.position_for_cell(cell)
	scene.get_node("Pieces").add_child(piece)
	piece.status_changed.connect(game._on_status_changed)
	piece.status_applied.connect(game._on_status_applied)
	_expect(game.board_state.register_piece(piece), "Fixture has unique occupancy")
	return piece

func _act(piece: Node3D, destination: Vector2i, ability: bool = false) -> void:
	game.handle_cell_clicked(piece.grid_coordinate)
	if ability:
		scene.get_node("Interface").ability_button.pressed.emit()
	game.handle_cell_clicked(destination)

func _finish() -> void:
	if game.capture_director.active:
		game.capture_director.accelerate()
	var deadline := Time.get_ticks_msec() + 5000
	while game.is_moving and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(not game.is_moving and game.debug_validate_state(false).is_empty(), "Action completes with consistent occupancy")

func _test_catalog() -> void:
	var session := root.get_node("MatchSession")
	_expect(session.CATALOG.validation_errors().is_empty() and session.CATALOG.characters.size() == 7, "Seven requested roster definitions are valid")
	_expect(session.CATALOG.find_character(&"executioner") == null and session.CATALOG.find_character(&"wyrm") == null, "Old characters are no longer selectable")
	var options: Array = session.get_loadouts()
	options[0].set_character(&"power", &"dragon")
	options[0].set_character(&"special", &"elf")
	var rules = load("res://scripts/army/army_rules.gd").new()
	var plan: Dictionary = rules.plan_match(session.FORMATION, options, session.CATALOG, session.collection, Vector2i(8,8))
	_expect(plan.errors.is_empty() and plan.pieces.size() == 16, "Dragon Power pair and Random Elf fit existing reflected formation")
	var dragons: Array = plan.pieces.filter(func(entry: Dictionary) -> bool: return entry.army == 0 and entry.character.character_id == &"dragon")
	_expect(dragons.size() == 2 and dragons[0].coordinate.x + dragons[1].coordinate.x == 6, "Dragon preserves the Law of Reflection")

func _test_movement() -> void:
	for army in [0, 1]:
		for entry in [["warden",4],["hunter",2],["werewolf",2],["witch",3],["dragon",8],["elf",3]]:
			var piece := _spawn(entry[0], army, Vector2i(3,3))
			var legal: Array = game._movement.destinations(piece, game.board_state, 0)
			_expect(legal.size() == entry[1], "%s has exact base movement for player %d" % [entry[0],army+1])
			if entry[0] in ["witch","elf"]:
				var forward := Vector2i(3,2 if army == 0 else 4)
				_expect(legal.has(forward) and not legal.has(Vector2i(3,4 if army == 0 else 2)), "Forward is army-relative, backward is excluded")
			game.board_state.remove_piece(piece)
			piece.free()

func _test_shield() -> void:
	await _setup()
	var attacker := _spawn("dragon",0,Vector2i(3,3))
	var defender := _spawn("warden",1,Vector2i(3,2))
	var witch := _spawn("witch",1,Vector2i(5,2))
	_act(attacker,defender.grid_coordinate)
	_expect(game.phase == game.Phase.DEFENDING and not game.capture_director.active, "Shield takes priority over rescue and cinematic")
	await _finish()
	_expect(defender.shield_spent and not witch.ability_spent and defender.visible, "First hit breaks only that shield, leaving Witch charge untouched")
	_expect(game.current_player == 1 and game.completed_turns == [1,0] and attacker.grid_coordinate == Vector2i(3,3), "Prevented capture consumes attacker turn and leaves both cells intact")
	_expect(not defender.get_node("Visuals/Model/Shield").visible, "Shield visibly falls and is removed")
	_expect(not attacker.statuses.has(&"flight_ready"), "Prevented capture grants no kill bonus")
	defender.replace_visual(load("res://scenes/pieces/characters/warden.tscn"))
	_expect(not defender.get_node("Visuals/Model/Shield").visible, "Visual replacement cannot restore a spent shield")
	_act(witch,Vector2i(5,3))
	await _finish()
	_act(attacker,defender.grid_coordinate)
	_expect(game.phase == game.Phase.DECIDING, "Second hit reaches optional Witch rescue")
	game.resolve_rescue(false)
	await _finish()
	_expect(game.board_state.piece_at(Vector2i(3,2)) == attacker and not witch.ability_spent, "Declining rescue allows real capture; Witch use remains available")
	await _dispose()

func _test_rescue() -> void:
	await _setup()
	var attacker := _spawn("dragon",0,Vector2i(3,3))
	var core := _spawn("core",1,Vector2i(3,2))
	var witch := _spawn("witch",1,Vector2i(5,2))
	_act(attacker,core.grid_coordinate)
	_expect(game.phase == game.Phase.DECIDING and not game.can_accept_input(), "Defender chooses rescue with gameplay locked")
	_expect(scene.get_node("Interface").rescue_dialog.visible, "Actual rescue dialog is shown")
	game.resolve_rescue(true)
	game.resolve_rescue(true)
	await _finish()
	_expect(witch.ability_spent and game.winner == -1 and core.visible, "Rescue can save Core, exactly once without ending match")
	_expect(game.completed_turns == [1,0] and attacker.grid_coordinate == Vector2i(3,3), "Repeated rescue callback cannot spend a second turn")
	_act(witch,Vector2i(5,3))
	await _finish()
	_act(attacker,core.grid_coordinate)
	await _finish()
	_expect(game.winner == 0 and game.phase == game.Phase.GAME_OVER, "Spent Witch cannot prevent subsequent Core destruction")
	await _dispose()
	await _setup()
	attacker = _spawn("dragon",0,Vector2i(3,3))
	witch = _spawn("witch",1,Vector2i(3,2))
	_act(attacker,witch.grid_coordinate)
	game.resolve_rescue(true)
	await _finish()
	_expect(witch.visible and witch.ability_spent and witch.grid_coordinate == Vector2i(3,2), "Witch can rescue herself")
	await _dispose()

func _test_bow() -> void:
	for army in [0,1]:
		await _setup()
		var hunter := _spawn("hunter",army,Vector2i(3,3))
		game.current_player = army
		var forward := -1 if army == 0 else 1
		var victim := _spawn("dragon",1-army,Vector2i(3,3+2*forward))
		var diagonal := _spawn("dragon",1-army,Vector2i(5,3+2*forward))
		var side := _spawn("dragon",1-army,Vector2i(1,3))
		var blocker := _spawn("core",army,Vector2i(3,3+forward))
		var targets: Array = game.ability_targets(hunter)
		_expect(not targets.has(victim.grid_coordinate) and targets.has(diagonal.grid_coordinate) and targets.has(side.grid_coordinate), "Bow has exact army-relative range and clear path")
		game.board_state.remove_piece(blocker)
		blocker.free()
		_act(hunter,victim.grid_coordinate,true)
		_expect(game.capture_director.active and hunter.ability_spent, "Bow starts cinematic and commits its per-instance use")
		await _finish()
		_expect(hunter.grid_coordinate == Vector2i(3,3) and hunter.position == game.battlefield.position_for_cell(Vector2i(3,3)), "Hunter stays on its source tile throughout ranged resolution")
		_expect(game.board_state.piece_at(Vector2i(3,3+2*forward)) == null and game.current_player == 1-army, "Arrow removes only target and consumes one turn")
		game.current_player = army
		_expect(game.ability_targets(hunter).is_empty(), "Arrow cannot be used twice")
		await _dispose()
	await _setup()
	var hunter := _spawn("hunter",0,Vector2i(3,3))
	var warden := _spawn("warden",1,Vector2i(3,1))
	_act(hunter,warden.grid_coordinate,true)
	await _finish()
	_expect(hunter.ability_spent and warden.shield_spent and game.board_state.piece_at(Vector2i(3,1)) == warden, "Shield blocks arrow, which still spends Hunter's shot")
	await _dispose()

func _test_cycle_and_wolf() -> void:
	await _setup()
	var wolf := _spawn("werewolf",0,Vector2i(3,3))
	var other_wolf := _spawn("werewolf",1,Vector2i(6,6))
	var original_path: String = wolf.get_node("Visuals").asset_info().scene
	game.completed_turns = [4,4] as Array[int]
	game.phase = game.Phase.RESOLVING
	game._advance_turn()
	_expect(not game.is_night and game.completed_turns == [5,4], "Five turns of one player alone do not trigger night")
	game.phase = game.Phase.RESOLVING
	game._advance_turn()
	_expect(game.is_night and wolf.is_night and other_wolf.is_night, "Night starts only after both players complete five turns")
	_expect(wolf.get_movement_behavior() == load("res://resources/characters/temporary_movement.tres") and wolf.get_node("Visuals").asset_info().scene != original_path, "Night changes actual visual and movement")
	_expect(wolf.get_node("PickBody").get_child_count() == 7, "Beast picking ignores hidden human weapon")
	var victim := _spawn("hunter",1,Vector2i(4,2))
	_act(wolf,victim.grid_coordinate)
	await _finish()
	_expect(wolf.statuses.has(&"blood_step") and not other_wolf.statuses.has(&"blood_step"), "Night kill earns per-instance Blood Step")
	game.current_player = 0
	var targets: Array = game.valid_destinations(wolf)
	_expect(targets.has(Vector2i(6,0)) and targets.has(Vector2i(2,4)) and targets.has(Vector2i(4,4)), "Blood Step supplies exact 2-tile moves including diagonals")
	var block := _spawn("core",0,Vector2i(5,1))
	_expect(not game.valid_destinations(wolf).has(Vector2i(6,0)), "Blood Step cannot jump an intervening statue")
	_act(wolf,Vector2i(4,4))
	await _finish()
	_expect(not wolf.statuses.has(&"blood_step"), "Blood Step expires after its one available turn")
	game.completed_turns = [9,9] as Array[int]
	game.current_player = 0
	game.phase = game.Phase.RESOLVING
	game._advance_turn()
	game.phase = game.Phase.RESOLVING
	game._advance_turn()
	_expect(not game.is_night and not wolf.is_night and wolf.get_node("Visuals").asset_info().scene == original_path, "Dawn restores human statue and movement after five night rounds")
	_expect(wolf.grid_coordinate == Vector2i(4,4) and game.debug_validate_state(false).is_empty(), "Transformation preserves identity and occupancy")
	await _dispose()
	await _setup()
	wolf = _spawn("werewolf",0,Vector2i(3,3))
	victim = _spawn("hunter",1,Vector2i(3,2))
	_act(wolf,victim.grid_coordinate)
	await _finish()
	_expect(not wolf.statuses.has(&"blood_step"), "Human daytime kill earns no Blood Step")
	await _dispose()

func _test_flight() -> void:
	await _setup()
	var dragon := _spawn("dragon",0,Vector2i(3,3))
	var victim := _spawn("hunter",1,Vector2i(4,2))
	var enemy := _spawn("hunter",1,Vector2i(7,0))
	_act(dragon,victim.grid_coordinate)
	await _finish()
	_expect(dragon.statuses.has(&"flight_ready") and not dragon.statuses.has(&"terrified"), "Dragon earns flight instead of old Terror status")
	_expect(game.ability_targets(dragon).is_empty(), "Pending flight cannot be used on enemy turn")
	_act(enemy,Vector2i(7,1))
	await _finish()
	var targets: Array = game.ability_targets(dragon)
	_expect(targets.size() == 62 and targets.has(Vector2i(0,7)) and not targets.has(enemy.grid_coordinate), "Flight reaches every empty tile, never an occupied one")
	_act(dragon,Vector2i(0,7),true)
	await _finish()
	_expect(game.current_player == 1 and game.skipped_turns == [1,0], "Flight schedules owner's next army turn as a cost")
	_expect(not dragon.statuses.has(&"flight_ready") and dragon.position == game.battlefield.position_for_cell(Vector2i(0,7)), "Flight uses bonus and lands exactly")
	_act(enemy,Vector2i(7,2))
	await _finish()
	_expect(game.current_player == 1 and game.completed_turns == [3,2] and game.skipped_turns == [0,0], "Opponent acts again after whole-army skip, with owner statuses/clock advanced")
	_act(enemy,Vector2i(7,3))
	await _finish()
	_expect(game.current_player == 0, "Skip costs exactly one turn")
	await _dispose()
	await _setup()
	dragon = _spawn("dragon",0,Vector2i(3,3))
	victim = _spawn("hunter",1,Vector2i(4,2))
	enemy = _spawn("hunter",1,Vector2i(7,0))
	_act(dragon,victim.grid_coordinate)
	await _finish()
	_act(enemy,Vector2i(7,1))
	await _finish()
	_act(dragon,Vector2i(4,3))
	await _finish()
	_expect(not dragon.statuses.has(&"flight_ready") and game.skipped_turns == [0,0], "Declining optional flight expires it without skip penalty")
	await _dispose()

func _test_bow_core_and_restart() -> void:
	await _setup()
	var hunter := _spawn("hunter",0,Vector2i(3,3))
	var core := _spawn("core",1,Vector2i(3,1))
	game.refresh_tactics()
	_expect(game.threatened_cores.has(core), "Unused bow contributes actual ranged Core threat")
	_act(hunter,core.grid_coordinate,true)
	await _finish()
	_expect(game.winner == 0 and hunter.grid_coordinate == Vector2i(3,3), "Ranged Core kill wins without relocating Hunter")
	await _dispose()
	await _setup()
	hunter = _spawn("hunter",0,Vector2i(3,3))
	var enemy := _spawn("dragon",1,Vector2i(3,1))
	_act(hunter,enemy.grid_coordinate,true)
	current_scene = scene
	var old_id := scene.get_instance_id()
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	root.push_input(restart, true)
	var deadline := Time.get_ticks_msec() + 5000
	while (current_scene == null or current_scene.get_instance_id() == old_id) and Time.get_ticks_msec() < deadline:
		await process_frame
	scene = current_scene
	game = scene.get_node("GameManager")
	_expect(not game.capture_director.active and scene.get_node("Effects").get_child_count() == 0 and game.can_accept_input(), "Restart during bow cinematic removes projectile, camera and action ownership")
	await _dispose()

func _test_bonus_edges() -> void:
	await _setup()
	var wolf := _spawn("werewolf",0,Vector2i(3,3))
	var enemy := _spawn("hunter",1,Vector2i(3,2))
	var ally := _spawn("hunter",0,Vector2i(6,6))
	game.completed_turns = [9,9] as Array[int]
	game.is_night = true
	wolf.set_night(true)
	_act(wolf,enemy.grid_coordinate)
	await _finish()
	var opponent := _spawn("hunter",1,Vector2i(7,0))
	_act(opponent,Vector2i(7,1))
	await _finish()
	_expect(not wolf.is_night and game.valid_destinations(wolf).has(Vector2i(5,2)), "Bonus earned at end of night survives until the promised next owner turn")
	_act(ally,Vector2i(6,5))
	await _finish()
	_expect(not wolf.statuses.has(&"blood_step"), "Using another statue still expires individual Blood Step")
	await _dispose()
	await _setup()
	var dragon := _spawn("dragon",0,Vector2i(3,3))
	enemy = _spawn("hunter",1,Vector2i(4,2))
	opponent = _spawn("dragon",1,Vector2i(7,0))
	_act(dragon,enemy.grid_coordinate)
	await _finish()
	_act(opponent,Vector2i(6,1))
	await _finish()
	_act(dragon,Vector2i(5,1),true)
	await _finish()
	_act(opponent,dragon.grid_coordinate)
	await _finish()
	_expect(game.current_player == 1 and game.skipped_turns == [0,0], "Flight penalty persists even if Dragon dies before the skipped turn")
	await _dispose()

func _test_exchange() -> void:
	await _setup()
	var elf := _spawn("elf",0,Vector2i(3,3))
	var ally := _spawn("hunter",0,Vector2i(4,3))
	var core := _spawn("core",0,Vector2i(2,3))
	var enemy := _spawn("dragon",1,Vector2i(3,2))
	var targets: Array = game.ability_targets(elf)
	_expect(targets == [ally.grid_coordinate], "Elf exchange excludes Core, enemies and empty tiles")
	_act(elf,ally.grid_coordinate,true)
	await _finish()
	_expect(elf.grid_coordinate == Vector2i(4,3) and ally.grid_coordinate == Vector2i(3,3), "Veil Exchange swaps logical cells and both visuals atomically")
	_expect(elf.ability_spent and game.current_player == 1 and core.grid_coordinate == Vector2i(2,3) and enemy.grid_coordinate == Vector2i(3,2), "Exchange spends one use and turn without affecting other statues")
	game.current_player = 0
	_expect(game.ability_targets(elf).is_empty(), "Elf cannot exchange twice")
	await _dispose()

func _test_restart() -> void:
	await _setup()
	var attacker := _spawn("dragon",0,Vector2i(3,3))
	var witch := _spawn("witch",1,Vector2i(3,2))
	_act(attacker,witch.grid_coordinate)
	_expect(game.phase == game.Phase.DECIDING, "Restart fixture pauses at decision")
	current_scene = scene
	var old_id := scene.get_instance_id()
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	scene.get_node("Interface").rescue_dialog.window_input.emit(restart)
	var deadline := Time.get_ticks_msec() + 5000
	while (current_scene == null or current_scene.get_instance_id() == old_id) and Time.get_ticks_msec() < deadline:
		await process_frame
	scene = current_scene
	game = scene.get_node("GameManager")
	_expect(game.current_player == 0 and game.completed_turns == [0,0] and not game.is_night and game.skipped_turns == [0,0], "Restart clears clock, pending rescue and army penalties")
	_expect(scene.get_node("Pieces").get_children().all(func(p: Node3D) -> bool: return not p.ability_spent and not p.shield_spent), "Restart restores all individual uses/shields")
	await _dispose()

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
