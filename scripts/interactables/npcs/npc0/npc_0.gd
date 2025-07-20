extends StaticBody2D

@export var dialogue_resource: Resource

# Variable para recordar si ya hemos hablado con este NPC.
var has_spoken_before: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Al iniciar, reproduce la animación de reposo.
	animated_sprite.play("idle")


func interact(player):
	# Cuando el jugador interactúa, decidimos qué diálogo mostrar.
	if not has_spoken_before:
		# Si es la primera vez, mostramos el diálogo de "start".
		DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
		# Y actualizamos la memoria para saber que ya hemos hablado.
		has_spoken_before = true
	else:
		# Si ya hemos hablado, mostramos el diálogo de "loop_dialogue".
		DialogueManager.show_dialogue_balloon(dialogue_resource, "loop_dialogue")


# --- MANEJO DE SEÑALES DE INTERACCIÓN ---

# Se ejecuta cuando un cuerpo entra en nuestra Area2D.
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entró pertenece al grupo "player".
	if body.is_in_group("player"):
		# Si es así, nos "registramos" con el jugador.
		body.register_interactable(self)


# Se ejecuta cuando un cuerpo sale de nuestra Area2D.
func _on_area_2d_body_exited(body: Node2D) -> void:
	# Verificamos si es el jugador quien está saliendo.
	if body.is_in_group("player"):
		# Si es así, nos "damos de baja" del jugador.
		body.unregister_interactable(self)
