extends Node2D

var normal_mob_scene = preload("res://characters/mob.tscn")
var ranged_mob_scene = preload("res://characters/ranged_mob.tscn") 
var bomber_mob_scene = preload("res://characters/bomber_mob.tscn")
var boss_scene = preload("res://characters/boss.tscn")
#item
var item_heart_scene = preload("res://item/item_heart.tscn")
var item_shield_scene = preload("res://item/item_shield.tscn")
var item_book_scene = preload("res://item/item_book.tscn")

@onready var health_label = $UI/HealthLabel
@onready var game_over_screen = $GameOver
@onready var victory_screen = $Victory
@onready var spawn_timer = $SpawnTimer
@onready var player = $Player
@onready var draw_line = $UI/DrawLine
@onready var boss_timer = $BossTimer
@onready var boss_progress_bar = $UI/BossProgressBar

var is_drawing = false
var stroke_points = [] #mảng lưu trữ toạ độ của nét vẽ
var kill_count = 0 #đếm số quái chết để spawn item
var is_boss_fight = false # Dùng để tắt rớt item khi đang đánh Boss

func _ready():
	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)
	# thanh đếm thời gian
	boss_progress_bar.max_value = boss_timer.wait_time
	boss_progress_bar.step = 0.01
	boss_progress_bar.value = 0.0
	
func _process(delta):
	if not is_boss_fight and not boss_timer.is_stopped():
		boss_progress_bar.value = boss_timer.wait_time - boss_timer.time_left
	
func _on_player_health_changed(new_health):
	var hearts_text = ""
	for i in range(new_health):
		hearts_text += "❤" 
	health_label.text = hearts_text
	
func _on_player_died():
	game_over_screen.show()
	spawn_timer.stop()
	boss_timer.stop()
	get_tree().paused = true

func _on_spawn_timer_timeout():
	var spawn_count = randi_range(1, 3)
	
	for i in range(spawn_count):
		
		var available_mobs = [normal_mob_scene, normal_mob_scene, normal_mob_scene, ranged_mob_scene, ranged_mob_scene,bomber_mob_scene]
		var selected_mob_scene = available_mobs.pick_random()
		
		var new_mob = selected_mob_scene.instantiate()
		
		var random_angle = randf() * 2.0 * PI
		var spawn_distance = 1000.0 
		
		var direction = Vector2.RIGHT.rotated(random_angle)
		var spawn_pos = player.global_position + (direction * spawn_distance)
		
		new_mob.global_position = spawn_pos
		new_mob.mob_died.connect(_on_mob_died) 
		add_child(new_mob)


func _on_retry_button_pressed():
	get_tree().reload_current_scene()

func _input(event): #hàm để vẽ 
	#Thêm 2 hàng fix lỗi chết vẫn vẽ được. 
	if not is_instance_valid(player):
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: #bấm chuột trái bắt đầu vẽ
		if event.pressed == true:
			is_drawing = true
			stroke_points.clear() 
			draw_line.clear_points() 
			
		elif event.pressed == false:
			is_drawing = false
			
			# kiểm tra độ dài nét vẽ tránh click nhầm
			if stroke_points.size() > 5:
				var symbol = recognize_gesture(stroke_points)
				
				if symbol != "":
					if is_instance_valid(player):
						player.attack(symbol) 
					
			draw_line.clear_points()

	#Ghi lại điểm vẽ
	elif event is InputEventMouseMotion and is_drawing == true:
		stroke_points.append(event.position) 
		draw_line.add_point(event.position)
		
