extends Node2D

var mob_scene = preload("res://mob.tscn")

@onready var health_label = $UI/HealthLabel
@onready var game_over_screen = $GameOver
@onready var spawn_timer = $SpawnTimer
@onready var player = $Player

@onready var draw_line = $UI/DrawLine
var is_drawing = false
var stroke_points = [] #mảng lưu trữ toạ độ của nét vẽ

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
	
	var random_angle = randf() * 2.0 * PI
	var spawn_distance = 800.0 
	
	var direction = Vector2.RIGHT.rotated(random_angle)
	var spawn_pos = player.global_position + (direction * spawn_distance)
	
	new_mob.global_position = spawn_pos
	add_child(new_mob)


func _on_retry_button_pressed():
	get_tree().reload_current_scene()

func _input(event): #hàm để vẽ 
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
					print("Bạn vừa vẽ hình: ", symbol) # In ra Output để dễ test
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
