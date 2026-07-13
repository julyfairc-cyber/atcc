extends Control

var button_type = null

func _on_play_pressed() :
	button_type = "play"
	$Fade_Transition.show()
	$Fade_Transition/Fade_timer.start()
	$Fade_Transition/AnimationPlayer.play("fade_in")

func _on_settings_pressed() :
	button_type = "settings"
	$Fade_Transition.show()
	$Fade_Transition/Fade_timer.start()
	$Fade_Transition/AnimationPlayer.play("fade_in")

func _on_exit_game_pressed() :
	get_tree().quit()

func _on_fade_timer_timeout():
	if button_type == "play" :
		get_tree().change_scene_to_file("res://Scenes/game.tscn")
	elif button_type == "settings" :
		SceneManager.go_to_scene("res://Scenes/settings.tscn")
