extends Control

var button_type = null
@export var is_overlay: bool = false
signal closed

func _ready():
	if not is_overlay:
		$Fade_Transition.show()
		$Fade_Transition/Fade_timer.start()
		$Fade_Transition/AnimationPlayer.play("fade_out")

func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_db(0, value)

func _on_back_pressed() -> void:
	if is_overlay:
		get_tree().paused = false
		closed.emit()
		queue_free()
	else:
		$Fade_Transition.show()
		$Fade_Transition/Fade_timer.start()
		$Fade_Transition/AnimationPlayer.play("fade_in")
		SceneManager.go_back()

func _on_resolutions_item_selected(index):
	match index:
		0:
			get_window().mode = Window.MODE_WINDOWED
			get_window().size = Vector2i(1280, 720)
		1:
			get_window().mode = Window.MODE_WINDOWED
			get_window().size = Vector2i(800, 600)

func _on_fs_2_item_selected(index):
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
