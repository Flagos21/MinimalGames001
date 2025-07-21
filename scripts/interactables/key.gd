extends Area2D

# Esta es la función que el jugador llamará cuando presione "E"
func interact(player):
	# La lógica de ser recogido ahora vive aquí
	player.inventory.append("key")
	print("Se ha añadido 'key' al inventario. Inventario actual: ", player.inventory)
	queue_free() # La llave se autodestruye

# Cuando el jugador entra en el área, nos registramos con él
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.register_interactable(self)

# Cuando el jugador sale del área, nos damos de baja
func _on_body_exited(body):
	if body.is_in_group("player"):
		body.unregister_interactable(self)
