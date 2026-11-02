extends Resource

const BLOOD_STEP: Resource = preload("res://resources/statuses/blood_step.tres")


func apply(attacker: Node3D, _board: RefCounted, completed_turns: Array[int]) -> void:
	var completed: int = completed_turns[attacker.army]
	attacker.apply_status(BLOOD_STEP, completed + 1, completed + 2)
