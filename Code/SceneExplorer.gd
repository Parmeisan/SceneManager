extends Control

#const SceneManager = preload("SceneManager.gd")
onready var mgr = $SceneManager
onready var grid = $ColorRect/GridContainer

func _ready():
	# First child is the invisible template; clear everything else and then start copying it
	while grid.get_child_count() > 1:
		remove_child(get_child(1))
	var template = grid.get_node("GridScene")
	for script in mgr.all_scripts.keys():
		# Main data
		var t = template.duplicate()
		t.get_node("Title").text = script
		var cmds = mgr.all_scripts[script]
		# Loop through commands for extra details
		var icon = t.get_node("Image")
		var img_count = 0
		var audio_count = 0
		var char_list = {}
		var var_list = []
		for c in cmds:
			match c.command_type:
				c.TYPE.BACKGROUND:
					img_count += 1
					if icon.texture == null:
						icon.texture = SceneManager.GetTexture(mgr.background_path, c.file_name, "." + c.file_ext)
						icon.texture.size = Vector2(80, 60)
				c.TYPE.AUDIO:
					audio_count += 1
				c.TYPE.DIALOGUE:
					if char_list.has(c.dial_character):
						char_list[c.dial_character] += 1
					else:
						char_list[c.dial_character] = 1
				c.TYPE.VARIABLE:
					if !var_list.has(c.var_name):
						var_list.append(c.var_name)
		# A little more manipulation
		var vars = PoolStringArray(var_list).join(", ")
		var chars = ""
		for c in char_list.keys():
			if chars != "":
				chars += ", "
			chars += c
			chars += " (%d)" % char_list[c]
		# Now display the extra details
		t.get_node("ItemCounts").text = "Images: %d\nAudio: %d" % [img_count, audio_count]
		t.get_node("ItemDetail").text = "Characters: %s\nVariables: %s" % [chars, vars]
		t.visible = true
		add_child(t)
	#get_parent().
	emit_signal("draw")
