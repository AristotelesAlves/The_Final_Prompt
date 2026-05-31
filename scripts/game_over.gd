extends CanvasLayer

func _ready() -> void:
	$Center/VBox/Restart.pressed.connect(_on_restart)

func _on_restart() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
