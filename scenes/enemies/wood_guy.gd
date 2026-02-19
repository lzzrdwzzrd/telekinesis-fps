extends AnimatableBody3D

@export var movement_speed := 6.0
@export var rotation_speed := 6.0
@export var health := 300
@export var max_health := 300

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player")

@onready var anchor: Node3D = $Anchor
@onready var hurtbox: Area3D = $Anchor/Area3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $Anchor/AnimationTree
@onready var healthbar: ProgressBar = $CanvasLayer/Health
@onready var health_anchor: Marker3D = $Marker3D
@onready var cam := get_viewport().get_camera_3d()

var is_attacking := false


func _ready() -> void:
	nav_agent.radius = 1.9
	nav_agent.avoidance_enabled = true
	nav_agent.max_speed = movement_speed


func _physics_process(delta: float) -> void:
	if not player:
		return

	nav_agent.target_position = player.global_position

	if not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		var direction = next_pos - global_position

		if direction.length() > 0.01:
			direction = direction.normalized()
			global_position += direction * movement_speed * delta * (0.7 if is_attacking else 1.0)

	_rotate_anchor_toward(player.global_position, delta)


func _rotate_anchor_toward(target_pos: Vector3, delta: float) -> void:
	var to_target = target_pos - anchor.global_position
	to_target.y = 0

	if to_target.length_squared() < 0.0001:
		return

	var target_yaw = atan2(-to_target.x, -to_target.z)
	anchor.rotation.y = lerp_angle(anchor.rotation.y, target_yaw, rotation_speed * delta)

func _process(delta: float) -> void:
	healthbar.value = lerp(healthbar.value, float(health), delta * 20.0)

	if health < max_health:
		healthbar.visible = !cam.is_position_behind(health_anchor.global_position)
		if healthbar.visible:
			healthbar.position = cam.unproject_position(health_anchor.global_position) + Vector2(-healthbar.size.x / 2, 0)

func on_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		get_parent().score += 20.0
		get_parent().spawn_guys()
		queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	_start_attack()

func _start_attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/ArmState/playback")
	playback.travel("Attack")


func _perform_attack() -> void:
	for body in hurtbox.get_overlapping_bodies():
		if body.has_method("on_damage"):
			body.on_damage(30)

func _stop_attack() -> void:
	is_attacking = false
	if hurtbox.get_overlapping_bodies().size() > 0:
		_start_attack()
