extends AnimatableBody3D

@export var movement_speed := 4.0
@export var health := 500

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var area_3d: Area3D = $Area3D
@onready var lookat: LookAtModifier3D = $Armature/Skeleton3D/LookAtModifier3D
@onready var marker_3d: Marker3D = $Armature/Skeleton3D/Marker3D

var is_attacking := false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	marker_3d.global_position = player.global_position

	look_at(player.global_position)
	rotation.x = 0
	rotation.z = 0

	if !is_attacking:
		global_position += global_position.direction_to(player.global_position) * movement_speed * delta

func on_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	_start_attack()

func _start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	var playback : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
	playback.travel("Attack")
	#is_attacking = false

func _perform_attack() -> void:
	for body in area_3d.get_overlapping_bodies():
		body.on_damage(50)

func _stop_attack() -> void:
	is_attacking = false
	if area_3d.get_overlapping_bodies().size():
		_start_attack()
