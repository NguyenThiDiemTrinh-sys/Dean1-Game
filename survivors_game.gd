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
@onready var dungeon_map= $DungeonMap
@onready var boss_timer = $BossTimer
@onready var boss_progress_bar = $UI/BossProgressBar

var is_drawing = false
var stroke_points = [] #mảng lưu trữ toạ độ của nét vẽ
var kill_count = 0 #đếm số quái chết để spawn item
var is_boss_fight = false # Dùng để tắt rớt item khi đang đánh Boss

func _ready():
	AudioManager.play_gameplay()
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
	AudioManager.play_dead()
	is_drawing = false
	stroke_points.clear()
	draw_line.clear_points()
	
	game_over_screen.show()
	spawn_timer.stop()
	boss_timer.stop()
	get_tree().paused = true

func _on_spawn_timer_timeout():
	var spawn_count = randi_range(1, 3)

	for i in range(spawn_count):
		var spawn_pos = find_spawn_position()

		if spawn_pos == null:
			continue

		var available_mobs = [
			normal_mob_scene,
			normal_mob_scene,
			normal_mob_scene,
			ranged_mob_scene,
			ranged_mob_scene,
			bomber_mob_scene
		]

		var selected_mob_scene = available_mobs.pick_random()
		var new_mob = selected_mob_scene.instantiate()

		new_mob.position = to_local(spawn_pos)
		new_mob.mob_died.connect(_on_mob_died)

		add_child(new_mob)


func _on_retry_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _input(event): #hàm để vẽ 
	#Thêm 2 hàng fix lỗi chết vẫn vẽ được. 
	if get_tree().paused == true or not is_instance_valid(player):
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: #bấm chuột trái bắt đầu vẽ
		if event.pressed == true:
			is_drawing = true
			stroke_points.clear() 
			draw_line.clear_points() 
			stroke_points.append(event.position)
			draw_line.add_point(event.position)
			
		elif event.pressed == false:
			is_drawing = false
			stroke_points.append(event.position)
			
			# kiểm tra độ dài nét vẽ tránh click nhầm
			if stroke_points.size() >= 3:
				var symbol = recognize_gesture(stroke_points)
				
				if symbol != "":
					if is_instance_valid(player):
						player.attack(symbol) 
					
			draw_line.clear_points()

	#Ghi lại điểm vẽ
	elif event is InputEventMouseMotion and is_drawing == true:
		stroke_points.append(event.position) 
		draw_line.add_point(event.position)
		
func recognize_gesture(points: Array) -> String:
	if points.size() < 3:
		return ""
		
	var p_start = points[0]
	var p_end = points[points.size() - 1]
	
	# Tìm khung bao quanh nét vẽ
	var min_x = p_start.x; var max_x = p_start.x
	var min_y = p_start.y; var max_y = p_start.y
	
	for p in points:
		if p.x < min_x: min_x = p.x
		if p.x > max_x: max_x = p.x
		if p.y < min_y: min_y = p.y
		if p.y > max_y: max_y = p.y
		
	var dx = max_x - min_x
	var dy = max_y - min_y
	
	# Chống click nhầm (nếu quẹt ngắn dưới 25px thì bỏ qua)
	if dx < 25 and dy < 25:
		return ""
		
	# Đo độ võng xuống cho chữ "v" (đáy max_y phải thấp hơn hẳn CẢ điểm đầu và điểm cuối)
	var v_depth = min(max_y - p_start.y, max_y - p_end.y)
	
	# Đo độ nhọn lên cho dấu "^" (đỉnh min_y phải cao hơn hẳn CẢ điểm đầu và điểm cuối)
	var caret_height = min(p_start.y - min_y, p_end.y - min_y)
	
	# Ngưỡng gấp khúc tối thiểu (giúp phân biệt chữ v/^ thật với nét thẳng vẽ hơi run tay)
	var min_bend = max(20.0, max(dx, dy) * 0.25)
	
	# 1. Kiểm tra chữ V và dấu Mũ TRƯỚC (bất kể vẽ hẹp, rộng hay lệch cạnh vẫn trúng!)
	if v_depth >= min_bend and v_depth > caret_height:
		return "v"
	elif caret_height >= min_bend and caret_height > v_depth:
		return "^"
		
	# 2. Nếu không gấp khúc -> Nó là nét thẳng (- hoặc |)
	if dx >= dy:
		return "-"
	else:
		return "|"

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

func is_valid_spawn_position(world_pos: Vector2) -> bool:
	var cell = dungeon_map.local_to_map(
		dungeon_map.to_local(world_pos))

	var tile_data = dungeon_map.get_cell_tile_data(cell)

	# Không có tile: nằm ngoài bản đồ
	if tile_data == null:
		return false

	# Tile có collision: không được sinh quái
	if tile_data.get_collision_polygons_count(0) > 0:
		return false
	return true
	
func find_spawn_position() -> Variant:
	var max_attempts = 30
	var spawn_distance = 1000.0

	for i in range(max_attempts):
		var angle = randf() * TAU
		var direction = Vector2.RIGHT.rotated(angle)

		var spawn_pos = player.global_position \
			+ direction * spawn_distance

		if is_valid_spawn_position(spawn_pos):
			return spawn_pos

	return null
  
func _on_summon_book_picked_up() -> void:
	AudioManager.play_boss()
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
	AudioManager.play_victory()
	print("CHIẾN THẮNG! Đã hạ gục Boss!")
	await get_tree().create_timer(0.8, false).timeout
	
	# Kiểm tra chắc chắn người chơi không bị chết đúng vào 0.8 giây đó
	if not get_tree().paused and is_instance_valid(player) and player.health > 0:
		is_drawing = false
		stroke_points.clear()
		draw_line.clear_points()
		victory_screen.show()
		get_tree().paused = true


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
