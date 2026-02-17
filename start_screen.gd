extends Node3D

@export var range := .2

func _ready() -> void:
	for child in get_children():
		if !(child is RigidBody3D):
			continue
		child.linear_velocity = Vector3(randf_range(-range, range), randf_range(-range, range), randf_range(-range, range))
		child.angular_velocity = Vector3(randf_range(-range, range), randf_range(-range, range), randf_range(-range, range))
		print(child)


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
