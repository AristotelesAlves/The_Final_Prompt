extends CanvasLayer

@onready var label: Label = $CenterContainer/Label

var dialogs = [
	"O kernel treme.",
	"O último modelo cai. O sistema para de responder.",
	"Cleiton sente o chão digital desaparecer.",
	"Uma luz branca. Muito brilhante.",
	"...",
	"Ele acorda suado. Teclado na face.",
	"Era 3 da manhã. Só um sonho.",
	"Stress, café e excesso de trabalho.",
	"Mas o prompt ainda piscava na tela."
]
var current_dialog = 0

func _ready() -> void:
	show_dialog()

func show_dialog() -> void:
	if current_dialog < dialogs.size():
		label.text = dialogs[current_dialog]
		label.modulate.a = 0

		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 1.2)
		tween.tween_interval(2.5)
		tween.tween_property(label, "modulate:a", 0, 1.0)
		tween.finished.connect(func():
			current_dialog += 1
			show_dialog()
		)
	else:
		finish()

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		finish()

func finish() -> void:
	set_process_input(false)
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
