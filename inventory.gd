extends Node

var items := {}
var equipped := {}

var base_equipment = {
	"eq_sword":   {"name": "能量剑",   "slot": "weapon", "atk": 10, "hp": 0},
	"eq_armor":   {"name": "合金护甲", "slot": "armor",  "atk": 0,  "hp": 30},
	"eq_helmet":  {"name": "星尘头盔", "slot": "helmet", "atk": 3,  "hp": 15},
	"eq_boots":   {"name": "疾风战靴", "slot": "boots",  "atk": 2,  "hp": 10},
	"eq_ring":    {"name": "虚空之戒", "slot": "ring",   "atk": 5,  "hp": 5},
	"eq_necklace":{"name": "星辰项链", "slot": "necklace","atk": 8, "hp": 20},
}

var quality_data = {
	"common":    {"name": "普通", "mult": 1.0, "weight": 60},
	"rare":      {"name": "稀有", "mult": 1.5, "weight": 25},
	"epic":      {"name": "史诗", "mult": 2.0, "weight": 12},
	"legendary": {"name": "传说", "mult": 3.0, "weight": 3},
}

var equipment_data = {}

var shop_data = {
	"eq_sword_common":    {"cost": {"mat_core": 3, "mat_chip": 2}},
	"eq_armor_common":    {"cost": {"mat_crystal": 3, "mat_gear": 2}},
	"eq_helmet_common":   {"cost": {"mat_core": 2, "mat_crystal": 2}},
	"eq_boots_common":    {"cost": {"mat_chip": 4, "mat_gear": 3}},
	"eq_ring_common":     {"cost": {"mat_crystal": 5, "mat_core": 3}},
	"eq_necklace_common": {"cost": {"mat_core": 5, "mat_crystal": 5, "mat_gear": 5}},
}

var mat_names = {
	"mat_core": "能量核心",
	"mat_chip": "机械芯片",
	"mat_crystal": "虚空水晶",
	"mat_gear": "齿轮零件",
}

func _ready():
	build_equipment_data()

func build_equipment_data():
	equipment_data.clear()
	for base_id in base_equipment:
		var base = base_equipment[base_id]
		for q_key in quality_data:
			var q = quality_data[q_key]
			var full_id = base_id + "_" + q_key
			equipment_data[full_id] = {
				"name": q["name"] + " " + base["name"],
				"slot": base["slot"],
				"atk": int(base["atk"] * q["mult"]),
				"hp": int(base["hp"] * q["mult"]),
				"quality": q_key,
				"base_id": base_id,
			}

func random_quality() -> String:
	var total = 0
	for q in quality_data:
		total += quality_data[q]["weight"]
	var r = randi() % total
	var acc = 0
	for q in quality_data:
		acc += quality_data[q]["weight"]
		if r < acc:
			return q
	return "common"

func random_equipment_id() -> String:
	var base_ids = base_equipment.keys()
	var base_id = base_ids[randi() % base_ids.size()]
	var quality = random_quality()
	return base_id + "_" + quality

func add_item(id: String, item_name: String, count: int = 1):
	if items.has(id):
		items[id]["count"] += count
	else:
		items[id] = {"name": item_name, "count": count}
	print("背包 +", item_name, " x", count)

func get_items():
	return items

func clear():
	items.clear()
	equipped.clear()

func load_items(data: Dictionary):
	items = data.duplicate(true)

func is_equipment(id: String) -> bool:
	return equipment_data.has(id)

func equip(id: String) -> bool:
	if not items.has(id):
		return false
	if not is_equipment(id):
		return false
	var slot = equipment_data[id]["slot"]
	equipped[slot] = id
	print("穿戴: ", equipment_data[id]["name"])
	return true

func get_bonus() -> Dictionary:
	var atk_bonus = 0
	var hp_bonus = 0
	for slot in equipped:
		var id = equipped[slot]
		if equipment_data.has(id):
			atk_bonus += equipment_data[id]["atk"]
			hp_bonus += equipment_data[id]["hp"]
	return {"atk": atk_bonus, "hp": hp_bonus}

func can_buy(item_id: String) -> bool:
	if not shop_data.has(item_id):
		return false
	var cost = shop_data[item_id]["cost"]
	for mat_id in cost:
		if not items.has(mat_id):
			return false
		if items[mat_id]["count"] < cost[mat_id]:
			return false
	return true

func buy(item_id: String) -> bool:
	if not can_buy(item_id):
		return false
	var cost = shop_data[item_id]["cost"]
	for mat_id in cost:
		items[mat_id]["count"] -= cost[mat_id]
		if items[mat_id]["count"] <= 0:
			items.erase(mat_id)
	var equip = equipment_data[item_id]
	add_item(item_id, equip["name"], 1)
	print("购买成功: ", equip["name"])
	return true

func get_text() -> String:
	if items.size() == 0:
		return "空"
	var t = ""
	for id in items:
		t += items[id]["name"] + " x" + str(items[id]["count"]) + "  "
	return t

func get_equip_text() -> String:
	if equipped.size() == 0:
		return "无"
	var t = ""
	for slot in equipped:
		var id = equipped[slot]
		if equipment_data.has(id):
			t += equipment_data[id]["name"] + "  "
	return t

func get_shop_text(item_id: String) -> String:
	if not shop_data.has(item_id):
		return ""
	var data = shop_data[item_id]
	var equip = equipment_data.get(item_id, {})

	var t = equip.get("name", item_id)
	if equip.size() > 0:
		t += "  (ATK+" + str(equip.get("atk", 0)) + " HP+" + str(equip.get("hp", 0)) + ")\n"
	else:
		t += "\n"

	t += "  需要: "
	for mat_id in data["cost"]:
		t += get_mat_name(mat_id) + " x" + str(data["cost"][mat_id]) + "  "
	return t

func get_mat_name(mat_id: String) -> String:
	return mat_names.get(mat_id, mat_id)
