extends Resource
## A character-owned timeline builder. Authored animation can replace this Resource
## while retaining the director's camera, impact, completion and cleanup contract.

@export var sequence_name: String = "Capture"
@export var camera_distance: float = 5.0
@export var camera_height: float = 2.9
@export var camera_side_bias: float = 0.9


func append(_timeline: Tween, _context: RefCounted) -> void:
	push_error("Capture behavior must supply a timeline")
