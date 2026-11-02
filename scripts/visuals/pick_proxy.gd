@tool
extends Node3D
## Author a few Shape3D resources here. The adapter builds the actual PickBody.

@export var shape: Shape3D


func get_proxy_shape() -> Shape3D:
	return shape
