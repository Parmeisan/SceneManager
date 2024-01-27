extends Node
class_name ScriptCommand

enum TYPE { NONE, AUDIO, BACKGROUND, MOOD, VARIABLE, DIALOGUE, OPTION, WAIT, INVALID }
var command_type : int

var original_line
# For audio and background
var file_name
var file_ext
# For dialogue
var dial_character
var dial_mood
var dial_line
var dial_emotion
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
	
	# Dialogue - two types
	if line.begins_with("\""):
		command_type = TYPE.DIALOGUE
		dial_character = "NR"
		dial_line = line.substr(1, line.length() - 2)
		dial_emotion = "neutral"
	var colon = line.find(":")
	if colon >= 0:
		var i = 0;
		var dialog = true;
		while(i < colon):
			var asc = ord(line[i])
			if(!(asc >= 65 && asc <= 90) && !(asc == 33)):
				dialog = false;
				i = colon + 1;
			i = i + 1;
		if dialog:
			command_type = TYPE.DIALOGUE
		dial_character = line.substr(0, colon).strip_edges()
		dial_line = line.substr(colon + 1)
		dial_emotion = "neutral" # TODO
