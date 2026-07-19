# battle_manager.gd
extends Node
class_name BattleManager

# Drag your battler nodes directly into these in the Inspector
@export var party: Array[Battler] = []
@export var enemies: Array[Battler] = []
@export var sword_button: TextureButton
@export var flee_button: TextureButton

signal battle_ended(victory: bool)
var current_party_index: int = 0
var current_enemy_index: int = 0
var active_battler: Battler = null
var awaiting_player_action: bool = false
var battle_over: bool = false

const PAUSE_MENU_SCENE = preload("res://Scenes/pause_menu.tscn")  # adjust path if different
var pause_menu_instance: Control = null

func _ready() -> void:
	%pause.pressed.connect(_on_pause_button_pressed)
	for battler in party + enemies:
		battler.died.connect(_on_battler_died.bind(battler))

	sword_button.pressed.connect(_on_attack_button_pressed)
	flee_button.pressed.connect(_on_flee_button_pressed)

	call_deferred("_start_next_player_turn")

func _start_next_player_turn() -> void:
	if battle_over:
		return

	active_battler = _get_next_alive_party_member()
	if active_battler == null:
		return  # shouldn't happen if battle-end check works

	awaiting_player_action = true
	print("%s's turn - choose an action" % active_battler.battler_name)

func _get_next_alive_party_member() -> Battler:
	var attempts = 0
	while attempts < party.size():
		var candidate = party[current_party_index]
		current_party_index = (current_party_index + 1) % party.size()
		attempts += 1
		if candidate.current_hp > 0:
			return candidate
	return null

func _get_next_alive_enemy() -> Battler:
	var attempts = 0
	while attempts < enemies.size():
		var candidate = enemies[current_enemy_index]
		current_enemy_index = (current_enemy_index + 1) % enemies.size()
		attempts += 1
		if candidate.current_hp > 0:
			return candidate
	return null

func _on_attack_button_pressed() -> void:
	if not awaiting_player_action or battle_over:
		return

	var target = _get_first_alive(enemies)
	if target == null:
		return

	awaiting_player_action = false
	await _perform_attack(active_battler, target)

	if battle_over:
		return

	# Immediately counterattack with one enemy
	var enemy = _get_next_alive_enemy()
	if enemy != null:
		await get_tree().create_timer(0.4).timeout
		var counter_target = _get_first_alive(party)
		if counter_target != null:
			await _perform_attack(enemy, counter_target)

	if battle_over:
		return

	_start_next_player_turn()

func _on_flee_button_pressed() -> void:
	if battle_over or not awaiting_player_action:
		return

	battle_over = true  # stop any further turns/attacks
	awaiting_player_action = false
	sword_button.disabled = true

	GameState.set_flee_cooldown(GameState.pending_enemy_id, 3.0)  # 5 seconds of safe passage
	SceneManager.go_back()
	
func _perform_attack(attacker: Battler, target: Battler) -> void:
	attacker.play_attack_animation()
	await get_tree().create_timer(0.4).timeout

	var damage = _calculate_damage(attacker)
	print("%s attacks %s for %d damage" % [attacker.battler_name, target.battler_name, damage])
	target.take_damage(damage)
	_check_battle_end()

func _calculate_damage(_attacker: Battler) -> int:
	return randi_range(15, 25)

func _get_first_alive(battlers: Array[Battler]) -> Battler:
	for b in battlers:
		if b.current_hp > 0:
			return b
	return null

func _on_battler_died(battler: Battler) -> void:
	print("%s has been defeated!" % battler.battler_name)
	_check_battle_end()

func _check_battle_end() -> void:
	if battle_over:
		return

	if _get_first_alive(enemies) == null:
		battle_over = true
		battle_ended.emit(true)
		_end_battle(true)
	elif _get_first_alive(party) == null:
		battle_over = true
		battle_ended.emit(false)
		_end_battle(false)

func _on_pause_button_pressed() -> void:
	if pause_menu_instance != null:
		return  # already open, don't double-instantiate

	pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
	get_tree().root.add_child(pause_menu_instance)
	get_tree().paused = true

func _end_battle(victory: bool) -> void:
	awaiting_player_action = false
	sword_button.disabled = true
	if victory:
		GameState.mark_defeated(GameState.pending_enemy_id)
	await get_tree().create_timer(1.5).timeout
	if victory:
		SceneManager.go_back()
	else:
		get_tree().change_scene_to_file("res://Scenes/game_over.tscn")
