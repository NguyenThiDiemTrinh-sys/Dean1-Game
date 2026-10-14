extends CharacterBody2D

signal health_changed(new_health)
signal player_died

var health = 3 

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 600
	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else :
		%HappyBoo.play_idle_animation()
		
func take_damage():
	health -= 1 
	health_changed.emit(health) 
	if health <= 0:
		player_died.emit()
		die()
		
func die():
	print("Game Over!")
	# để tạm
	queue_free()
		
func attack(symbol: String):
	# enemies là để nhắm vào những con quái có trên màn hình
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		enemy.check_symbol(symbol)
			
# Hàm phụ để giúp Godot biết cách sắp xếp quái theo khoảng cách gần -> xa
func sort_by_distance(a, b):
	var dist_a = global_position.distance_squared_to(a.global_position)
	var dist_b = global_position.distance_squared_to(b.global_position)
	return dist_a < dist_b
	
	
	
