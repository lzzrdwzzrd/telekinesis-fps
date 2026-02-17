extends CharacterBody3D

@export var base_speed := 13.0

@export var acceleration := 7.0
@export var slowdown := 15.0

@export var jump_velocity := 5.5
@export var in_air_speed_rate := 0.35
@export var mouse_sensitivity := 0.05
@export var mouse_sensitivity_ratio : float

@export var max_health := 100.0
@export var health := max_health
var display_health := max_health

@export var speed_mod := 0.0
@export var accel_mod := 0.0
@export var hurt_speed_mod := 0.0

@export var target_fov := 90.0:
	set(value):
		target_fov = value
		camera.fov = target_fov + fov_mod
@export var fov_mod := 0.0:
	set(value):
		fov_mod = value
		camera.fov = target_fov + fov_mod

@export var hold_distance : float = 4.0
@export var min_hold_dist : float = 1.5
@export var max_hold_dist : float = 8.0

@export var throw_impulse : float = 30.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/CamContainer/Camera3D
@onready var crosshair: Panel = $HUD/Crosshair
@onready var arm: Node3D = $Head/CamContainer/ArmWouldGoHere
@onready var grab_beam: MeshInstance3D = $Head/CamContainer/ArmWouldGoHere/GrabBeam
@onready var grab_raycast: ShapeCast3D = $Head/CamContainer/Camera3D/GrabRaycast
@onready var root := get_tree().root

var mouse_input : Vector2
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var was_on_floor := true
var current_speed : float = 0.0
var tangent_speed : float = 0.0
var air_time := 0.0
var beam_pull_dir : Vector3
var arc_h : float
var beam_tween : Tween

var grab_target : Grabbable3D
var grabbing := false

@export var crosshair_position : Vector2

func _ready() -> void:
	var config := ConfigFile.new()
	var _error := config.load("user://pref.cfg")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_sensitivity = config.get_value("conf", "mouse_sensitivity", 0.05)

func _handle_head_rotation() -> void:
	head.rotation_degrees.y -= mouse_input.x * mouse_sensitivity
	head.rotation_degrees.x -= mouse_input.y * mouse_sensitivity
	mouse_input = Vector2.ZERO
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _handle_movement(delta: float, input_dir: Vector2) -> void:
	var rotated_direction := input_dir.rotated(-head.rotation.y)
	var direction := Vector3(rotated_direction.x, 0, rotated_direction.y)

	var real_speed : float = max(0.0, base_speed + speed_mod + hurt_speed_mod)

	if is_on_floor():
		if rotated_direction.is_equal_approx(Vector2.ZERO):
			velocity.x = lerp(velocity.x, direction.x * real_speed, (slowdown + accel_mod) * delta)
			velocity.z = lerp(velocity.z, direction.z * real_speed, (slowdown + accel_mod) * delta)
		else:
			velocity.x = lerp(velocity.x, direction.x * real_speed, (acceleration + accel_mod) * delta)
			velocity.z = lerp(velocity.z, direction.z * real_speed, (acceleration + accel_mod) * delta)
	else:
		velocity.x = lerp(velocity.x, direction.x * real_speed, (acceleration + accel_mod) * delta * in_air_speed_rate)
		velocity.z = lerp(velocity.z, direction.z * real_speed, (acceleration + accel_mod) * delta * in_air_speed_rate)

func _handle_jumping() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_velocity

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input.x += event.relative.x * mouse_sensitivity_ratio
		mouse_input.y += event.relative.y * mouse_sensitivity_ratio

func on_damage(damage: float) -> void:
	health -= damage
	if health <= 0:
		# die
		pass

