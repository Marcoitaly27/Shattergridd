extends Resource
## Real imported streams go here. Empty variations are valid, intentionally silent.

@export var cue_id: StringName
@export var variations: Array[AudioStream] = []
@export var bus: StringName = &"SFX"
@export var positional: bool = false
@export var looping: bool = false
@export_range(-60, 0) var volume_db: float = -16.0
@export var pitch_range: Vector2 = Vector2(0.98, 1.02)
@export_range(0, 5) var priority: int = 1
@export_range(1, 6) var max_instances: int = 2
@export_range(0, 2) var min_interval: float = 0.08
@export_range(0.1, 30) var max_duration: float = 6.0
@export var unit_size: float = 12.0
@export var max_distance: float = 90.0


func streams() -> Array[AudioStream]:
	var result: Array[AudioStream] = []
	for stream in variations:
		if stream != null and not result.has(stream):
			result.append(stream)
	return result
