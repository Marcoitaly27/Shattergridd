extends RefCounted
## Per-capture presentation state. No turns, legal moves or status effects here.

const StoneDestruction = preload("res://scripts/effects/stone_destruction.gd")
var director: Node
var attacker: Node3D
var victim: Node3D
var attacker_visual: Node3D
var victim_visual: Node3D
var start: Vector3
var destination: Vector3
var direction: Vector3
var side: Vector3
var contact: Vector3
var victim_bounds: AABB
var victim_is_core: bool = false
var shattered: bool = false
var seed_value: int
var _attacker_root: Transform3D
var _victim_root: Transform3D
var _attacker_pose: Transform3D
var _victim_pose: Transform3D
var _parts: Dictionary = {}
var _cracks: Node3D
var _effect: Node3D


func setup(owner_director: Node, source: Node3D, target: Node3D, seed_number: int) -> void:
	director = owner_director
	attacker = source
	victim = target
	seed_value = seed_number
	attacker_visual = attacker.get_node("Visuals")
	victim_visual = victim.get_node("Visuals")
	_attacker_root = attacker.global_transform
	_victim_root = victim.global_transform
	_attacker_pose = attacker_visual.transform
	_victim_pose = victim_visual.transform
	start = attacker.global_position
	destination = victim.global_position
	direction = ((destination - start) * Vector3(1, 0, 1)).normalized()
	side = direction.cross(Vector3.UP)
	contact = destination - direction * 0.70
	contact.y = start.y
	victim_bounds = victim.get_visual_bounds()
	victim_is_core = victim.character_definition != null and victim.character_definition.is_core_objective
	attacker_visual.rotation.y = atan2(-direction.x, -direction.z)


func cue(event: StringName) -> void:
	if is_instance_valid(director) and director.active:
		director.cue_emitted.emit(event, attacker, victim)


func impact(strength: float, duration: float = 0.16) -> void:
	cue(&"impact")
	cue(&"stone_impact")
	if not director.active:
		return
	director.camera_director.shake(strength, duration)
	mark_cracks()


func mark_cracks() -> void:
	if is_instance_valid(_cracks):
		return
	_cracks = Node3D.new()
	_cracks.name = "CaptureCracks"
	victim.add_child(_cracks)
	var to_camera: Vector3 = director.camera_director.camera.global_position - victim_bounds.get_center()
	to_camera.y = 0
	to_camera = to_camera.normalized()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.035, 0.038, 0.034)
	for index in range(3):
		var line := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.017, maxf(0.2, victim_bounds.size.y * 0.35), 0.018)
		line.mesh = mesh
		line.material_override = material
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_cracks.add_child(line)
		line.global_position = victim_bounds.get_center() + to_camera * minf(victim_bounds.size.x, victim_bounds.size.z) * 0.43
		line.global_position += Vector3((index - 1) * 0.10, (index - 1) * 0.12, 0)
		line.rotation.z = -0.30 if index % 2 == 0 else 0.42


func shatter(inward: bool = false) -> void:
	if shattered:
		return
	shattered = true
	cue(&"stone_crack")
	if not director.active:
		return
	if victim_is_core:
		cue(&"core_destruction")
	var material: Material = preload("res://materials/foundation_stone.tres")
	var meshes := victim_visual.find_children("*", "MeshInstance3D", true, false)
	if not meshes.is_empty():
		var mesh := meshes[0] as MeshInstance3D
		material = mesh.material_override if mesh.material_override != null else material
	_effect = StoneDestruction.new()
	_effect.name = "StoneDestruction"
	director.effects.add_child(_effect)
	_effect.spawn(victim_bounds, material, direction, inward, victim_is_core, seed_value)
	victim.hide()
	var body := victim.get_node_or_null("PickBody") as CollisionObject3D
	if body != null:
		body.collision_layer = 0
	cue(&"debris")
	if director.active:
		director.victim_shattered.emit(attacker, victim)


func find_part(name: String) -> Node3D:
	var part := attacker_visual.find_child(name, true, false) as Node3D
	if part != null and not _parts.has(part):
		_parts[part] = part.transform
	return part


func append_hold(timeline: Tween, duration: float) -> void:
	timeline.tween_callback(director.hold.bind(duration))
	timeline.tween_interval(duration)


func append_settle(timeline: Tween, duration: float) -> void:
	timeline.tween_property(attacker, "global_position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	timeline.parallel().tween_property(attacker_visual, "position", _attacker_pose.origin, duration)
	timeline.parallel().tween_property(attacker_visual, "rotation", _attacker_pose.basis.get_euler(), duration)
	timeline.parallel().tween_property(attacker_visual, "scale", _attacker_pose.basis.get_scale(), duration)
	for part in _parts:
		var pose: Transform3D = _parts[part]
		timeline.parallel().tween_property(part, "rotation", pose.basis.get_euler(), duration)
		timeline.parallel().tween_property(part, "position", pose.origin, duration)


func restore_visuals() -> void:
	if is_instance_valid(attacker_visual):
		attacker_visual.transform = _attacker_pose
	for part in _parts:
		if is_instance_valid(part):
			part.transform = _parts[part]
	if is_instance_valid(_cracks):
		_cracks.queue_free()
	_parts.clear()


func abort() -> void:
	restore_visuals()
	if is_instance_valid(attacker):
		attacker.global_transform = _attacker_root
	if is_instance_valid(victim):
		victim.global_transform = _victim_root
		victim_visual.transform = _victim_pose
		victim.show()
		var body := victim.get_node_or_null("PickBody") as CollisionObject3D
		if body != null:
			body.collision_layer = 2
	if is_instance_valid(_effect):
		_effect.queue_free()
