extends CharacterBody2D # El jugador es un cuerpo de personaje, lo que le da físicas básicas.

#=============================================================================
# --- VARIABLES ---
# Las variables controlan el comportamiento y estado del jugador.
#=============================================================================

@export var speed := 100 # Velocidad base de movimiento del jugador en píxeles/segundo.
@export var run_multiplier := 1.5 # Multiplicador de velocidad cuando el jugador está corriendo (sprint).

@export var message_box: Control # Referencia a un nodo de interfaz de usuario para mostrar mensajes (ej. diálogos).

# Enum (enumeración) para definir los posibles estados del jugador.
# Ayuda a controlar la lógica específica de cada estado en _physics_process.
enum State { MOVE, DIALOGUE, IN_VEHICLE } 

var current_vehicle = null # Referencia al vehículo actual en el que el jugador está montado (si aplica).
var initial_camera_position: Vector2 # Almacena la posición LOCAL original de la cámara respecto al jugador.
@onready var camera = $Camera # Referencia al nodo Camera2D hijo. Se inicializa cuando el nodo está listo.
@onready var sprite: AnimatedSprite2D = $Sprite # Referencia al nodo AnimatedSprite2D hijo para las animaciones.
@onready var collision_shape: CollisionShape2D = $HitBox # Referencia a la forma de colisión del jugador.
var current_state = State.MOVE # Estado inicial del jugador al comenzar el juego.

var direction := Vector2.ZERO # Vector de dirección del movimiento del jugador (normalizado).
var is_running := false # Booleano para saber si el jugador está actualmente corriendo.
var last_direction := Vector2.DOWN # Almacena la última dirección de movimiento para animaciones de inactividad.

var interactable_in_range = null # Referencia al objeto interactuable más cercano.
var inventory = [] # Lista para almacenar los ítems que tiene el jugador.

# --- ¡NUEVA VARIABLE PARA ROBUSTZ! ---
# Almacenará la posición local del sprite cuando es hijo del Player.
# Esto es útil si decides cambiar el offset del sprite en el editor en el futuro.
var _original_sprite_local_position: Vector2 

#=============================================================================
# --- FUNCIONES DEL MOTOR DE GODOT ---
# Estas funciones son llamadas automáticamente por Godot en momentos específicos.
#=============================================================================

func _ready():
	# Conecta las señales del DialogueManager para manejar el inicio y fin de diálogos.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.mutated.connect(_on_dialogue_mutated)
	
	# Captura la posición LOCAL original de la cámara (configurada en el editor).
	# Esta es la base para cómo la cámara siempre verá al jugador.
	initial_camera_position = camera.position
	
	# --- ¡CAPTURA DE LA POSICIÓN ORIGINAL DEL SPRITE! ---
	# En _ready(), el sprite ya está en su posición local por defecto (ej. Vector2(0, -15))
	# respecto a su padre (el nodo Player). La capturamos aquí para usarla más tarde.
	_original_sprite_local_position = sprite.position

# _physics_process se ejecuta en cada fotograma de física.
# Es ideal para el movimiento y la lógica de colisión.
func _physics_process(delta):
	# Usa una sentencia 'match' para ejecutar la lógica específica según el 'current_state'.
	match current_state:
		State.MOVE:
			# Si el jugador presiona "interactuar" y hay algo interactuable en rango.
			if Input.is_action_just_pressed("interact") and interactable_in_range != null:
				interactable_in_range.interact(self) # Llama al método 'interact' del objeto.
				return # Salimos para no procesar movimiento si interactuamos.
			
			get_input() # Procesa las entradas de teclado para determinar la dirección.
			
			# Calcula la velocidad final, aplicando el multiplicador si está corriendo.
			var final_speed = speed * (run_multiplier if is_running else 1)
			velocity = direction * final_speed # Establece la velocidad para move_and_slide.
			move_and_slide() # Mueve el CharacterBody2D y maneja las colisiones.
			update_animation() # Actualiza la animación del sprite.
		
		State.DIALOGUE:
			# En este estado, el jugador no se mueve. La lógica de diálogo se maneja externamente.
			pass
			
		State.IN_VEHICLE:
			# Si el jugador presiona "interactuar" mientras está en el vehículo, desmonta.
			if Input.is_action_just_pressed("interact"):
				dismount_vehicle()
				return # Salimos para no procesar movimiento del vehículo.
			
			get_input() # Obtiene la dirección de movimiento para el vehículo.
			
			# Damos velocidad al vehículo. El vehículo se mueve por su cuenta.
			current_vehicle.velocity = direction * current_vehicle.speed
			
			# --- ¡SOLUCIÓN CLAVE PARA LA CONSISTENCIA DE CÁMARA EN VEHÍCULO! ---
			# El nodo Player (y, por lo tanto, su Camera2D) ahora seguirá la posición GLOBAL
			# del PlayerMountPoint del barco. Esto es CRUCIAL.
			# Como el PlayerMountPoint está configurado para ser donde los PIES del jugador deben estar
			# cuando está montado, esto asegura que la cámara siempre vea la BASE del personaje
			# de manera CONSISTENTE, tanto en el vehículo como a pie, eliminando los "saltos".
			self.global_position = current_vehicle.get_node("PlayerMountPoint").global_position
			
			update_player_animation_in_vehicle() # Actualiza la animación del jugador en el vehículo.


#=============================================================================
# --- MANEJO DE SEÑALES DE DIALOGUE MANAGER ---
# Estas funciones se llaman cuando el sistema de diálogo emite señales.
#=============================================================================

func _on_dialogue_started(resource: Resource):
	current_state = State.DIALOGUE # Cambia el estado del jugador a DIALOGUE.
	_force_idle_animation() # Asegura que el jugador muestre una animación de inactividad durante el diálogo.

