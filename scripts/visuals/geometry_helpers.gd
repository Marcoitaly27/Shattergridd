@tool
extends RefCounted


static func meshes(root: Node3D) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root is MeshInstance3D and root.mesh != null:
		result.append(root)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		if node.mesh != null:
			result.append(node)
	return result


static func bounds_in(root: Node3D, space: Transform3D) -> AABB:
	var bounds := AABB()
	var started := false
	for mesh in meshes(root):
		var part := space.affine_inverse() * mesh.global_transform * mesh.mesh.get_aabb()
		bounds = bounds.merge(part) if started else part
		started = true
	return bounds


static func disable_source_collision(root: Node3D) -> void:
	var objects := root.find_children("*", "CollisionObject3D", true, false)
	if root is CollisionObject3D:
		objects.append(root)
	for object in objects:
		object.collision_layer = 0
		object.collision_mask = 0
		if object is RigidBody3D:
			object.freeze = true
		if object is Area3D:
			object.monitoring = false
			object.monitorable = false
	for shape in root.find_children("*", "CollisionShape3D", true, false):
		shape.disabled = true
