extends Resource

const Event = preload("res://scripts/audio/ambient_event.gd")
@export var category: StringName
@export var enabled: bool = true
@export var min_interval: float = 90.0
@export var max_interval: float = 240.0
@export var events: Array[Event] = []
