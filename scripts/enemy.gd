extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

const SPEED_NORMAL = 120.0

var player: Node2D = null
var health := 2
var max_health := 2
var damage_cooldown := 1.5
var speed := SPEED_NORMAL
var attack_damage_cooldown := 2.0
var attack_range := 60.0
var _base_color: Color

# Temporizador do telegraph: toca animação de ataque, dano vem depois
var attack_timer := 0.0
const ATTACK_WINDUP := 0.4

@export var boss_type := 0
var is_boss := false

# Máquina de estados atualizada para incluir as ações do GPT Boss
enum BossState { CHASE, WAIT, LUNGE, TOKEN_BEAM, SHIELD_SLAM }
var boss_state := BossState.CHASE
var boss_state_timer := 0.0
var lunge_dir := 1.0

# --- CONFIGURAÇÕES EXCLUSIVAS DO GPT BOSS ---
const GPT_BEAM_RANGE := 400.0      # Alcance longo do raio de código
const GPT_SHIELD_RANGE := 45.0     # Dano agora só entra colado com o escudo
var gpt_cooldown_timer := 0.0      # Tempo de recarga entre ataques especiais

signal health_changed(current: int, maximum: int)

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	_base_color = animation.modulate
	
	# Desincroniza o tempo de ataque inicial
	damage_cooldown = randf_range(0.5, 2.5)
	
	if has_node("TextureProgressBar"):
		$TextureProgressBar.hide()
		
	# --- CORREÇÃO: Força a configuração visual de cada ID logo no nascimento ---
	if boss_type > 0:
		_configure_boss()
	else:
		is_boss = false
		animation.play("idle") # Cleiton comum inicia em Idle padrão estável

func _configure_boss() -> void:
	is_boss = true
	match boss_type:
		1:  # DeepSeek — velocidade e agressividade
			health = 8
			max_health = 8
			speed = 220.0
			attack_damage_cooldown = 1.2
			attack_range = 70.0
			_base_color = Color(0.2, 0.85, 1.0)
			
			# --- ALTERADO: Aumenta o tamanho do DeepSeek e ajusta altura padrão ---
			animation.scale = Vector2(1.5, 1.5)
			animation.position.y = -70.0
			
			# Força a sprite inicial correta do DeepSeek
			animation.play("walk_deepseek")

		2:  # Claude — estratégico, avança em lunge
			health = 15
			max_health = 15
			speed = 150.0
			attack_damage_cooldown = 1.8
			attack_range = 80.0
			_base_color = Color(1.0, 0.5, 0.1)
			
			# --- ALTERADO: Aumenta o tamanho do Claude e ajusta altura padrão ---
			animation.scale = Vector2(1.5, 1.5)
			animation.position.y = -90.0
			
			# Força a sprite inicial correta do Claude
			animation.play("claude_walk")

		3:  # GPT — O grande Boss das Spritesheets
			health = 35            
			max_health = 35
			speed = 100.0          
			attack_damage_cooldown = 2.5
			attack_range = 45.0    
			_base_color = Color(1.0, 1.0, 1.0)
			animation.scale = Vector2(1.5, 1.5)
			
			# Altura padrão de caminhada flutuante do GPT
			animation.position.y = -150.0
			
			# Força a sprite inicial correta do GPT Boss
			animation.play("walk_gpt")

			# Ajuste cirúrgico da colisão apenas para o GPT Boss
			var collision = $CollisionShape2D
			if collision and collision.shape:
				collision.shape = collision.shape.duplicate()
				if collision.shape is CapsuleShape2D:
					collision.shape.radius *= 1.0 
					collision.shape.height *= 1.6
				elif collision.shape is RectangleShape2D:
					collision.shape.extents *= 1.5

			animation.use_parent_material = false
			var shader_material = ShaderMaterial.new()
			var shader = Shader.new()
			shader.code = "
				shader_type canvas_item;
				void fragment() {
					vec4 color = texture(TEXTURE, UV);
					if (distance(color.rgb, vec3(0.745, 0.765, 0.765)) < 0.15) {
						discard;
					}
					COLOR = color;
				}
			"
			shader_material.shader = shader
			animation.material = shader_material
			
	animation.modulate = _base_color

	if is_boss and has_node("TextureProgressBar"):
		$TextureProgressBar.max_value = max_health
		$TextureProgressBar.value = health
		
		# --- ALTERADO: Desliga o texto de porcentagem (100%) da barra de vida ---
		if "show_percentage" in $TextureProgressBar:
			$TextureProgressBar.show_percentage = false
			
		$TextureProgressBar.show()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if damage_cooldown > 0:
		damage_cooldown -= delta

	if gpt_cooldown_timer > 0:
		gpt_cooldown_timer -= delta

	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0 and player:
			_apply_attack_damage()

	if player:
		var diff = player.global_position.x - global_position.x
		var distance = abs(diff)

		# Inteligência de Pulo: se o player estiver acima e o inimigo estiver no chão
		if is_on_floor() and player.global_position.y < global_position.y - 100:
			if randf() < 0.05: # Chance pequena por frame para não pularem todos juntos
				velocity.y = -600.0

		if is_boss:
			if boss_type == 1:
				_handle_chase(diff, distance)
			elif boss_type == 2:
				_handle_claude(delta, diff, distance)
			elif boss_type == 3:
				_handle_gpt_boss(delta, diff, distance)
		else:
			_handle_chase(diff, distance)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if is_boss:
			if boss_type == 1: animation.play("walk_deepseek")
			elif boss_type == 2: animation.play("claude_walk")
			elif boss_type == 3: animation.play("walk_gpt")
		else:
			animation.play("idle")

	if global_position.y > 900:
		die()

	move_and_slide()

