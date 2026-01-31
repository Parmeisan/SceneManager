extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var facing = "RIGHT"
var metafloor = true

var invincible = false
var stunned = false

var invincibleDuration = 2
var stunDuration = 0.4

func _ready():
	Global.landed.connect(land)
	
	FormSetup()
	hide_sprites()
	activate_sprites()
	$SpiderStanding.visible = true

func is_player():
	return true

func get_hit(damage: int, direction: Vector2, force: int):
	print(	direction)
	if !invincible:
		velocity = direction.normalized() * force
		become_invincible()
		become_stunned()
		

func become_invincible():
	invincible = true
	$AnimationPlayer.play("invincibility")
	await get_tree().create_timer(invincibleDuration).timeout
	invincible = false
	$AnimationPlayer.stop()
	$AnimationPlayer.seek(0.11, true)

func become_stunned():
	stunned = true;
	await get_tree().create_timer(stunDuration).timeout
	stunned = false;

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
	if !metafloor && is_on_floor():
		Global.landed.emit()
		metafloor = true
		 
	CheckFormSwap()
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
		hide_sprites()
		$SpiderJumping.visible = true
		metafloor = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	#left-right movement.
	#briefly disable it when taking damage
	var direction := Input.get_axis("ui_left", "ui_right")
	if !stunned:
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

func land():
	print("landed!")
	hide_sprites()
	$SpiderStanding.visible = true

func activate_sprites():
	$SpiderStanding.play()
	$SpiderJumping.play()

func hide_sprites():
	$SpiderStanding.visible = false
	$SpiderJumping.visible = false
#endregion
