extends Node2D

onready var mgr = $SceneManager

func _ready():
	mgr.BeginScene("intro")
