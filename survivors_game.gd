extends Node2D

var mob_scene = preload("res://mob.tscn")

@onready var health_label = $UI/HealthLabel
@onready var game_over_screen = $GameOver
@onready var spawn_timer = $SpawnTimer
@onready var player = $Player

func _ready():
	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)
	
func _on_player_health_changed(new_health):
	var hearts_text = ""
	for i in range(new_health):
		hearts_text += "❤" 
	health_label.text = hearts_text
	
func _on_player_died():
	game_over_screen.show()
	spawn_timer.stop()

func _on_spawn_timer_timeout():
	var new_mob = mob_scene.instantiate()
	
	var random_x = randf_range(-100, 1200)
	var random_y = randf_range(-100, 700)
	
	new_mob.global_position = Vector2(random_x, random_y)
	
	add_child(new_mob)


func _on_retry_button_pressed():
	get_tree().reload_current_scene()
