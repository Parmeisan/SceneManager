extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var facing = "RIGHT"

func _ready():
	FormSetup()
	
func _input(_event: InputEvent) -> void:
	CheckFormSwap()

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
	
	# Handle player-induced upward velocity
	if (currPhysics == PHYSICS.FLY):
		if Input.is_action_just_pressed("ui_accept") and !is_on_floor():
			if flyCount < FLY_MAX:
				flyCount += 1
				velocity.y = JUMP_VELOCITY * 1.5
	elif (currPhysics == PHYSICS.JUMP):
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
	# Add the gravity.
	if (currPhysics == PHYSICS.JUMP or currPhysics == PHYSICS.FLY):
		if not is_on_floor():
			velocity += get_gravity() * delta
	elif (currPhysics == PHYSICS.SWIM):
		if not is_on_floor():
			velocity += get_gravity() * delta / 3

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
			body.get_punched(facing)


#region Forms
enum FORM { SPIDER, BIRD, SNAKE, JELLYFISH }
var currForm = FORM.SPIDER

enum PHYSICS { JUMP, FLY, CRAWL, SWIM }
var formPhysics = [ PHYSICS.CRAWL, PHYSICS.FLY, PHYSICS.JUMP, PHYSICS.SWIM ]
var currPhysics = formPhysics[currForm]

var formSpriteNames = [ "spider", "bird", "snake", "jellyfish" ]
var formSprites = [] # Gets loaded on config

var flyCount = 0
const FLY_MAX = 3

func FormSetup() -> void:
	for n in formSpriteNames:
		formSprites.append(SceneManager.GetTexture("res://Assets/characters/", n, ".png"))
	$Sprite2D.texture = formSprites[currForm]
	
func CheckFormSwap() -> void:
	
	var prevForm = currForm
	if Input.is_action_just_pressed("form_cycle"):
		CycleUntilAllowed(1)
	elif Input.is_action_just_pressed("form_cycle_reverse"):
		CycleUntilAllowed(-1)
	elif Input.is_action_just_pressed("form_spider"):
		SwitchIfAllowed(FORM.SPIDER)
	elif Input.is_action_just_pressed("form_bird"):
		SwitchIfAllowed(FORM.BIRD)
	elif Input.is_action_just_pressed("form_snake"):
		SwitchIfAllowed(FORM.SNAKE)
	elif Input.is_action_just_pressed("form_jelly"):
		SwitchIfAllowed(FORM.JELLYFISH)
	
	if (currForm != prevForm):
		print ("Changed form to %s" % currForm)
		currPhysics = formPhysics[currForm]
		$Sprite2D.texture = formSprites[currForm]
		
		if (currPhysics != PHYSICS.FLY):
			flyCount = 0

func IsFormAllowed(form : FORM):
	var allowedForms = [ true, true, true, true] #Global.GetVar("hasSnake"), Global.GetVar("hasSpider") ]
	return allowedForms[form]

func CycleUntilAllowed(dir : int):
	while true: # This forces at least one iteration, like a do-while (which Godot lacks)
		currForm = (currForm as int + dir) % FORM.size() as FORM
		if IsFormAllowed(currForm):
			break

func SwitchIfAllowed(form : FORM):
	if (IsFormAllowed(form)):
		currForm = form
#endregion
