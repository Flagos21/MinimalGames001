extends CharacterBody2D

@export var speed := 100
@export var run_multiplier := 1.5

var direction := Vector2.ZERO
var is_running := false
var last_direction := Vector2.DOWN  # Por defecto, mirando abajo

func _physics_process(delta):
	get_input()
	move_and_slide()
	update_animation()

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
