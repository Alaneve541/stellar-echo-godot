extends Node

const SAVE_FILE = "user://accounts.json"

var accounts := {}
var current_user := ""

func _ready():
	load_accounts()

func load_accounts():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			accounts = json.data
	print("加载账号: ", accounts.size(), " 个")

func save_accounts():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(accounts, "  "))
	file.close()

func register(username: String, password: String) -> bool:
	if accounts.has(username):
		return false
	accounts[username] = {
		"password": password,
		"level": 1,
		"exp": 0,
		"max_hp": 100,
		"atk": 15,
		"wins": 0,
		"highest_wave": 0,
		"total_kills": 0,
		"inventory": {},
		"skill_levels": {"1": 1, "2": 1, "3": 1, "4": 1},
		"achievements": {},
		"daily_quest": {}
	}
	save_accounts()
	return true

func login(username: String, password: String) -> bool:
	if not accounts.has(username):
		return false
	if accounts[username]["password"] != password:
		return false
	current_user = username
	return true

func save_player_data(data: Dictionary):
	if current_user == "":
		return
	accounts[current_user]["level"] = data.get("level", 1)
	accounts[current_user]["exp"] = data.get("exp", 0)
	accounts[current_user]["max_hp"] = data.get("max_hp", 100)
	accounts[current_user]["atk"] = data.get("atk", 15)
	accounts[current_user]["wins"] = data.get("wins", 0)
	accounts[current_user]["inventory"] = Inventory.get_items()
	accounts[current_user]["skill_levels"] = data.get("skill_levels", {"1": 1, "2": 1, "3": 1, "4": 1})
	save_accounts()

func update_record(wave: int, kills: int):
	if current_user == "":
		return
	if wave > accounts[current_user].get("highest_wave", 0):
		accounts[current_user]["highest_wave"] = wave
	accounts[current_user]["total_kills"] = accounts[current_user].get("total_kills", 0) + kills
	save_accounts()

func get_player_data() -> Dictionary:
	if current_user == "":
		return {}
	return accounts[current_user]

func logout():
	current_user = ""
