# sign.gd
extends StaticBody2D

# Al igual que el NPC, ahora exportamos el recurso de diálogo.
# Podemos arrastrar nuestro archivo .dialogue aquí desde el Inspector.
@export var dialogue_resource: Resource

# La función de interacción ahora es idéntica a la del NPC.
func interact(player):
	# Simplemente le pide al DialogueManager que inicie nuestro "guion".
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

# Las señales de interacción no cambian.
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		body.unregister_interactable(self)
