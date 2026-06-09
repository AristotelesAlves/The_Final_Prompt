extends CanvasLayer

@onready var label: Label = $CenterContainer/Label
@onready var timer: Timer = $Timer

var sfx_steps: AudioStreamPlayer

var dialogs = [
	"Meia-noite. Datacenter fervendo.",
	"Cleiton estava debugando um erro crítico com o Claude Code...",
	"Mas então o pior aconteceu: 'Out of Tokens'.",
	"Exausto, ele desabou sobre o teclado.",
	"Ao encostar no 'Enter', sua consciência foi digitalizada...",
	"Ele agora está preso no Kernel do Linux!",
	"Sobreviva a 10 níveis de Bugs e IAs para escapar!"
]
var current_dialog = 0

func _ready() -> void:
	setup_audio()
	show_dialog()
	timer.timeout.connect(_on_timer_timeout)

func setup_audio() -> void:
	sfx_steps = AudioStreamPlayer.new()
	sfx_steps.stream = load("res://musics/sfx_steps.wav")
	add_child(sfx_steps)

func show_dialog() -> void:
	if current_dialog < dialogs.size():
		label.text = dialogs[current_dialog]
		label.modulate.a = 0
		
		# Toca som de passos se for um texto de movimento (exemplo)
		if sfx_steps.stream: sfx_steps.play()
		
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 1.0)
		tween.tween_interval(2.0)
		tween.tween_property(label, "modulate:a", 0, 1.0)
		tween.finished.connect(func(): 
			current_dialog += 1
			show_dialog()
		)
	else:
		start_game()

func _on_timer_timeout() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		start_game()

func start_game() -> void:
	get_tree().change_scene_to_file("res://scene/boss_arena_night.tscn")
