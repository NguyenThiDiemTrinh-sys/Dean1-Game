extends Area2D

var speed = 300.0
var direction = Vector2.ZERO

<<<<<<< Updated upstream
func _physics_process(delta):
	position += direction * speed * delta
=======
@export var max_distance = 700.0
var travelled_distance = 0.0      
var is_explosive = false

func _physics_process(delta):
	var move_step = direction * speed * delta #tính độ dài đường đi của đạn để xét giới hạn
	position += move_step
	travelled_distance += move_step.length()
	if travelled_distance >= max_distance:
		if is_explosive:
			split_explode()
		queue_free()
>>>>>>> Stashed changes
	
func split_explode():#hàm cho đạn nổ
	var bullet_scene = load("res://item/enemy_bullet.tscn")
	for i in range(6):
		var small_bullet = bullet_scene.instantiate()
		small_bullet.global_position = global_position
		var angle = i * (2.0 * PI / 6.0)
		small_bullet.direction = Vector2.RIGHT.rotated(angle)
		small_bullet.speed = 380.0
		small_bullet.max_distance = 800.0
		small_bullet.scale = Vector2(1.4, 1.4)
		get_parent().add_child(small_bullet)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
		queue_free() 

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
	
