extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 120.0 # Um pouco mais rápido para te achar logo
const DETECTION_RANGE = 5000.0 # Alcance quase infinito dentro da gaiola

var player: Node2D = null
var health := 2
var damage_cooldown := 0.0

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if damage_cooldown > 0: damage_cooldown -= delta

	if player:
		var diff = player.global_position.x - global_position.x
		var distance = abs(diff)

		# Sempre persegue o jogador se ele existir
		var direction = sign(diff)
		
		# Se estiver muito perto, tenta atacar
		if distance < 60.0 and abs(player.global_position.y - global_position.y) < 100.0:
			velocity.x = 0
			animation.play("idle")
			if damage_cooldown <= 0:
				if player.has_method("take_damage"):
					player.take_damage()
					damage_cooldown = 1.5 # Tempo entre ataques do inimigo
		else:
			# Se estiver longe, corre atrás
			velocity.x = direction * SPEED
			animation.play("walk")
			animation.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animation.play("idle")
	
	# Se o inimigo cair por algum erro de mapa, ele morre e conta o ponto
	if global_position.y > 900:
		die()

	move_and_slide()

func take_damage() -> void:
	health -= 1
	var tween = create_tween()
	tween.tween_property(animation, "modulate", Color.WHITE, 0.1)
	tween.tween_property(animation, "modulate", Color(1, 0.38, 0.32), 0.1)
	if health <= 0: die()

func die() -> void:
	# Desativa colisões para não contar morte dupla
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	await tween.finished
	queue_free()
