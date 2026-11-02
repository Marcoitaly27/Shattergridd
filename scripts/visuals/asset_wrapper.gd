@tool
extends Node3D
## Method tracks target this wrapper's report_animation_event, never a Piece root.

signal animation_event(event: StringName)


func report_animation_event(event: StringName) -> void:
	animation_event.emit(event)
