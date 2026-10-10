extends Control

const GAME_SCENE := "res://scenes/main.tscn"

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_overlay: Control = %SettingsOverlay
@onready var close_settings_button: Button = %CloseSettingsButton


func _ready() -> void:
	InputSetup.ensure_actions()
	DisplayServer.window_set_ime_active(false)
	settings_overlay.visible = false
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_settings_button.pressed.connect(_on_close_settings)
	start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not settings_overlay.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_settings()
		get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	settings_overlay.visible = true
	close_settings_button.grab_focus()


func _on_close_settings() -> void:
	settings_overlay.visible = false
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
