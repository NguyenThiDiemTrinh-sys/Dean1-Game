extends Control

func _ready() -> void:
	AudioManager.play_menu()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_setting_pressed() -> void:
	print("Đã bấm Setting (Chức năng đang phát triển!)") #để tạm nữa sửa sau
