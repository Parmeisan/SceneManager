extends Node
class_name ScriptCommand

enum TYPE { NONE, AUDIO, BACKGROUND, MOOD, VARIABLE, DIALOGUE, WAIT, INVALID }
var command_type : int

var original_line
# For audio and background
var file_name
var file_ext
# For dialogue
var dial_character
var dial_mood
var dial_line
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
		
	# Wait -- this one has to be before looking for a file
	if line.begins_with("..."):
		command_type = TYPE.WAIT
		var remainder = line.replace("...", "")
		print ("remainder %s (length %s)" % [remainder, remainder.length()])
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
			"ogg":
				command_type = TYPE.AUDIO
			"png":
				command_type = TYPE.BACKGROUND
		if command_type != null:
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
		print("position %s operation %s" % [op_posn, var_operation])
		if var_operation != OPERATION.INVALID:
			command_type = TYPE.VARIABLE
			var_name = line.substr(1, op_posn-1) # Skip the $
			var_value = float(line.substr(op_posn + 1))
			return
		# If we get here after the line started with a $, it's a problem
		command_type = TYPE.INVALID
		error_message = "Invalid value used with variable: " + var_value
		return
	
	# Dialogue
	var dash = line.find("-")
	if dash >= 0:
		command_type = TYPE.DIALOGUE
		dial_character = line.substr(0, dash).strip_edges()
		dial_line = line.substr(dash + 1)
