extends Control
## Development UI only. Validation and spawn planning live in the army domain.

const SetupAudio = preload("res://scripts/audio/setup_audio.gd")
const Rules = preload("res://scripts/army/army_rules.gd")
var loadouts: Array[Resource] = []
var selectors: Array[Dictionary] = [{}, {}]
var _previews: Array[GridContainer] = []
var _details: Array[Label] = []
var _message: Label
var start_button: Button
var _starting: bool = false

@onready var session: Node = get_node("/root/MatchSession")


func _ready() -> void:
	loadouts = session.get_loadouts()
	_build_interface()
	for player in range(2):
		_refresh_preview(player)
		_show_details(player, &"core")
	_refresh_validation()
	start_button.grab_focus()
	add_child(SetupAudio.new())


func _build_interface() -> void:
	var theme_data := Theme.new()
	theme_data.default_font_size = 16
	theme_data.set_color("font_color", "Label", Color(0.79, 0.77, 0.69))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.055, 0.065, 0.067)
	panel.border_color = Color(0.25, 0.26, 0.23)
	panel.set_border_width_all(1)
	panel.content_margin_left = 18
	panel.content_margin_right = 18
	panel.content_margin_top = 14
	panel.content_margin_bottom = 14
	theme_data.set_stylebox("panel", "PanelContainer", panel)
	var button_style := panel.duplicate() as StyleBoxFlat
	button_style.bg_color = Color(0.105, 0.12, 0.12)
	button_style.content_margin_top = 8
	button_style.content_margin_bottom = 8
	for type in ["Button", "OptionButton"]:
		theme_data.set_stylebox("normal", type, button_style)
		theme_data.set_color("font_color", type, Color(0.84, 0.81, 0.72))
	theme = theme_data
	var background := ColorRect.new()
	background.color = Color(0.018, 0.027, 0.031)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)
	var title := _label("SHATTERGRID · LAW OF REFLECTION", 26)
	rows.add_child(title)
	rows.add_child(_label("“The Grid does not summon armies. It reflects them.”", 16))
	rows.add_child(_label("Choose once for each pair: both statues share that character. Each army has one Core and one Special.", 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(scroll)
	var armies := HBoxContainer.new()
	armies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	armies.add_theme_constant_override("separation", 18)
	scroll.add_child(armies)
	for player in range(2):
		_build_army_panel(armies, player)
	_message = _label("", 14)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_message)
	start_button = Button.new()
	start_button.name = "StartMatch"
	start_button.text = "START MATCH"
	start_button.custom_minimum_size.y = 46
	start_button.pressed.connect(_start_match)
	rows.add_child(start_button)


func _build_army_panel(parent: Control, player: int) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	panel.add_child(rows)
	rows.add_child(_label("PLAYER %d · %s" % [player + 1, "ASH" if player == 0 else "SLATE"], 20))
	# Put Core first in the form without tying domain slot order to presentation.
	var slots: Array = session.FORMATION.slots.duplicate()
	slots.sort_custom(func(a: Resource, b: Resource) -> bool:
		return a.category == &"core" and b.category != &"core")
	for slot in slots:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var label := _label(String(slot.category).to_upper() + (" PAIR ×2" if slot.paired else ""), 14)
		label.custom_minimum_size.x = 145
		row.add_child(label)
		var options := OptionButton.new()
		options.name = "P%d_%s" % [player + 1, slot.slot_id]
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(options)
		var chosen := -1
		for character in session.CATALOG.characters:
			if not slot.accepts(character) or not session.collection.is_visible(character):
				continue
			var index := options.item_count
			var unlocked: bool = session.collection.is_unlocked(character)
			options.add_item(character.display_name + ("" if unlocked else " · locked"))
			options.set_item_metadata(index, character.character_id)
			options.set_item_disabled(index, not unlocked)
			if character.character_id == loadouts[player].character_for(slot.slot_id):
				chosen = index
		options.select(chosen)
		options.item_selected.connect(_on_choice.bind(player, slot.slot_id, options))
		options.focus_entered.connect(_show_details.bind(player, slot.slot_id))
		selectors[player][slot.slot_id] = options
	var detail := _label("", 15)
	detail.custom_minimum_size.y = 100
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(detail)
	_details.append(detail)
	rows.add_child(_label("FORMATION · highlighted cells belong to this choice", 13))
	var preview := GridContainer.new()
	preview.columns = session.FORMATION.board_dimensions.x
	preview.add_theme_constant_override("h_separation", 3)
	preview.add_theme_constant_override("v_separation", 2)
	rows.add_child(preview)
	_previews.append(preview)


func _on_choice(index: int, player: int, slot_id: StringName, options: OptionButton) -> void:
	if index < 0 or options.is_item_disabled(index):
		return
	get_node("/root/SoundManager").play_ui(&"ui.army_select")
	loadouts[player].set_character(slot_id, options.get_item_metadata(index))
	_refresh_preview(player)
	_show_details(player, slot_id)
	_refresh_validation()


func _show_details(player: int, slot_id: StringName) -> void:
	var character: Resource = session.CATALOG.find_character(loadouts[player].character_for(slot_id))
	if character == null:
		_details[player].text = "Choose an available character."
		return
	_details[player].text = "%s · %s\n%s\n%s" % [character.display_name, character.title,
		String(character.deployment_category).to_upper(), character.gameplay_description]
	for cell in _previews[player].get_children():
		var selected: bool = cell.get_meta("slot_id", &"") == slot_id
		cell.modulate = Color(0.94, 0.79, 0.49) if selected else Color.WHITE


func _refresh_preview(player: int) -> void:
	var grid := _previews[player]
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var placements: Dictionary = {}
	for slot in session.FORMATION.slots:
		var character: Resource = session.CATALOG.find_character(loadouts[player].character_for(slot.slot_id))
		for coordinate in slot.coordinates():
			placements[session.FORMATION.coordinate_for_player(coordinate, player)] = {"character": character, "slot": slot}
	for y in range(session.FORMATION.board_dimensions.y):
		for x in range(session.FORMATION.board_dimensions.x):
			var entry: Dictionary = placements.get(Vector2i(x, y), {})
			var cell := _label("·", 12)
			cell.custom_minimum_size = Vector2(36, 16)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if not entry.is_empty() and entry.character != null:
				cell.text = String(entry.character.character_id).left(3).to_upper()
				cell.tooltip_text = "%s · %s%s · (%d, %d)" % [entry.character.display_name,
					String(entry.slot.category).to_upper(), " PAIR" if entry.slot.paired else "", x, y]
				cell.set_meta("slot_id", entry.slot.slot_id)
			grid.add_child(cell)


func _refresh_validation() -> void:
	var plan := Rules.new().plan_match(session.FORMATION, loadouts, session.CATALOG,
		session.collection, session.FORMATION.board_dimensions)
	start_button.disabled = not plan.errors.is_empty()
	if plan.errors.is_empty():
		var count: int = plan.pieces.filter(func(entry: Dictionary) -> bool: return entry.army == 0).size()
		_message.text = "%d statues per army · matching pair choices deploy twice · Player 1 begins." % count
	else:
		_message.text = "\n".join(plan.errors)


func _start_match() -> void:
	if _starting:
		return
	var errors: Array[String] = session.configure_loadouts(loadouts)
	if not errors.is_empty():
		_message.text = "\n".join(errors)
		return
	get_node("/root/SoundManager").play_ui(&"ui.match_start")
	_starting = true
	start_button.disabled = true
	var error := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if error != OK:
		_starting = false
		start_button.disabled = false
		_message.text = "Could not start match: %s" % error_string(error)


func _label(text: String, size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	return result
