extends Node3D

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var player_path: NodePath

var player: Node3D
var wave := 0
var enemies_alive := 0
var between_waves := false
var between_timer := 0.0
const BETWEEN_TIME := 3.0

func _ready():
	if player_path:
		player = get_node_or_null(player_path)
	if player == null:
		player = get_tree().get_root().find_child("Player", true, false)
	start_next_wave()

func pick_enemy_type() -> String:
	var types = ["melee"]
	if wave >= 4:
		types.append("ranged")
	if wave >= 6:
		types.append("fast")
	if wave >= 8:
		types.append("bomber")
	return types[randi() % types.size()]

func start_next_wave():
	wave += 1
	between_waves = false
	print("=== 第 ", wave, " 波 ===")

	DailyQuest.set_progress("wave", wave)

	var is_boss_wave = (wave % 5 == 0)

	if is_boss_wave:
		spawn_boss()
	else:
		var count = 1 + int(wave / 2.0)
		for i in range(count):
			spawn_enemy()

func spawn_enemy():
	if enemy_scene == null:
		print("enemy_scene 未设置")
		return

	var e = enemy_scene.instantiate()
	var angle = randf() * TAU
	var dist = randf_range(12, 20)
	e.position = Vector3(cos(angle) * dist, 1, sin(angle) * dist)
	e.enemy_type = pick_enemy_type()

	add_child(e)

	var hp_scale = 1.0
	var atk_scale = 1.0
	match e.enemy_type:
		"fast":
			hp_scale = 0.5
			atk_scale = 0.7
		"ranged":
			hp_scale = 0.8
			atk_scale = 1.2
		"bomber":
			hp_scale = 0.7
			atk_scale = 3.0

	e.max_hp = int((60 + wave * 10) * hp_scale)
	e.hp = e.max_hp
	e.atk = int((8 + wave * 2) * atk_scale)
	if e.has_method("update_hp"):
		e.update_hp()

	e.tree_exited.connect(_on_enemy_died)
	enemies_alive += 1

func spawn_boss():
	if boss_scene == null:
		print("boss_scene 未设置")
		return

	var b = boss_scene.instantiate()
	var angle = randf() * TAU
	var dist = 15.0
	b.position = Vector3(cos(angle) * dist, 1, sin(angle) * dist)

	add_child(b)

	b.max_hp = 300 + wave * 50
	b.hp = b.max_hp
	b.atk = 20 + wave * 3
	b.enemy_type = "melee"

	if b.has_method("setup_boss"):
		b.setup_boss()

	b.tree_exited.connect(_on_enemy_died)
	enemies_alive += 1
	print("Boss 出现！")

func _on_enemy_died():
	enemies_alive -= 1
	if enemies_alive <= 0 and not between_waves:
		between_waves = true
		between_timer = BETWEEN_TIME
		print("清完一波，", BETWEEN_TIME, " 秒后下一波")

func _process(delta):
	if between_waves:
		between_timer -= delta
		if between_timer <= 0:
			start_next_wave()
