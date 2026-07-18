# pause_menu.gd
extends Control

const PAUSE_MENU_SCENE = preload("res://Scenes/pause_menu.tscn")
var pause_menu_instance: Control = null

func _ready() -> void:
	$buttons/unpause/Return/unpause.pressed.connect(_on_return_pressed)
	$buttons/unpause/quit/quit.pressed.connect(_on_quit_pressed)

func _on_return_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	SceneManager.go_to_scene("res://Scenes/menu.tscn")  # adjust path to your actual main menu

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):  # see note below about input action
		_toggle_pause_menu()

func _toggle_pause_menu() -> void:
	if pause_menu_instance != null:
		return  # already open

	pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
	get_tree().root.add_child(pause_menu_instance)
	get_tree().paused = true
