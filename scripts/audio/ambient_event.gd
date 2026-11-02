extends Resource

@export var cue_id: StringName
@export_range(0, 10) var weight: float = 1.0
@export var has_position: bool = false
@export var position: Vector3
