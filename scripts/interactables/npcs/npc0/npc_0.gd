extends StaticBody2D

var initial_animation: StringName = "idle_lado"
var initial_flip_h: bool = false

@export var dialogue_resource: Resource

# Variable para recordar si ya hemos hablado con este NPC.
var has_spoken_before: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play(initial_animation)
	animated_sprite.flip_h = initial_flip_h

func interact(player):
	# --- LÓGICA DE GIRO ---
	# 1. Obtenemos el vector que va desde la posición del NPC hacia la del jugador.
	var direction_to_player = player.global_position - self.global_position
	
	# 2. Comparamos las componentes vertical y horizontal para ver cuál domina.
	#    Esto nos dice si el jugador está más "a los lados" o más "arriba/abajo".
	if abs(direction_to_player.y) > abs(direction_to_player.x):
		# El movimiento vertical es más importante.
		if direction_to_player.y > 0:
			# El jugador está ABAJO del NPC -> El NPC mira al FRENTE.
			animated_sprite.play("idle_frente")
		else:
			# El jugador está ARRIBA del NPC -> El NPC mira de ESPALDAS.
			animated_sprite.play("idle_espalda")
	else:
		# El movimiento horizontal es más importante (o son iguales).
		# El NPC mira de LADO.
		animated_sprite.play("idle_lado")
		# Y ahora decidimos si voltear el sprite o no.
		# Si el jugador está a la izquierda (x < 0), volteamos.
		animated_sprite.flip_h = direction_to_player.x < 0
	
	# --- LÓGICA DE DIÁLOGO (EXISTENTE) ---
	# El resto de tu lógica de diálogo no cambia en absoluto.
	if not has_spoken_before:
		DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
		has_spoken_before = true
	else:
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
	if body.is_in_group("player"):
		body.unregister_interactable(self)
		# Al irse el jugador, el NPC vuelve a su orientación original.
		animated_sprite.play(initial_animation)
		animated_sprite.flip_h = initial_flip_h
