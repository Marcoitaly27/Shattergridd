extends RefCounted
## Replace this presentation with character-specific combat in a later version.


func remove_placeholder(piece: Node3D) -> void:
	piece.hide()
	piece.queue_free()
