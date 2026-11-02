extends CanvasLayer

@onready var game: Node = $"../GameManager"
@onready var turn_label: Label = $Panel/Margin/Rows/Turn
@onready var hint_label: Label = $Panel/Margin/Rows/Hint
@onready var status_label: Label = $Panel/Margin/Rows/Status
@onready var victory_screen: Control = $VictoryScreen
@onready var victory_label: Label = $VictoryScreen/Center/Result/Margin/Rows/Winner


func _ready() -> void:
	game.turn_changed.connect(_show_turn)
	game.selection_changed.connect(_show_selection)
	game.phase_changed.connect(_show_phase)
	game.victory.connect(_show_victory)
	game.capture_director.cue_emitted.connect(_show_capture_cue)
	$VictoryScreen/Center/Result/Margin/Rows/Restart.pressed.connect(game.restart_match)
	$VictoryScreen/Center/Result/Margin/Rows/Loadout.pressed.connect(game.return_to_loadout)
	$Loadout.pressed.connect(game.return_to_loadout)
	_show_turn(game.current_player)


func _show_turn(player: int) -> void:
	turn_label.text = "PLAYER %d TURN" % (player + 1)
	hint_label.text = "Select a statue"
	status_label.hide()


func _show_selection(piece: Node3D) -> void:
	status_label.hide()
	if piece == null:
		hint_label.text = "Moving…" if game.is_moving else "Select a statue"
	else:
		hint_label.text = "%s · choose a marked tile" % piece.get_display_name()
		status_label.text = piece.statuses.summary(game.completed_turns[piece.army])
		status_label.visible = not status_label.text.is_empty()


func _show_phase(phase: int) -> void:
	if phase == game.Phase.READY:
		_show_turn(game.current_player)
	elif phase == game.Phase.CAPTURING:
		turn_label.text = "CAPTURE"
		hint_label.text = "Capture in progress"
		status_label.hide()


func _show_capture_cue(event: StringName, attacker: Node3D, _victim: Node3D) -> void:
	if event == &"capture_started":
		var behavior: Resource = attacker.get_capture_behavior()
		hint_label.text = behavior.sequence_name if behavior != null else "Capture in progress"


func _show_victory(player: int) -> void:
	turn_label.text = "MATCH ENDED"
	hint_label.text = "The opposing Core has fallen"
	victory_label.text = "PLAYER %d VICTORY" % (player + 1)
	victory_screen.show()
	$VictoryScreen/Center/Result/Margin/Rows/Restart.grab_focus()
