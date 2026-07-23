# game_state.gd
extends Node

var current_stage_path: String = "res://Scenes/Stage1.tscn"
var last_player_position: Vector2 = Vector2.ZERO
var skip_next_fade_in: bool = false
var defeated_enemies: Array[String] = []
var pending_enemy_id: String = ""
var flee_cooldowns: Dictionary = {} 

func reset_for_new_game() -> void:
	last_player_position = Vector2.ZERO
	skip_next_fade_in = false
	defeated_enemies.clear()
	pending_enemy_id = ""
	flee_cooldowns.clear()

func mark_defeated(enemy_id: String) -> void:
	if enemy_id != "" and not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)

func is_defeated(enemy_id: String) -> bool:
	return defeated_enemies.has(enemy_id)

func set_flee_cooldown(enemy_id: String, duration_sec: float) -> void:
	flee_cooldowns[enemy_id] = Time.get_ticks_msec() + int(duration_sec * 1000)

func is_on_flee_cooldown(enemy_id: String) -> bool:
	if not flee_cooldowns.has(enemy_id):
		return false
	return Time.get_ticks_msec() < flee_cooldowns[enemy_id]
