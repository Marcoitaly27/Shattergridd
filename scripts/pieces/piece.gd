@tool
extends Node3D
## Piece identity and presentation hooks. Board state owns logical occupancy.
## Replace the Visuals child with a model scene later; retain this root and its data.

enum Army { ASH, SLATE }
signal status_changed(piece: Node3D)
signal status_applied(piece: Node3D, definition: Resource)
const CharacterDefinition = preload("res://scripts/pieces/character_definition.gd")
const StatusState = preload("res://scripts/status/status_state.gd")
const DEFAULT_MOVEMENT: Resource = preload("res://resources/characters/temporary_movement.tres")
var statuses: RefCounted = StatusState.new()

@export var piece_id: StringName = &"placeholder"
@export var character_definition: CharacterDefinition:
	set(value):
		character_definition = value
		if is_node_ready():
			_apply_appearance()
			_refresh_picking_body()
## Optional per-instance overrides; otherwise use the archetype's shared data.
@export var display_name: String = ""
@export var movement_behavior: Resource
@export var picking_height: float = 1.34
@export var picking_radius: float = 0.28
@export var army: Army = Army.ASH:
	set(value):
		army = value
		if is_node_ready():
			_apply_appearance()
			_refresh_picking_body()
			if not Engine.is_editor_hint():
				_add_army_mark()
@export var grid_coordinate: Vector2i = Vector2i.ZERO
## Deployment provenance is instance identity; it grants no in-match privileges.
var deployment_slot_id: StringName
var reflected_member: int = 0


func _ready() -> void:
	_apply_appearance()
	if Engine.is_editor_hint():
		return
	_add_picking_body()
	_add_selection_ring()
	_add_army_mark()
	statuses.changed.connect(func() -> void: status_changed.emit(self))
	statuses.granted.connect(func(definition: Resource) -> void: status_applied.emit(self, definition))


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return character_definition.display_name if character_definition != null else "Stone sentinel"


func get_movement_behavior() -> Resource:
	if movement_behavior != null:
		return movement_behavior
	if character_definition != null and character_definition.movement_behavior != null:
		return character_definition.movement_behavior
	return DEFAULT_MOVEMENT


func get_pick_point() -> Vector3:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("get_pick_point"):
		return visuals.call("get_pick_point")
	return global_position + Vector3.UP * picking_height * 0.6


func get_capture_behavior() -> Resource:
	return character_definition.capture_behavior if character_definition != null else null


func apply_status(definition: Resource, starts_after: int, expires_at: int) -> bool:
	if character_definition != null and character_definition.status_immunities.has(definition.status_id):
		return false
	statuses.grant(definition, starts_after, expires_at)
	return true


func get_movement_summary() -> String:
	var behavior := get_movement_behavior()
	var summary: Variant = behavior.get("summary") if behavior != null else null
	return String(summary) if summary != null else "See the marked legal destinations."


func set_hovered(hovered: bool, capture: bool = false) -> void:
	var ring := get_node_or_null("HoverRing") as Node3D
	if ring == null and hovered:
		ring = _add_corner_ring("HoverRing", 0.66)
	if ring != null:
		ring.visible = hovered
		for edge in ring.get_children():
			edge.material_override = preload("res://materials/attack_hint.tres") if capture else preload("res://materials/hover_hint.tres")


func set_threatened(threatened: bool) -> void:
	var ring := get_node_or_null("ThreatRing") as Node3D
	if ring == null and threatened:
		ring = _add_corner_ring("ThreatRing", 0.72)
		for edge in ring.get_children():
			edge.material_override = preload("res://materials/attack_hint.tres")
	if ring != null:
		ring.visible = threatened


