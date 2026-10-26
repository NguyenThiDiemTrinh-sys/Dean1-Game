extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Kiểm tra xem thứ vừa chạm vào có phải là người chơi không 
	if body.has_method("heal"):
		var is_healed = body.heal() #nếu hàm heal là true thì hồi máu
		queue_free()
