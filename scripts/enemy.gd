extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 100.0
const DETECTION_RANGE = 500.0

var player: Node2D = null
var health := 2
var damage_cooldown := 0.0
var direction := 1.0

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

		if distance < DETECTION_RANGE:
			direction = sign(diff)
			
			# Lógica rudimentar para evitar buracos:
			# Se estiver indo para um abismo ou parede (fora dos limites do chão)
			if global_position.x < 100 or global_position.x > 1800:
				direction *= -1
			
			velocity.x = direction * SPEED
			animation.play("walk")
			animation.flip_h = direction < 0
			
			if distance < 60.0 and abs(player.global_position.y - global_position.y) < 100.0:
				if damage_cooldown <= 0:
					if player.has_method("take_damage"):
						player.take_damage()
						damage_cooldown = 1.0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			animation.play("idle")
	
	move_and_slide()

func take_damage() -> void:
	health -= 1
	var tween = create_tween()
	tween.tween_property(animation, "modulate", Color.WHITE, 0.1)
	tween.tween_property(animation, "modulate", Color(1, 0.38, 0.32), 0.1)
	if health <= 0: die()

func die() -> void:
	set_physics_process(false)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	await tween.finished
	queue_free()
