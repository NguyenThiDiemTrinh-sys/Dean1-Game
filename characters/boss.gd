extends CharacterBody2D

signal boss_defeated

const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")
const NORMAL_MOB = preload("res://characters/mob.tscn")
const RANGED_MOB = preload("res://characters/ranged_mob.tscn")
const BOMBER_MOB = preload("res://characters/bomber_mob.tscn")
const BULLET_SCENE = preload("res://item/enemy_bullet.tscn")

@onready var player = get_node("/root/Game/Player")
@onready var symbol_container = $SymbolContainer
@onready var slime_sprite = %Slime

const AVAILABLE_SYMBOLS = ["-", "|", "v", "^"]
var current_symbols = []

# Định nghĩa 3 trạng thái của Boss bằng enum
enum State { PHASE_1, PHASE_2, PHASE_3 }
var current_state = State.PHASE_1

enum MoveState { CHASE, WINDUP, DASH } #3 trang thai di chuyen cua boss
var move_state = MoveState.CHASE
var action_timer = 2.0
var dash_direction = Vector2.ZERO

var chase_speed = 280.0
var dash_speed = 1100.0
# boss khong bi tan cong khi con quai nho
var is_invulnerable = false
var minions_alive = 0

# Biến cho chiêu Tia Laser ở Trạng thái 3
enum LaserState { NONE, WARNING, FIRING }
var laser_state = LaserState.NONE
var laser_direction = Vector2.ZERO

func _ready():
	%Slime.play_walk()
	generate_symbols(6)

func _physics_process(delta):
	if not is_instance_valid(player):
		return
		
	if current_state == State.PHASE_3:
		velocity = Vector2.ZERO
		if laser_state == LaserState.FIRING: #kiểm tra player có đứng trong vùng của laser không
			var start_pos = global_position
			var end_pos = global_position + laser_direction * 2500.0
			var closest_point = Geometry2D.get_closest_point_to_segment(player.global_position, start_pos, end_pos)
			if player.global_position.distance_to(closest_point) <= 100.0:
				player.take_damage()
		return
	action_timer -= delta
	match move_state:
		MoveState.CHASE:
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * chase_speed
			move_and_slide()
			
			if action_timer <= 0:
				move_state = MoveState.WINDUP
				action_timer = 0.45
				dash_direction = global_position.direction_to(player.global_position)
				queue_redraw() #ve duong mau do chi huong sap lao toi
				
		MoveState.WINDUP:
			velocity = Vector2.ZERO
			
			if action_timer <= 0:
				move_state = MoveState.DASH
				action_timer = 0.55
				queue_redraw() 
				
		MoveState.DASH:
			velocity = dash_direction * dash_speed
			move_and_slide()
			
			if action_timer <= 0:
				move_state = MoveState.CHASE
				action_timer = 3.0

func _draw():#ve do khien cho boss khi con quai nho vs duong canh bao, tia laser (nua sua sau)
	if is_invulnerable:
		draw_arc(Vector2.ZERO, 45.0, 0, 2 * PI, 40, Color(1.0, 0.85, 0.0, 0.9), 2.5)
		
	if move_state == MoveState.WINDUP and current_state != State.PHASE_3:
		draw_line(Vector2.ZERO, dash_direction * 150.0, Color(1.0, 0.15, 0.15, 0.35), 55.0)
		
	if current_state == State.PHASE_3:
		if laser_state == LaserState.WARNING:
			draw_line(Vector2.ZERO, laser_direction * 500.0, Color(1.0, 0.1, 0.1, 0.35), 40.0)
			draw_line(Vector2.ZERO, laser_direction * 500.0, Color(1.0, 0.2, 0.2, 0.8), 4.0)
		elif laser_state == LaserState.FIRING:
			draw_line(Vector2.ZERO, laser_direction * 500.0, Color(1.0, 0.15, 0.3, 0.9), 40.0)
			draw_line(Vector2.ZERO, laser_direction * 500.0, Color(1.0, 1.0, 0.9, 1.0), 16.0)

func clear_symbol_container():
	for child in symbol_container.get_children():
		symbol_container.remove_child(child)
		child.queue_free()

func generate_symbols(amount: int):
	clear_symbol_container()
	current_symbols.clear()
	for i in range(amount):
		var random_symbol = AVAILABLE_SYMBOLS.pick_random()
		current_symbols.append(random_symbol)
		
		var label = Label.new()
		label.text = random_symbol
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_color_override("font_color", Color.BLACK)
		symbol_container.add_child(label)

func check_symbol(drawn_symbol: String) -> bool:
	if is_invulnerable or current_symbols.is_empty():# boss khong bi tan cong khi con quai nho
		return false
		
	var symbol_index = current_symbols.find(drawn_symbol)
	if symbol_index != -1:
		current_symbols.remove_at(symbol_index)
		
		var label_to_remove = symbol_container.get_child(symbol_index)
		if is_instance_valid(label_to_remove):
			symbol_container.remove_child(label_to_remove)
			label_to_remove.queue_free()
			
		if current_symbols.is_empty():
			advance_phase()
		return true
	return false

