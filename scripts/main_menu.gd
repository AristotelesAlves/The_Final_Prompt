extends CanvasLayer

const SETTINGS_PATH = "user://settings.cfg"

@onready var main_menu_container = $CenterContainer
@onready var settings_panel = $SettingsPanel
@onready var master_slider = $SettingsPanel/VBox/MasterSlider
@onready var music_slider = $SettingsPanel/VBox/MusicSlider
@onready var sfx_slider = $SettingsPanel/VBox/SfxSlider

func _ready() -> void:
	setup_buses()
	load_settings()
	
	$CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$SettingsPanel/VBox/CloseButton.pressed.connect(_on_close_settings)
	
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

func setup_buses() -> void:
	# Cria barramentos de áudio se não existirem
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
		
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/cutscene.tscn")

func _on_settings_pressed() -> void:
	main_menu_container.visible = false
	settings_panel.visible = true

func _on_close_settings() -> void:
	settings_panel.visible = false
	main_menu_container.visible = true
	save_settings()

func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	var master_v = config.get_value("audio", "master_volume", 0.5)
	var music_v = config.get_value("audio", "music_volume", 0.8)
	var sfx_v = config.get_value("audio", "sfx_volume", 0.8)
	
	master_slider.value = master_v
	music_slider.value = music_v
	sfx_slider.value = sfx_v
	
	_on_master_changed(master_v)
	_on_music_changed(music_v)
	_on_sfx_changed(sfx_v)