func _physics_process(delta: float) -> void:
	if display_health != health:
		display_health = round(lerp(display_health, health, delta * 15.0))
		#health_progress.value = display_health
		#health_progress.max_value = max_health

	if not is_on_floor() and gravity:
		velocity.y -= gravity * delta * 1.2

	var input_dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input_dir = Input.get_vector("left", "right", "forward", "back")

	_handle_movement(delta, input_dir)
	_handle_jumping()

	#var real_velocity := get_real_velocity()
	#tangent_speed = Vector3.ZERO.distance_to(Vector3(real_velocity.x, 0.0, real_velocity.z))
	#current_speed = Vector3.ZERO.distance_to(real_velocity)
	#_handle_headbob(delta, input_dir.is_equal_approx(Vector2.ZERO))

	if !is_on_floor():
		air_time += delta
	elif !was_on_floor:
		#if air_time >= 0.5 and jump_anim_enabled:
			#jump_anim.play("land")
		air_time = 0.0

	if !grabbing:
		if grab_raycast.is_colliding() and (!grab_target or grab_target.get_instance_id() != grab_raycast.get_collider(0).get_instance_id()) and grab_raycast.get_collider(0) is Grabbable3D:
			if grab_target: grab_target._set_hover_vfx(false)
			grab_target = grab_raycast.get_collider(0)
			grab_target._set_hover_vfx(true)
		elif !grab_raycast.is_colliding() and grab_target:
			grab_target._set_hover_vfx(false)
			grab_target = null

	if Input.is_action_just_pressed("grab") and !grabbing and grab_target:
		grab_target._set_hover_vfx(false)
		grabbing = true
		#hold_distance = camera.global_position.distance_to(grab_raycast.get_collision_point()) - 0.5
		hold_distance = 2.5
		grab_target.start_grab(self)
		if beam_tween: beam_tween.kill()
		beam_tween = create_tween()
		beam_tween.tween_method(_set_beam_shader_value, -0.1, 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	#hold_distance = clamp(hold_distance, min_hold_dist, max_hold_dist)

	var throw := Input.is_action_just_pressed("throw")

	if grabbing and (Input.is_action_just_released("grab") or !is_instance_valid(grab_target) or throw):
		grabbing = false
		if is_instance_valid(grab_target):
			grab_target.stop_grab()
			grab_target._set_hover_vfx(false)
			if throw:
				var dir = -camera.global_transform.basis.z
				#grab_target.apply_central_impulse(dir * throw_impulse + get_real_velocity())
				grab_target.linear_velocity = dir * throw_impulse + get_real_velocity()
				grab_target.particles(grab_target.linear_velocity)
		grab_target = null

	if grabbing:
		var origin = camera.global_transform.origin
		var forward = -camera.global_transform.basis.z
		var target_pos = origin + forward * hold_distance

		grab_target.set_grab_target(target_pos, camera.global_transform.basis)

	_handle_beam(delta)

	fov_mod = clampf(tangent_speed * 4 / base_speed, 0, 5)

	mouse_sensitivity_ratio = float(root.size.x) / float(root.content_scale_size.x)
	crosshair_position = (Vector2(root.content_scale_size) / 2.0) if !grab_target or grabbing else camera.unproject_position(grab_target.global_position)

	was_on_floor = is_on_floor()
	move_and_slide()

func _grab_arc_points(hand_pos: Vector3, object_pos: Vector3, pull_dir: Vector3, segments: int, curvature: float) -> PackedVector3Array:
	var points := PackedVector3Array()

	var mid = (hand_pos + object_pos) * 0.5

	var bend_dir = pull_dir
	if bend_dir.length_squared() < 0.000001:
		bend_dir = (object_pos - hand_pos).normalized()

	bend_dir = bend_dir.normalized()

	var control = mid + bend_dir * curvature

	for i in range(segments + 1):
		var t = float(i) / segments
		var a = hand_pos.lerp(control, t)
		var b = control.lerp(object_pos, t)
		points.append(a.lerp(b, t))

	return points

func _transport_frame(prev_frame: Basis, prev_tangent: Vector3, new_tangent: Vector3) -> Basis:
	var axis = prev_tangent.cross(new_tangent)
	var dot = prev_tangent.dot(new_tangent)

	# If nearly parallel, keep frame
	if axis.length_squared() < 0.000001:
		return prev_frame

	axis = axis.normalized()
	var angle = acos(clamp(dot, -1.0, 1.0))

	var q = Quaternion(axis, angle)
	return Basis(q) * prev_frame


func _frame_from_tangent(tangent: Vector3) -> Basis:
	var up = Vector3.UP
	if abs(tangent.dot(up)) > 0.99:
		up = Vector3.RIGHT

	var right = tangent.cross(up).normalized()
	var normal = right.cross(tangent).normalized()

	return Basis(right, normal, tangent)

func _handle_beam(delta: float, segments := 24, thickness := 0.04) -> void:
	if !grabbing or !is_instance_valid(grab_target):
		grab_beam.visible = false
		return

	arc_h = lerp(arc_h, absf(grab_target.linear_velocity.length() - grab_target.last_linear_velocity.length()) * 0.8, delta * 0.1)
	var pull_dir = (grab_target.grab_target_position - grab_target.global_position)

	beam_pull_dir = beam_pull_dir.lerp(pull_dir, 4.0 * delta)
	var curve_points : PackedVector3Array = _grab_arc_points(Vector3.ZERO, grab_target.global_position - arm.global_position, pull_dir, segments, arc_h)

	var beam : ImmediateMesh = grab_beam.mesh
	beam.clear_surfaces()
	beam.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var radial_segments = 5
	var rings := []

	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
	var r = thickness * pulse

	var frames := []

	var tangents := []
	for i in range(curve_points.size()):
		if i == curve_points.size() - 1:
			tangents.append((curve_points[i] - curve_points[i - 1]).normalized())
		else:
			tangents.append((curve_points[i + 1] - curve_points[i]).normalized())

	frames.append(_frame_from_tangent(tangents[0]))

	for i in range(1, tangents.size()):
		var new_frame = _transport_frame(frames[i - 1], tangents[i - 1], tangents[i])
		frames.append(new_frame)

	for i in range(curve_points.size()):
		var p = curve_points[i]

		var frame = frames[i]

		var ring := []
		for j in range(radial_segments):
			var angle = TAU * float(j) / radial_segments
			var offset = frame.x * cos(angle) * r + frame.y * sin(angle) * r

			ring.append(p + offset)

		rings.append(ring)

	var ring_count = rings.size()

	for i in range(ring_count - 1):
		var ring_a = rings[i]
		var ring_b = rings[i + 1]

		var v0 = float(i) / float(ring_count - 1)
		var v1 = float(i + 1) / float(ring_count - 1)

		for j in range(radial_segments):
			var next = (j + 1) % radial_segments

			var u0 = float(j) / float(radial_segments)
			var u1 = float(next) / float(radial_segments)

			var a0 = ring_a[j]
			var a1 = ring_a[next]
			var b0 = ring_b[j]
			var b1 = ring_b[next]

			beam.surface_set_uv(Vector2(u0, v0))
			beam.surface_add_vertex(a0)

			beam.surface_set_uv(Vector2(u0, v1))
			beam.surface_add_vertex(b0)

			beam.surface_set_uv(Vector2(u1, v1))
			beam.surface_add_vertex(b1)

			beam.surface_set_uv(Vector2(u0, v0))
			beam.surface_add_vertex(a0)

			beam.surface_set_uv(Vector2(u1, v1))
			beam.surface_add_vertex(b1)

			beam.surface_set_uv(Vector2(u1, v0))
			beam.surface_add_vertex(a1)


	beam.surface_end()
	grab_beam.mesh = beam
	grab_beam.global_rotation = Vector3.ZERO # reeeeeal hacky
	grab_beam.visible = true

func _set_beam_shader_value(value: float):
	grab_beam.material_override.set_shader_parameter("uv_threshold", value);

func _process(_delta: float) -> void:
	crosshair.position = lerp(crosshair.position, crosshair_position, _delta * 20.0)
	_handle_head_rotation()
