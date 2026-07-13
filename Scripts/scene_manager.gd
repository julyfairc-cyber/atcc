extends Node

var previous_scene_path: String = ""

func go_to_scene(path: String) -> void:
	previous_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(path)

func go_back() -> void:
	if previous_scene_path != "":
		get_tree().change_scene_to_file(previous_scene_path)
	else:
		# fallback if there's no recorded previous scene
		get_tree().change_scene_to_file("res://main_menu.tscn")
