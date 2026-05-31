extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

const SPEED_NORMAL = 120.0

var player: Node2D = null
var health := 2
var max_health := 2
var damage_cooldown := 0.0
var speed := SPEED_NORMAL
var attack_damage_cooldown := 1.5
var attack_range := 60.0
var _base_color: Color

# Defina boss_type ANTES de add_child para configurar o boss no _ready
# 0 = inimigo normal, 1 = DeepSeek, 2 = Claude, 3 = GPT
var boss_type := 0
var is_boss := false

enum BossState { CHASE, WAIT, LUNGE }
var boss_state := BossState.CHASE
var boss_state_timer := 0.0
var lunge_dir := 1.0

signal health_changed(current: int, maximum: int)

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	_base_color = animation.modulate
	if boss_type > 0:
		_configure_boss()

func _configure_boss() -> void:
	is_boss = true
	match boss_type:
		1:  # DeepSeek — velocidade e agressividade
			health = 8
			max_health = 8
			speed = 220.0
			attack_damage_cooldown = 0.8
			attack_range = 70.0
			_base_color = Color(0.2, 0.85, 1.0)
		2:  # Claude — estratégico, avança em lunge
			health = 15
			max_health = 15
			speed = 150.0
			attack_damage_cooldown = 1.2
			attack_range = 80.0
			_base_color = Color(1.0, 0.5, 0.1)
		3:  # GPT — mais forte e frequente
			health = 25
			max_health = 25
			speed = 175.0
			attack_damage_cooldown = 0.5
			attack_range = 70.0
			_base_color = Color(0.1, 0.85, 0.4)
	animation.modulate = _base_color

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if damage_cooldown > 0:
		damage_cooldown -= delta

	if player:
		var diff = player.global_position.x - global_position.x
		var distance = abs(diff)

		if is_boss and boss_type == 2:
			_handle_claude(delta, diff, distance)
		else:
			_handle_chase(diff, distance)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		animation.play("idle")

	if global_position.y > 900:
		die()

	move_and_slide()

func _handle_chase(diff: float, distance: float) -> void:
	var direction = sign(diff)
	if distance < attack_range and abs(player.global_position.y - global_position.y) < 100.0:
		velocity.x = 0
		animation.play("idle")
		if damage_cooldown <= 0:
			if player.has_method("take_damage"):
				player.take_damage()
				damage_cooldown = attack_damage_cooldown
	else:
		velocity.x = direction * speed
		animation.play("walk")
		animation.flip_h = direction < 0

func _handle_claude(delta: float, diff: float, distance: float) -> void:
	boss_state_timer -= delta
	var direction = sign(diff)

	match boss_state:
		BossState.CHASE:
			if distance < 200.0:
				boss_state = BossState.WAIT
				boss_state_timer = 1.5
				velocity.x = 0
				animation.play("idle")
			else:
				velocity.x = direction * speed
				animation.play("walk")
				animation.flip_h = direction < 0

		BossState.WAIT:
			velocity.x = 0
			if boss_state_timer <= 0:
				lunge_dir = direction
				boss_state = BossState.LUNGE
				boss_state_timer = 0.4

		BossState.LUNGE:
			velocity.x = lunge_dir * 380.0
			animation.play("walk")
			animation.flip_h = lunge_dir < 0
			if distance < attack_range and abs(player.global_position.y - global_position.y) < 100.0:
				if damage_cooldown <= 0 and player.has_method("take_damage"):
					player.take_damage()
					damage_cooldown = attack_damage_cooldown
			if boss_state_timer <= 0:
				boss_state = BossState.CHASE

func take_damage() -> void:
	health -= 1
	var tween = create_tween()
	tween.tween_property(animation, "modulate", Color.WHITE, 0.1)
	tween.tween_property(animation, "modulate", _base_color, 0.1)
	health_changed.emit(health, max_health)
	if health <= 0:
		die()

func die() -> void:
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	await tween.finished
	queue_free()
