extends CanvasLayer
## Production feedback consumes game signals; it never changes legal moves or locks.

var ability_button: Button
var cycle_label: Label
var rescue_dialog: ConfirmationDialog
var info_panel: PanelContainer
var info_text: Label
var hover_text: Label
var threat_text: Label
var identity_text: Label
var feedback_text: Label
var _feedback_timer: Timer
var _feedback_queue: Array[String] = []
var _turn_tween: Tween

@onready var game: Node = $"../GameManager"
@onready var turn_label: Label = $Panel/Margin/Rows/Turn
@onready var hint_label: Label = $Panel/Margin/Rows/Hint
@onready var status_label: Label = $Panel/Margin/Rows/Status
@onready var victory_screen: Control = $VictoryScreen
@onready var victory_label: Label = $VictoryScreen/Center/Result/Margin/Rows/Winner


func _ready() -> void:
	_build_feedback()
	game.turn_changed.connect(_show_turn)
	game.cycle_changed.connect(_show_cycle)
	game.rescue_requested.connect(_offer_rescue)
	game.selection_changed.connect(_show_selection)
	game.phase_changed.connect(_show_phase)
	game.tactics_changed.connect(_show_tactics)
	game.feedback_requested.connect(_notify)
	$"../Interaction".hover_changed.connect(_show_hover)
	game.victory.connect(_show_victory)
	game.capture_director.cue_emitted.connect(_show_capture_cue)
	$VictoryScreen/Center/Result/Margin/Rows/Restart.pressed.connect(game.restart_match)
	$VictoryScreen/Center/Result/Margin/Rows/Loadout.pressed.connect(game.return_to_loadout)
	$Loadout.pressed.connect(game.return_to_loadout)
	_show_cycle(game.is_night, 5)
	_show_turn(game.current_player, false)


func _build_feedback() -> void:
	$Panel.offset_left = -240
	$Panel.offset_right = 240
	$Panel.offset_bottom = 136
	var rows := $Panel/Margin/Rows
	identity_text = _label(13)
	rows.add_child(identity_text)
	rows.move_child(identity_text, 1)
	cycle_label = _label(13)
	rows.add_child(cycle_label)
	rows.move_child(cycle_label, 2)
	var style: StyleBox = $Panel.get_theme_stylebox("panel")
	info_panel = PanelContainer.new()
	info_panel.name = "PieceInformation"
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	info_panel.offset_left = -374
	info_panel.offset_right = -18
	info_panel.offset_top = -420
	info_panel.offset_bottom = -72
	info_panel.add_theme_stylebox_override("panel", style)
	add_child(info_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	info_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	info_text = _label(15)
	info_text.name = "Details"
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info_rows := VBoxContainer.new()
	info_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(info_rows)
	info_rows.add_child(info_text)
	ability_button = Button.new()
	ability_button.name = "CharacterAbility"
	ability_button.pressed.connect(game.toggle_ability)
	info_rows.add_child(ability_button)
	rescue_dialog = ConfirmationDialog.new()
	rescue_dialog.title = "LAST MERCY"
	rescue_dialog.ok_button_text = "SAVE STATUE"
	rescue_dialog.cancel_button_text = "ALLOW CAPTURE"
	rescue_dialog.confirmed.connect(func() -> void: game.resolve_rescue(true))
	rescue_dialog.canceled.connect(func() -> void: game.resolve_rescue(false))
	rescue_dialog.add_button("ARMY LOADOUT", true, &"loadout")
	rescue_dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"loadout":
			game.return_to_loadout())
	rescue_dialog.window_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			game.restart_match())
	add_child(rescue_dialog)
	info_panel.hide()
	var footer := VBoxContainer.new()
	footer.name = "InteractionFeedback"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 18
	footer.offset_right = 1010
	footer.offset_top = -116
	footer.offset_bottom = -18
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	threat_text = _label(15)
	threat_text.add_theme_color_override("font_color", Color(0.76, 0.47, 0.34))
	footer.add_child(threat_text)
	feedback_text = _label(16)
	footer.add_child(feedback_text)
	hover_text = _label(14)
	footer.add_child(hover_text)
	var legend := _label(13)
	legend.text = "Border: MOVE   X: CAPTURE   Gold: SELECTED   +: BONUS   Grey: UNAVAILABLE"
	footer.add_child(legend)
	if get_parent().get_meta("capture_lab", false):
		footer.hide()
	_feedback_timer = Timer.new()
	_feedback_timer.one_shot = true
	_feedback_timer.wait_time = 2.2
	_feedback_timer.timeout.connect(_next_feedback)
	add_child(_feedback_timer)


func _label(size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.77, 0.73, 0.63))
	return label


