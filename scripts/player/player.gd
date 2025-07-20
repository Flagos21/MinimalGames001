extends CharacterBody2D

#=============================================================================
# --- VARIABLES CONFIGURABLES ---
# Estas variables aparecen en el Inspector de Godot para ajustarlas fácilmente.
#=============================================================================
@export var speed := 100
@export var run_multiplier := 1.5

#==================================================aw=========================
# --- MÁQUINA DE ESTADOS Y VARIABLES INTERNAS ---
#=============================================================================
# Usamos una Máquina de Estados Finita (FSM) para controlar el comportamiento del jugador.
# Cada estado define un conjunto de acciones y transiciones permitidas.
enum State { MOVE, DIALOGUE } 
var current_state = State.MOVE

# Variables para la lógica de movimiento y animación.
var direction := Vector2.ZERO # La dirección en la que el jugador intenta moverse.
var is_running := false      # Verdadero si el jugador está corriendo.
var last_direction := Vector2.DOWN # Guarda la última dirección para las animaciones 'Idle'.

# Almacena el objeto con el que se puede interactuar si está en rango.
# Es 'null' si no hay nada cerca.
var interactable_in_range = null

# Inventario simple para guardar ítems como strings.
var inventory = []


#=============================================================================
# --- FUNCIONES DEL MOTOR DE GODOT ---
#=============================================================================

# La función _ready() se ejecuta una sola vez cuando el nodo entra en la escena.
# Es el lugar ideal para configurar conexiones iniciales y suscripciones a eventos.
func _ready():
	# Nos suscribimos a las "notificaciones" (señales) del Dialogue Manager.
	# Esto desacopla a nuestro jugador: no necesita saber CÓMO funciona el diálogo,
	# solo reacciona a los eventos de 'inicio', 'fin' y 'nueva línea'.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.mutated.connect(_on_dialogue_mutated)

# La función _physics_process() se ejecuta en cada fotograma de física.
# Es el corazón de la lógica del jugador, donde nuestra máquina de estados opera.
func _physics_process(delta):
	# El 'match' dirige el flujo del código al bloque correspondiente al estado actual.
	match current_state:
		
		State.MOVE:
			# Lógica cuando el jugador puede moverse libremente.
			# Primero, comprobamos si se inicia una interacción.
			if Input.is_action_just_pressed("interact") and interactable_in_range != null:
				# Delegamos la acción al objeto interactuable ('interactable_in_range').
				interactable_in_range.interact(self)
				# 'return' es crucial para evitar bugs de "mismo frame". Detiene la ejecución aquí
				# para que la lógica de movimiento no anule la de la interacción recién iniciada.
				return
			
			# Si no hubo interacción, procesamos el movimiento y la animación.
			get_input()
			move_and_slide()
			update_animation()
		
		State.DIALOGUE:
			# Cuando estamos en diálogo, no hacemos nada activamente aquí.
			# El plugin DialogueManager gestiona la entrada (tecla 'E'/Espacio)
			# por sí mismo, ya que escucha la acción "ui_accept" de forma global.
			# Dejar 'pass' es la forma más limpia de manejarlo.
			pass


#=============================================================================
# --- MANEJO DE SEÑALES DE DIALOGUE MANAGER ---
# Estas funciones se ejecutan automáticamente cuando el plugin emite una señal.
#=============================================================================

# Se ejecuta cuando un diálogo comienza. Recibe el recurso de diálogo como argumento.
func _on_dialogue_started(resource: Resource):
	# Cambiamos el estado para detener el movimiento y la lógica de interacción.
	current_state = State.DIALOGUE
	# Forzamos la animación de reposo para que el jugador se vea quieto.
	_force_idle_animation()

# Se ejecuta cuando un diálogo termina. Recibe el recurso de diálogo como argumento.
func _on_dialogue_ended(_resource: Resource):
	# Devolvemos el control al jugador, permitiéndole moverse de nuevo.
	current_state = State.MOVE

# Se ejecuta cuando hay una nueva línea de texto para mostrar.
func _on_dialogue_mutated(data: Dictionary):
	pass
	
#=============================================================================
# --- SISTEMA DE INTERACCIÓN, MOVIMIENTO Y ANIMACIÓN ---
#=============================================================================
# Permite que otros objetos (NPCs, letreros) se registren con el jugador.
func register_interactable(obj):
	interactable_in_range = obj

# Permite que los objetos se den de baja cuando el jugador se aleja.
func unregister_interactable(obj):
	if interactable_in_range == obj:
		interactable_in_range = null

# Comprueba si un ítem existe en el inventario.
func has_item(item_name):
	return item_name in inventory

# Función de ayuda para forzar la animación de reposo y no repetir código.
func _force_idle_animation():
	var sprite := $Sprite
	if last_direction.y < 0: sprite.play("BackIdle")
	elif last_direction.y > 0: sprite.play("FrontIdle")
	elif last_direction.x != 0:
		sprite.play("SideIdle")
		sprite.flip_h = last_direction.x < 0

# Procesa las entradas del teclado para determinar la dirección e intención de movimiento.
func get_input():
	direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"): direction.y -= 1
	if Input.is_action_pressed("move_down"): direction.y += 1
	if Input.is_action_pressed("move_left"): direction.x -= 1
	if Input.is_action_pressed("move_right"): direction.x += 1
	
	direction = direction.normalized()
	
	if direction != Vector2.ZERO:
		last_direction = direction
	
	is_running = Input.is_action_pressed("sprint")
	var final_speed = speed * (run_multiplier if is_running else 1)
	velocity = direction * final_speed

# Actualiza la animación del sprite basándose en el estado del movimiento.
func update_animation():
	var sprite := $Sprite
	# Comprueba si el jugador INTENTA moverse ('direction') pero la FÍSICA ('velocity')
	# se lo impide, por ejemplo, al chocar contra una pared.
	var is_stuck = direction != Vector2.ZERO and velocity.is_zero_approx()

	# Si el jugador está quieto o atascado, forzamos la animación de reposo.
	if direction == Vector2.ZERO or is_stuck:
		_force_idle_animation()
	# Si no, se está moviendo, así que reproducimos la animación correspondiente.
	else:
		if direction.y < 0: sprite.play("BackSprint" if is_running else "BackWalk")
		elif direction.y > 0: sprite.play("FrontSprint" if is_running else "FrontWalk")
		elif direction.x != 0:
			sprite.play("SideSprint" if is_running else "SideWalk")
			# Aplicamos el volteo del sprite para el movimiento lateral.
			sprite.flip_h = direction.x < 0
