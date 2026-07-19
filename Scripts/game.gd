extends Node2D
const PAUSE_MENU_SCENE = preload("res://Scenes/pause_menu.tscn")
var pause_menu_instance: Control = null

func _ready() -> void:
	%pause.pressed.connect(_on_pause_button_pressed)

	if GameState.skip_next_fade_in:
		GameState.skip_next_fade_in = false  
		$Fade_Transition.hide() 
	else:
		$Fade_Transition.show()
		$Fade_Transition/AnimationPlayer.play("fade_out")

func _on_settings_pressed() -> void:
	GameState.last_player_position = $player.global_position
	GameState.skip_next_fade_in = true
	SceneManager.go_to_scene("res://Scenes/settings.tscn")

func _on_pause_button_pressed() -> void:
	if pause_menu_instance != null:
		return
	pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
	pause_menu_instance.closed.connect(func(): pause_menu_instance = null)
	get_tree().root.add_child(pause_menu_instance)
	get_tree().paused = true
