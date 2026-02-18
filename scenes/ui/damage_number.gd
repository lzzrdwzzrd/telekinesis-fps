extends Node3D

func action(damage: int) -> void:
	$Label3D.text = str(damage)
	$AnimationPlayer.play("action")
