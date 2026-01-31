extends Control
class_name SceneManager

# ==== Configuration ==============================================================================

const debug_mode = true
const incr_size = 0.1 # time in seconds between checking for a Wait to be canceled
@export var script_path = "Assets/scripts/"
@export var background_path = "Assets/images/"
@export var audio_path = "Assets/audio/"
@export var sprite_path = "Assets/characters/"
@export var font_path = "Assets/fonts/"
@export var wait_after_dialogue : bool = true
@export var startup_scene = ""

# ==== Main functions & variables =================================================================

enum MODES { INIT, READY, RUNNING, STOPPING, WAITING }
var mode = MODES.INIT
var variables = {}
var all_scripts = {}
var characters = {}
var playing = false

#Associated with shake effect
var vibrate_time = 0.0;
var centerPoint
var vibrating = false
var vibratingObject
var rng = RandomNumberGenerator.new()

#Associated with Title slide
var title_slide = false
var title_progress = 0

#associated with generic slide
var slide = false
var slideDuration
var slidFor = 0.0
var slideObject
var slideDirection
var displacementVector
var displacementFactor = 1.0
var homePosition

func _ready():
	visible = false
	LoadAllScripts()
	FillCharacterArray()
	mode = MODES.READY
	if startup_scene != "":
		BeginScene(startup_scene)

func _physics_process(delta):
	if vibrating:
		var xShake = rng.randi_range(-10,10)
		var yShake = rng.randi_range(-10,10)
		vibratingObject.position = Vector2(centerPoint.x + xShake, centerPoint.y +yShake)
		vibrate_time = vibrate_time + delta
		if(vibrate_time > 1.0):
			vibrate_time = 0
			vibratingObject.position = centerPoint
			vibrating = false
	if title_slide:
		#two seconds
		title_progress = title_progress + delta/2
		$Game_Title.position = Vector2(512, 300.0 * title_progress)
		if(title_progress >= 1):
			title_progress = 1
			title_slide = false
	
	if slide:
		slideObject.position = homePosition + displacementVector * displacementFactor
		slidFor = slidFor + delta
		displacementFactor = 1.0 - (slidFor / slideDuration)
		if(slidFor >= slideDuration):
			slide = false
			slideObject.position = homePosition
			slidFor = 0
			displacementFactor = 1.0

func displace(dir):
	if dir == "RIGHT":
		displacementVector = Vector2(512,0)
	if dir == "LEFT":
		displacementVector = Vector2(-512,0)
	if dir == "TOP":
		displacementVector = Vector2(0,300)
	if dir == "BOTTOM":
		displacementVector = Vector2(0,300)

func debug(s):
	if debug_mode:
		print("SceneManager | %s" % s)

# === Loading scripts and other files =============================================================

func LoadAllScripts():
	# Load in scripts
	print("Loading all scripts at ", script_path)
	var dir = DirAccess.open("res://%s" % script_path)
	if dir:
		var list = DirAccess.get_files_at("res://%s" % script_path)
		for fname in list:
			print("Found ", fname)
			if fname == "":
				break
			if not fname.begins_with(".") and not fname.begins_with("_"):
				var script_name = fname.substr(0, fname.rfind("."))
				LoadScript(script_name)
		dir.list_dir_end()
	else:
		print("!!!Error opening " + script_path + "!!!")

func LoadScript(script_name):
	print("   Loading ", script_name)
	# Proceed only if this hasn't already been loaded
	if all_scripts.has(script_name):
		return
	# Open and read the file
	var fname = script_path + "/" + script_name + ".txt"
	var file = FileAccess.open(fname, FileAccess.READ)
	if file == null:
		print ("Error opening file %s: %s" % [fname, FileAccess.get_open_error()])
		return
	file.seek(0)
	# Init vars for this loop
	var current_line : String
	var line_count = 0 # For reporting errors
	var command_array = []
	var do_wait = ScriptCommand.new("...") # We might need this a bunch
	# Every line in this file will correspond to some type of command - play audio, show dialogue, etc
	while !file.eof_reached():
		current_line = file.get_line()
		line_count += 1 # Human-readable, so first line is 1
		var command : ScriptCommand
		command = ScriptCommand.new(current_line)
		if !command.isValid():
			print ("Invalid command found in %s at line %s" % [script_name, line_count])
			print ("Error message was: %s" % command.error_message)
		elif command.isCommand():
			command_array.append(command)
			# If set as such in configuration, dialogue automatically waits before moving on
			# It will be skippable by clicking / pressing certain keys and will stop if there's
			# an accompanying sound effect that completes
			if wait_after_dialogue and command.command_type == command.TYPE.DIALOGUE:
				command_array.append(do_wait)
	# And, save it
	print("   Loaded %d commands" % command_array.size())
	all_scripts[script_name] = command_array

static func GetImage(folder, file, ext):
	var fname = folder + file + ext
	# This file read stuff isn't necessary to actually read the image, however it seems useful for error handling
	var f = FileAccess.open(fname, FileAccess.READ)
	if f == null:
		print ("Error reading image file %s: %s" % [fname, FileAccess.get_open_error()])
	f.close()
	return Image.load_from_file(fname)
