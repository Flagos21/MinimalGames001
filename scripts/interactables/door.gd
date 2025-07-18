extends StaticBody2D

#Variable si la puerta esta abierta, comienza como cerrada
var is_open = false

func interact(player):
	if is_open:
		return

	is_open = true
	print("La puerta se ha abierto y ha desaparecido.") # Mensaje actualizado
	
	# 1. Hacemos que la puerta entera (y sus hijos) sea invisible.
	visible = false
	# 2. Seguimos desactivando la colisión. Esto es importante.
	#    Aunque la puerta sea invisible, si su colisión estuviera activa,
	#    seguiría bloqueando el paso del jugador.
	$CollisionShape2D.disabled = true
	
	# 3. Nos damos de baja de la interacción.
	player.unregister_interactable(self)

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		body.unregister_interactable(self)
