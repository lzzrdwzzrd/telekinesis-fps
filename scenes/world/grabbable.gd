class_name Grabbable3D
extends RigidBody3D

@export var mesh : MeshInstance3D
@export var collision_shape : CollisionShape3D
@onready var bounds: Node3D = $Bounds # the points are named NNN (Negative X, Negative Y, Negative Z), NNP (-X, -Y, +Z), NPN, NPP, etc.

@export var grab_stiffness : float = 20.0
@export var grab_damping : float = 30.0
@export var max_grab_force : float = 2000.0
@export var maintain_upright : bool = false
@export var upright_torque_strength : float = 10.0

var bounds_hover_tween : Tween
var is_grabbed : bool = false
var grab_target_position : Vector3
var grab_target_rotation : Basis
var grab_anchor : Node3D
var noise_tween : Tween

var original_gravity_scale : float

const GRABBED_MATERIAL = preload("uid://coc4737377k3b")

func _ready():
	_position_bounds()
	mesh.material_overlay = GRABBED_MATERIAL.duplicate()
	mesh.material_overlay.set_local_to_scene(true)
	mesh.material_overlay.set_shader_parameter("alpha", 0.0)
	original_gravity_scale = gravity_scale

func _set_grab_vfx(enable: bool) -> void:
	mesh.material_overlay.set_shader_parameter("alpha", 1.0 if enable else 0.0)
	if noise_tween: noise_tween.kill()
	if enable:
		noise_tween = create_tween()
		noise_tween.tween_method(_set_shader_value, 1.0, 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _set_hover_vfx(enable: bool) -> void:
	if enable:
		if bounds_hover_tween: bounds_hover_tween.kill()
		bounds_hover_tween = create_tween()
		bounds_hover_tween.tween_property(bounds, "scale", Vector3.ONE, 0.2).from(Vector3(1.2, 1.2, 1.2)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

	bounds.visible = enable

func _position_bounds() -> void:
	if not collision_shape or not collision_shape.shape:
		return

	var half_extents = _get_shape_half_extents(collision_shape.shape)

	bounds.transform = collision_shape.transform

	var sign_map := {
		"NNN": Vector3(-1, -1, -1),
		"NNP": Vector3(-1, -1,  1),
		"NPN": Vector3(-1,  1, -1),
		"NPP": Vector3(-1,  1,  1),
		"PNN": Vector3( 1, -1, -1),
		"PNP": Vector3( 1, -1,  1),
		"PPN": Vector3( 1,  1, -1),
		"PPP": Vector3( 1,  1,  1),
	}

	for name_ in sign_map.keys():
		if not bounds.has_node(name_):
			continue

		var marker: Node3D = bounds.get_node(name_)
		marker.position = sign_map[name_] * half_extents

func _get_shape_half_extents(shape: Shape3D) -> Vector3:
	if shape is BoxShape3D:
		return shape.size * 0.5

	if shape is SphereShape3D:
		return Vector3.ONE * shape.radius

	if shape is CylinderShape3D:
		return Vector3(shape.radius, shape.height * 0.5, shape.radius)

	if shape is CapsuleShape3D:
		return Vector3(
			shape.radius,
			shape.height * 0.5 + shape.radius,
			shape.radius
		)

	var debug_mesh = shape.get_debug_mesh()
	if debug_mesh:
		return debug_mesh.get_aabb().size * 0.5

	return Vector3.ONE * 0.5

func start_grab(by: Node3D):
	grab_anchor = by
	is_grabbed = true
	gravity_scale = 0.0
	sleeping = false
	_set_grab_vfx(true)

func stop_grab():
	is_grabbed = false
	gravity_scale = original_gravity_scale
	grab_anchor = null
	_set_grab_vfx(false)

func set_grab_target(pos: Vector3, rot: Basis):
	grab_target_position = pos
	grab_target_rotation = rot

func _physics_process(delta: float) -> void:
	if not is_grabbed:
		return

	_apply_position_force(delta)
	_apply_rotation_force(delta)

func _apply_position_force(_delta: float) -> void:
	var displacement = grab_target_position - global_position
	var desired_velocity = displacement * grab_stiffness
	var velocity_error = desired_velocity - linear_velocity

	var force = velocity_error * grab_damping

	if force.length() > max_grab_force:
		force = force.normalized() * max_grab_force

	apply_central_force(force)

func _set_shader_value(value: float):
	mesh.material_overlay.set_shader_parameter("noise_override", value);

func _apply_rotation_force(_delta: float) -> void:
	if not maintain_upright:
		return

	var current = global_transform.basis
	var target = grab_target_rotation

	var delta_rot = (target * current.inverse()).get_euler()
	var torque = delta_rot * upright_torque_strength - angular_velocity * 2.0
	apply_torque(torque)
