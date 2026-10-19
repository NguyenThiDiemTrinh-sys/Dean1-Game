extends CharacterBody2D

signal health_changed(new_health)
signal player_died

var health = 3 
var is_hurt = false

var walk_speed = 600
var run_speed = 1000

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Kiểm tra xem có đang đè phím chạy không (cần setup "run" trong Input Map)
	var current_speed = walk_speed
	if Input.is_action_pressed("run"):
		current_speed = run_speed
		
	velocity = direction * current_speed
	move_and_slide()
	
	if not is_hurt:
		if velocity.length() > 0.0:
			if current_speed == run_speed:
				$AnimatedSprite2D.play("running")
			else:
				$AnimatedSprite2D.play("walking2")
		else:
			$AnimatedSprite2D.play("idle")
		
	
		
func take_damage():
	if is_hurt: 
		return
	health -= 1 
	health_changed.emit(health) 
	if health <= 0:
		player_died.emit()
		die()
	else:
		# Bật trạng thái bị thương và phát animation
		is_hurt = true
		$AnimatedSprite2D.play("hurt2")
		
		# Yêu cầu code đợi cho đến khi animation "hurt" chạy xong hoàn toàn
		await $AnimatedSprite2D.animation_finished
		
		# Tắt trạng thái bị thương để nhân vật có thể đi lại bình thường
		is_hurt = false
		
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
	
	
	
