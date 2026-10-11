extends Node2D

var mob_scene = preload("res://mob.tscn")

func _on_spawn_timer_timeout():
	var new_mob = mob_scene.instantiate()
	
	var random_x = randf_range(-100, 1200)
	var random_y = randf_range(-100, 700)
	
	new_mob.global_position = Vector2(random_x, random_y)
	
	add_child(new_mob)
