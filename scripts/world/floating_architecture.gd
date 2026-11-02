@tool
extends Node3D
## Replaceable ruined architectural shell beneath the independent gameplay slab.

const STONE: Material = preload("res://materials/world/ancient_masonry.tres")
const MOSS: Material = preload("res://materials/world/moss.tres")


func _ready() -> void:
	if get_node_or_null("GothicRibs") != null:
		return
	var supports: Array[Transform3D] = []
	var arches: Array[Transform3D] = []
	var shards: Array[Transform3D] = []
	var moss: Array[Transform3D] = []
	for side in range(4):
		var yaw := side * PI * 0.5
		var orientation := Basis(Vector3.UP, yaw)
		for bay in range(3):
			var position := Vector3((bay - 1) * 3.6, -2.25, 6.25).rotated(Vector3.UP, yaw)
			arches.append(Transform3D(orientation, position))
		for pier in range(4):
			var position := Vector3((pier - 1.5) * 3.6, -3.65, 6.18).rotated(Vector3.UP, yaw)
			supports.append(Transform3D(orientation * Basis.from_scale(Vector3(0.55, 3.8 - (0.45 if pier == side else 0), 0.75)), position))
		for patch in range(5):
			var position := Vector3((patch - 2) * 2.5, -0.15 - (patch % 2) * 0.17, 6.58).rotated(Vector3.UP, yaw)
			moss.append(Transform3D(orientation * Basis.from_scale(Vector3(0.65 + patch * 0.10, 0.10, 0.23)), position))
	# A compact central keel and irregular broken teeth, all below the play plane.
	for index in range(8):
		var angle := index * TAU / 8.0
		var position := Vector3(cos(angle) * 3.1, -4.6 - (index % 3) * 0.35, sin(angle) * 3.1)
		var basis := Basis(Vector3.UP, angle).rotated(Vector3.FORWARD, PI)
		shards.append(Transform3D(basis * Basis.from_scale(Vector3(2.2, 3.2 + (index % 2) * 0.6, 2.4)), position))
	var box := BoxMesh.new()
	_batch("ButtressFragments", box, supports, STONE)
	_batch("GothicRibs", _arch_mesh(), arches, STONE)
	_batch("HangingFoundation", PrismMesh.new(), shards, STONE)
	_batch("MossInRimJoints", box, moss, MOSS)


func _arch_mesh() -> ArrayMesh:
	# Two pointed ribs: an open arch, not a filled decorative wall.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sign_value in [-1.0, 1.0]:
		var rib := BoxMesh.new()
		rib.size = Vector3(0.20, 2.05, 0.45)
		var transform := Transform3D(Basis(Vector3.FORWARD, sign_value * 0.62), Vector3(sign_value * 0.60, -0.67, 0))
		surface.append_from(rib, 0, transform)
	return surface.commit()


func _batch(label: String, mesh: Mesh, transforms: Array[Transform3D], material: Material) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multimesh
	instance.set_meta("placement_transforms", transforms)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
