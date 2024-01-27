extends Control
class_name SceneCharacter

export var character_abbreviation : String
export var character_full_name : String
export var neutral_image : Texture
#export (Array, String) var emotions
export (Array, String) var emotion_keywords
export (Array, Texture) var emotion_images
export var dialogue_colour : Color
export var dialogue_shadow : Color
export var dialogue_background : Color
export var dialogue_fontname : String
export var dialogue_fontsize : int
export var image_side : int

# It would be nice to have a dictionary of textures accessible by the keyword
# Hopefully the number of keywords and images above are the same...
var emotions = {}

func _ready():
	var size = min(emotion_keywords.size(), emotion_images.size())
	var i = 0

func GetEmotionTexture(e : String):
	if emotion_keywords.has(e):
		var pos = emotion_keywords.find(e, 0)
		return emotion_images[pos]
	else:
		return neutral_image

#func setLabelFont(label, c):
#	var font = Game.getFont(c.Font_Path, c.Font_Filename, c.Font_Extension)
#	font.size = int(c.Font_Size)
#	label.set("custom_fonts/font", font)
#	label.set("custom_colors/font_color", c.Font_Colour)
#	if c.Font_Shadow != "":
#		label.set("custom_colors/font_color_shadow", c.Font_Shadow)