func _show_turn(player: int, animate: bool = true) -> void:
	turn_label.text = "PLAYER %d TURN" % (player + 1)
	identity_text.text = "%s · %s · %s pedestal cut%s" % ["I" if player == 0 else "II",
		"ASH" if player == 0 else "SLATE", "ONE" if player == 0 else "TWO", "" if player == 0 else "S"]
	hint_label.text = "Select a statue"
	status_label.hide()
	if animate:
		if is_instance_valid(_turn_tween):
			_turn_tween.kill()
		$Panel.modulate.a = 0.62
		_turn_tween = create_tween()
		_turn_tween.tween_property($Panel, "modulate:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE)


func _show_selection(piece: Node3D) -> void:
	status_label.hide()
	info_panel.visible = is_instance_valid(piece)
	if not is_instance_valid(piece):
		hint_label.text = "Moving…" if game.is_moving else "Select a statue"
		return
	hint_label.text = "%s · choose a marked %s" % [piece.get_display_name(), "ability target" if game.ability_mode else "tile"]
	var definition: Resource = piece.character_definition
	var effect: Resource = definition.post_capture_effect if definition != null else null
	var ability := "None\nNo capture-triggered ability."
	if effect != null:
		var name: Variant = effect.get("display_name")
		var description: Variant = effect.get("description")
		ability = "%s\n%s" % [name if name != null else "Capture effect", description if description != null else "Triggers after a successful capture."]
	if definition != null and not definition.ability_description.is_empty():
		ability = piece.ability_summary()
	var kind: StringName = definition.active_ability if definition != null else &""
	ability_button.visible = kind != &""
	ability_button.disabled = not game.ability_mode and game.ability_targets(piece).is_empty()
	var names := {&"bow": "BOW SHOT", &"flight": "TERROR FLIGHT", &"exchange": "VEIL EXCHANGE"}
	ability_button.text = "CANCEL ABILITY" if game.ability_mode else String(names.get(kind, "ABILITY"))
	var status: String = piece.statuses.describe(game.completed_turns[piece.army])
	if definition != null and not definition.status_immunities.is_empty():
		status += "\nImmune: " + ", ".join(definition.status_immunities)
	info_text.text = "%s\n%s · PLAYER %d\nMOVEMENT\n%s\nABILITY · %s\nSTATUS\n%s" % [piece.get_display_name(),
		String(definition.deployment_category).to_upper() if definition != null else "STATUE", piece.army + 1,
		piece.get_movement_summary(), ability, status]
	status_label.text = piece.statuses.summary(game.completed_turns[piece.army])
	status_label.visible = not status_label.text.is_empty()


func _show_phase(phase: int) -> void:
	if phase != game.Phase.DECIDING:
		rescue_dialog.hide()
	if phase == game.Phase.DECIDING:
		turn_label.text = "LAST MERCY"
		hint_label.text = "Defending player chooses whether to save the statue"
	elif phase == game.Phase.DEFENDING:
		turn_label.text = "CAPTURE PREVENTED"
		hint_label.text = "Both statues remain · attacker spends the turn"
	elif phase == game.Phase.READY:
		_show_turn(game.current_player, false)
	elif phase == game.Phase.CAPTURING:
		turn_label.text = "CAPTURE"
		hint_label.text = "Capture in progress · please wait"
		status_label.hide()
	elif phase == game.Phase.RESOLVING:
		turn_label.text = "RESOLVING"
		hint_label.text = "The Core has fallen" if game.winner >= 0 else "Resolving action"
	elif phase == game.Phase.MOVING:
		hint_label.text = "Moving · please wait"
	if phase != game.Phase.READY:
		info_panel.hide()
		hover_text.text = ""


func _show_capture_cue(event: StringName, attacker: Node3D, _victim: Node3D) -> void:
	if event == &"capture_started":
		var behavior: Resource = attacker.get_capture_behavior()
		hint_label.text = behavior.sequence_name if behavior != null else "Capture in progress"


func _show_hover(cell: Vector2i, kind: StringName, piece: Node3D) -> void:
	var name: String = piece.get_display_name() if is_instance_valid(piece) else "(%d, %d)" % [cell.x, cell.y]
	match kind:
		&"capture": hover_text.text = "CAPTURE × %s · click to begin" % name
		&"exchange": hover_text.text = "EXCHANGE with %s · click to confirm" % name
		&"move": hover_text.text = "MOVE to %s · click to confirm" % name
		&"selectable": hover_text.text = "SELECT %s · Player %d" % [name, game.current_player + 1]
		&"selected": hover_text.text = "SELECTED %s · click again or Esc to cancel" % name
		&"unavailable": hover_text.text = "UNAVAILABLE · select your own statue or choose a marked tile"
		_: hover_text.text = ""


func _show_tactics() -> void:
	var warnings: PackedStringArray = []
	for core in game.threatened_cores:
		warnings.append("PLAYER %d CORE THREATENED" % (core.army + 1))
	threat_text.text = " · ".join(warnings)
	if game.can_accept_input() and is_instance_valid(game.selected_piece):
		_show_selection(game.selected_piece)


func _notify(message: String, _kind: StringName) -> void:
	if _kind == &"threat":
		return # The persistent Core warning already displays this event.
	if feedback_text.text == message or _feedback_queue.has(message):
		return
	if _feedback_timer.is_stopped():
		feedback_text.text = message
		_feedback_timer.start()
	elif _feedback_queue.size() < 3:
		_feedback_queue.append(message)


func _next_feedback() -> void:
	feedback_text.text = ""
	if not _feedback_queue.is_empty():
		feedback_text.text = _feedback_queue.pop_front()
		_feedback_timer.start()


func _show_victory(player: int) -> void:
	turn_label.text = "MATCH ENDED"
	hint_label.text = "The opposing Core has fallen"
	victory_label.text = "PLAYER %d VICTORIOUS" % (player + 1)
	victory_screen.show()
	$VictoryScreen/Center/Result/Margin/Rows/Restart.grab_focus()


func _show_cycle(night: bool, rounds_remaining: int) -> void:
	cycle_label.text = "%s · %d round%s until %s" % ["NIGHT" if night else "DAY", rounds_remaining,
		"" if rounds_remaining == 1 else "s", "dawn" if night else "nightfall"]


func _offer_rescue(witch: Node3D, target: Node3D) -> void:
	rescue_dialog.dialog_text = "PLAYER %d · Last Mercy\nSave %s?\nThis uses your Witch's only rescue this match.\nBoth statues stay in place; the attacker's turn ends." % [witch.army + 1, target.get_display_name()]
	rescue_dialog.popup_centered(Vector2i(460, 180))
