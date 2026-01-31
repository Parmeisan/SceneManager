extends EnemyBase
class_name EnemyWanderer

@export var startsLeft : bool = true
@export var wanderSpeed : float = 40

const LEFT = -1
const RIGHT = 1
var currDir = -1 if startsLeft else 1

func _ready():
	pass

func _process(delta):
	# Guards
	if not is_on_floor():
		return
	
	# Proceed
	var foundMove = false
	if currDir == LEFT:
		if %EdgeCheckerL.is_colliding():
			foundMove = true
		else:
			currDir *= -1 # Try the other way
	elif currDir == RIGHT: # If we swapped directions, just wait for the next frame
		if %EdgeCheckerR.is_colliding():
			foundMove = true
		else:
			currDir *= -1 # Try the other way
	if foundMove:
		velocity.x = currDir * wanderSpeed #move_toward(currDir * speed, 0, speed)
