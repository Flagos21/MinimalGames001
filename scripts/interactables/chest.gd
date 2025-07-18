extends StaticBody2D

# Este cofre solo se abre si el jugador tiene la llave llamada item (revisa el inventario)

# Una variable para saber si el cofre ya fue abierto
var is_open = false

# La función que el jugador llamará al presionar "E"
func interact(player):
	# Si ya está abierto, no hacemos nada
	if is_open:
		print("El cofre ya está abierto.")
		return # 'return' detiene la función aquí

	# Revisamos el inventario del jugador
	if player.has_item("key"):
		print("¡Usaste la llave! El cofre se abre.")
		is_open = true
		
		# (FUTURO) Aquí podrías cambiar el sprite a un cofre abierto
		# $Sprite2D.texture = load("res://assets/interactables/chest_open.png")
		
		# (FUTURO) Aquí podrías darle loot al jugador
		# player.inventory.append("gold_coin")
	else:
		print("El cofre está cerrado. Necesitas una llave.")

# --- ¡ESTAS FUNCIONES SON LAS MISMAS QUE EN LA LLAVE! ---
# Solo cambia el nombre del método porque conectamos la señal desde un nodo hijo

# Cuando el jugador entra en el área, nos registramos con él
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		body.register_interactable(self)

# Cuando el jugador sale del área, nos damos de baja
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		body.unregister_interactable(self)
