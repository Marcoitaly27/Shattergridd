extends Resource
@export var display_name: String = "Blood Step"
@export var description: String = "Night capture: next owner turn adds exact 2-tile moves in all 8 directions, with a clear path. No extra action."
const BONUS = preload("res://resources/statuses/wolf_blood_step.tres")
func apply(attacker: Node3D, _board: RefCounted, turns: Array[int]) -> void:
	if attacker.is_night:
		attacker.apply_status(BONUS, turns[attacker.army] + 1, turns[attacker.army] + 2)
