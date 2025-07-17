extends CharacterBody2D

const SPEED := 100
const RUN_MULTIPLIER := 1.5

func _physics_process(delta):
	var direccion := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direccion.x += 1
	if Input.is_action_pressed("move_left"):
		direccion.x -= 1
	if Input.is_action_pressed("move_down"):
		direccion.y += 1
	if Input.is_action_pressed("move_up"):
		direccion.y -= 1

	direccion = direccion.normalized()

	var speed_multiplier := 1.0
	if Input.is_action_pressed("ui_shift"):
		speed_multiplier = RUN_MULTIPLIER

	velocity = direccion * SPEED * speed_multiplier
	move_and_slide()

	# ─── Animación ─────────────────────────────
	if direccion == Vector2.ZERO:
		$Animation.play("idle")
	else:
		$Animation.play("idle")

		# Voltear sprite si se mueve a la izquierda o derecha
		if direccion.x < 0:
			$Animation.flip_h = true
		elif direccion.x > 0:
			$Animation.flip_h = false
