extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var facing = Global.FACING.RIGHT
var metafloor = true

var invincible = false
var stunned = false
var crawling
var direction

var invincibleDuration = 2
var stunDuration = 0.4

func _ready():
	Global.landed.connect(land)
	
	FormSetup()
	hide_sprites()
	activate_sprites()
	show_sprite(%SpiderStanding)

func is_player():
	return true

func get_hit(damage: int, direction: Vector2, force: int):
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
	crawling = false
	await get_tree().create_timer(stunDuration).timeout
	stunned = false
	
func _input(_event: InputEvent) -> void:
	CheckFormSwap()

func _unhandled_input(event):
	if event.get_class() == "InputEventKey":
		if event.keycode == 4194326 && event.pressed == true:
			if facing == Global.FACING.RIGHT:
				$ThePunchZone.position.x = 43
			else:
				$ThePunchZone.position.x = -43
			await get_tree().create_timer(0.1).timeout
			POooooOONCH()

func _physics_process(delta: float) -> void:
	
	# Handle player-induced upward velocity
	if (currPhysics == PHYSICS.FLY):
		if Input.is_action_just_pressed("jump") and !is_on_floor():
			if flyCount < FLY_MAX:
				flyCount += 1
				velocity.y = JUMP_VELOCITY * 1.5
	elif (currPhysics == PHYSICS.JUMP):
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
	# Add the gravity.
	if !metafloor && is_on_floor():
		Global.landed.emit()
		metafloor = true
	
	if !crawling:
		crawling = (is_on_floor() or custom_on_ceiling() or %SpiderWallLeft.is_colliding() && direction < 0 or %SpiderWallRight.is_colliding() && direction > 0)
	else:
		if !is_on_floor() && !custom_on_ceiling() && !%SpiderWallLeft.is_colliding() && !%SpiderWallRight.is_colliding():
			crawling = false
			
	if (currPhysics == PHYSICS.JUMP or currPhysics == PHYSICS.FLY):
		if not is_on_floor():
			pass
			print(velocity.y)
			velocity += get_gravity() * delta
	elif (currPhysics == PHYSICS.SWIM):
		if not is_on_floor():
			velocity += get_gravity() * delta / 3
	elif currPhysics == PHYSICS.CRAWL:
		if stunned || !crawling:
			velocity += get_gravity() * delta


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	#left-right movement.
	#briefly disable it when taking damage
	direction = Input.get_axis("ui_left", "ui_right")
	if !stunned:
		if direction:
			velocity.x = direction * SPEED
			if(velocity.x < 0):
				facing = Global.FACING.LEFT
			if(velocity.x > 0):
				facing = Global.FACING.RIGHT
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if currPhysics == PHYSICS.CRAWL and crawling:
		var updir := Input.get_axis("ui_up", "ui_down")
		if updir && (%SpiderWallLeft.is_colliding() || %SpiderWallRight.is_colliding() || custom_on_ceiling()):
			velocity.y = updir * SPEED
			if(velocity.y < 0):
				facing = Global.FACING.UP
			if(velocity.y > 0):
				facing = Global.FACING.DOWN
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)
		
	# Die code
	if global_position.y > 2000:
		get_tree().quit()

	UpdateSprites()
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
		UpdateSprites()
		
		if (currPhysics != PHYSICS.FLY):
			flyCount = 0

func land():
	hide_sprites()
	$SpiderStanding.visible = true

func custom_on_ceiling():
	var bodies = %SpiderCeiling.get_overlapping_bodies()
	for body in bodies:
		if body.get_class() == "TileMap" && !stunned && (Input.is_action_pressed("ui_up") || Input.is_action_pressed("ui_left") || Input.is_action_pressed("ui_right") || crawling):
			return true
	return false

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

#region Animations

@onready var all_sprites = [
	%SpiderStanding, %SpiderWalking,
	%SnakeStanding, %SnakeWalking, %SnakeJumping,
	%BirdFlying,
	%JellyfishSwimming
]

func activate_sprites():
	for sprite in all_sprites:
		if (sprite):
			sprite.play()

func hide_sprites():
	for sprite in all_sprites:
		if (sprite):
			sprite.visible = false

func show_sprite(sprite : Node):
	sprite.visible = true
	
func UpdateSprites():
	hide_sprites()
	var is_moving = Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")
	match currForm:
		FORM.SNAKE:
			var sprite
			if is_on_floor():
				if is_moving:
					sprite = %SnakeWalking
				else:
					sprite = %SnakeStanding
			else:
				sprite = %SnakeJumping
			show_sprite(sprite)
			SpriteRotate(sprite, facing == Global.FACING.LEFT)
		FORM.SPIDER:
			var sprite
			if is_moving:
				sprite = %SpiderWalking
			else:
				sprite = %SpiderStanding
			show_sprite(sprite)
			if is_on_floor():
				SpriteRotate(sprite, facing == Global.FACING.LEFT, false)
			elif %SpiderWallLeft.is_colliding():
				SpriteRotate(sprite, facing == Global.FACING.UP, false, 90)
			elif %SpiderWallRight.is_colliding():
				SpriteRotate(sprite, facing == Global.FACING.DOWN, false, -90)
			elif custom_on_ceiling():
				SpriteRotate(sprite, facing == Global.FACING.LEFT, true)
			else:
				if !stunned:
					SpriteRotate(sprite, facing == Global.FACING.LEFT, false)
		FORM.BIRD:
			show_sprite(%BirdFlying)
		FORM.JELLYFISH:
			show_sprite(%JellyfishSwimming)

func SpriteRotate(sprite : Node, flip_h : bool, flip_v : bool = false, rotation : int = 0):
	sprite.flip_h = flip_h
	sprite.flip_v = flip_v
	sprite.rotation = rotation

#endregion
