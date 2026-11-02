extends Node3D
## Bounded native rigid bodies and a short CPU dust puff; no mesh fracturing.

signal fragment_contact(position: Vector3, strength: float)
const LIFETIME: float = 2.4
var elapsed: float = 0.0
var fragment_count: int = 0
var _meshes: Array[MeshInstance3D] = []
var _born_usec: int = 0
var _reported_contacts: Dictionary = {}


func spawn(bounds: AABB, stone: Material, attack_direction: Vector3, inward: bool, core: bool, seed_value: int) -> void:
	_born_usec = Time.get_ticks_usec()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	fragment_count = 12 if core else (7 if inward else 8)
	var center := bounds.get_center()
	for index in range(fragment_count):
		var size := Vector3(random.randf_range(0.18, 0.35), random.randf_range(0.20, 0.42), random.randf_range(0.18, 0.34))
		var body := RigidBody3D.new()
		body.name = "Stone_%02d" % index
		body.mass = 3.5
		body.gravity_scale = 1.35
		body.linear_damp = 0.8
		body.angular_damp = 3.0
		body.continuous_cd = true
		body.collision_layer = 4
		body.collision_mask = 1
		var physics := PhysicsMaterial.new()
		physics.friction = 0.85
		physics.bounce = 0.05
		body.physics_material_override = physics
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		visual.mesh = mesh
		visual.material_override = stone
		body.add_child(visual)
		add_child(body)
		if index < 2:
			body.contact_monitor = true
			body.max_contacts_reported = 2
			body.body_entered.connect(_on_contact.bind(body, index))
		var angle := TAU * float(index) / fragment_count + random.randf_range(-0.12, 0.12)
		var outward := Vector3(cos(angle), 0, sin(angle))
		body.global_position = center + outward * random.randf_range(0.12, 0.30)
		body.global_position.y = bounds.position.y + random.randf_range(0.25, maxf(0.4, bounds.size.y * 0.8))
		var horizontal := 0.18 if inward else 0.75
		body.linear_velocity = outward * horizontal + attack_direction * (0.12 if inward else 0.40)
		body.linear_velocity.y = -0.15 if inward else random.randf_range(0.35, 0.90)
		body.angular_velocity = Vector3(random.randf_range(-1.8, 1.8), random.randf_range(-1.8, 1.8), random.randf_range(-1.8, 1.8))
		_meshes.append(visual)
	_spawn_dust(center, core)


func _on_contact(other: Node, body: RigidBody3D, index: int) -> void:
	if _reported_contacts.has(index) or _reported_contacts.size() >= 2:
		return
	if not other is PhysicsBody3D or (other.collision_layer & 1) == 0:
		return
	# Only actual tile/slab contacts count. Falling into the void has no event.
	_reported_contacts[index] = true
	fragment_contact.emit(body.global_position, minf(body.linear_velocity.length(), 6.0))


func _process(_delta: float) -> void:
	elapsed = float(Time.get_ticks_usec() - _born_usec) / 1000000.0
	if elapsed >= LIFETIME:
		queue_free()
	elif elapsed > LIFETIME - 0.35:
		var remaining := maxf((LIFETIME - elapsed) / 0.35, 0.01)
		for mesh in _meshes:
			mesh.scale = Vector3.ONE * remaining


func _spawn_dust(center: Vector3, core: bool) -> void:
	var dust := CPUParticles3D.new()
	dust.name = "StoneDust"
	dust.amount = 24 if core else 16
	dust.lifetime = 0.60
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = 0.30
	dust.direction = Vector3.UP
	dust.spread = 70.0
	dust.initial_velocity_min = 0.2
	dust.initial_velocity_max = 0.65
	dust.gravity = Vector3(0, -0.6, 0)
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.8
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.37, 0.34, 0.29, 0.24), Color(0.37, 0.34, 0.29, 0.0)])
	dust.color_ramp = ramp
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	dust.mesh = mesh
	add_child(dust)
	dust.global_position = center
	dust.emitting = true
