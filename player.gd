extends CharacterBody3D

@export var speed := 8.0
@export var jump_velocity := 6.0
@export var mouse_sensitivity := 0.003

var gravity := 15.0
var base_max_hp := 100
var base_atk := 15
var max_hp := 100
var hp := 100
var exp_value := 0
var level := 1
var kills := 0
var attack_cd := 0.0

var skill_cd = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
var skill_cd_max = {1: 1.5, 2: 2.0, 3: 3.0, 4: 5.0}
var skill_levels = {1: 1, 2: 1, 3: 1, 4: 1}
const SKILL_MAX_LEVEL := 10

var info_label = null
var skill_label = null

var shop_panel = null
var shop_msg = null

var upgrade_panel = null
var upgrade_msg = null

var ach_panel = null
var ach_list = null
var ach_msg = null

var inv_panel = null
var inv_bag_label = null
var inv_equip_label = null
var inv_msg = null

var dq_panel = null
var dq_msg = null

@onready var camera := $Camera3D
@onready var ray := $Camera3D/RayCast3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var data = Account.get_player_data()
	if data.size() > 0:
		level = int(data.get("level", 1))
		exp_value = int(data.get("exp", 0))
		base_max_hp = int(data.get("max_hp", 100))
		base_atk = int(data.get("atk", 15))
		var sl = data.get("skill_levels", {})
		for k in sl:
			var key = int(k)
			if skill_levels.has(key):
				skill_levels[key] = int(sl[k])

	recalc_stats()
	hp = max_hp

	AudioManager.play_bgm()
	DailyQuest.load_quests()

	info_label = get_tree().get_root().find_child("InfoLabel", true, false)
	skill_label = get_tree().get_root().find_child("SkillLabel", true, false)

	shop_panel = get_tree().get_root().find_child("ShopPanel", true, false)
	shop_msg = get_tree().get_root().find_child("MsgLabel", true, false)

	upgrade_panel = get_tree().get_root().find_child("SkillUpgradePanel", true, false)
	upgrade_msg = get_tree().get_root().find_child("UpgradeMsgLabel", true, false)

	ach_panel = get_tree().get_root().find_child("AchievementPanel", true, false)
	ach_list = get_tree().get_root().find_child("ListLabel", true, false)
	ach_msg = get_tree().get_root().find_child("AchMsgLabel", true, false)

	inv_panel = get_tree().get_root().find_child("InventoryPanel", true, false)
	inv_bag_label = get_tree().get_root().find_child("BagLabel", true, false)
	inv_equip_label = get_tree().get_root().find_child("EquipLabel", true, false)
	inv_msg = get_tree().get_root().find_child("InvMsgLabel", true, false)

	dq_panel = get_tree().get_root().find_child("DailyQuestPanel", true, false)
	dq_msg = get_tree().get_root().find_child("QuestMsgLabel", true, false)

	if shop_panel:
		shop_panel.visible = false
		ShopBtnConnect()
	if upgrade_panel:
		upgrade_panel.visible = false
		UpgradeBtnConnect()
	if ach_panel:
		ach_panel.visible = false
		AchBtnConnect()
	if inv_panel:
		inv_panel.visible = false
		InvBtnConnect()
	if dq_panel:
		dq_panel.visible = false
		DQBtnConnect()

	update_hud()

# ================= 背包面板 =================
func InvBtnConnect():
	if inv_panel == null:
		return
	var close = inv_panel.get_node_or_null("CloseBtn")
	if close:
		close.pressed.connect(toggle_inv)

func toggle_inv():
	if inv_panel == null:
		return
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible:
		close_all_panels(inv_panel)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_inv_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_inv_ui():
	if inv_panel == null:
		return
	if inv_bag_label:
		inv_bag_label.text = Inventory.get_text()
	if inv_equip_label:
		inv_equip_label.text = Inventory.get_equip_text()
	if inv_msg:
		inv_msg.text = "按 E 一键穿戴背包内所有装备"

# ================= 商店 =================
func ShopBtnConnect():
	var ids = [
		"eq_sword_common", "eq_armor_common", "eq_helmet_common",
		"eq_boots_common", "eq_ring_common", "eq_necklace_common",
	]
	for i in range(ids.size()):
		var btn = shop_panel.get_node_or_null("Item" + str(i + 1) + "Btn")
		if btn:
			var item_id = ids[i]
			btn.pressed.connect(func(): _try_buy(item_id))
	var close = shop_panel.get_node_or_null("CloseBtn")
	if close:
		close.pressed.connect(toggle_shop)

func _try_buy(item_id: String):
	if Inventory.buy(item_id):
		if shop_msg:
			shop_msg.text = "购买成功: " + Inventory.equipment_data[item_id]["name"]
	else:
		if shop_msg:
			shop_msg.text = "材料不足"

