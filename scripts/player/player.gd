extends CharacterBody2D

@export var speed := 100
@export var run_multiplier := 1.5

enum State { MOVE, UI }
var current_state = State.MOVE
@export var message_box: Control

var direction := Vector2.ZERO
var is_running := false
var last_direction := Vector2.DOWN  # Por defecto, mirando abajo

#Referencia para el sprite del item sostenido en la mano
#@onready var held_item_sprite = $Hand/HeldItemSprite

#Funcion que actualiza visualmente el item sostenido en la mano
#func update_held_item_visual():
#	# Preguntamos: ¿Está el item "key" en nuestro inventario?
#	if has_item("key"):
#		# Si es así, hacemos visible el sprite de la llave.
#		held_item_sprite.visible = true
#	else:
#		# Si no, nos aseguramos de que esté invisible.
#		held_item_sprite.visible = false

# Guardará el objeto con el que podemos interactuar si esta cerca
var interactable_in_range = null

#Se agrega inventario basico para almacenar la llave
var inventory = []

#Funcion para validar si el usuario tiene algun item en concreto
func has_item(item_name):
	return item_name in inventory
	
func register_interactable(obj):
	interactable_in_range = obj

func unregister_interactable(obj):
	# Nos aseguramos de no borrar la referencia si ya hemos entrado en otra área
	if interactable_in_range == obj:
		interactable_in_range = null

func show_message_box(message: String):
	message_box.get_node("PanelContainer/Label").text = message
	message_box.visible = true
	current_state = State.UI

func _physics_process(delta):
	match current_state:
		State.MOVE:
			if Input.is_action_just_pressed("interact") and interactable_in_range != null:
				interactable_in_range.interact(self)
			get_input()
			move_and_slide()
			update_animation()
			# update_held_item_visual() 
		State.UI:
			# Se cierra el mensaje/sign con "interact" (E) O con "ui_cancel" (Escape)
			if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
				message_box.visible = false
				current_state = State.MOVE

func get_input():
	direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	direction = direction.normalized()

	# Guardamos la última dirección si se está moviendo
	if direction != Vector2.ZERO:
		last_direction = direction

	is_running = Input.is_action_pressed("sprint")
	var final_speed = speed * (run_multiplier if is_running else 1)
	velocity = direction * final_speed

func update_animation():
	var sprite := $Sprite

	if direction != Vector2.ZERO:
		# Movimiento hacia arriba
		if direction.y < 0:
			sprite.play("BackSprint" if is_running else "BackWalk")

		# Movimiento hacia abajo
		elif direction.y > 0:
			sprite.play("FrontSprint" if is_running else "FrontWalk")

		# Movimiento lateral (predomina si direction.x ≠ 0)
		elif direction.x != 0:
			sprite.play("SideSprint" if is_running else "SideWalk")

		# Flip horizontal solo para movimiento lateral
		if direction.x != 0:
			sprite.flip_h = direction.x < 0

	else:
		# Reposo: usar última dirección
		if last_direction.y < 0:
			sprite.play("BackIdle")
		elif last_direction.y > 0:
			sprite.play("FrontIdle")
		elif last_direction.x != 0:
			sprite.play("SideIdle")
			sprite.flip_h = last_direction.x < 0
