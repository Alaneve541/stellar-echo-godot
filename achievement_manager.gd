extends Node

const ACHIEVEMENTS = {
	"kill_10":    {"name": "初出茅庐", "desc": "累计击杀 10 个敌人", "type": "kills", "target": 10},
	"kill_50":    {"name": "小有名气", "desc": "累计击杀 50 个敌人", "type": "kills", "target": 50},
	"kill_100":   {"name": "百人斩",   "desc": "累计击杀 100 个敌人", "type": "kills", "target": 100},
	"kill_500":   {"name": "杀戮机器", "desc": "累计击杀 500 个敌人", "type": "kills", "target": 500},
	"wave_5":     {"name": "初战告捷", "desc": "到达第 5 波", "type": "wave", "target": 5},
	"wave_10":    {"name": "百战之躯", "desc": "到达第 10 波", "type": "wave", "target": 10},
	"wave_20":    {"name": "无尽征途", "desc": "到达第 20 波", "type": "wave", "target": 20},
	"level_5":    {"name": "崭露头角", "desc": "等级达到 5 级", "type": "level", "target": 5},
	"level_10":   {"name": "身经百战", "desc": "等级达到 10 级", "type": "level", "target": 10},
	"level_20":   {"name": "传说战士", "desc": "等级达到 20 级", "type": "level", "target": 20},
	"legendary":  {"name": "欧皇附体", "desc": "获得一件传说装备", "type": "special", "target": 1},
}

var unlocked := {}

func _ready():
	pass

func load_achievements():
	if Account.current_user == "":
		unlocked = {}
		return
	var data = Account.get_player_data()
	if data.size() > 0:
		unlocked = data.get("achievements", {}).duplicate()
	else:
		unlocked = {}
	print("加载成就: ", unlocked.size(), " 个已解锁")

func save_achievements():
	if Account.current_user == "":
		return
	Account.accounts[Account.current_user]["achievements"] = unlocked
	Account.save_accounts()

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

func check_achievement(id: String) -> bool:
	if is_unlocked(id):
		return false
	if not ACHIEVEMENTS.has(id):
		return false
	unlocked[id] = true
	save_achievements()
	print(">>> 成就解锁: ", ACHIEVEMENTS[id]["name"])
	return true

func check_kills(total_kills: int):
	for id in ACHIEVEMENTS:
		var a = ACHIEVEMENTS[id]
		if a["type"] == "kills" and total_kills >= a["target"]:
			check_achievement(id)

func check_wave(wave: int):
	for id in ACHIEVEMENTS:
		var a = ACHIEVEMENTS[id]
		if a["type"] == "wave" and wave >= a["target"]:
			check_achievement(id)

func check_level(level: int):
	for id in ACHIEVEMENTS:
		var a = ACHIEVEMENTS[id]
		if a["type"] == "level" and level >= a["target"]:
			check_achievement(id)

func check_legendary():
	check_achievement("legendary")

func get_all() -> Dictionary:
	return ACHIEVEMENTS

func get_unlocked() -> Dictionary:
	return unlocked