func recognize_gesture(points: Array) -> String:#thuật toán nhận diện
	# Tìm ra khung chữ nhật bao quanh nét vẽ (Điểm xa nhất các hướng)
	var min_x = points[0].x; var max_x = points[0].x
	var min_y = points[0].y; var max_y = points[0].y
	var min_y_index = 0; var max_y_index = 0
	
	for i in range(points.size()):
		var p = points[i]
		if p.x < min_x: min_x = p.x
		if p.x > max_x: max_x = p.x
		if p.y < min_y:
			min_y = p.y; min_y_index = i 
		if p.y > max_y:
			max_y = p.y; max_y_index = i 
			
	# Tính chiều rộng (dx) và chiều cao (dy) của nét vẽ
	var dx = max_x - min_x
	var dy = max_y - min_y
	
	if dx < 30 and dy < 30: 
		return ""

	# THUẬT TOÁN ĐỌC HÌNH:
	# Nếu chiều Rộng lớn hơn chiều Cao gấp rưỡi -> Đó là nét Ngang
	if dx > dy * 1.5:
		return "-"
		
	# Nếu chiều Cao lớn hơn chiều Rộng gấp rưỡi -> Đó là nét Dọc
	elif dy > dx * 1.5:
		return "|"
		
	# Nếu Rộng và Cao sàn sàn nhau -> Nó là chữ V hoặc Dấu Mũ
	else:
		var total_points = points.size()
		# Nếu cái đáy (điểm thấp nhất max_y) nằm ở khúc GIỮA nét vẽ -> Chữ V
		if max_y_index > total_points * 0.2 and max_y_index < total_points * 0.8:
			return "v"
		# Nếu cái đỉnh (điểm cao nhất min_y) nằm ở khúc GIỮA nét vẽ -> Dấu Mũ ^
		elif min_y_index > total_points * 0.2 and min_y_index < total_points * 0.8:
			return "^"
			
	return ""

func _on_mob_died(death_position): #đếm số lượng quái để spawn item
	if is_boss_fight == true:
		return
	kill_count += 1 
	if kill_count % 10 == 0:
		drop_random_item(death_position)

func drop_random_item(drop_pos):

	var available_items = [
		item_heart_scene, item_heart_scene, 
		item_shield_scene, item_shield_scene, 
		item_book_scene
	]
	
	var selected_item_scene = available_items.pick_random() #lấy item ngẫu nhiên
	
	var new_item = selected_item_scene.instantiate() #tạo item bỏ vào chỗ báo con quái chết
	new_item.global_position = drop_pos
	call_deferred("add_child", new_item)


func _on_boss_timer_timeout() -> void:
	print("=== ĐÃ ĐỦ THỜI GIAN: NGỪNG SPAWN QUÁI & HIỆN SÁCH TRIỆU HỒI! ===")
	
	boss_progress_bar.value = boss_progress_bar.max_value
	spawn_timer.stop()
	is_boss_fight = true
	
	if is_instance_valid(player):
		var summon_book = item_book_scene.instantiate()
		summon_book.global_position = player.global_position + Vector2(0, -180)
		summon_book.make_attract_mode() # Bật hiệu ứng to, chớp sáng & chữ vàng
		
		summon_book.book_picked_up.connect(_on_summon_book_picked_up)
		add_child(summon_book)

func _on_summon_book_picked_up() -> void:
	print("=== ĐÃ CHẠM SÁCH! QUÉT SẠCH QUÁI & BOSS XUẤT HIỆN! ===")
	boss_progress_bar.hide()
	
	if is_instance_valid(player):
		var camera = player.get_node_or_null("Camera2D")
		if is_instance_valid(camera):
			var cam_tween = create_tween()
			cam_tween.tween_property(camera, "zoom", Vector2(0.35, 0.35), 1.5).set_trans(Tween.TRANS_SINE)
			
		var new_boss = boss_scene.instantiate()
		new_boss.global_position = player.global_position + Vector2(0, -1200)
		new_boss.boss_defeated.connect(_on_boss_defeated)
		
		call_deferred("add_child", new_boss)

func _on_boss_defeated():
	print("CHIẾN THẮNG! Đã hạ gục Boss!")
	await get_tree().create_timer(0.8, false).timeout
	
	# Kiểm tra chắc chắn người chơi không bị chết đúng vào 0.8 giây đó
	if not get_tree().paused and is_instance_valid(player) and player.health > 0:
		is_drawing = false
		stroke_points.clear()
		draw_line.clear_points()
		victory_screen.show()
		get_tree().paused = true
