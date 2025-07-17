extends CanvasLayer

@export var corazon_lleno: Texture2D
@export var corazon_vacio: Texture2D

var vida_maxima := 5
var vida_actual := 1

func _ready():
	actualizar_barra_vida()

func actualizar_barra_vida():
	for i in range(vida_maxima):
		var corazon = $HBoxContainer.get_child(i)
		if i < vida_actual:
			corazon.texture = corazon_lleno
		else:
			corazon.texture = corazon_vacio