# --- ATUALIZADO: Movimentação e Ataque do DeepSeek e Inimigos Comuns ---
func _handle_chase(diff: float, distance: float) -> void:
	var direction = sign(diff)
	if distance < attack_range and abs(player.global_position.y - global_position.y) < 100.0:
		velocity.x = 0
		if damage_cooldown <= 0 and attack_timer <= 0:
			# Adiciona um pequeno atraso aleatório extra para não baterem no mesmo frame
			damage_cooldown = randf_range(0.1, 0.4) 
			
			if boss_type == 1:
				animation.play("atack_deepseek")
			else:
				animation.play("attack") # Cleiton comum
				animation.position.y = -12.4 # Sprite de ataque tem moldura maior, ajusta para não enterrar no chão
			attack_timer = ATTACK_WINDUP
		elif attack_timer <= 0:
			if boss_type == 1:
				animation.play("walk_deepseek")
			else:
				animation.play("idle")
				animation.position.y = 2.0
	else:
		velocity.x = direction * speed
		if boss_type == 3:
			animation.play("walk_gpt")
		elif boss_type == 1:
			animation.play("walk_deepseek")
		else:
			animation.play("walk") # Cleiton comum
			animation.position.y = 2.0

		animation.flip_h = direction < 0

# --- ATUALIZADO: Movimentação e Ataques Exclusivos do Claude ---
func _handle_claude(delta: float, diff: float, distance: float) -> void:
	boss_state_timer -= delta
	var direction = sign(diff)

	match boss_state:
		BossState.CHASE:
			if distance < 200.0:
				boss_state = BossState.WAIT
				boss_state_timer = 1.5
				velocity.x = 0
				animation.play("claude_walk")
			else:
				velocity.x = direction * speed
				animation.play("claude_walk")
				animation.flip_h = direction < 0

		BossState.WAIT:
			velocity.x = 0
			if boss_state_timer <= 0:
				lunge_dir = direction
				boss_state = BossState.LUNGE
				boss_state_timer = 0.4

		BossState.LUNGE:
			velocity.x = lunge_dir * 380.0
			animation.play("claude_walk")
			animation.flip_h = lunge_dir < 0
			if distance < attack_range and abs(player.global_position.y - global_position.y) < 100.0:
				if damage_cooldown <= 0 and attack_timer <= 0:
					animation.play("claude_atack") 
					attack_timer = ATTACK_WINDUP
			if boss_state_timer <= 0:
				boss_state = BossState.CHASE

