extends CharacterBody2D

signal health_changed(new_health)
signal player_died

var health = 3 
var is_hurt = false
var is_transitioning = false
var is_attacking = false # Khóa di chuyển khi đang vẽ/đánh
var combo_step = 0

var max_health = 3 #này phụ cho item hồi máu thoi 
var is_shielded = false #kiểm tra khiên

var walk_speed = 600
var run_speed = 1000

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Kiểm tra xem có đang đè phím chạy không (cần setup "run" trong Input Map)
	var current_speed = walk_speed
	if Input.is_action_pressed("run"):
		current_speed = run_speed
		
	if is_hurt:
		velocity = Vector2.ZERO # Bị thương thì vấp ngã đứng im
	elif is_attacking:
		velocity = direction * (current_speed * 0.3) # Đang đánh thì tốc độ di chuyển còn 30%
	else:
		velocity = direction * current_speed # Bình thường
		
	move_and_slide()
	
	if not is_hurt and not is_transitioning and not is_attacking:
		if velocity.length() > 0.0:
			if current_speed == run_speed:
				# Nếu đang đi bộ (walking2) mà đột ngột nhấn Shift -> Kích hoạt chuyển cảnh
				if $AnimatedSprite2D.animation == "walking2":
					is_transitioning = true
					$AnimatedSprite2D.play("walk_to_run_down")
					
					# Code sẽ dừng ở đây để đợi 4 frame chuyển tiếp chạy xong
					await $AnimatedSprite2D.animation_finished 
					is_transitioning = false # Mở khóa lại
				
				# Sau khi mở khóa, tiếp tục phát loop chạy nhanh
				if not is_transitioning:
					$AnimatedSprite2D.play("running")
			elif current_speed == walk_speed:
				if $AnimatedSprite2D.animation == "running":
					is_transitioning = true
					$AnimatedSprite2D.play("run_to_walk_down")
					
					# Code sẽ dừng ở đây để đợi 4 frame chuyển tiếp chạy xong
					await $AnimatedSprite2D.animation_finished 
					is_transitioning = false # Mở khóa lại
				# Sau khi mở khóa, tiếp tục phát loop chạy nhanh
				if not is_transitioning:
					$AnimatedSprite2D.play("walking2")
			else:
				$AnimatedSprite2D.play("walking2")
		else:
			$AnimatedSprite2D.play("idle")



func take_damage():
	if is_shielded == true: #này của item khiên
		return
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
		
	#Xử lý combo 
	if is_attacking and combo_step == 1:
		combo_step = 2
	elif is_attacking and combo_step == 2:
		combo_step = 3
	# Nếu trước đó đang đứng im, bắt đầu chuỗi đánh
	elif not is_attacking:
		is_attacking = true
		combo_step = 1
		play_combo_animations()
		
# Hàm phụ để chạy chuỗi animation
func play_combo_animations():
	$AnimatedSprite2D.play("attack_1_down")
	await $AnimatedSprite2D.animation_finished
	
	# Nếu trong lúc chờ hit 1 chạy, người chơi đã vẽ xong hình 2 (combo_step tăng lên 2)
	if combo_step >= 2:
		$AnimatedSprite2D.play("attack_2_down")
		await $AnimatedSprite2D.animation_finished
		
		# Tương tự cho hit 3
		if combo_step >= 3:
			$AnimatedSprite2D.play("attack_3_down")
			await $AnimatedSprite2D.animation_finished
			
	# Đánh xong toàn bộ, reset trạng thái
	is_attacking = false
	combo_step = 0
			
# Hàm phụ để giúp Godot biết cách sắp xếp quái theo khoảng cách gần -> xa
func sort_by_distance(a, b):
	var dist_a = global_position.distance_squared_to(a.global_position)
	var dist_b = global_position.distance_squared_to(b.global_position)
	return dist_a < dist_b

# Hàm hồi máu
func heal():
	# Chỉ hồi máu khi số máu hiện tại đang nhỏ hơn máu tối đa
	if health < max_health:
		health += 1
		health_changed.emit(health) 
		return true # Trả về true là ăn được tim
	else:
		return false # Trả về false là không ăn được tim

#Hàm khiên	
func activate_shield():
	is_shielded = true
	queue_redraw() 
	
	await get_tree().create_timer(5.0).timeout #bật khiên 5 giây
	
	is_shielded = false
	queue_redraw() 
	
func _draw(): #vẽ tạm cái khiên ngu ngu nữa sửa sau
	if is_shielded == true:
		var shield_color = Color(0.2, 0.5, 1.0, 0.4)
		draw_circle(Vector2.ZERO, 60.0, shield_color)
		
		draw_arc(Vector2.ZERO, 60.0, 0, 2*PI, 30, Color(0.0, 0.8, 1.0), 3.0)
		
#item sách
func use_magic_book():
	print("Kích hoạt Sách Phép! Quét sạch quái vật!")
	
	var shockwave = Sprite2D.new() #vẽ đỡ hiệu ứng item sách nữa sửa sau
	# Lấy tạm hình tròn trắng
	shockwave.texture = preload("res://smoke_explosion/circle_32.png") 
	shockwave.modulate = Color(1.0, 0.8, 0.0, 0.8) 
	shockwave.global_position = global_position
	get_parent().add_child(shockwave)
	
	#phóng to vòng tròn ra gấp 100 lần trong 0.5 giây
	var tween = create_tween()
	tween.tween_property(shockwave, "scale", Vector2(100.0, 100.0), 0.5)
	#phóng xong ròi cho mờ dần
	tween.parallel().tween_property(shockwave, "modulate", Color(1.0, 0.8, 0.0, 0.0), 0.5)
	tween.tween_callback(shockwave.queue_free)
	
	var all_enemies = get_tree().get_nodes_in_group("enemies") #cho quái toàn màn hình chết hết
	for enemy in all_enemies:
		if enemy.has_method("die"):
			enemy.die()
