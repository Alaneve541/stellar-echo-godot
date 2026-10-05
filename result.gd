extends Control

@onready var score_label = $ScoreLabel

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$RestartBtn.pressed.connect(_on_restart)
	$LogoutBtn.pressed.connect(_on_logout)

	var stats = GameStats.last_run
	score_label.text = (
		"本局等级: " + str(stats.get("level", 1)) +
		"\n本局波次: " + str(stats.get("wave", 0)) +
		"\n本局击杀: " + str(stats.get("kills", 0)) +
		"\n本局经验: " + str(stats.get("exp", 0)) +
		"\n\n最高波次: " + str(stats.get("highest_wave", 0)) +
		"\n总击杀数: " + str(stats.get("total_kills", 0))
	)

func _on_restart():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_logout():
	Account.save_player_data(GameStats.last_run)
	Inventory.clear()
	get_tree().change_scene_to_file("res://MainMenu.tscn")
