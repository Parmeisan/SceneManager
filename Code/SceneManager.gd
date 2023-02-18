extends Control

# ==== Configuration ==============================================================================

const debug_mode = true
const incr_size = 0.1 # time in seconds between checking for a Wait to be cancelled
export var script_path = "Assets/scripts/"
export var background_path = "Assets/images/"
export var audio_path = "Assets/audio/"
export var sprite_path = "Assets/characters/"
export var wait_after_dialogue : bool = true

# ==== Main functions & variables =================================================================

enum MODES { INIT, READY, RUNNING, STOPPING, WAITING }
var mode = MODES.INIT
var variables = {}
var all_scripts = {}

func _ready():
	LoadAllScripts()
	mode = MODES.READY

func debug(s):
	if debug_mode:
		print("SceneManager | %s" % s)

# === Loading scripts and other files =============================================================

func LoadAllScripts():
	# Load in scripts
	var dir = Directory.new()
	if dir.dir_exists(script_path):
		dir.open(script_path)
		dir.list_dir_begin()
		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with(".") and not file.begins_with("_") and dir.current_is_dir():
				LoadScript(file)
		dir.list_dir_end()
func LoadScript(script_name):
	
	# Proceed only if this hasn't already been loaded
	if all_scripts.has(script_name):
		return
	
	# Open and read the file
	var file = File.new()
	if not file.open(script_path + "/" + script_name + ".txt", file.READ) == OK:
		return
	file.seek(0)
	
	var current_line : String
	var line_count = 0 # For reporting errors
	var command_array = []
	
	# Every line in this file will correspond to some type of
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
	
	all_scripts[script_name] = command_array

static func GetImage(folder, file, ext):
	var img = Image.new()
	var fname = folder + file + ext
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		img.load(fname)
	else:
		print ("Error reading image file " + fname)
	f.close()
	return img
static func GetTexture(folder, file, ext):
# https://godotengine.org/qa/30210/how-do-load-resource-works
	var img =GetImage(folder, file, ext)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex
static func GetFont(folder, file, ext):
	var fname = folder + file + ext
	var font = DynamicFont.new()
	# Report error
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		font.font_data = load(fname)
	else:
		print ("Error reading font file " + fname)
	return font
static func GetAudio(folder, file, ext):
# https://github.com/godotengine/godot/issues/17748
	var fname = folder + file + ext
	var stream
	if ext == ".ogg":
		stream = AudioStreamOGGVorbis.new()
	else:
		stream = AudioStreamSample.new()
		stream.format = stream.FORMAT_16_BITS
		stream.mix_rate = 48000
	var afile = File.new()
	if afile.open(fname, File.READ) == OK:
		var bytes = afile.get_buffer(afile.get_len())
		stream.data = bytes
	else:
		print ("Error reading sound file " + fname)
	afile.close()
	return stream

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
	if event.is_action_pressed("ui_click"):
		Continue()


# The main one
func BeginScene(script_name):
	$BG_Image.visible = false
	
	# Get our array of commands
	if !all_scripts.has(script_name):
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
			# .wavs play once through the SFX player, .oggs loop through the music player
			cmd.TYPE.AUDIO:
				var player : AudioStreamPlayer
				if cmd.file_ext == "wav":
					player = $SFX_Player
				elif cmd.file_ext == "ogg":
					player = $Music_Looper
				if player != null:
					player.stream = GetAudio(audio_path, cmd.file_name, "." + cmd.file_ext)
					player.stop()
					player.play()
					player.volume_db = float(-8)
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
			cmd.TYPE.WAIT:
				var seconds = float(cmd.wait_seconds)
				# Wait on a loop; the loop may be ended early from elsewhere
				# DO NOT PUT THIS INSIDE A FUNCTION
				mode = MODES.WAITING
				var waited = 0.0
				while mode == MODES.WAITING and (seconds == cmd.WAIT_FOREVER or waited < seconds):
					# MODES.WAITING may be set to false outside this function
					yield(WaitIncrement(incr_size), "timeout")
					waited += incr_size
				mode = MODES.RUNNING

	print("==== Finished! ====")
	$BG_Image.visible = false
	mode = MODES.READY
