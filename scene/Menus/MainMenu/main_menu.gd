extends Control

func _ready():
	$Menu/New.pressed.connect(_on_new_pressed)
	$Menu/Load.pressed.connect(_on_load_pressed)
	$Menu/Exit.pressed.connect(_on_exit_pressed)

func _on_new_pressed():
	get_tree().change_scene_to_file("res://scene/Map/Bosque/Bosque.tscn")

func _on_load_pressed():
	# Aquí puedes abrir una pantalla de selección o simplemente cargar
	print("Cargar partidas (aquí irá la lógica de guardado)")

func _on_exit_pressed():
	get_tree().quit()
