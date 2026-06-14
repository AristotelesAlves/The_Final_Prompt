extends RigidBody2D

var explosion_scene = preload("res://entities/explosion_effect.tscn")
var explosion_radius := 250.0
var damage_delay := 1.5
var exploded := false

func _ready() -> void:
	await get_tree().create_timer(damage_delay).timeout
	explode()

func _physics_process(_delta: float) -> void:
	# Se a granada cair num buraco e sair do mapa, explode antes de se perder no vazio
	if not exploded and global_position.y > 900:
		explode()

func explode() -> void:
	if exploded:
		return
	exploded = true

	# Efeito visual - Adiciona ao pai e centraliza (sobe um pouco a animação)
	var exp_inst = explosion_scene.instantiate()
	get_parent().add_child(exp_inst)
	# Sprite agora é centralizado corretamente, então a explosão fica no ponto de impacto
	exp_inst.global_position = global_position
	
	# Som da explosão
	var sfx = AudioStreamPlayer.new()
	# Tenta carregar sfx_explosion.wav, se não existir usa sfx_fall.wav como placeholder
	var sfx_path = "res://musics/sfx_explosion.wav"
	if not FileAccess.file_exists(sfx_path):
		sfx_path = "res://musics/sfx_fall.wav"
	
	sfx.stream = load(sfx_path)
	sfx.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	sfx.volume_db = 0.0
	get_parent().add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	# Dano em área
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < explosion_radius:
			if enemy.has_method("take_damage"):
				# Granada dá 3 de dano (mata Cleitons comuns na hora)
				enemy.take_damage()
				enemy.take_damage()
				enemy.take_damage()
	
	queue_free()
