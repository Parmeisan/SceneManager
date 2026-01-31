extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var facing = "RIGHT"

func _unhandled_input(event):
	if event.get_class() == "InputEventKey":
		if event.keycode == 4194326 && event.pressed == true:
			print("Control pressed")
			if facing == "RIGHT":
				$ThePunchZone.position.x = 43
			else:

				$ThePunchZone.position.x = -43
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if(velocity.x < 0):
			facing = "LEFT"
		if(velocity.x > 0):
			facing = "RIGHT"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if global_position.y > 2000:
		get_tree().quit()

	move_and_slide()
