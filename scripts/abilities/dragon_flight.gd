extends Resource
@export var display_name: String = "Terror Flight"
@export var description: String = "Capture: optional flight to any empty tile on your next turn. If used, your army skips its following turn."
const BONUS = preload("res://resources/statuses/flight_ready.tres")
func apply(attacker: Node3D, _board: RefCounted, turns: Array[int]) -> void:
	attacker.apply_status(BONUS, turns[attacker.army] + 1, turns[attacker.army] + 2)
