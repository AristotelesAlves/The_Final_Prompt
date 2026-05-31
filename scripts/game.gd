extends Node2D

@onready var player: CharacterBody2D = $player
@onready var hud_label: Label = $HUD/Control/Label
@onready var health_bar: ProgressBar = $HUD/Control/HealthBar

var current_round := 1
var enemies_to_spawn := 0
var enemies_alive := 0
var enemy_scene = preload("res://entities/enemy.tscn")

var bgm: AudioStreamPlayer

func _ready() -> void:
	setup_audio()
	player.scale = Vector2(8, 8)
	start_round()

func setup_audio() -> void:
	bgm = AudioStreamPlayer.new()
	bgm.stream = load("res://musics/bgm_game.mp3")
	bgm.autoplay = true
	add_child(bgm)
	if bgm.stream: 
		bgm.volume_db = -5.0
		bgm.play()

func _process(_delta: float) -> void:
	if not player: return
	
	# Fosso 100% limpo: Apenas teleporta de volta se cair
	if player.global_position.y > 900:
		player.global_position = Vector2(41, 400)
		player.velocity = Vector2.ZERO

	# Round Finish
	if enemies_alive <= 0 and enemies_to_spawn <= 0:
		if current_round < 10:
			current_round += 1
			start_round()
		else:
			get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func start_round() -> void:
	enemies_to_spawn = 2 + current_round
	enemies_alive = 0
	update_hud()
	spawn_next_enemy()

func spawn_next_enemy() -> void:
	if enemies_to_spawn > 0:
		var enemy = enemy_scene.instantiate()
		var spawn_x = randf_range(200, 1200)
		if abs(spawn_x - player.position.x) < 200: spawn_x += 400
		enemy.position = Vector2(spawn_x, 600)
		enemy.scale = Vector2(8, 8) 
		add_child(enemy)
		enemy.tree_exited.connect(_on_enemy_died)
		enemies_alive += 1
		enemies_to_spawn -= 1
		await get_tree().create_timer(max(0.5, 2.0 / current_round)).timeout 
		spawn_next_enemy()

func _on_enemy_died() -> void:
	enemies_alive -= 1
	update_hud()

func update_hud() -> void:
	if player:
		hud_label.text = "VIDAS: %d | ROUND: %d/10 | BUGS: %d" % [player.lives, current_round, enemies_alive + enemies_to_spawn]
		health_bar.value = player.health
