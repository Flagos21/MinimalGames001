extends StaticBody2D

# Al usar @export, podemos escribir el mensaje de cada
# letrero directamente desde el editor de Godot.
@export_multiline var message: String = "Hola"

# Esta es la función que el jugador llamará cuando presione "E"
func interact(player):
	# El letrero no hace el trabajo de mostrar el UI.
	# Simplemente le pide al jugador que lo haga por él,
	# pasándole el mensaje que debe mostrar.
	player.show_message_box(message)

# Cuando el jugador entra en el área, nos registramos con él
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		body.register_interactable(self)

# Cuando el jugador sale del área, nos damos de baja
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		body.unregister_interactable(self)
