extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("Có vật gì đó vừa chạm vào Khiên: ", body.name)
	if body.has_method("activate_shield"):
		body.activate_shield()
		queue_free() 
