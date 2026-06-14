extends CharacterBody2D

@onready var animetion: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

const SPEED = 400.0
const ACCEL = 1500.0
const FRICTION = 2000.0
const JUMP_VELOCITY = -600.0
const ATTACK_TIME = 0.45

var grenade_scene = preload("res://entities/granada.tscn")
var grenade_cooldown := 0.0
var grenades_ammo := 0

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
var sfx_attack: AudioStreamPlayer
var sfx_revive: AudioStreamPlayer
var sfx_steps: AudioStreamPlayer
var sfx_jump: AudioStreamPlayer

func _ready() -> void:
	add_to_group("player")
	setup_audio()
	update_health_bar()
	update_hud_call()

func setup_audio() -> void:
	sfx_attack = AudioStreamPlayer.new()
	sfx_attack.stream = load("res://musics/sfx_attack.wav")
	sfx_attack.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	sfx_attack.volume_db = 0.0
	add_child(sfx_attack)
	
	sfx_revive = AudioStreamPlayer.new()
	sfx_revive.stream = load("res://musics/gaita_do_reviver.mp3")
	sfx_revive.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	sfx_revive.volume_db = -6.0
	add_child(sfx_revive)
	
	sfx_steps = AudioStreamPlayer.new()
	sfx_steps.stream = load("res://musics/sfx_steps.wav")
	sfx_steps.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	sfx_steps.volume_db = 0.0 # Reduzido de 10.0 para 0.0
	add_child(sfx_steps)
	
	sfx_jump = AudioStreamPlayer.new()
	sfx_jump.stream = load("res://musics/sfx_jump.wav")
	sfx_jump.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	sfx_jump.volume_db = -5.0
	add_child(sfx_jump)

func _physics_process(delta: float) -> void:
	if is_reviving:
		handle_revive(delta)
		return

	if grenade_cooldown > 0: grenade_cooldown -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta
		if sfx_steps.playing: sfx_steps.stop()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if sfx_jump.stream: sfx_jump.play()

	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
		facing_right = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	animetion.flip_h = not facing_right

	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()
		
	if Input.is_action_just_pressed("grenade") and grenade_cooldown <= 0 and grenades_ammo > 0:
		throw_grenade()

	if not is_attacking:
		if direction != 0: 
			animetion.play("walk")
			if is_on_floor() and not sfx_steps.playing: sfx_steps.play(8.0)
		else: 
			animetion.play("idle")
			sfx_steps.stop()

	move_and_slide()

func start_attack() -> void:
	is_attacking = true
	animetion.play("attack")
	if sfx_attack.stream: sfx_attack.play()
	check_attack_hit()
	await get_tree().create_timer(ATTACK_TIME).timeout
	is_attacking = false

func check_attack_hit() -> void:
	var attack_range = 150.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) < attack_range:
			if enemy.has_method("take_damage"): enemy.take_damage()

func throw_grenade() -> void:
	grenades_ammo -= 1
	grenade_cooldown = 0.6 # Cooldown curto para não travar a ação
	var granada = grenade_scene.instantiate()
	granada.global_position = global_position + Vector2(0, -30)
	get_parent().add_child(granada)
	# Evita que a granada colida com o próprio jogador ao nascer e caia aos pés dele
	granada.add_collision_exception_with(self)

	# Arremesso mais natural: força pra frente e um pouco pra cima
	var launch_dir = Vector2(1.2, -1.0).normalized() if facing_right else Vector2(-1.2, -1.0).normalized()
	granada.apply_central_impulse(launch_dir * 600.0)
	update_hud_call()

func add_grenades(amount: int) -> void:
	grenades_ammo += amount
	update_hud_call()

func take_damage(amount: float = 20.0) -> void:
	if is_invincible or health <= 0 or is_reviving: return

	health -= amount
	is_invincible = true
	update_health_bar()
	
	var tween = create_tween()
	tween.tween_property(animetion, "modulate", Color.RED, 0.1)
	tween.tween_property(animetion, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		start_revive_event()
	else:
		await get_tree().create_timer(1.5).timeout
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
