extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var facing = "RIGHT"

func _ready():
	FormSetup()
	
func _unhandled_input(event):
	if event.get_class() == "InputEventKey":
		if event.keycode == 4194326 && event.pressed == true:
			if facing == "RIGHT":
				$ThePunchZone.position.x = 43
			else:
				$ThePunchZone.position.x = -43
			await get_tree().create_timer(0.1).timeout
			POooooOONCH()

func _physics_process(delta: float) -> void:
	
	if (currPhysics == PHYSICS.FLY):
		if not is_on_floor():
			velocity += get_gravity() * delta
		if Input.is_action_just_pressed("ui_accept") and !is_on_floor():
			if flyCount < FLY_MAX:
				flyCount += 1
				velocity.y = JUMP_VELOCITY * 1.5
		move_and_slide()
		return
		
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
	
func POooooOONCH():
	var bodies = $ThePunchZone.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("is_punchable") && body.is_punchable():
			body.get_punched()


#region Forms
enum FORM { REGULAR, BIRD, SNAKE, SPIDER }
var currForm = FORM.REGULAR

enum PHYSICS { NORMAL, FLY, CRAWL }
var currPhysics = PHYSICS.NORMAL
var formPhysics = [ PHYSICS.NORMAL, PHYSICS.FLY, PHYSICS.FLY, PHYSICS.CRAWL ]

var formSpriteNames = [ "Attack1", "treefoot", "Barbarian", "Space_Wizard" ]
var formSprites = [] # Gets loaded on config

var flyCount = 0
const FLY_MAX = 3

func FormSetup() -> void:
	for n in formSpriteNames:
		formSprites.append(SceneManager.GetTexture("res://Assets/characters/", n, ".png"))
	
func CheckFormSwap() -> void:
	var prevForm = currForm
	if Input.is_action_just_pressed("form_cycle"):
		var allowedForms = [ true, true, Global.GetVar("hasSnake"), Global.GetVar("hasSpider") ]
		while true: # This forces at least one iteration, like a do-while (which Godot lacks)
			currForm = (currForm as int + 1) % FORM.size() as FORM
			if allowedForms[currForm]:
				break
	elif Input.is_action_just_pressed("form_bird"):
		currForm = FORM.BIRD
	
	if (currForm != prevForm):
		print ("Changed form to %s" % currForm)
		currPhysics = formPhysics[currForm]
		$Sprite2D.texture = formSprites[currForm]
		
		if (currPhysics != PHYSICS.FLY):
			flyCount = 0

#endregion
