extends CharacterBody3D

@export var speed := 2.0
@export var player_path: NodePath
@export var enemy_type := "melee"

var player: Node3D
var gravity := 15.0

var max_hp := 60
var hp := 60
var atk := 8
var attack_cd := 0.0
var is_boss := false
var dead := false

var boss_panel = null
var boss_fill = null

var shoot_cd := 0.0
const SHOOT_INTERVAL := 1.5
const SHOOT_RANGE := 10.0
const KEEP_DIST := 6.0

var bomb_triggered := false

# Boss 技能冷却
var skill_timer := 5.0
var current_skill := 0
var boss_phase := 1

# 冲锋状态
var charging := false
var charge_dir := Vector3.ZERO
var charge_timer := 0.0
const CHARGE_DURATION := 0.6
const CHARGE_SPEED := 18.0

const BulletScript = preload("res://bullet.gd")
const BoomScript = preload("res://boom.gd")
const EnemyScene = preload("res://enemy.tscn")

@onready var hp_label = $Label3D

func _ready():
	add_to_group("enemies")

	apply_type()

	if player_path:
		player = get_node_or_null(player_path)
	if player == null:
		player = get_tree().get_root().find_child("Player", true, false)

	apply_color()
	update_hp()

func setup_boss():
	is_boss = true
	boss_panel = get_tree().get_root().find_child("BossPanel", true, false)
	boss_fill = get_tree().get_root().find_child("HPBarFill", true, false)
	if boss_panel:
		boss_panel.visible = true
	apply_color()
	update_hp()

func apply_type():
	if is_boss:
		return
	match enemy_type:
		"fast":
			speed = 5.0
		"ranged":
			speed = 1.5
		"bomber":
			speed = 3.5
		_:
			pass

func apply_color():
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	var mat = StandardMaterial3D.new()
	var c = Color(1, 0.24, 0.24)
	match enemy_type:
		"fast":
			c = Color(0.95, 0.77, 0.06)
		"ranged":
			c = Color(0.61, 0.35, 0.71)
		"bomber":
			c = Color(0.90, 0.49, 0.13)
		_:
			c = Color(1, 0.24, 0.24)
	if is_boss:
		c = Color(0.55, 0, 0)
	mat.albedo_color = c
	mesh.material_override = mat

func update_hp():
	if hp_label and is_instance_valid(hp_label):
		if is_boss:
			hp_label.text = "BOSS  " + str(hp) + "/" + str(max_hp)
		else:
			hp_label.text = str(hp) + "/" + str(max_hp)

	if is_boss and boss_fill and is_instance_valid(boss_fill):
		var ratio = float(hp) / float(max_hp)
		boss_fill.size.x = 600 * ratio
		if boss_panel:
			boss_panel.visible = true

func take_damage(dmg):
	if dead:
		return
	hp -= dmg
	if hp < 0:
		hp = 0
	AudioManager.play_sfx("hit")
	update_hp()
	if hp <= 0:
		dead = true
		AudioManager.play_sfx("enemy_die")
		if is_boss and boss_panel:
			boss_panel.visible = false
		drop_loot()
		give_exp()
		give_kill()
		queue_free()
	elif is_boss:
		# 血量低于 50% 进入二阶段
		if hp < max_hp / 2 and boss_phase == 1:
			boss_phase = 2
			speed *= 1.3
			print("Boss 进入二阶段！")

# ================= Boss 技能 =================
func boss_use_skill(my_pos: Vector3, ppos: Vector3):
	current_skill += 1
	if current_skill > 4:
		current_skill = 1

	match current_skill:
		1:
			boss_skill_shockwave(my_pos)
		2:
			boss_skill_summon(my_pos)
		3:
			boss_skill_charge(my_pos, ppos)
		4:
			boss_skill_barrage(my_pos, ppos)

func boss_skill_shockwave(my_pos: Vector3):
	print("Boss 技能: 范围爆炸")
	if player and is_instance_valid(player) and player.is_inside_tree():
		var p_pos = player.global_position
		var dist_2d = Vector2(my_pos.x - p_pos.x, my_pos.z - p_pos.z).length()
		if dist_2d < 8.0:
			if player.has_method("take_damage"):
				player.take_damage(int(atk * 1.5))

	# 爆炸特效
	var boom = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	boom.mesh = sphere
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(1, 0.2, 0.2, 0.8)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.emission_enabled = true
	bmat.emission = Color(1, 0.2, 0.2)
	bmat.emission_energy_multiplier = 3.0
	boom.material_override = bmat
	boom.set_script(BoomScript)
	get_tree().current_scene.add_child(boom)
	boom.global_position = my_pos + Vector3(0, 1, 0)

