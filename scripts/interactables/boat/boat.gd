# boat.gd
# Este script controla el comportamiento del vehículo "Barco", permitiendo
# que sea pilotado por el jugador y gestionando sus animaciones y colisiones.
extends CharacterBody2D

#=============================================================================
# --- VARIABLES CONFIGURABLES (DESDE EL INSPECTOR) ---
#=============================================================================

# La velocidad a la que se moverá el barco cuando esté siendo pilotado.
@export var speed := 150

# Con @export, podemos elegir la animación inicial desde un menú en el Inspector.
# Esto nos permite colocar barcos en la escena mirando en diferentes direcciones.
@export var initial_animation: StringName = &"idle_lado"

# Asignamos aquí, arrastrando desde la escena, el nodo de colisión que debe
# estar activo cuando el barco está aparcado.
@export var initial_collider: CollisionShape2D


#=============================================================================
# --- REFERENCIAS A NODOS HIJOS (@onready) ---
#=============================================================================

# Referencia al nodo 'Visuals', que contiene todos los elementos gráficos.
# Lo usamos para voltear la apariencia del barco sin afectar su colisión.
@onready var visuals: Node2D = $Visuals

# Referencia al sprite para cambiar las animaciones.
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D

# Referencias a nuestras 3 formas de colisión para activarlas/desactivarlas.
# ¡Asegúrate de que los nombres coincidan con los de tu escena!
@onready var collision_side: CollisionShape2D = $CollisionSide
@onready var collision_front: CollisionShape2D = $CollisionFront
@onready var collision_back: CollisionShape2D = $CollisionBack


#=============================================================================
# --- FUNCIONES DEL MOTOR DE GODOT ---
#=============================================================================

# _ready() se ejecuta una sola vez cuando el nodo entra en la escena.
# Es perfecto para la configuración inicial.
func _ready() -> void:
	# El barco empieza "apagado" (su física no se procesa).
	set_physics_process(false)
	# Reproduce la animación inicial que hemos definido en el Inspector.
	animated_sprite.play(initial_animation)
	
	# Desactivamos todas las colisiones primero para empezar desde un estado limpio.
	collision_side.disabled = true
	collision_front.disabled = true
	collision_back.disabled = true
	
	# Y luego activamos ÚNICAMENTE la colisión inicial que hemos asignado en el Inspector.
	# La comprobación 'if initial_collider:' evita errores si olvidamos asignarla.
	if initial_collider:
		initial_collider.disabled = false

# _physics_process() se ejecuta en cada fotograma de física, pero solo si está activado.
func _physics_process(delta):
	# Mueve el cuerpo basándose en su 'velocity' y gestiona las colisiones.
	move_and_slide()
	# Después de movernos, actualizamos la animación y la colisión.
	update_boat_animation_and_collision()


#=============================================================================
# --- CONTROL DEL VEHÍCULO ---
#=============================================================================

# El jugador llama a esta función para "encender" el motor del barco.
func start_piloting():
	set_physics_process(true)

# El jugador llama a esta función para "apagar" el motor del barco.
func stop_piloting():
	# Simplemente detenemos el movimiento y apagamos la física.
	# Ya no lo forzamos a volver a un estado inicial. Se quedará
	# con la última animación y colisión que tuvo.
	velocity = Vector2.ZERO
	set_physics_process(false)


#=============================================================================
# --- LÓGICA DE ANIMACIÓN Y COLISIÓN ---
#=============================================================================

# Actualiza la apariencia y la forma física del barco mientras se mueve.
func update_boat_animation_and_collision():
	# Si el barco no se está moviendo, no hacemos nada.
	if velocity.is_zero_approx():
		return

	# Si se está moviendo, elegimos la animación y colisión correctas.
	if abs(velocity.y) > abs(velocity.x): # Movimiento Vertical
		collision_side.disabled = true
		if velocity.y > 0:
			animated_sprite.play("idle_frente")
			collision_front.disabled = false
			collision_back.disabled = true
		else:
			animated_sprite.play("idle_espalda")
			collision_front.disabled = true
			collision_back.disabled = false
		visuals.scale.x = 1 # Nos aseguramos de que no esté volteado.
	else: # Movimiento Horizontal
		animated_sprite.play("idle_lado")
		collision_side.disabled = false
		collision_front.disabled = true
		collision_back.disabled = true
		# Volteamos el nodo 'Visuals' para la dirección.
		visuals.scale.x = 1 if velocity.x > 0 else -1


#=============================================================================
# --- LÓGICA DE INTERACCIÓN ---
#=============================================================================

# El jugador llama a esta función al presionar 'E'.
func interact(player):
	player.mount_vehicle(self)

# --- MANEJO DE SEÑALES DE AREA2D ---
# Se conectan a las señales 'body_entered' y 'body_exited' del Area2D.

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.register_interactable(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.unregister_interactable(self)
