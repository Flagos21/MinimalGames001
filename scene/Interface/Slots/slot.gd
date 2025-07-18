extends TextureButton

@onready var label := $Label

func clear():
	texture_normal = null
	label.text = ""
	visible = true
