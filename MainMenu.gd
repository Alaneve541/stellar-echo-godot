extends Control

var settings_panel = null
var leaderboard_panel = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	$StartBtn.pressed.connect(_on_start)
	$SettingsBtn.pressed.connect(_on_settings)
	$ExitBtn.pressed.connect(_on_exit)

	var lb_btn = get_node_or_null("LeaderboardBtn")
	if lb_btn:
		lb_btn.pressed.connect(_on_leaderboard)

	Account.logout()
	Inventory.clear()

	settings_panel = get_node_or_null("SettingsPanel")
	if settings_panel:
		settings_panel.visible = false
		connect_settings()

	leaderboard_panel = get_node_or_null("LeaderboardPanel")
	if leaderboard_panel:
		leaderboard_panel.visible = false
		var close = leaderboard_panel.get_node_or_null("CloseBtn")
		if close:
			close.pressed.connect(_on_leaderboard_close)

func _on_leaderboard():
	if leaderboard_panel == null:
		return
	leaderboard_panel.visible = true
	if settings_panel:
		settings_panel.visible = false
	var list = leaderboard_panel.get_node_or_null("ListLabel")
	if list:
		list.text = Leaderboard.get_text()

func _on_leaderboard_close():
	if leaderboard_panel:
		leaderboard_panel.visible = false

func connect_settings():
	var bgm_slider = settings_panel.get_node_or_null("BGMSlider")
	var sfx_slider = settings_panel.get_node_or_null("SFXSlider")
	var close_btn = settings_panel.get_node_or_null("CloseBtn")

	if bgm_slider:
		bgm_slider.value = AudioManager.bgm_volume
		bgm_slider.value_changed.connect(_on_bgm_changed)
	if sfx_slider:
		sfx_slider.value = AudioManager.sfx_volume
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if close_btn:
		close_btn.pressed.connect(_on_settings_close)

func _on_bgm_changed(value: float):
	AudioManager.set_bgm_volume(value)

func _on_sfx_changed(value: float):
	AudioManager.set_sfx_volume(value)
	AudioManager.play_sfx("shoot")

func _on_settings():
	if settings_panel:
		settings_panel.visible = true
	if leaderboard_panel:
		leaderboard_panel.visible = false

func _on_settings_close():
	if settings_panel:
		settings_panel.visible = false

func _on_start():
	get_tree().change_scene_to_file("res://Login.tscn")

func _on_exit():
	get_tree().quit()
