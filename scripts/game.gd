extends Node2D

@onready var player: CharacterBody2D = $player
@onready var hud_label: Label = $HUD/Control/Label
@onready var hearts_container: HBoxContainer = $HUD/Control/HeartsContainer
@onready var boss_panel: VBoxContainer = $HUD/Control/BossPanel
@onready var boss_name_label: Label = $HUD/Control/BossPanel/BossName
@onready var boss_health_bar: ProgressBar = $HUD/Control/BossPanel/BossHealthBar

var current_round := 1
var enemies_to_spawn := 0
var enemies_alive := 0
var enemy_scene = preload("res://entities/enemy.tscn")
var life_item_scene = preload("res://entities/life_item.tscn")

var bgm: AudioStreamPlayer
var spawn_timer: Timer

const BOSS_ROUNDS := {8: 1, 9: 2, 10: 3}
const BOSS_NAMES := {1: "DeepSeek", 2: "Claude", 3: "GPT"}

func _ready() -> void:
	setup_audio()
	setup_cage()
	setup_spawn_timer()
	player.scale = Vector2(8, 8)
	start_round()

func setup_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func setup_audio() -> void:
	bgm = AudioStreamPlayer.new()
	bgm.stream = load("res://musics/bgm_game.mp3")
	bgm.autoplay = true
	add_child(bgm)
	if bgm.stream:
		bgm.volume_db = -5.0
		bgm.play()

func setup_cage() -> void:
	var cage = StaticBody2D.new()
	add_child(cage)
	var wall_left = CollisionShape2D.new()
	var shape_left = WorldBoundaryShape2D.new()
	shape_left.normal = Vector2.RIGHT
	wall_left.shape = shape_left
	cage.add_child(wall_left)
	var wall_right = CollisionShape2D.new()
	var shape_right = WorldBoundaryShape2D.new()
	shape_right.normal = Vector2.LEFT
	wall_right.shape = shape_right
	wall_right.position = Vector2(2000, 0)
	cage.add_child(wall_right)

func _process(_delta: float) -> void:
	if not player: return
	if player.global_position.y > 900:
		player.global_position = Vector2(100, 400)
		player.velocity = Vector2.ZERO

	if enemies_alive <= 0 and enemies_to_spawn <= 0:
		if current_round < 10:
			current_round += 1
			spawn_life_item()
			start_round()
		else:
			get_tree().change_scene_to_file("res://scene/victory.tscn")

func start_round() -> void:
	boss_panel.visible = false
	update_hud()
	if current_round in BOSS_ROUNDS:
		enemies_to_spawn = 0
		enemies_alive = 0
		_spawn_boss_for_round(current_round)
	else:
		enemies_to_spawn = 3 + (current_round * 2)
		enemies_alive = 0
		spawn_timer.wait_time = max(0.5, 2.0 / current_round)
		spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemies_to_spawn > 0:
		spawn_enemy()
		enemies_to_spawn -= 1
	else:
		spawn_timer.stop()

func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	var offset = randf_range(400, 800)
	if randf() > 0.5: offset *= -1
	var spawn_x = clamp(player.global_position.x + offset, 100, 1900)
	enemy.position = Vector2(spawn_x, 600)
	enemy.scale = Vector2(8, 8)
	add_child(enemy)
	enemy.tree_exited.connect(_on_enemy_died)
	enemies_alive += 1
	update_hud()

func _spawn_boss_for_round(round_num: int) -> void:
	var type: int = BOSS_ROUNDS[round_num]
	var boss = enemy_scene.instantiate()
	boss.boss_type = type  # define antes do add_child para que _ready configure o boss
	var spawn_x = clamp(player.global_position.x + 900, 100, 1900)
	boss.position = Vector2(spawn_x, 600)
	boss.scale = Vector2(8, 8)
	add_child(boss)  # _ready roda aqui e chama _configure_boss
	boss.health_changed.connect(_on_boss_health_changed)
	boss.tree_exited.connect(_on_enemy_died)
	enemies_alive += 1

	boss_name_label.text = ">>> %s <<<" % BOSS_NAMES[type]
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.health
	_apply_boss_theme(type)
	boss_panel.visible = true
	update_hud()

func _apply_boss_theme(type: int) -> void:
	var boss_color: Color
	match type:
		1: boss_color = Color(0.2, 0.85, 1.0)
		2: boss_color = Color(1.0, 0.5, 0.1)
		3: boss_color = Color(0.1, 0.85, 0.4)

	boss_name_label.add_theme_color_override("font_color", boss_color)

	var fill = StyleBoxFlat.new()
	fill.bg_color = boss_color
	boss_health_bar.add_theme_stylebox_override("fill", fill)

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	boss_health_bar.add_theme_stylebox_override("background", bg)

func spawn_life_item() -> void:
	var item = life_item_scene.instantiate()
	item.position = Vector2(randf_range(200, 1800), 600)
	add_child(item)

func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_health_bar.max_value = maximum
	boss_health_bar.value = current

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if boss_panel.visible and enemies_alive <= 0:
		boss_panel.visible = false
	update_hud()

func update_hud() -> void:
	if player:
		var h1 = hearts_container.get_node("Heart1")
		var h2 = hearts_container.get_node("Heart2")
		var h3 = hearts_container.get_node("Heart3")
		h1.visible = player.lives >= 1
		h2.visible = player.lives >= 2
		h3.visible = player.lives >= 3

		if current_round in BOSS_ROUNDS:
			hud_label.text = "ROUND: %d/10 | BOSS" % current_round
		else:
			hud_label.text = "ROUND: %d/10 | BUGS: %d" % [current_round, enemies_alive + enemies_to_spawn]
