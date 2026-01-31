extends Node

enum FACING { LEFT, RIGHT, UP, DOWN } # Up and down are ONLY spider form
#region signals
signal landed()
#endregion

#region Variables

var variables = {}
# Variable functions
func GetVar(v):
	if !variables.has(v):
		variables[v] = 0
	return Global.variables[v]
func SetVar(v, to):
	Global.variables[v] = to
	print(Global.variables)
#endregion

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
