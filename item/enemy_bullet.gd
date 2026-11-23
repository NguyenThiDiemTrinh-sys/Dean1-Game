extends Area2D

var speed = 300.0
var direction = Vector2.ZERO

@export var max_distance = 700.0
var travelled_distance = 0.0      

func _physics_process(delta):
	var move_step = direction * speed * delta #tính độ dài đường đi của đạn để xét giới hạn
	position += move_step
	travelled_distance += move_step.length()
	if travelled_distance >= max_distance:
		queue_free()
	
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
		queue_free() 

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
