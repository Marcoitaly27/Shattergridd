extends Node
## Runs before GameManager registers occupancy. Complete validation precedes spawning.

const PieceScene = preload("res://scenes/pieces/placeholder_piece.tscn")
const Rules = preload("res://scripts/army/army_rules.gd")
var validation_errors: Array[String] = []


func _ready() -> void:
	var session: Node = get_node("/root/MatchSession")
	var battlefield: Node3D = get_node("../Battlefield")
	var pieces: Node3D = get_node("../Pieces")
	var plan := Rules.new().plan_match(session.FORMATION, session.get_loadouts(), session.CATALOG,
		session.collection, battlefield.board_dimensions)
	validation_errors = plan.errors
	if not validation_errors.is_empty():
		push_error("Cannot deploy armies: %s" % "; ".join(validation_errors))
		return
	if pieces.get_child_count() != 0:
		validation_errors.append("Armies are already deployed.")
		push_error(validation_errors[0])
		return
	var entries: Array = plan.pieces
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.army != b.army:
			return a.army < b.army
		if a.coordinate.x != b.coordinate.x:
			return a.coordinate.x < b.coordinate.x
		return a.coordinate.y < b.coordinate.y)
	var counts := [0, 0]
	for entry in entries:
		var piece := PieceScene.instantiate() as Node3D
		counts[entry.army] += 1
		var prefix := "Ash" if entry.army == 0 else "Slate"
		piece.name = "%s_%02d" % [prefix, counts[entry.army]]
		piece.piece_id = StringName("%s_%s_%d" % [prefix.to_lower(), entry.slot_id, entry.member])
		piece.character_definition = entry.character
		piece.army = entry.army
		piece.grid_coordinate = entry.coordinate
		piece.deployment_slot_id = entry.slot_id
		piece.reflected_member = entry.member
		piece.position = battlefield.position_for_cell(entry.coordinate)
		pieces.add_child(piece)
