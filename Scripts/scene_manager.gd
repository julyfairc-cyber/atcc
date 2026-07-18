extends Node

var previous_scene_path: String = ""

func go_to_scene(path: String) -> void:
	previous_scene_path = get_tree().current_scene.scene_file_path
	call_deferred("_deferred_change_scene", path)

func go_back() -> void:
	if previous_scene_path != "":
		call_deferred("_deferred_change_scene", previous_scene_path)
	else:
		call_deferred("_deferred_change_scene", "res://Scenes/menu.tscn")

func _deferred_change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
