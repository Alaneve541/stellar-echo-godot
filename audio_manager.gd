extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

var bgm_battle: AudioStream
var sfx = {}

var bgm_volume := 0.5
var sfx_volume := 0.5

const SETTINGS_FILE = "user://settings.json"

func _ready():
	print("=== AudioManager 启动 ===")

	load_settings()

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

	bgm_battle = load_audio_any("res://assets/sounds/battle_bgm")
	sfx["shoot"] = load_audio_any("res://assets/sounds/shoot")
	sfx["skill1"] = load_audio_any("res://assets/sounds/skill1")
	sfx["skill2"] = load_audio_any("res://assets/sounds/skill2")
	sfx["skill3"] = load_audio_any("res://assets/sounds/skill3")
	sfx["skill4"] = load_audio_any("res://assets/sounds/skill4")
	sfx["hit"] = load_audio_any("res://assets/sounds/hit")
	sfx["enemy_die"] = load_audio_any("res://assets/sounds/enemy_die")

	apply_volumes()

func load_audio_any(base_path: String) -> AudioStream:
	for ext in [".ogg", ".mp3", ".wav"]:
		var p = base_path + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null

func apply_volumes():
	if bgm_player:
		if bgm_volume <= 0:
			bgm_player.volume_db = -80
		else:
			bgm_player.volume_db = linear_to_db(bgm_volume)
	for p in sfx_players:
		if sfx_volume <= 0:
			p.volume_db = -80
		else:
			p.volume_db = linear_to_db(sfx_volume)

func set_bgm_volume(v: float):
	bgm_volume = clamp(v, 0.0, 1.0)
	apply_volumes()
	save_settings()

func set_sfx_volume(v: float):
	sfx_volume = clamp(v, 0.0, 1.0)
	apply_volumes()
	save_settings()

func save_settings():
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	var data = {"bgm": bgm_volume, "sfx": sfx_volume}
	file.store_string(JSON.stringify(data))
	file.close()

func load_settings():
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			bgm_volume = json.data.get("bgm", 0.5)
			sfx_volume = json.data.get("sfx", 0.5)

func play_bgm():
	if bgm_battle and bgm_player:
		bgm_player.stream = bgm_battle
		bgm_player.play()

func stop_bgm():
	if bgm_player:
		bgm_player.stop()

func play_sfx(sfx_name: String):
	if not sfx.has(sfx_name):
		return
	var stream = sfx[sfx_name]
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	sfx_players[0].stream = stream
	sfx_players[0].play()
