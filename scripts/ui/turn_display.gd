extends CanvasLayer

@onready var game: Node = $"../GameManager"
@onready var turn_label: Label = $Panel/Margin/Rows/Turn
@onready var hint_label: Label = $Panel/Margin/Rows/Hint


func _ready() -> void:
	game.turn_changed.connect(_show_turn)
	game.selection_changed.connect(_show_selection)
	_show_turn(game.current_player)


func _show_turn(player: int) -> void:
	turn_label.text = "PLAYER %d TURN" % (player + 1)
	hint_label.text = "Select a statue"


func _show_selection(piece: Node3D) -> void:
	if piece == null:
		hint_label.text = "Moving…" if game.is_moving else "Select a statue"
	else:
		hint_label.text = "%s · choose a marked tile" % piece.display_name
