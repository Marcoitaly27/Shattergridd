extends Resource
## Animation names/paths belong to the wrapper, not to gameplay or the director.

@export var player_path: NodePath
@export var tree_path: NodePath
@export var states: Dictionary = {}
@export_range(0, 0.12) var impact_shake: float = 0.045
@export_range(0, 0.12) var hit_pause: float = 0.07
