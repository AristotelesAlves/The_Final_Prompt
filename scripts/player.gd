extends CharacterBody2D

@onready var animetion: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const ATTACK_TIME = 0.45

var health := 100.0
var lives := 3
var is_attacking := false
var facing_right := true
var is_invincible := false
var is_reviving := false

# Mini-game de Reviver
var revive_mash := 0.0
var revive_goal := 100.0

# Canais de áudio
var sfx_attack: AudioStreamPlayer2D
var sfx_revive: AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("player")
	setup_audio()
	update_health_bar()
	update_hud_call()

func setup_audio() -> void:
	sfx_attack = AudioStreamPlayer2D.new()
	sfx_attack.stream = load("res://musics/sfx_attack.wav")
	add_child(sfx_attack)
	
	sfx_revive = AudioStreamPlayer2D.new()
	sfx_revive.stream = load("res://musics/gaita_do_reviver.mp3")
	sfx_revive.volume_db = -12.0
	add_child(sfx_revive)

func _physics_process(delta: float) -> void:
	if is_reviving:
		handle_revive(delta)
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_on_floor():
		if direction > 0: facing_right = true
		elif direction < 0: facing_right = false

	animetion.flip_h = not facing_right

	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	if not is_attacking:
		if direction != 0: animetion.play("walk")
		else: animetion.play("idle")

	move_and_slide()

func start_attack() -> void:
	is_attacking = true
	animetion.play("attack")
	if sfx_attack.stream: sfx_attack.play()
	check_attack_hit()
	await get_tree().create_timer(ATTACK_TIME).timeout
	is_attacking = false

func check_attack_hit() -> void:
	var attack_range = 100.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) < attack_range:
			if enemy.has_method("take_damage"): enemy.take_damage()

func take_damage() -> void:
	if is_invincible or health <= 0 or is_reviving: return
		
	health -= 25
	is_invincible = true
	update_health_bar()
	
	var tween = create_tween()
	tween.tween_property(animetion, "modulate", Color.RED, 0.1)
	tween.tween_property(animetion, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		start_revive_event()
	else:
		await get_tree().create_timer(1.0).timeout
		is_invincible = false

func start_revive_event() -> void:
	is_reviving = true
	revive_mash = 30.0
	velocity = Vector2.ZERO
	
	var hud = get_parent().get_node_or_null("HUD/Control/RevivePanel")
	if hud: hud.visible = true
	
	var game = get_parent()
	if game and "bgm" in game: game.bgm.stop()
	if sfx_revive.stream: sfx_revive.play()

func handle_revive(delta: float) -> void:
	revive_mash -= delta * 20.0 
	if Input.is_action_just_pressed("jump"): revive_mash += 10.0

	var mash_bar = get_parent().get_node_or_null("HUD/Control/RevivePanel/VBox/MashBar")
	if mash_bar: mash_bar.value = revive_mash

	if revive_mash >= revive_goal: complete_revive(true)
	elif revive_mash <= 0: complete_revive(false)

func complete_revive(success: bool) -> void:
	is_reviving = false
	var panel = get_parent().get_node_or_null("HUD/Control/RevivePanel")
	if panel: panel.visible = false
	sfx_revive.stop()
	
	if success:
		health = 100
		is_invincible = false
		var game = get_parent()
		if game and "bgm" in game: game.bgm.play()
		update_health_bar()
		update_hud_call()
	else:
		lives -= 1
		update_hud_call()
		if lives > 0:
			health = 100
			global_position = Vector2(100, 400)
			is_invincible = false
			var game = get_parent()
			if game and "bgm" in game: game.bgm.play()
			update_health_bar()
		else:
			get_tree().change_scene_to_file("res://scene/game_over.tscn")

func update_health_bar() -> void:
	if health_bar:
		health_bar.value = health

func update_hud_call() -> void:
	var game = get_parent()
	if game and game.has_method("update_hud"):
		game.update_hud()
