extends MeshInstance3D

var dir := Vector3.ZERO
var damage := 0
var speed := 15.0
var life := 0.0
var max_life := 2.5
var target_player: Node3D = null

func _process(delta):
	if not is_inside_tree():
		return

	life += delta
	if life > max_life:
		queue_free()
		return

	global_position += dir * speed * delta

	if target_player and is_instance_valid(target_player) and target_player.is_inside_tree():
		var center = target_player.global_position + Vector3(0, 1, 0)
		if global_position.distance_to(center) < 1.0:
			if target_player.has_method("take_damage"):
				target_player.take_damage(damage)
			queue_free()
