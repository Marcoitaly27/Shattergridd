extends Resource

@export var display_name: String = "Blood Step"
@export_multiline var description: String = "Capture: next owner turn gains 1-tile diagonals. No extra action or stacking."
const BLOOD_STEP: Resource = preload("res://resources/statuses/blood_step.tres")


func apply(attacker: Node3D, _board: RefCounted, completed_turns: Array[int]) -> void:
	var completed: int = completed_turns[attacker.army]
	attacker.apply_status(BLOOD_STEP, completed + 1, completed + 2)
