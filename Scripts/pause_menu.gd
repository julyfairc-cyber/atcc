# pause_menu.gd
extends CanvasLayer

@export var return_button: TextureButton
@export var quit_button: TextureButton
signal closed

func _ready() -> void:
	return_button.pressed.connect(_on_return_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_return_pressed() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	closed.emit()
	SceneManager.go_to_scene("res://Scenes/menu.tscn")
	queue_free()
