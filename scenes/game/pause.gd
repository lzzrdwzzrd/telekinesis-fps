extends CanvasLayer

var blur_tween : Tween

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("pause"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().paused = true
				visible = true
				$ColorRect.material.set_shader_parameter("center", $"../Character".crosshair_position / Vector2(get_tree().root.size))
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_tree().paused = false
				visible = false


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://start_screen.tscn")

func _on_start_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	visible = false
