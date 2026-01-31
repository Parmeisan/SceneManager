extends EnemyBase

@export var leftRange :int
@export var rightRange : int

var startPoint : Vector2
var direction = "LEFT"
var speed = 300

func _ready():
	startPoint = global_position

func _physics_process(delta):
	if direction == "LEFT":
		velocity = Vector2(-1 * speed, 0)
	if direction == "RIGHT":
		velocity = Vector2(speed, 0)
	if direction == "LEFT" && global_position.x < startPoint.x - leftRange:
		direction = "RIGHT"
	if direction == "RIGHT" && global_position.x > startPoint.x +  rightRange:
		direction = "LEFT"
	move_and_slide()
	bonk()
