extends 'res://tests/capture_smoke.gd'
## Exercise actual capture timelines at opposite edges, then restart paths.
var edge_row: int = 0
func _setup(archetype: String, victim_archetype: String = 'warden', cell: Vector2i = Vector2i(3,3), target: Vector2i = Vector2i(4,3)) -> void:
	if cell == Vector2i(3,3) and target == Vector2i(4,3):
		cell.y = edge_row
		target.y = edge_row
	await super._setup(archetype, victim_archetype, cell, target)
func _run() -> void:
	for row in [0,7]:
		edge_row = row
		await _test_sequence('hunter')
		await _test_sequence('witch')
	await _setup('hunter', 'witch', Vector2i(3,3),Vector2i(5,3))
	var origin: Vector2i = attacker.grid_coordinate
	var destination := Vector2i(3,2)
	game.handle_cell_clicked(origin)
	_expect(game.selected_piece == attacker and game.valid_destinations(attacker).has(destination), 'Selection exposes legal empty move')
	game.handle_cell_clicked(destination)
	await _finish()
	_expect(attacker.grid_coordinate == destination and game.current_player == 1, 'Movement commits and advances turn')
	await _dispose()
	await _test_restart(false)
	await _test_restart(true)
	await _test_victory_restart()
	print('Cloister capture/restart: %d checks, %d failures' % [checks, failures])
	quit(0 if failures == 0 else 1)