func toggle_shop():
	if shop_panel == null:
		return
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		close_all_panels(shop_panel)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_shop_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_shop_ui():
	if shop_panel == null:
		return
	var ids = [
		"eq_sword_common", "eq_armor_common", "eq_helmet_common",
		"eq_boots_common", "eq_ring_common", "eq_necklace_common",
	]
	for i in range(ids.size()):
		var btn = shop_panel.get_node_or_null("Item" + str(i + 1) + "Btn")
		if btn:
			btn.text = Inventory.get_shop_text(ids[i])
	if shop_msg:
		shop_msg.text = ""

# ================= 技能升级 =================
func UpgradeBtnConnect():
	for i in range(1, 5):
		var btn = upgrade_panel.get_node_or_null("Skill" + str(i) + "Btn")
		if btn:
			var key = i
			btn.pressed.connect(func(): _try_upgrade(key))
	var close = upgrade_panel.get_node_or_null("CloseBtn")
	if close:
		close.pressed.connect(toggle_upgrade)

func upgrade_cost(skill_key: int) -> int:
	return 10 * skill_levels[skill_key]

func _try_upgrade(skill_key: int):
	if skill_levels[skill_key] >= SKILL_MAX_LEVEL:
		if upgrade_msg:
			upgrade_msg.text = "技能已满级"
		return
	var cost = upgrade_cost(skill_key)
	if exp_value < cost:
		if upgrade_msg:
			upgrade_msg.text = "经验不足，需要 " + str(cost) + " 经验"
		return
	exp_value -= cost
	skill_levels[skill_key] += 1
	DailyQuest.add_progress("spend", cost)
	if upgrade_msg:
		upgrade_msg.text = "升级成功！技能 " + str(skill_key) + " → Lv." + str(skill_levels[skill_key])
	update_hud()
	update_upgrade_ui()

func toggle_upgrade():
	if upgrade_panel == null:
		return
	upgrade_panel.visible = not upgrade_panel.visible
	if upgrade_panel.visible:
		close_all_panels(upgrade_panel)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_upgrade_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_upgrade_ui():
	if upgrade_panel == null:
		return
	var names = ["重击", "散射", "回复", "爆发"]
	for i in range(1, 5):
		var btn = upgrade_panel.get_node_or_null("Skill" + str(i) + "Btn")
		if btn:
			var lv = skill_levels[i]
			if lv >= SKILL_MAX_LEVEL:
				btn.text = str(i) + " " + names[i-1] + "  Lv." + str(lv) + "  (满级)"
			else:
				var cost = upgrade_cost(i)
				btn.text = (
					str(i) + " " + names[i-1] +
					"  Lv." + str(lv) + " → Lv." + str(lv + 1) +
					"  消耗 " + str(cost) + " 经验"
				)
	if upgrade_msg:
		upgrade_msg.text = ""

# ================= 成就 =================
func AchBtnConnect():
	var close = ach_panel.get_node_or_null("CloseBtn")
	if close:
		close.pressed.connect(toggle_ach)

func toggle_ach():
	if ach_panel == null:
		return
	ach_panel.visible = not ach_panel.visible
	if ach_panel.visible:
		close_all_panels(ach_panel)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_ach_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_ach_ui():
	if ach_panel == null or ach_list == null:
		return
	var text = ""
	var all = AchievementManager.get_all()
	for id in all:
		var a = all[id]
		var done = AchievementManager.is_unlocked(id)
		if done:
			text += "[已解锁] " + a["name"] + "  —  " + a["desc"] + "\n"
		else:
			text += "[未解锁] " + a["name"] + "  —  " + a["desc"] + "\n"
	ach_list.text = text
	if ach_msg:
		ach_msg.text = ""

# ================= 每日任务 =================
func DQBtnConnect():
	for i in range(1, 4):
		var btn = dq_panel.get_node_or_null("Quest" + str(i) + "Btn")
		if btn:
			var idx = i - 1
			btn.pressed.connect(func(): _try_claim_quest(idx))
	var close = dq_panel.get_node_or_null("CloseBtn")
	if close:
		close.pressed.connect(toggle_dq)

func _try_claim_quest(idx: int):
	var quests = DailyQuest.get_quests()
	if idx < 0 or idx >= quests.size():
		return
	var q = quests[idx]
	if DailyQuest.claim(q, self):
		if dq_msg:
			dq_msg.text = "领取成功: " + q["desc"]
		update_dq_ui()
	else:
		if dq_msg:
			if DailyQuest.is_claimed(q):
				dq_msg.text = "该任务已领取"
			else:
				dq_msg.text = "任务未完成"