func _on_dialogue_ended(_resource: Resource):
	current_state = State.MOVE # Vuelve al estado de movimiento cuando el diálogo termina.

func _on_dialogue_mutated(data: Dictionary):
	# Esta función se llama cuando los datos del diálogo cambian.
	# Actualmente no tiene lógica implementada.
	pass

#=============================================================================
# --- SISTEMA DE INTERACCIÓN, MOVIMIENTO Y ANIMACIÓN ---
# Funciones auxiliares para la interacción, entrada y animaciones.
#=============================================================================

# Registra un objeto interactuable cuando el jugador entra en su rango.
func register_interactable(obj):
	interactable_in_range = obj

# Desregistra un objeto interactuable cuando el jugador sale de su rango.
func unregister_interactable(obj):
	if interactable_in_range == obj:
		interactable_in_range = null # Usa 'null' en GDScript para valores nulos.

# Comprueba si el jugador tiene un ítem específico en su inventario.
func has_item(item_name):
	return item_name in inventory

# Fuerza una animación de inactividad basada en la última dirección.
func _force_idle_animation():
	# Elige la animación de inactividad frontal, trasera o lateral.
	sprite.play("BackIdle" if last_direction.y < 0 else "FrontIdle" if last_direction.y > 0 else "SideIdle")
	# Voltea el sprite horizontalmente si la última dirección fue hacia la izquierda.
	if last_direction.x != 0:
		sprite.flip_h = last_direction.x < 0

# Procesa las entradas del teclado para determinar la dirección de movimiento.
func get_input():
	direction = Vector2.ZERO # Reinicia la dirección en cada fotograma.
	# Añade componentes a la dirección según las teclas presionadas.
	if Input.is_action_pressed("move_up"): direction.y -= 1
	if Input.is_action_pressed("move_down"): direction.y += 1
	if Input.is_action_pressed("move_left"): direction.x -= 1
	if Input.is_action_pressed("move_right"): direction.x += 1
	direction = direction.normalized() # Normaliza el vector para que la velocidad sea constante en diagonal.
	
	# Si el jugador se está moviendo, actualiza la última dirección.
	if direction != Vector2.ZERO:
		last_direction = direction
	
	is_running = Input.is_action_pressed("sprint") # Actualiza el estado de "correr".

# Actualiza la animación del sprite del jugador basada en la dirección y el estado de carrera.
func update_animation():
	# is_stuck ayuda a manejar casos donde direction no es ZERO pero velocity sí (ej. contra una pared).
	var is_stuck = direction != Vector2.ZERO and velocity.is_zero_approx()
	
	if direction == Vector2.ZERO or is_stuck:
		_force_idle_animation() # Si no se mueve o está atascado, reproduce animación de inactividad.
	else:
		# Determina el prefijo de la animación (Back, Front, Side).
		var anim_prefix = "Back" if direction.y < 0 else "Front" if direction.y > 0 else "Side"
		# Determina el sufijo de la animación (Sprint o Walk).
		var anim_suffix = "Sprint" if is_running else "Walk"
		sprite.play(anim_prefix + anim_suffix) # Reproduce la animación combinada.
		
		# Si la animación es lateral, voltea el sprite según la dirección horizontal.
		if anim_prefix == "Side":
			sprite.flip_h = direction.x < 0

#=============================================================================
# --- SISTEMA DE MONTAR VEHICULOS ---
# Funciones para la lógica de montar y desmontar vehículos.
#=============================================================================

# Actualiza la animación del jugador cuando está en el vehículo.
# (Generalmente una animación de inactividad, ya que el vehículo es el que se mueve).
func update_player_animation_in_vehicle():
	# Decidimos qué dirección usar para la animación: la actual si nos movemos,
	# o la última guardada si estamos quietos.
	var anim_direction = direction if not direction.is_zero_approx() else last_direction
	
	# Aplicamos la lógica de 'Idle' a esa dirección para una orientación consistente.
	if abs(anim_direction.y) > abs(anim_direction.x):
		if anim_direction.y > 0:
			sprite.play("FrontIdle")
		else:
			sprite.play("BackIdle")
	else:
		sprite.play("SideIdle")
		sprite.flip_h = anim_direction.x < 0

func mount_vehicle(vehicle):
	current_vehicle = vehicle
	current_state = State.IN_VEHICLE
	
	vehicle.start_piloting()
	
	# Desactivamos el CUERPO del jugador.
	collision_shape.set_deferred("disabled", true)
	
	# Movemos el SPRITE ORIGINAL al barco.
	remove_child(sprite)
	vehicle.get_node("PlayerMountPoint").add_child(sprite)
	
	# Aplicamos el offset original del sprite para que se posicione correctamente.
	sprite.position = _original_sprite_local_position
	
	# Transferimos la CÁMARA al vehículo.
	if camera.get_parent() == self:
		remove_child(camera)
		vehicle.add_child(camera)

func dismount_vehicle():
	var vehicle = current_vehicle
	var mount_point = vehicle.get_node("PlayerMountPoint")
	
	vehicle.stop_piloting()
	
	# Recuperamos nuestro SPRITE ORIGINAL.
	mount_point.remove_child(sprite)
	add_child(sprite)
	
	# Recuperamos la CÁMARA.
	if camera.get_parent() == vehicle:
		vehicle.remove_child(camera)
		add_child(camera)
	
	# Reaparecemos al lado del barco y REACTIVAMOS el cuerpo.
	global_position = vehicle.global_position + Vector2(0, 30)
	collision_shape.set_deferred("disabled", false)
	
	# Reseteamos el estado.
	current_vehicle = null
	current_state = State.MOVE
