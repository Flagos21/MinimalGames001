extends Control

@onready var grid := $GridContainer
var slot_scene := preload("res://scene/Interface/Slots/Slot.tscn")

func _ready():
	# Limpia el contenedor por si acaso


	# Instancia 20 slots vacíos
	for i in range(20):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.clear()  # Asegura que no muestre nada
