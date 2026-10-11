extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
#tao ky hieu tren dau quai
@onready var symbol_container = $SymbolContainer

const AVAILABLE_SYMBOLS = ["-","|","v","^"]#danh sach ky hieu mai mot sua sau

var current_symbols = []

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
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * 250.0
	move_and_slide()
	