#Hàm chuyển phase 
func advance_phase():
	if current_state == State.PHASE_1:
		current_state = State.PHASE_2
		print("=== BOSS CHUYỂN SANG TRẠNG THÁI 2 ===")
		slime_sprite.modulate = Color(0.9, 0.3, 0.9) #doi mau khi chuyen phase (nua sua sau)
		start_phase_2()
		
	elif current_state == State.PHASE_2:
		current_state = State.PHASE_3
		print("=== BOSS CHUYỂN SANG TRẠNG THÁI 3 ===")
		slime_sprite.modulate = Color(1.0, 0.2, 0.2) #doi mau khi chuyen phase (nua sua sau)
		move_state = MoveState.CHASE
		queue_redraw()
		generate_symbols(6)
		start_phase_3_loop()
		
	elif current_state == State.PHASE_3:
		die()

# logic phase 2
func start_phase_2():
	is_invulnerable = true
	current_symbols.clear()
	minions_alive = 5
	update_shield_status_text()
	queue_redraw()
	
	var mob_pool = [NORMAL_MOB, RANGED_MOB, BOMBER_MOB]
	for i in range(5):
		var minion = mob_pool.pick_random().instantiate()
		var angle = i * (2.0 * PI / 5.0)
		minion.global_position = global_position + Vector2.RIGHT.rotated(angle) * 320.0
		minion.tree_exited.connect(_on_minion_exited)
		get_parent().add_child(minion)
		
#Phase 3
func start_phase_3_loop():
	await get_tree().create_timer(1.0, false).timeout
	
	while is_inside_tree() and current_state == State.PHASE_3:
		# CHIÊU 1: Bắn 3 dãy đạn dài (mỗi dãy 5 viên)
		await skill_bullet_rows()
		if not is_inside_tree() or current_state != State.PHASE_3: return
		await get_tree().create_timer(2.0, false).timeout # Nghỉ 2 giây
		if not is_inside_tree() or current_state != State.PHASE_3: return
		
		# CHIÊU 2: Bắn lần lượt 5 viên đạn nổ to
		await skill_exploding_bullets()
		if not is_inside_tree() or current_state != State.PHASE_3: return
		await get_tree().create_timer(2.0, false).timeout # Nghỉ 2 giây
		if not is_inside_tree() or current_state != State.PHASE_3: return
		
		# CHIÊU 3: Cảnh báo đỏ 3 giây rồi bắn tia Laser to
		await skill_laser()
		if not is_inside_tree() or current_state != State.PHASE_3: return
		await get_tree().create_timer(2.0, false).timeout # Nghỉ 2 giây

# Hàm chiêu 1
func skill_bullet_rows():
	if not is_instance_valid(player): return
	var base_direction = global_position.direction_to(player.global_position)
	var angles = [-0.3, 0.0, 0.3]
	
	for row in range(5):
		if not is_inside_tree() or not is_instance_valid(player): return
		for angle in angles:
			var bullet = BULLET_SCENE.instantiate()
			bullet.global_position = global_position
			bullet.direction = base_direction.rotated(angle)
			bullet.speed = 520.0
			bullet.max_distance = 1600.0 
			bullet.scale = Vector2(1.6, 1.6)
			get_parent().add_child(bullet)
		await get_tree().create_timer(0.14, false).timeout

# Hàm chiêu 2
func skill_exploding_bullets():
	for i in range(5):
		if not is_inside_tree() or not is_instance_valid(player): return
		var bullet = BULLET_SCENE.instantiate()
		bullet.global_position = global_position
		bullet.direction = global_position.direction_to(player.global_position)
		bullet.is_explosive = true 
		bullet.scale = Vector2(2.8, 2.8)
		bullet.modulate = Color(1.0, 0.6, 0.0) #có vẽ lại đạn thì sửa đoạn này
		bullet.speed = 450.0
		bullet.max_distance = 650.0
		get_parent().add_child(bullet)
		await get_tree().create_timer(0.45, false).timeout

# hàm chiêu 3
func skill_laser():
	if not is_instance_valid(player): return
	laser_direction = global_position.direction_to(player.global_position)
	laser_state = LaserState.WARNING
	queue_redraw()
	
	await get_tree().create_timer(2.0, false).timeout #khoá hướng ng chơi trong 2s
	if not is_inside_tree() or current_state != State.PHASE_3: return
	
	#bắn tia laser trong 0.7s
	laser_state = LaserState.FIRING
	queue_redraw()
	await get_tree().create_timer(0.7, false).timeout
	if not is_inside_tree(): return
	
	laser_state = LaserState.NONE
	queue_redraw()

func update_shield_status_text():
	clear_symbol_container()
	var info_label = Label.new()
	symbol_container.add_child(info_label)

func _on_minion_exited():
	# Chống lỗi khi cả màn chơi bị xóa lúc bấm Retry
	if not is_inside_tree():
		return
		
	minions_alive -= 1
	if minions_alive > 0:
		update_shield_status_text()
	elif minions_alive <= 0 and is_invulnerable:
		is_invulnerable = false
		queue_redraw()
		generate_symbols(6)
		print("=== ĐÃ DIỆT HẾT QUÁI CON! BOSS HẾT BẤT TỬ! ===")

func die():
	print("=== BOSS ĐÃ BỊ TIÊU DIỆT! ===")
	var smoke = SMOKE_SCENE.instantiate()
	smoke.global_position = global_position
	smoke.scale = Vector2(4.0, 4.0) # Nổ làn khói cực to
	get_parent().add_child(smoke)
	
	boss_defeated.emit()
	queue_free()

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
