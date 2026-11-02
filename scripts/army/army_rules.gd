extends RefCounted
## Pure validation and deployment planning; no nodes, UI or progression rewards.


func plan_match(formation: Resource, loadouts: Array, catalog: Resource, collection: Resource,
		dimensions: Vector2i) -> Dictionary:
	var errors: Array[String] = catalog.validation_errors()
	var pieces: Array[Dictionary] = []
	if formation == null or formation.slots.is_empty():
		errors.append("A formation with deployment slots is required.")
		return {"errors": errors, "pieces": pieces}
	if formation.board_dimensions != dimensions:
		errors.append("Formation dimensions do not match the battlefield.")
	if loadouts.size() != 2:
		errors.append("Two army loadouts are required.")
		return {"errors": errors, "pieces": pieces}
	var core_column := -1
	for slot in formation.slots:
		if slot != null and slot.category == &"core" and not slot.paired:
			core_column = slot.left_coordinate.x
	for slot in formation.slots:
		if slot != null and slot.paired and core_column >= 0:
			if slot.left_coordinate.x + slot.mirrored_coordinate.x != 2 * core_column \
					or slot.left_coordinate.y != slot.mirrored_coordinate.y:
				errors.append("Paired slot %s must reflect across the Core column." % slot.slot_id)
	var occupied: Dictionary = {}
	for player in range(2):
		var loadout: Resource = loadouts[player]
		if loadout == null:
			errors.append("Player %d has no loadout." % (player + 1))
			continue
		var slot_ids: Dictionary = {}
		var core_count := 0
		for slot in formation.slots:
			if slot == null:
				errors.append("Formation contains an empty slot.")
				continue
			if slot.slot_id == &"" or slot_ids.has(slot.slot_id):
				errors.append("Formation slot IDs must be nonempty and unique.")
			slot_ids[slot.slot_id] = true
			var character: Resource = catalog.find_character(loadout.character_for(slot.slot_id))
			if character == null or not slot.accepts(character):
				errors.append("Player %d: invalid character/category for %s." % [player + 1, slot.slot_id])
			elif not collection.is_unlocked(character):
				errors.append("Player %d: %s is locked." % [player + 1, character.display_name])
			var cells: Array[Vector2i] = slot.coordinates()
			if slot.category == &"core":
				core_count += cells.size()
			for member in range(cells.size()):
				var cell: Vector2i = formation.coordinate_for_player(cells[member], player)
				if cell.x < 0 or cell.y < 0 or cell.x >= dimensions.x or cell.y >= dimensions.y:
					errors.append("Deployment coordinate %s is outside the battlefield." % cell)
				if occupied.has(cell):
					errors.append("Deployment slots overlap at %s." % cell)
				occupied[cell] = true
				pieces.append({"character": character, "army": player, "coordinate": cell,
					"slot_id": slot.slot_id, "member": member})
		if core_count != 1:
			errors.append("Each army must have exactly one unpaired Core.")
		for key in loadout.selections:
			if not slot_ids.has(key):
				errors.append("Loadout references an unknown slot: %s." % key)
	# Never return a partially valid army to the spawner.
	return {"errors": errors, "pieces": pieces if errors.is_empty() else []}
