extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("use_magic_book"):
		body.use_magic_book()
		queue_free()
