extends CanvasLayer

# Danh sách 4 Video hướng dẫn (sau này chỉ cần kéo 4 file .ogv vào đây ở Inspector!)
@export var page_videos: Array[VideoStream] = []

# Danh sách 4 dòng chữ hướng dẫn bên dưới từng trang
@export_multiline var page_texts: Array[String] = [
	"Dùng các phím W, A, S, D để di chuyển.",
	"Giữ chuột trái và vẽ 4 ký hiệu (- | v ^) để tiêu diệt quái vật.",
	"Nhấn giữ phím Shift trong lúc di chuyển để chạy nhanh hơn.",
	"Nhặt vật phẩm hỗ trợ để sinh tồn."
]

@onready var description_label: Label = find_child("DescriptionLabel", true, false)
@onready var prev_button: Button = find_child("PrevButton", true, false)
@onready var next_button: Button = find_child("NextButton", true, false)
@onready var dots_container: HBoxContainer = find_child("DotsContainer", true, false)
@onready var skip_button: Button = find_child("SkipButton", true, false)

var video_player: VideoStreamPlayer = null
var current_page = 0

func _ready() -> void:
	get_tree().paused = true
	
	# Tự động tìm node VideoStreamPlayer bên trong Tutorial (bất kể bạn đặt tên gì)
	video_player = find_video_player(self)
	if video_player != null:
		video_player.expand = true 
		video_player.loop = true   # Phát lặp lại liên tục
	
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	create_page_dots()
	update_page()

# Hàm phụ tìm node VideoStreamPlayer
func find_video_player(node: Node) -> VideoStreamPlayer:
	for child in node.get_children():
		if child is VideoStreamPlayer:
			return child
		var found = find_video_player(child)
		if found != null:
			return found
	return null

func create_page_dots() -> void:
	for child in dots_container.get_children():
		child.queue_free()
		
	for i in range(page_texts.size()):
		var dot = Panel.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", style)
		
		dots_container.add_child(dot)

# Cập nhật video, chữ, chấm tròn và nút < > mỗi khi chuyển trang
func update_page() -> void:
	description_label.text = page_texts[current_page]
	
	if video_player != null and current_page < page_videos.size() and page_videos[current_page] != null:
		video_player.stop()
		video_player.stream = page_videos[current_page]
		video_player.play()
		
	for i in range(dots_container.get_child_count()):
		var dot = dots_container.get_child(i)
		if i == current_page:
			dot.modulate = Color(1.0, 0.85, 0.2, 1.0) # Sáng vàng
		else:
			dot.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Xám mờ
			
	prev_button.disabled = (current_page == 0)
	next_button.disabled = (current_page == page_texts.size() - 1)

func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_page()

func _on_next_pressed() -> void:
	if current_page < page_texts.size() - 1:
		current_page += 1
		update_page()

func _on_skip_pressed() -> void:
	get_tree().paused = false
	queue_free()