static func GetTexture(folder, file, ext):
# https://godotengine.org/qa/30210/how-do-load-resource-works
	var img = GetImage(folder, file, ext)
	var tex = ImageTexture.create_from_image(img)
	return tex
static func GetFont(folder, file, ext):
	var fname = folder + file + ext
	var font# = FontFile.new()
	# Report error
	var f = FileAccess.open(fname, FileAccess.READ)
	if f == null:
		print ("Error reading font file %s: %s" % [fname, FileAccess.get_open_error()])
	else:
		font = load(fname)
	return font
static func GetAudio(folder, file, ext):
# https://github.com/godotengine/godot/issues/17748
	var fname = folder + file + ext
	var stream
	# TODO: Is any of this necessary?  I hope not, because I've bypassed it below. But we should check.
	if ext == ".ogg":
		stream = AudioStreamOggVorbis.new()
	else:
		stream = AudioStreamWAV.new()
		stream.format = stream.FORMAT_16_BITS
		stream.mix_rate = 48000
	var afile = FileAccess.open(fname, FileAccess.READ)
	if afile == null:
		print ("Error reading sound file %s: %s" % [fname, FileAccess.get_open_error()])
	else:
		#var bytes = afile.get_buffer(afile.get_length())
		#stream.data = bytes
		stream = load(fname)
		afile.close()
	return fname

# === Running scripts from our array of ScriptCommands ============================================

# Variable functions
func GetVar(v):
	return variables[v]
func SetVar(v, to):
	variables[v] = to
	print(variables)

# Wait-related functions
func WaitIncrement(seconds):
	return get_tree().create_timer(seconds)
func Continue():
	print("Continue")
	if mode == MODES.WAITING:
		mode = MODES.RUNNING
func _input(event):
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("ui_accept"):
		Continue()
	if event.is_action_pressed("ui_click") and visible == true:
		Continue()
	if event.is_action_pressed("ui_debug_scenes"):
		visible = false
		mode = MODES.READY


