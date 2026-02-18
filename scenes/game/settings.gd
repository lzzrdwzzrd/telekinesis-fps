extends Control

@onready var sens_slider: HSlider = $VBoxContainer/SensSlider
@onready var music_volume: HSlider = $VBoxContainer/HBoxContainer/MusicVolume
@onready var sfx_volume: HSlider = $VBoxContainer/HBoxContainer/SFXVolume

var sensitivity := 0.05
var music := 0.8
var sfx := 0.8

var config := ConfigFile.new()

func _ready() -> void:
	var error := config.load("user://pref.cfg")

	if error != OK:
		config.set_value("settings", "sensitivity", 0.05)
		config.set_value("settings", "music", 0.8)
		config.set_value("settings", "sfx", 0.8)

		config.save("user://pref.cfg")
	else:
		sensitivity = config.get_value("settings", "sensitivity", 0.05)
		music = config.get_value("settings", "music", 0.8)
		sfx = config.get_value("settings", "sfx", 0.8)

	sens_slider.value = sensitivity
	var player = get_tree().get_first_node_in_group("player")
	if player: player.mouse_sensitivity = sensitivity

	music_volume.value = music
	var music_index := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_index, music)

	sfx_volume.value = sfx
	var sfx_index := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(sfx_index, sfx)

func _on_sens_slider_drag_ended(value_changed: bool) -> void:
	sensitivity = sens_slider.value
	var player = get_tree().get_first_node_in_group("player")
	if player: player.mouse_sensitivity = sensitivity
	config.set_value("settings", "sensitivity", sensitivity)
	config.save("user://pref.cfg")


func _on_music_volume_value_changed(value: float) -> void:
	music = value
	var music_index := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_index, music)

func _on_music_volume_drag_ended(value_changed: bool) -> void:
	config.set_value("settings", "music", music)
	config.save("user://pref.cfg")


func _on_sfx_volume_value_changed(value: float) -> void:
	sfx = value
	var music_index := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(music_index, sfx)

func _on_sfx_volume_drag_ended(value_changed: bool) -> void:
	config.set_value("settings", "sfx", sfx)
	config.save("user://pref.cfg")
