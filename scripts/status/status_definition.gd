extends Resource
## Immutable rule modifiers; timers live on the individual piece, not this Resource.

@export var status_id: StringName
@export var display_name: String
@export var extra_destinations: Array[Vector2i] = []
@export var blocks_capture: bool = false
