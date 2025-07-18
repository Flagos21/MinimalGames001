extends Node2D

# Carga previa del menú
var game_menu_scene := preload("res://scene/Interface/Menu.tscn")
var game_menu_instance: Node = null
var menu_abierto := false

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		if menu_abierto:
			# Cerrar el menú
			if game_menu_instance:
				game_menu_instance.queue_free()
				game_menu_instance = null
			menu_abierto = false
			get_tree().paused = false  # Reanudar el juego
		else:
			# Abrir el menú
			game_menu_instance = game_menu_scene.instantiate()
			$CanvasLayer.add_child(game_menu_instance)  # Añadir al CanvasLayer para UI
			menu_abierto = true
			get_tree().paused = true  # Pausar el juego