func refresh_status_indicators(completed_owner_turns: int) -> void:
	var text: String = statuses.markers(completed_owner_turns)
	var marker := get_node_or_null("StatusMarker") as Label3D
	if marker == null and not text.is_empty():
		marker = Label3D.new()
		marker.name = "StatusMarker"
		marker.position = Vector3(-0.57, 0.30, 0.65)
		marker.no_depth_test = true
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 32
		marker.pixel_size = 0.009
		marker.modulate = Color(0.81, 0.70, 0.45)
		marker.outline_modulate = Color(0.035, 0.04, 0.04)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)
	if marker != null:
		marker.text = text
		marker.visible = not text.is_empty()


func get_visual_bounds() -> AABB:
	var bounds := AABB(global_position, Vector3.ZERO)
	var started := false
	for mesh_node in $Visuals.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var part := mesh.global_transform * mesh.mesh.get_aabb()
		bounds = bounds.merge(part) if started else part
		started = true
	return bounds


func set_selected(selected: bool) -> void:
	var ring := get_node_or_null("SelectionRing") as Node3D
	if ring != null:
		ring.visible = selected


func animate_to(destination: Vector3, duration: float) -> Tween:
	var animation := create_tween()
	animation.tween_property(self, "position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return animation


func _add_picking_body() -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("create_picking_body"):
		if visuals.call("create_picking_body", self):
			return
	# Fallback for replacement models without a compound picking implementation.
	var body := StaticBody3D.new()
	body.name = "PickBody"
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("piece", self)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = picking_radius
	shape.height = picking_height
	collision.shape = shape
	collision.position.y = picking_height * 0.5
	body.add_child(collision)
	var base_collision := CollisionShape3D.new()
	var base_shape := CylinderShape3D.new()
	base_shape.radius = 0.44
	base_shape.height = 0.32
	base_collision.shape = base_shape
	base_collision.position.y = 0.16
	body.add_child(base_collision)
	add_child(body)


func _refresh_picking_body() -> void:
	if Engine.is_editor_hint():
		return
	var previous := get_node_or_null("PickBody")
	if previous != null:
		remove_child(previous)
		previous.queue_free()
	_add_picking_body()


func _add_selection_ring() -> void:
	var ring := Node3D.new()
	ring.name = "SelectionRing"
	# Outline outside architectural bases, rather than hiding a circular ring
	# inside the new rectangular plinths. It still stays within a single tile.
	ring.position.y = 0.025
	for side in range(4):
		var edge := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(1.36, 0.014, 0.035)
		edge.mesh = bar
		edge.material_override = preload("res://materials/selected_hint.tres")
		edge.position = Vector3(0, 0, 0.68).rotated(Vector3.UP, side * PI * 0.5)
		edge.rotation.y = side * PI * 0.5
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(edge)
	ring.visible = false
	add_child(ring)


func _add_corner_ring(label: String, radius: float) -> Node3D:
	var ring := Node3D.new()
	ring.name = label
	ring.position.y = 0.035
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.29, 0.014, 0.035)
	for side in range(4):
		var edge := MeshInstance3D.new()
		edge.mesh = mesh
		edge.position = Vector3(radius - 0.13, 0, radius).rotated(Vector3.UP, side * PI * 0.5)
		edge.rotation.y = side * PI * 0.5
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(edge)
	add_child(ring)
	return ring


func _add_army_mark() -> void:
	# One versus two cuts in the pedestal: team identity does not rely on color.
	var previous := get_node_or_null("ArmyMark")
	if previous != null:
		remove_child(previous)
		previous.queue_free()
	var marks := Node3D.new()
	marks.name = "ArmyMark"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.055, 0.018, 0.16)
	for index in range(army + 1):
		var cut := MeshInstance3D.new()
		cut.mesh = mesh
		cut.position = Vector3((index - army * 0.5) * 0.14, 0.205, 0.48)
		cut.material_override = preload("res://materials/hover_hint.tres")
		cut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marks.add_child(cut)
	add_child(marks)


func _apply_appearance() -> void:
	# Future model scenes keep their own materials and animation hierarchy.
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("set_character"):
		visuals.call("set_character", character_definition)
	if visuals != null and visuals.has_method("set_army"):
		visuals.call("set_army", army)
