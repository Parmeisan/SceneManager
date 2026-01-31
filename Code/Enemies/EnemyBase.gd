extends CharacterBody2D
class_name EnemyBase

@export var dialogue_script: String

var hitpoints = 5
var talkable = false;

var damage = 2
var bonkPower = 200

func bonk():
	var bodies = $PlayerBonker.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("is_player") && body.is_player():
			var direction = body.global_position - global_position
			body.get_hit(damage, direction, bonkPower)

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
	if(facing == Global.FACING.LEFT):
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
