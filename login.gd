extends Control

@onready var user_input = $UserInput
@onready var pwd_input = $PwdInput
@onready var msg_label = $BackLabel

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$LoginBtn.pressed.connect(_on_login)
	$RegisterBtn.pressed.connect(_on_register)
	$BackBtn.pressed.connect(_on_back)
	msg_label.text = ""

func _on_back():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_login():
	var u = user_input.text.strip_edges()
	var p = pwd_input.text.strip_edges()

	if u == "" or p == "":
		msg_label.text = "账号和密码不能为空"
		return

	if Account.login(u, p):
		msg_label.text = "登录成功"
		var data = Account.get_player_data()
		Inventory.load_items(data.get("inventory", {}))
		AchievementManager.load_achievements()
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		msg_label.text = "账号或密码错误"

func _on_register():
	var u = user_input.text.strip_edges()
	var p = pwd_input.text.strip_edges()

	if u == "" or p == "":
		msg_label.text = "账号和密码不能为空"
		return
	if u.length() < 3:
		msg_label.text = "账号至少3个字符"
		return
	if p.length() < 6:
		msg_label.text = "密码至少6位"
		return

	if Account.register(u, p):
		msg_label.text = "注册成功，请登录"
	else:
		msg_label.text = "账号已存在"
