extends Node3D

const GRABBABLE_PREFAB = preload("uid://b6fh7ftlq2w4x")

func _ready() -> void:
	var chosen_rock_idx := randi_range(0, get_child_count() - 1)
	var chosen_rock := get_child(chosen_rock_idx)

	var grabbable : Grabbable3D = GRABBABLE_PREFAB.instantiate()
	add_sibling.call_deferred(grabbable)
	grabbable.global_transform = global_transform

	var rock_collider : CollisionShape3D = chosen_rock.get_child(0)

	chosen_rock.remove_child(rock_collider)
	grabbable.add_child.call_deferred(rock_collider)
	grabbable.set_deferred("collision_shape", rock_collider)

	remove_child(chosen_rock)
	grabbable.add_child.call_deferred(chosen_rock)
	grabbable.set_deferred("mesh", chosen_rock)

	queue_free()