func toggle_dq():
	if dq_panel == null:
		return
	dq_panel.visible = not dq_panel.visible
	if dq_panel.visible:
		close_all_panels(dq_panel)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_dq_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_dq_ui():
	if dq_panel == null:
		return
	var quests = DailyQuest.get_quests()
	for i in range(1, 4):
		var btn = dq_panel.get_node_or_null("Quest" + str(i) + "Btn")
		if btn == null:
			continue
		if i - 1 >= quests.size():
			btn.text = ""
			btn.disabled = true
			continue
		var q = quests[i - 1]
		var prog = DailyQuest.get_progress(q["id"])
		var status = ""
		if DailyQuest.is_claimed(q):
			status = "已领取"
		elif DailyQuest.is_completed(q):
			status = "可领取"
		else:
			status = "进行中"
		btn.text = (
			q["desc"] + "\n" +
			"进度: " + str(prog) + "/" + str(q["target"]) +
			"   奖励: " + str(q["reward_exp"]) + "经验 + " +
			Inventory.get_mat_name(q["reward_mat"]) + " x" + str(q["reward_count"]) +
			"   [" + status + "]"
		)
	if dq_msg:
		dq_msg.text = ""

# ================= 面板互斥 =================
func close_all_panels(except_panel):
	if shop_panel and shop_panel != except_panel:
		shop_panel.visible = false
	if upgrade_panel and upgrade_panel != except_panel:
		upgrade_panel.visible = false
	if ach_panel and ach_panel != except_panel:
		ach_panel.visible = false
	if inv_panel and inv_panel != except_panel:
		inv_panel.visible = false
	if dq_panel and dq_panel != except_panel:
		dq_panel.visible = false

func is_any_panel_open() -> bool:
	if shop_panel and shop_panel.visible:
		return true
	if upgrade_panel and upgrade_panel.visible:
		return true
	if ach_panel and ach_panel.visible:
		return true
	if inv_panel and inv_panel.visible:
		return true
	if dq_panel and dq_panel.visible:
		return true
	return false

# ================= 技能效果 =================
func skill_damage_mult(skill_key: int) -> float:
	return 1.0 + 0.2 * (skill_levels[skill_key] - 1)

func skill_cd_mult(skill_key: int) -> float:
	return max(0.3, 1.0 - 0.05 * (skill_levels[skill_key] - 1))

func get_skill_cd(key: int) -> float:
	return skill_cd_max[key] * skill_cd_mult(key)

# ================= 通用 =================
func recalc_stats():
	var bonus = Inventory.get_bonus()
	max_hp = base_max_hp + bonus["hp"]
	if hp > max_hp:
		hp = max_hp

func get_atk() -> int:
	var bonus = Inventory.get_bonus()
	return base_atk + bonus["atk"]

func update_hud():
	if info_label:
		info_label.text = (
			"Lv." + str(level) +
			"  HP: " + str(hp) + "/" + str(max_hp) +
			"  ATK: " + str(get_atk()) +
			"  EXP: " + str(exp_value) +
			"  击杀: " + str(kills)
		)

	if skill_label:
		var names = ["重击", "散射", "回复", "爆发"]
		var text = ""
		for i in range(4):
			var k = i + 1
			var lv = skill_levels[k]
			if skill_cd[k] > 0:
				text += str(k) + " " + names[i] + " Lv." + str(lv) + "(" + str(snapped(skill_cd[k], 0.1)) + "s)  "
			else:
				text += str(k) + " " + names[i] + " Lv." + str(lv) + "(就绪)  "
		skill_label.text = text + "\nE 背包   B 商店   U 技能升级   J 成就   K 每日任务"

func take_damage(dmg):
	hp -= dmg
	if hp < 0:
		hp = 0
	update_hud()
	if hp <= 0:
		die()

func add_kill():
	kills += 1
	update_hud()
	var data = Account.get_player_data()
	var total = data.get("total_kills", 0) + kills
	AchievementManager.check_kills(total)
	DailyQuest.add_progress("kills", 1)

func add_exp(amount):
	exp_value += amount
	if exp_value >= 100:
		exp_value -= 100
		level += 1
		base_max_hp += 20
		base_atk += 5
		recalc_stats()
		hp = max_hp
		AchievementManager.check_level(level)
	update_hud()

func equip_first():
	var equipped_any = false
	var to_equip = []
	for id in Inventory.get_items():
		if Inventory.is_equipment(id):
			to_equip.append(id)
	for id in to_equip:
		if Inventory.equip(id):
			equipped_any = true
			if id.ends_with("_legendary"):
				AchievementManager.check_legendary()
	if equipped_any:
		recalc_stats()
		hp = max_hp
		update_hud()
		update_inv_ui()
	else:
		if inv_msg:
			inv_msg.text = "背包里没有可穿戴的装备"

