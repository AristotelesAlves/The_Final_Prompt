extends CharacterBody2D

@onready var animetion: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const ATTACK_TIME = 0.35

var is_attacking := false
var facing_right := true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")

	# Movimento
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Guarda direção do personagem
	if direction > 0:
		facing_right = true
	elif direction < 0:
		facing_right = false

	# Aplica flip UMA VEZ
	animetion.flip_h = not facing_right

	# Ataque
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	# Animações
	if not is_attacking:
		if direction != 0:
			animetion.play("walk")
		else:
			animetion.play("idle")

	move_and_slide()

func start_attack() -> void:
	is_attacking = true
	animetion.play("attack")

	await get_tree().create_timer(ATTACK_TIME).timeout

	is_attacking = false
