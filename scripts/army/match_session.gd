extends Node
## Scene-to-scene loadout snapshots. Gameplay does not depend on the builder UI.

const Rules = preload("res://scripts/army/army_rules.gd")
const CATALOG = preload("res://resources/armies/prototype_catalog.tres")
const FORMATION = preload("res://resources/armies/reflection_formation.tres")
const DEFAULT_LOADOUT = preload("res://resources/armies/default_loadout.tres")
const Collection = preload("res://scripts/army/character_collection.gd")
var collection: Resource = Collection.new()
var _loadouts: Array[Resource] = []


func get_loadouts() -> Array[Resource]:
	var source: Array = _loadouts if not _loadouts.is_empty() else [DEFAULT_LOADOUT, DEFAULT_LOADOUT]
	var result: Array[Resource] = []
	for loadout in source:
		result.append(loadout.copy())
	return result


func configure_loadouts(candidates: Array) -> Array[String]:
	var plan := Rules.new().plan_match(FORMATION, candidates, CATALOG, collection, FORMATION.board_dimensions)
	if not plan.errors.is_empty():
		return plan.errors
	_loadouts.clear()
	for loadout in candidates:
		_loadouts.append(loadout.copy())
	return []
