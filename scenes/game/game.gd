extends Node3D

@export var score := 30.0

var rock_limit := 20

const ROCK = preload("uid://cj3l61mvpmy8d")
const ROCK_2 = preload("uid://vxdhm25hm2bu")
const ROCK_3 = preload("uid://b42okickprssl")
const ROCK_4 = preload("uid://c7kqqt0meixj6")
var rocks := [ROCK, ROCK_2, ROCK_3, ROCK_4]

var run_over := false

@onready var score_label: Label = $CanvasLayer2/Score
const STONE_GOLEM = preload("uid://vte8jao2k7fv")
const WOOD_GUY = preload("uid://d4e4g1kku4o6l")

func _on_rock_interval_timeout() -> void:
	if get_tree().get_nodes_in_group("throwable").size() < rock_limit:
		var rock_scene = rocks[randi() % rocks.size()]
		var rock_instance = rock_scene.instantiate()
		add_child(rock_instance)
		var distance := randf_range(0, 50)
		var angle := randf_range(0, 2 * PI)
		var x := distance * cos(angle)
		var z := distance * sin(angle)
		rock_instance.global_position = Vector3(x, .2, z)

func on_player_dead() -> void:
	run_over = true

func _process(delta: float) -> void:
	if !run_over:
		score -= delta * 1.2
	score_label.text = "SCORE  %.02f" % score

func spawn_guys() -> void:
	for _i in range(2):
		await get_tree().create_timer(randf_range(0.5, 3.0))
		var enemy = [STONE_GOLEM, WOOD_GUY, WOOD_GUY][randi() % 3] if get_tree().get_node_count_in_group("stone_golem") < 3 else WOOD_GUY
		var enemy_instance = enemy.instantiate()
		add_child(enemy_instance)
		var distance := randf_range(0, 50)
		var angle := randf_range(0, 2 * PI)
		var x := distance * cos(angle)
		var z := distance * sin(angle)
		enemy_instance.global_position = Vector3(x, 0, z)
