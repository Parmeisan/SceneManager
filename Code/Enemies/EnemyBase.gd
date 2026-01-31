extends CharacterBody2D
class_name EnemyBase

@export var dialogue_script: String

var hitpoints = 5
var talkable = false;


func _physics_process(delta):
	if !is_on_floor():
		velocity = velocity + get_gravity() * delta
	
	move_and_slide()

func _input(_event: InputEvent) -> void:
	if(talkable):
		if Input.is_action_just_pressed("ui_up"):
			%SceneManager.BeginScene(dialogue_script)
	else: 
		pass

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


func _on_dialogue_area_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if(!talkable): 
		if(body == %Player):
			talkable = true;
			print(body, talkable)
			
		
		
	



func _on_dialogue_area_body_exited(body: Node2D) -> void:
	if(talkable):
		if(body.get_path() == %Player.get_path()):
			talkable = false
			print(body, talkable)
