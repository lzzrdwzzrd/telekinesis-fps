extends CanvasLayer

var blur_tween : Tween
@onready var color_rect: ColorRect = $ColorRect
@onready var settings: Control = $Settings

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("pause"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().paused = true
				visible = true
				print($"../Character".crosshair_position, Vector2(get_tree().root.size))
				color_rect.material.set_shader_parameter("center", $"../Character".crosshair_position / Vector2(get_tree().root.content_scale_size))
				if blur_tween: blur_tween.kill()
				blur_tween = create_tween()
				blur_tween.tween_method(_set_vignette_shader_value, 0.0, 1.4, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
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

func _set_vignette_shader_value(value: float):
	color_rect.material.set_shader_parameter("intensity", value);

func _on_settings_button_pressed() -> void:
	settings.visible = !settings.visible