func die():
	AudioManager.stop_bgm()
	var wave = 0
	var wm = get_tree().get_root().find_child("WaveManager", true, false)
	if wm:
		wave = wm.wave
	AchievementManager.check_wave(wave)
	DailyQuest.set_progress("wave", wave)
	GameStats.update(level, exp_value, base_max_hp, 0, wave, kills)
	Leaderboard.submit(Account.current_user, wave, kills, level)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Result.tscn")

func save_and_logout():
	AudioManager.stop_bgm()
	var sl_str = {"1": skill_levels[1], "2": skill_levels[2], "3": skill_levels[3], "4": skill_levels[4]}
	Account.save_player_data({
		"level": level,
		"exp": exp_value,
		"max_hp": base_max_hp,
		"atk": base_atk,
		"wins": kills,
		"skill_levels": sl_str
	})
	Inventory.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Login.tscn")

func attack():
	if attack_cd > 0:
		return
	if is_any_panel_open():
		return
	attack_cd = 0.3
	AudioManager.play_sfx("shoot")

	if ray and ray.is_colliding():
		var target = ray.get_collider()
		if target == null:
			return
		if not is_instance_valid(target):
			return
		if target.has_method("take_damage"):
			target.take_damage(get_atk())

func use_skill(key):
	if skill_cd[key] > 0:
		return
	if is_any_panel_open():
		return

	var mult = skill_damage_mult(key)

	if key == 1:
		if exp_value < 10:
			return
		exp_value -= 10
		skill_cd[1] = get_skill_cd(1)
		AudioManager.play_sfx("skill1")
		DailyQuest.add_progress("spend", 10)
		DailyQuest.add_progress("skills", 1)
		if ray and ray.is_colliding():
			var target = ray.get_collider()
			if target != null and is_instance_valid(target) and target.has_method("take_damage"):
				target.take_damage(int(get_atk() * 2 * mult))

	elif key == 2:
		if exp_value < 8:
			return
		exp_value -= 8
		skill_cd[2] = get_skill_cd(2)
		AudioManager.play_sfx("skill2")
		DailyQuest.add_progress("spend", 8)
		DailyQuest.add_progress("skills", 1)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 5:
				if enemy.has_method("take_damage"):
					enemy.take_damage(int(get_atk() / 2 * mult))

	elif key == 3:
		if exp_value < 15:
			return
		exp_value -= 15
		skill_cd[3] = get_skill_cd(3)
		AudioManager.play_sfx("skill3")
		DailyQuest.add_progress("spend", 15)
		DailyQuest.add_progress("skills", 1)
		var heal = int(randi_range(20, 35) * mult)
		hp = min(hp + heal, max_hp)

	elif key == 4:
		if exp_value < 25:
			return
		exp_value -= 25
		skill_cd[4] = get_skill_cd(4)
		AudioManager.play_sfx("skill4")
		DailyQuest.add_progress("spend", 25)
		DailyQuest.add_progress("skills", 1)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 10:
				if enemy.has_method("take_damage"):
					enemy.take_damage(int(get_atk() * 3 * mult))

	update_hud()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if camera == null:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attack()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			use_skill(1)
		elif event.keycode == KEY_2:
			use_skill(2)
		elif event.keycode == KEY_3:
			use_skill(3)
		elif event.keycode == KEY_4:
			use_skill(4)
		elif event.keycode == KEY_E:
			if inv_panel and inv_panel.visible:
				equip_first()
			else:
				toggle_inv()
		elif event.keycode == KEY_B:
			toggle_shop()
		elif event.keycode == KEY_U:
			toggle_upgrade()
		elif event.keycode == KEY_J:
			toggle_ach()
		elif event.keycode == KEY_K:
			toggle_dq()
		elif event.keycode == KEY_ESCAPE:
			if is_any_panel_open():
				if shop_panel and shop_panel.visible:
					toggle_shop()
				elif upgrade_panel and upgrade_panel.visible:
					toggle_upgrade()
				elif ach_panel and ach_panel.visible:
					toggle_ach()
				elif inv_panel and inv_panel.visible:
					toggle_inv()
				elif dq_panel and dq_panel.visible:
					toggle_dq()
			else:
				save_and_logout()

func _physics_process(delta):
	if attack_cd > 0:
		attack_cd -= delta

	for k in skill_cd:
		if skill_cd[k] > 0:
			skill_cd[k] -= delta

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	if is_any_panel_open():
		velocity.x = 0
		velocity.z = 0
	else:
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	update_hud()
