extends Node

const QUEST_POOL = [
	{"id": "kill_20",  "desc": "击杀 20 个敌人",    "type": "kills",   "target": 20,   "reward_exp": 80, "reward_mat": "mat_chip",  "reward_count": 2},
	{"id": "kill_50",  "desc": "击杀 50 个敌人",    "type": "kills",   "target": 50,   "reward_exp": 150, "reward_mat": "mat_core", "reward_count": 3},
	{"id": "wave_5",   "desc": "到达第 5 波",       "type": "wave",    "target": 5,    "reward_exp": 60,  "reward_mat": "mat_gear", "reward_count": 2},
	{"id": "wave_8",   "desc": "到达第 8 波",       "type": "wave",    "target": 8,    "reward_exp": 120, "reward_mat": "mat_crystal", "reward_count": 2},
	{"id": "skill_10", "desc": "使用 10 次技能",    "type": "skills",  "target": 10,   "reward_exp": 70,  "reward_mat": "mat_chip",  "reward_count": 3},
	{"id": "loot_5",   "desc": "获得 5 件装备",     "type": "loot",    "target": 5,    "reward_exp": 100, "reward_mat": "mat_core",  "reward_count": 2},
	{"id": "spend_50", "desc": "消耗 50 点经验",    "type": "spend",   "target": 50,   "reward_exp": 80,  "reward_mat": "mat_gear",  "reward_count": 3},
]

var today := ""
var quests := []   # 当前 3 个任务
var progress := {} # { quest_id: 当前进度 }
var claimed := {}  # { quest_id: true }

func _ready():
	pass

func get_today() -> String:
	var d = Time.get_date_dict_from_system()
	return str(d["year"]) + "-" + str(d["month"]) + "-" + str(d["day"])

func load_quests():
	if Account.current_user == "":
		return
	var data = Account.get_player_data()
	var saved = data.get("daily_quest", {})

	today = get_today()

	# 如果日期不对，刷新
	if saved.get("date", "") != today:
		refresh_quests()
		return

	# 读存档
	quests = saved.get("quests", [])
	progress = saved.get("progress", {})
	claimed = saved.get("claimed", {})
	if quests.size() == 0:
		refresh_quests()

func refresh_quests():
	quests = []
	progress = {}
	claimed = {}
	var pool = QUEST_POOL.duplicate()
	pool.shuffle()
	for i in range(min(3, pool.size())):
		quests.append(pool[i])
		progress[pool[i]["id"]] = 0
	save_quests()
	print("每日任务已刷新: ", quests.size(), " 个")

func save_quests():
	if Account.current_user == "":
		return
	Account.accounts[Account.current_user]["daily_quest"] = {
		"date": today,
		"quests": quests,
		"progress": progress,
		"claimed": claimed
	}
	Account.save_accounts()

func add_progress(quest_type: String, amount: int):
	if Account.current_user == "":
		return
	for q in quests:
		if q["type"] != quest_type:
			continue
		var id = q["id"]
		if claimed.get(id, false):
			continue
		progress[id] = progress.get(id, 0) + amount
		if progress[id] >= q["target"]:
			progress[id] = q["target"]
	save_quests()

func set_progress(quest_type: String, value: int):
	# 用于 wave 这种取最大值的类型
	if Account.current_user == "":
		return
	for q in quests:
		if q["type"] != quest_type:
			continue
		var id = q["id"]
		if claimed.get(id, false):
			continue
		if value > progress.get(id, 0):
			progress[id] = value
		if progress[id] > q["target"]:
			progress[id] = q["target"]
	save_quests()

func is_completed(q: Dictionary) -> bool:
	return progress.get(q["id"], 0) >= q["target"]

func is_claimed(q: Dictionary) -> bool:
	return claimed.get(q["id"], false)

func can_claim(q: Dictionary) -> bool:
	return is_completed(q) and not is_claimed(q)

func claim(q: Dictionary, player) -> bool:
	if not can_claim(q):
		return false
	claimed[q["id"]] = true

	# 给奖励
	if player and player.has_method("add_exp"):
		player.add_exp(q["reward_exp"])
	Inventory.add_item(q["reward_mat"], Inventory.get_mat_name(q["reward_mat"]), q["reward_count"])

	save_quests()
	print("领取奖励: ", q["desc"], "  经验+", q["reward_exp"])
	return true

func get_quests() -> Array:
	return quests

func get_progress(id: String) -> int:
	return progress.get(id, 0)