func boss_skill_summon(my_pos: Vector3):
	print("Boss 技能: 召唤小怪")
	for i in range(2):
		var e = EnemyScene.instantiate()
		var angle = randf() * TAU
		var dist = 4.0
		e.position = Vector3(my_pos.x + cos(angle) * dist, 1, my_pos.z + sin(angle) * dist)
		e.enemy_type = "fast"
		get_tree().current_scene.add_child(e)
		e.max_hp = 40
		e.hp = 40
		e.atk = 8
		if e.has_method("update_hp"):
			e.update_hp()

func boss_skill_charge(my_pos: Vector3, ppos: Vector3):
	print("Boss 技能: 冲锋")
	var dir = ppos - my_pos
	dir.y = 0
	if dir.length() < 0.1:
		return
	charge_dir = dir.normalized()
	charging = true
	charge_timer = CHARGE_DURATION

func boss_skill_barrage(my_pos: Vector3, ppos: Vector3):
	print("Boss 技能: 弹幕")
	var base_dir = ppos - my_pos
	base_dir.y = 0
	if base_dir.length() < 0.1:
		return
	base_dir = base_dir.normalized()
	var base_angle = atan2(base_dir.z, base_dir.x)

	for i in range(8):
		var a = base_angle + (i - 3.5) * 0.25
		var dir = Vector3(cos(a), 0, sin(a))

		var bullet = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.2
		sphere.height = 0.4
		bullet.mesh = sphere

		var bmat = StandardMaterial3D.new()
		bmat.albedo_color = Color(1, 0.3, 0.3)
		bmat.emission_enabled = true
		bmat.emission = Color(1, 0.3, 0.3)
		bmat.emission_energy_multiplier = 2.5
		bullet.material_override = bmat

		bullet.set_script(BulletScript)
		bullet.dir = dir
		bullet.damage = int(atk * 0.6)
		bullet.target_player = player

		get_tree().current_scene.add_child(bullet)
		bullet.global_position = my_pos + Vector3(0, 1.5, 0)

# ================= 普通敌人攻击 =================
func drop_loot():
	var mat_table = [
		["mat_core", "能量核心"],
		["mat_chip", "机械芯片"],
		["mat_crystal", "虚空水晶"],
		["mat_gear", "齿轮零件"],
	]
	var chance = 1.0 if is_boss else 0.6
	if randf() < chance:
		if randf() < 0.5:
			var mat = mat_table[randi() % mat_table.size()]
			Inventory.add_item(mat[0], mat[1], 1)
		else:
			var equip_id = Inventory.random_equipment_id()
			var equip = Inventory.equipment_data[equip_id]
			Inventory.add_item(equip_id, equip["name"], 1)

func give_exp():
	var p = get_tree().get_root().find_child("Player", true, false)
	if p and p.has_method("add_exp"):
		var amount = 200 if is_boss else 30
		p.add_exp(amount)

func give_kill():
	var p = get_tree().get_root().find_child("Player", true, false)
	if p and p.has_method("add_kill"):
		p.add_kill()

func shoot_at_player(my_pos: Vector3, target_pos: Vector3):
	var dir = target_pos - my_pos
	dir.y = 0
	if dir.length() < 0.01:
		return
	dir = dir.normalized()

	var bullet = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	bullet.mesh = sphere

	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.8, 0.3, 1.0)
	bmat.emission_enabled = true
	bmat.emission = Color(0.8, 0.3, 1.0)
	bmat.emission_energy_multiplier = 2.0
	bullet.material_override = bmat

	bullet.set_script(BulletScript)
	bullet.dir = dir
	bullet.damage = atk
	bullet.target_player = player

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = my_pos + Vector3(0, 1.5, 0)

