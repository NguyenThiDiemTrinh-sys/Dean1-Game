extends Node

const MENU_BGM = preload("res://audio/bgm/menu.mp3")
const BOSS_BGM = preload("res://audio/bgm/boss.mp3")
const DEAD_BGM = preload("res://audio/bgm/dead.mp3")
const VICTORY_BGM = preload("res://audio/bgm/victory.mp3")
const GAMEPLAY_BGM = preload("res://audio/bgm/gameplay.mp3")

var bgm_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -15.0
	add_child(bgm_player)

func play_bgm(music: AudioStream):
	if bgm_player.stream == music and bgm_player.playing:
		return

	bgm_player.stream = music
	bgm_player.play()

func stop_bgm():
	bgm_player.stop()
	
func play_gameplay():
	play_bgm(GAMEPLAY_BGM)
		
func play_victory():
	play_bgm(VICTORY_BGM)

func play_menu():
	play_bgm(MENU_BGM)

func play_boss():
	play_bgm(BOSS_BGM)

func play_dead():
	play_bgm(DEAD_BGM)
