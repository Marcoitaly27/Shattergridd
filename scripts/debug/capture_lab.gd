extends Node
## Optional F6-only developer scene. It is never added to the normal match UI.

const MatchScene = preload("res://scenes/main.tscn")
const BoardState = preload("res://scripts/board/board_state.gd")
const ARCHETYPES := ["warden", "hunter", "executioner", "witch", "wyrm", "core"]
var archetype_index: int = 0
var core_victim: bool = false
var _match: Node3D

@onready var instructions: Label = $Overlay/Instructions


func _ready() -> void:
	_load_scenario.call_deferred()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		archetype_index = event.keycode - KEY_1
		_load_scenario()
	elif event.keycode == KEY_ENTER:
		_load_scenario()
	elif event.keycode == KEY_C:
		core_victim = not core_victim
		_load_scenario()
	else:
		return
	get_viewport().set_input_as_handled()


func _load_scenario() -> void:
	if is_instance_valid(_match):
		_match.get_node("CaptureDirector").abort()
		remove_child(_match)
		_match.queue_free()
	_match = MatchScene.instantiate() as Node3D
	_match.set_meta("capture_lab", true)
	add_child(_match)
	var game: Node = _match.get_node("GameManager")
	var attacker: Node3D = _match.get_node("Pieces/Ash_01")
	var victim: Node3D = _match.get_node("Pieces/Slate_01")
	attacker.character_definition = load("res://resources/characters/%s.tres" % ARCHETYPES[archetype_index])
	victim.character_definition = load("res://resources/characters/%s.tres" % ("core" if core_victim else "warden"))
	attacker.grid_coordinate = Vector2i(3, 4)
	victim.grid_coordinate = Vector2i(4, 4)
	# Neighbors demonstrate Terror and Core immunity, without covering the shot.
	_match.get_node("Pieces/Slate_02").grid_coordinate = Vector2i(4, 3)
	_match.get_node("Pieces/Slate_03").grid_coordinate = Vector2i(5, 3)
	_match.get_node("Pieces/Slate_04").grid_coordinate = Vector2i(3, 3)
	if core_victim:
		_match.get_node("Pieces/Slate_04").character_definition = load("res://resources/characters/warden.tres")
	game.board_state = BoardState.new(game.battlefield.board_dimensions)
	for piece in _match.get_node("Pieces").get_children():
		piece.position = game.battlefield.position_for_cell(piece.grid_coordinate)
		game.board_state.register_piece(piece)
	instructions.text = "CAPTURE LAB · 1 Warden · 2 Hunter · 3 Executioner · 4 Witch · 5 Wyrm · 6 Core\nEnter: replay · C: Core victim (%s) · Space: fast-forward · R: return to normal match" % ("ON" if core_victim else "OFF")
	_begin_capture.call_deferred()


func _begin_capture() -> void:
	var game: Node = _match.get_node("GameManager")
	game.handle_cell_clicked(Vector2i(3, 4))
	game.handle_cell_clicked(Vector2i(4, 4))