# --- COMPORTAMENTO INTELIGENTE DO GPT BOSS ---
func _handle_gpt_boss(delta: float, diff: float, distance: float) -> void:
	var direction = sign(diff)
	
	if attack_timer > 0 and boss_state != BossState.SHIELD_SLAM:
		velocity.x = 0
		return

	match boss_state:
		BossState.CHASE:
			animation.flip_h = direction < 0
			animation.position.y = -150.0
			
			if distance <= GPT_SHIELD_RANGE and gpt_cooldown_timer <= 0:
				boss_state = BossState.SHIELD_SLAM
				lunge_dir = -1.0 if animation.flip_h else 1.0
				velocity.x = lunge_dir * 350.0
				animation.position.y = -130.0
				animation.play("shield_slam")
				attack_timer = 0.5 
				return
				
			if distance > GPT_SHIELD_RANGE and distance <= GPT_BEAM_RANGE and gpt_cooldown_timer <= 0:
				boss_state = BossState.TOKEN_BEAM
				velocity.x = 0
				animation.play("token_beam")
				attack_timer = 0.8 
				return
			
			if distance > attack_range:
				velocity.x = direction * speed
				animation.play("walk_gpt")
			else:
				velocity.x = 0
				animation.play("idle")

		BossState.SHIELD_SLAM:
			if attack_timer > 0:
				velocity.x = lunge_dir * 250.0 
				animation.position.y = -130.0
			else:
				animation.position.y = -150.0
				boss_state = BossState.CHASE
				gpt_cooldown_timer = attack_damage_cooldown

		BossState.TOKEN_BEAM:
			velocity.x = 0
			if attack_timer <= 0:
				animation.position.y = -150.0
				boss_state = BossState.CHASE
				gpt_cooldown_timer = attack_damage_cooldown

func _apply_attack_damage() -> void:
	var current_range = attack_range
	var check_height = 100.0 

	if boss_type == 3:
		if boss_state == BossState.TOKEN_BEAM:
			current_range = GPT_BEAM_RANGE
			check_height = 40.0 
		elif boss_state == BossState.SHIELD_SLAM:
			current_range = GPT_SHIELD_RANGE
			check_height = 80.0

	var current_dist = abs(player.global_position.x - global_position.x)
	var current_height_diff = abs(player.global_position.y - global_position.y)
	
	var boss_facing_dir = -1.0 if animation.flip_h else 1.0
	var player_dir = sign(player.global_position.x - global_position.x)
	
	if current_dist <= current_range and current_height_diff < check_height:
		if boss_type != 3 or player_dir == boss_facing_dir or current_dist < 20.0:
			if player.has_method("take_damage"):
				var damage := 20.0
				match boss_type:
					1: damage = 25.0  # DeepSeek
					2: damage = 30.0  # Claude
					3: # GPT
						if boss_state == BossState.TOKEN_BEAM: damage = 40.0
						elif boss_state == BossState.SHIELD_SLAM: damage = 35.0
						else: damage = 25.0
				player.take_damage(damage)
			
	damage_cooldown = attack_damage_cooldown
	
	if boss_type == 3:
		boss_state = BossState.CHASE

func take_damage() -> void:
	health -= 1
	
	if has_node("TextureProgressBar"):
		$TextureProgressBar.value = health
		
	var tween = create_tween()
	var flash_color = Color.RED if (is_boss and boss_type == 3) else Color.WHITE
	tween.tween_property(animation, "modulate", flash_color, 0.1)
	tween.tween_property(animation, "modulate", _base_color, 0.1)
	health_changed.emit(health, max_health)
	
	if health <= 0:
		if has_node("TextureProgressBar"):
			$TextureProgressBar.hide()
		die()

func die() -> void:
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	
	# --- CORREÇÃO: Executa os frames de morte específicos de cada IA ---
	if boss_type == 1:
		animation.play("death_deepseek")
		await get_tree().create_timer(1.2).timeout 
	elif boss_type == 2:
		animation.play("claude_death")
		await get_tree().create_timer(1.2).timeout 
	elif boss_type == 3:
		animation.play("death")
		await get_tree().create_timer(2.0).timeout 
	else:
		animation.play("death") 
		await get_tree().create_timer(0.4).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)
	await tween.finished
	queue_free()