# The main one
func BeginScene(script_name):
	$BG_Image.visible = false
	$BranchOptions.visible = false
	$Character_Left.texture = null
	$Character_Right.texture = null
	$Game_Title.position = Vector2(0,0)
	title_slide = false
	var num = 0
	for opt in $BranchOptions.get_children():
		if (num > 0): # The first one will serve as a template
			$BranchOptions.remove_child(opt)
		num += 1
	visible = true
	
	# Get our array of commands
	if !all_scripts.has(script_name):
		print(all_scripts)
		LoadScript(script_name)
	var commands = all_scripts[script_name]

	# Do the appropriate action for each one
	for cmd in commands:
		debug("Command: %s" % cmd.original_line)
		
		# We want to be able to stop this function mid-cutscene
		if mode == MODES.STOPPING:
			mode = MODES.READY
			return
		
		mode = MODES.RUNNING
		match cmd.command_type:
			# Play audio of some kind.
			cmd.TYPE.AUDIO:
				var player : AudioStreamPlayer
				if cmd.file_ext == "wav":
					# Ensure that we have 16-bit (can downgrade in Audacity)
					$AudioManager.play_sfx("res://" + GetAudio(audio_path, cmd.file_name, "." + cmd.file_ext))
				elif cmd.file_ext == "ogg":
					$AudioManager.play_bgm("res://" + GetAudio(audio_path, cmd.file_name, "." + cmd.file_ext))
				#if player != null:
					#player.stream = GetAudio(audio_path, cmd.file_name, "." + cmd.file_ext)
					#player.stop()
					#player.play()
					#player.volume_db = float(8)
			# Set a background
			cmd.TYPE.BACKGROUND:
				$BG_Image.visible = true
				$BG_Image.texture = GetTexture(background_path, cmd.file_name, "." + cmd.file_ext)
			# Perform some operation on a variable
			cmd.TYPE.VARIABLE:
				if !variables.has(cmd.var_name):
					variables[cmd.var_name] = 0
				var value = GetVar(cmd.var_name)
				match cmd.var_operation:
					cmd.OPERATION.EQUALS:
						value = cmd.var_value
					cmd.OPERATION.PLUS:
						value += cmd.var_value
					cmd.OPERATION.MINUS:
						value -= cmd.var_value
				SetVar(cmd.var_name, value)
			# Display options for the player
			# We will get these over multiple lines, we add each of them as we receive them,
			# but they will all be hidden until we reach the end of the file
			cmd.TYPE.OPTION:
				var template = $BranchOptions.get_child(0);
				var new_button = template.duplicate()
				new_button.get_node("Label").text = cmd.opt_text
				new_button.connect("pressed", Callable(self, "option_button_pressed").bind(cmd.opt_destination))
				new_button.visible = true
				$BranchOptions.add_child(new_button)
			cmd.TYPE.WAIT:
				var seconds = float(cmd.wait_seconds)
				# Wait on a loop; the loop may be ended early from elsewhere
				# DO NOT PUT THIS INSIDE A FUNCTION
				mode = MODES.WAITING
				var waited = 0.0
				while mode == MODES.WAITING and (seconds == cmd.WAIT_FOREVER or waited < seconds):
					# MODES.WAITING may be set to false outside this function
					if playing and !($SFX_Player.playing):
						playing = false;
						Continue()
						break
					await WaitIncrement(incr_size).timeout
					waited += incr_size
				mode = MODES.RUNNING
			cmd.TYPE.HIDE:
				if cmd.image_location != null and cmd.image_location != cmd.IMAGE_LOCATION.UNDEFINED:
					match cmd.image_location:
						cmd.IMAGE_LOCATION.LEFT:
							$Character_Left.texture = null
						cmd.IMAGE_LOCATION.RIGHT:
							$Character_Right.texture = null
						#cmd.IMAGE_LOCATION.CENTER:
						#	$Character_Center.texture = null
				if cmd.target != null:
					print("Hiding " + cmd.target)
					get_node(cmd.target).visible = false
			cmd.TYPE.DIALOGUE:
				$Nametag_Background.visible = false
				$Nametag_text.visible = false
				$Speaker_Background.visible = true
				var box = get_node("Speaker_Text")
				box.text = cmd.dial_line
				# This is quick-and-dirty, we'll want some scaffolding around this
				if !characters.has(cmd.dial_character):
					print("Failed to find " + cmd.dial_character)
					print(characters)
				else:
					var c : SceneCharacter = characters[cmd.dial_character]
					if ((c != $Characters/NobodyLeft) &&
					   (c != $Characters/NobodyRight) &&
					   (c != $Characters/TEXT) && 
					   (c != $Characters/Monologue)):
						$Speaker_Background.visible = true
						$Speaker_Text.visible = true
						$Nametag_Background.visible = true
						$Nametag_text.visible = true
						$Nametag_text.text = c.character_full_name
					# Override the previous location?
					if cmd.image_location != cmd.IMAGE_LOCATION.UNDEFINED:
						c.image_side = cmd.image_location
					# Display on appropriate side
					if c.image_side == cmd.IMAGE_LOCATION.LEFT:
						$Character_Left.texture = c.GetEmotionTexture(cmd.dial_emotion)
					elif c.image_side == cmd.IMAGE_LOCATION.RIGHT:
						$Character_Right.texture = c.GetEmotionTexture(cmd.dial_emotion)
					#elif cmd.image_location == cmd.IMAGE_LOCATION.CENTER:
					#	$Character_Center.texture = c.GetEmotionTexture(cmd.dial_emotion)
					var font = GetFont(font_path, c.dialogue_fontname, "")
					font.fixed_size = c.dialogue_fontsize
					box.set("theme_override_fonts/font", font)
					$Nametag_text.set("theme_override_fonts/font", font)
					box.set("theme_override_colors/font_color", c.dialogue_colour)
					$Nametag_text.set("theme_override_colors/font_color", c.dialogue_colour)
					if c.dialogue_shadow != c.dialogue_colour:
						box.set("theme_override_colors/font_shadow_color", c.dialogue_shadow)
						$Nametag_text.set("theme_override_colors/font_shadow_color", c.dialogue_shadow)
					var box_back = c.dialogue_background
					box_back.a8 = 224
					$Speaker_Background.color = box_back
					$Nametag_Background.color = box_back
			cmd.TYPE.EVENT:
				if(cmd.event == "SHAKE"):
					vibratingObject = get_node(cmd.target)
					var original_position = vibratingObject.position
					centerPoint = original_position
					vibrating = true
				if(cmd.event == "SHOW"):
					var character = characters[cmd.dial_character]
					var image = character.GetEmotionTexture(cmd.dial_emotion)
					get_node(cmd.target).texture = image
				if(cmd.event == "TITLE"):
					title_slide = true
				if(cmd.event == "SLIDE"):
					if(slide):
						slideObject.position = homePosition
					slideObject = get_node(cmd.target)
					slideDuration = float(cmd.duration)
					slideDirection = cmd.direction
					homePosition = slideObject.position
					displace(slideDirection)
					slideObject.position = slideObject.position + displacementVector
					slide = true

	# Display options, if there are any beyond than the template
	if $BranchOptions.get_child_count() > 1:
		print("==== Options ====")
		$BranchOptions.visible = true
		mode = MODES.WAITING
	
	else:
		print("==== Finished! ====")
		visible = false
		mode = MODES.READY


# === Loading and retrieving characters / emotions ================================================

func FillCharacterArray():
	for node in $Characters.get_children():
		var c : SceneCharacter = node
		print("Adding character " + c.character_abbreviation)
		characters[c.character_abbreviation] = c

func option_button_pressed(scene):
	print("going to scene" + scene)
	BeginScene(scene)
#
#func GetCharacter(abbr : String):
#	pass
