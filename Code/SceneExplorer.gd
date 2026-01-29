extends Control
class_name SceneExplorer

@onready var mgr = $SceneManager
@onready var grid = $SceneList/GridContainer

func _ready():
	# First child is the invisible template; clear everything else and then start copying it
	grid.get_child(0).visible = false
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
						var img = SceneManager.GetImage(mgr.background_path, c.file_name, "." + c.file_ext)
						img.resize(80, 60)
						var tex = ImageTexture.new()
						icon.texture = tex.create_from_image(img)
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
		var vars = ", ".join(PackedStringArray(var_list))
		var chars = ""
		for c in char_list.keys():
			if chars != "":
				chars += ", "
			chars += c
			chars += " (%d)" % char_list[c]
		# Now display the extra details
		t.get_node("ItemCounts").text = "Images: %d\nAudio: %d" % [img_count, audio_count]
		t.get_node("ItemDetail").text = "Characters: %s\nVariables: %s" % [chars, vars]
		# And the final touches
		t.get_node("ButtonBG/Button").connect("pressed", Callable(self, "scene_button_pressed").bind(script))
		t.visible = true
		grid.add_child(t)
	emit_signal("draw")

func scene_button_pressed(script):
	mgr.BeginScene(script)


	
