extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
#tao ky hieu tren dau quai
@onready var symbol_container = $SymbolContainer
@onready var slime_sprite = %Slime # Lấy hình ảnh con Slime để lát đổi màu

const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")

const AVAILABLE_SYMBOLS = ["-","|","v","^"]#danh sach ky hieu mai mot sua sau
var current_symbols = []

var is_fusing = false 

func _ready():
	%Slime.play_walk()
	generate_symbols()
	
func generate_symbols():
	var num_symbols = randi_range(1, 3)
	
	for i in range(num_symbols):
		var random_symbol = AVAILABLE_SYMBOLS.pick_random() #lấy ngẫu nhiên 1 ký hiệu 
		current_symbols.append(random_symbol) #lưu vào mảng vừa tạo
		
		var label = Label.new()
		label.text = random_symbol
		
		label.add_theme_font_size_override("font_size", 40)#chỉnh kích thước với màu kí hiệu nữa sửa sau
		label.add_theme_color_override("font_color", Color.BLACK)
		
		symbol_container.add_child(label)
	
func _physics_process(delta):
	if is_fusing == true: #đứng im nếu sắp nổ
		return 
	if is_instance_valid(player):
		var direction = global_position.direction_to(player.global_position)
		# Quái bom nặng nề nên đi chậm hơn (100 thay vì 250)
		velocity = direction * 150.0 
		move_and_slide()

func _on_hit_box_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body.has_method("take_damage"):
		body.take_damage()
		queue_free()
		
func check_symbol(drawn_symbol: String) -> bool: #cơ chế bị đánh của quái
	# Nếu quái không có ký hiệu nào, bỏ qua
	if current_symbols.is_empty():
		return false
	var symbol_index = current_symbols.find(drawn_symbol)
	if symbol_index != -1:
		
		current_symbols.remove_at(symbol_index)
		
		var label_to_remove = symbol_container.get_child(symbol_index)
		if is_instance_valid(label_to_remove):
			label_to_remove.queue_free()
			
		if current_symbols.is_empty():
			die()
		return true
	return false
func die():
	var smoke = SMOKE_SCENE.instantiate()
	smoke.global_position = global_position
	get_parent().add_child(smoke)
	queue_free()


func _on_explosion_zone_body_entered(body):
	if body.has_method("take_damage") and is_fusing == false:
		start_explosion()
		
func start_explosion():
	is_fusing = true
	queue_redraw() 
	#hiệu ứng nổ tạm thời nữa sửa
	var tween = create_tween().set_loops(4) 
	tween.tween_property(slime_sprite, "modulate", Color.RED, 0.2) 
	tween.tween_property(slime_sprite, "modulate", Color.WHITE, 0.2)
	
	#1.5 giây trc khi nổ
	await get_tree().create_timer(1.5).timeout
	explode()
	
func explode():
	var smoke = SMOKE_SCENE.instantiate()
	smoke.global_position = global_position
	smoke.scale = Vector2(2.0, 2.0) #làm cho cục khói to hơn
	get_parent().add_child(smoke)
	
	#quét xem ng chơi nó nằm trong vùng nổ ko
	var bodies_in_zone = $ExplosionZone.get_overlapping_bodies()
	for body in bodies_in_zone:
		if body.has_method("take_damage"):
			body.take_damage()
			
	queue_free()
	
func _draw(): #hien thi khu vuc nos
	if is_fusing == true:
		var radius = $ExplosionZone/CollisionShape2D.shape.radius
		var warning_color = Color(1.0, 0.0, 0.0, 0.3) 
		draw_circle(Vector2.ZERO, radius, warning_color)
