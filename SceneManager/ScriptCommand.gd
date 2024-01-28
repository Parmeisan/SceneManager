extends Node
class_name ScriptCommand

enum TYPE { NONE, AUDIO, BACKGROUND, MOOD, VARIABLE, DIALOGUE, HIDE, OPTION, WAIT, EVENT, INVALID }
var command_type : int

# Text parsing
const BANG_ASCII = 33
const AT_ASCII = 64
const ASCII_ZERO = 48
const ASCII_NINE = 57
const UPPER_ASCII_LIMIT = 90
const LOWER_ASCII_LIMIT = 65
const POUND_ASCII = 35

var original_line
# For audio and background
var file_name
var file_ext
# For dialogue
var dial_character
var dial_mood
var dial_line
var dial_emotion
enum IMAGE_LOCATION { LEFT = -1, CENTER, RIGHT, UNDEFINED = -99 }
var image_location = IMAGE_LOCATION.UNDEFINED
# For options
var opt_text
var opt_destination
# For waiting
var wait_seconds : float
const WAIT_FOREVER = -1
# For variables
enum OPERATION { PLUS, MINUS, EQUALS, INVALID }
var var_name
var var_operation : int = OPERATION.INVALID
var var_value
# For events
var event
var target
var direction
var duration

# Checking for validity, errors, etc
var error_message
func isValid():
	return command_type != TYPE.INVALID
func isCommand():
	return isValid() and command_type != TYPE.NONE

# And the meat and potatoes - parse a string into this type of variable
func _init(line : String):
	original_line = line
	# Empty line or comment line
	if line == null:
		command_type = TYPE.NONE
		return
	if line.begins_with("["):
		command_type = TYPE.NONE
		return
		
	# Options
	var arrow_posn = line.find_last("=>")
	if arrow_posn > 0:
		command_type = TYPE.OPTION
		opt_text = line.substr(0, arrow_posn)
		if opt_text.begins_with("-"):
			opt_text = opt_text.substr(1)
		opt_text = opt_text.strip_edges()
		opt_destination = line.substr(arrow_posn + 2).strip_edges()
		
	# Wait -- this one has to be before looking for a file
	if line.begins_with("..."):
		command_type = TYPE.WAIT
		var remainder = line.replace("...", "")
		if remainder.length() > 0:
			wait_seconds = float(remainder)
		else:
			wait_seconds = WAIT_FOREVER
			#if float(remainder)) == TYPE_INT:
			#	wait_seconds = int(remainder)
			#else:
			#	command_type = TYPE.INVALID
			#	error_message = "Invalid time given with wait: " + remainder
		return
		
	# Audio or image name
	var period_posn = line.find_last(".")
	if period_posn > 0: # If it's at 0 it's not a valid file name
		file_name = line.substr(0, period_posn)
		file_ext = line.substr(period_posn + 1)
		match file_ext:
			"wav":
				command_type = TYPE.AUDIO
				return
			"ogg":
				command_type = TYPE.AUDIO
				return
			"png":
				command_type = TYPE.BACKGROUND
				return
	
	# Variable
	if line.begins_with("$"):
		var op_posn = line.find("+") # Trying it out
		if op_posn >= 0:
			var_operation = OPERATION.PLUS
		else:
			op_posn = line.find("-")
			if op_posn >= 0:
				var_operation = OPERATION.MINUS
			else:
				op_posn = line.find("=")
				if op_posn >= 0:
					var_operation = OPERATION.EQUALS
		if var_operation != OPERATION.INVALID:
			command_type = TYPE.VARIABLE
			var_name = line.substr(1, op_posn-1) # Skip the $
			var_value = float(line.substr(op_posn + 1))
			return
		# If we get here after the line started with a $, it's a problem
		command_type = TYPE.INVALID
		error_message = "Invalid value used with variable: " + var_value
		return
	
	if line.begins_with("<"):
		command_type = TYPE.EVENT
		var exclamation = line.find("!")
		event = line.substr(1, exclamation - 1)
		var closeBracket = line.find(">")
		target = line.substr(exclamation + 1 , closeBracket - exclamation -1)
		if event == "SHOW":
			exclamation = target.find("!")
			var at = target.find("@")
			dial_character = target.substr(0, exclamation)
			dial_emotion = target.substr(exclamation + 1, at - exclamation - 1)
			target = target.substr(at +1, target.length() - at - 1)
		if event == "TITLE":
			event = "TITLE"
		if event == "SLIDE":
			var at = line.find("@")
			var lc = line.find(">")
			var pound = line.find("#")
			direction = line.substr(exclamation + 1, at - exclamation - 1)
			target = line.substr(at + 1, pound - at -1)
			duration = line.substr(pound + 1, lc - pound - 1)
			
	
	# Hide a character
	if line.begins_with("hide@"):
		command_type = TYPE.HIDE
		var side = line.substr(5)
		if side == "R":
			image_location = IMAGE_LOCATION.RIGHT
		elif side == "L":
			image_location = IMAGE_LOCATION.LEFT
		elif side == "C":
			image_location = IMAGE_LOCATION.CENTER
		else:
			image_location = IMAGE_LOCATION.UNDEFINED
			
	# Dialogue - two types
	if line.begins_with("\""):
		command_type = TYPE.DIALOGUE
		dial_character = "NR"
		dial_line = line.substr(1, line.length() - 2)
		dial_emotion = "neutral"
	var colon = line.find(":")
	var at = line.find("@")
	if colon >= 0:
		var i = 0
		var dialog = true
		# Check for valid ascii characters
		while(i < colon):
			var asc = ord(line[i])
			var valid = false
			if asc >= LOWER_ASCII_LIMIT && asc <= UPPER_ASCII_LIMIT:
				valid = true
			elif asc >= ASCII_ZERO && asc <= ASCII_NINE:
				valid = true
			elif asc == BANG_ASCII || asc == AT_ASCII:
				valid = true
			elif asc == POUND_ASCII:
				valid = true
			if !valid:
				dialog = false
				i = colon + 1
			i = i + 1
		if dialog:
			command_type = TYPE.DIALOGUE
		dial_character = line.substr(0, colon).strip_edges()
		dial_line = line.substr(colon + 1)
		dial_emotion = "neutral"
		# Emotions are denoted by !
		var exclamation = line.find("!")
		if (exclamation >= 0 and exclamation < colon):
			var erb = colon -1
			if(at >= 0):
				erb = min(at -1, erb)
			dial_emotion = line.substr(exclamation + 1, erb - exclamation)
			dial_character = line.substr(0, exclamation)
	# Character sides are denoted by @
	if at >= 0:
		var location = line.substr(at+1, 1)
		if location == "R":
			image_location = 1
		elif location == "L":
			image_location = -1
