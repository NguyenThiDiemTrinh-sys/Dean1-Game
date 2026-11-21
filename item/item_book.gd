extends Area2D

signal book_picked_up # Báo tin khi quyển sách này được nhặt

# Hàm biến sách thành Sách Triệu Hồi thu hút người chơi
func make_attract_mode():
	# 1. Phóng to quyển sách lên 1.5 lần cho nổi bật
	scale = Vector2(1.5, 1.5)
	
	# 2. Tạo vòng lặp Tween làm sách đập nhịp (to-nhỏ) và chớp sáng vàng thu hút (nữa sửa lại)
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.9, 1.9), 0.45).set_trans(Tween.TRANS_SINE)
	pulse_tween.parallel().tween_property(self, "modulate", Color(1.4, 1.4, 0.5, 1.0), 0.45)
	pulse_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.45).set_trans(Tween.TRANS_SINE)
	pulse_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.45)
	
	# 3. Thêm dòng chữ vàng phía trên để người chơi nhìn là muốn chạy tới chạm ngay
	var hint_label = Label.new()
	hint_label.text = "CHẠM VÀO ĐÂY, CÓ QUÀ!"
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color.FIREBRICK)
	hint_label.position = Vector2(-85, -55)
	add_child(hint_label)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("use_magic_book"):
		body.use_magic_book()
		book_picked_up.emit()
		queue_free()
