extends CharacterBody2D
class_name EnemyBase

var hitpoints = 5
var damage = 2
var bonkPower = 200

func bonk():
	var bodies = $PlayerBonker.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("is_player") && body.is_player():
			var direction = body.global_position - global_position
			body.get_hit(damage, direction, bonkPower)

func is_punchable():
	return true

func get_punched(facing):
	$Sprite2D/AnimationPlayer.play("get hit")
	var xMul
	if(facing == Global.FACING.LEFT):
		xMul = -1
	else:
		xMul = 1
	var newVelocity = Vector2(200, -150)
	newVelocity.x = newVelocity.x * xMul
	velocity = newVelocity
	hitpoints = hitpoints - 1
	if(hitpoints <= 0):
		queue_free()
