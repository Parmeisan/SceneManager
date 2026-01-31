extends CharacterBody2D
class_name EnemyBase

var hitpoints = 5

func _physics_process(delta):
	if !is_on_floor():
		velocity = velocity + get_gravity() * delta
	
	move_and_slide()

func is_punchable():
	return true

func get_punched(facing):
	$Sprite2D/AnimationPlayer.play("get hit")
	var xMul
	if(facing == "LEFT"):
		xMul = -1
	else:
		xMul = 1
	var newVelocity = Vector2(200, -150)
	newVelocity.x = newVelocity.x * xMul
	velocity = newVelocity
	hitpoints = hitpoints - 1
	if(hitpoints <= 0):
		queue_free()
