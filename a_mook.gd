extends CharacterBody2D

func _physics_process(delta):
	if !is_on_floor():
		velocity = velocity + get_gravity() * delta
	
	move_and_slide()

func is_punchable():
	return true

func get_punched():
	print("ouch")
