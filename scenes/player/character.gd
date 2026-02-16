extends CharacterBody3D

@export var base_speed := 13.0

@export var acceleration := 7.0
@export var slowdown := 15.0

@export var jump_velocity := 5.5
@export var in_air_speed_rate := 0.35
@export var mouse_sensitivity := 0.05

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

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/CamContainer/Camera3D
@onready var grab_raycast: RayCast3D = $Head/CamContainer/Camera3D/GrabRaycast

var mouse_input : Vector2
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var was_on_floor := true
var current_speed : float = 0.0
var tangent_speed : float = 0.0
var air_time := 0.0



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
	if event.is_action_pressed("pause"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input.x += event.relative.x
		mouse_input.y += event.relative.y

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

	_handle_head_rotation()
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

	fov_mod = clampf(tangent_speed * 4 / base_speed, 0, 5)

	was_on_floor = is_on_floor()
	move_and_slide()