func bomb_explode(my_pos: Vector3):
	if bomb_triggered:
		return
	bomb_triggered = true
	AudioManager.play_sfx("enemy_die")

	if player and is_instance_valid(player) and player.is_inside_tree():
		var p_pos = player.global_position
		var dist_2d = Vector2(my_pos.x - p_pos.x, my_pos.z - p_pos.z).length()
		if dist_2d < 3.0:
			if player.has_method("take_damage"):
				player.take_damage(atk)

	var boom = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	boom.mesh = sphere
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(1, 0.5, 0.1, 0.8)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.emission_enabled = true
	bmat.emission = Color(1, 0.5, 0.1)
	bmat.emission_energy_multiplier = 3.0
	boom.material_override = bmat
	boom.set_script(BoomScript)
	get_tree().current_scene.add_child(boom)
	boom.global_position = my_pos + Vector3(0, 1, 0)

	dead = true
	give_kill()
	queue_free()

func _physics_process(delta):
	if dead:
		return
	if not is_inside_tree():
		return

	var my_pos = global_position

	if my_pos.y < -10:
		queue_free()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if attack_cd > 0:
		attack_cd -= delta
	if shoot_cd > 0:
		shoot_cd -= delta

	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		move_and_slide()
		return

	var ppos = player.global_position
	var dir = ppos - my_pos
	dir.y = 0
	var dist = dir.length()

	# ============ Boss 行为 ============
	if is_boss:
		# 冲锋中
		if charging:
			charge_timer -= delta
			velocity.x = charge_dir.x * CHARGE_SPEED
			velocity.z = charge_dir.z * CHARGE_SPEED
			if charge_timer <= 0:
				charging = false

			# 冲锋时碰到玩家造成伤害
			var dist_2d = Vector2(my_pos.x - ppos.x, my_pos.z - ppos.z).length()
			if dist_2d < 1.8 and attack_cd <= 0:
				attack_cd = 0.5
				if player.has_method("take_damage"):
					player.take_damage(int(atk * 1.5))
			move_and_slide()
			return

		# 技能冷却
		skill_timer -= delta
		if skill_timer <= 0:
			var base_cd = 5.0 if boss_phase == 1 else 3.5
			skill_timer = base_cd
			boss_use_skill(my_pos, ppos)

		# 追击玩家
		if dist > 2.0:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			var target = Vector3(ppos.x, my_pos.y, ppos.z)
			look_at(target, Vector3.UP)
		else:
			velocity.x = 0
			velocity.z = 0
			if attack_cd <= 0:
				attack_cd = 1.0
				if player.has_method("take_damage"):
					player.take_damage(atk)

		if dead or not is_inside_tree():
			return
		move_and_slide()
		if dead or not is_inside_tree():
			return
		var limit_b = 28.0
		var pos_b = global_position
		pos_b.x = clamp(pos_b.x, -limit_b, limit_b)
		pos_b.z = clamp(pos_b.z, -limit_b, limit_b)
		global_position = pos_b
		return

	# ============ 普通敌人行为 ============
	if enemy_type == "bomber":
		if dist > 1.8:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			var target = Vector3(ppos.x, my_pos.y, ppos.z)
			look_at(target, Vector3.UP)
		else:
			bomb_explode(my_pos)
			return
	elif enemy_type == "ranged":
		if dist > SHOOT_RANGE:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			var target = Vector3(ppos.x, my_pos.y, ppos.z)
			look_at(target, Vector3.UP)
		elif dist < KEEP_DIST:
			dir = -dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0
			velocity.z = 0
			var target = Vector3(ppos.x, my_pos.y, ppos.z)
			look_at(target, Vector3.UP)
			if shoot_cd <= 0:
				shoot_cd = SHOOT_INTERVAL
				shoot_at_player(my_pos, ppos)
	else:
		if dist > 1.5:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			var target = Vector3(ppos.x, my_pos.y, ppos.z)
			look_at(target, Vector3.UP)
		else:
			velocity.x = 0
			velocity.z = 0
			if attack_cd <= 0:
				attack_cd = 1.0
				if player.has_method("take_damage"):
					player.take_damage(atk)

	if dead or not is_inside_tree():
		return

	move_and_slide()

	if dead or not is_inside_tree():
		return

	var limit = 28.0
	var pos = global_position
	pos.x = clamp(pos.x, -limit, limit)
	pos.z = clamp(pos.z, -limit, limit)
	global_position = pos
