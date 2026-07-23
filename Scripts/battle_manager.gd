extends Node
class_name BattleManager

@export var party: Array[Battler] = []
@export var enemies: Array[Battler] = []
@export var sword_button: TextureButton
@export var flee_button: TextureButton
@export var skill_button: TextureButton
@export var inventory: TextureButton
@export var skip_button: TextureButton
@export var fast_forward_button: TextureButton
@export var settings_button: TextureButton
@export var pause_button: TextureButton


signal battle_ended(victory: bool)
var current_party_index: int = 0
var current_enemy_index: int = 0
var active_battler: Battler = null
var awaiting_player_action: bool = false
var battle_over: bool = false
var ready_time_ms: int = 0
const SKILL_MENU_SCENE = preload("res://Scenes/skill_menu.tscn")
const PAUSE_MENU_SCENE = preload("res://Scenes/pause_menu.tscn")
const SETTINGS_SCENE = preload("res://Scenes/settings.tscn")
var settings_instance: Control = null

var pause_menu_instance: CanvasLayer = null

func _ready() -> void:
	settings_button.pressed.connect(_on_settings_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	fast_forward_button.pressed.connect(_on_fast_forward_pressed)
	skip_button.pressed.connect(_on_skip_battle_pressed)
	
	for battler in party + enemies:
		battler.died.connect(_on_battler_died.bind(battler))
	sword_button.pressed.connect(_on_attack_button_pressed)
	skill_button.pressed.connect(_on_skill_button_pressed)
	flee_button.pressed.connect(_on_flee_button_pressed)

	call_deferred("_scale_enemies_and_start")

func _scale_enemies_and_start() -> void:
	var reference_level = party[0].data.level
	for enemy in enemies:
		enemy.scale_enemy_level(reference_level)
		enemy._update_ui()

	_start_next_player_turn()

func _on_item_used(item: ItemData) -> void:
	match item.effect_type:
		ItemData.EffectType.HEAL_HP:
			active_battler.heal(item.amount)
		ItemData.EffectType.HEAL_MP:
			active_battler.restore_mp(item.amount)

	Inventory.remove_item(item, 1)
	awaiting_player_action = false

	var enemy = _get_next_alive_enemy()
	if enemy != null:
		await get_tree().create_timer(0.4).timeout
		var counter_target = _get_first_alive(party)
		if counter_target != null:
			await _perform_attack(enemy, counter_target)

	if not battle_over:
		_start_next_player_turn()

func _on_skill_used(skill: SkillData) -> void:
	if not active_battler.use_mp(skill.mp_cost):
		return 

	var target = _get_first_alive(enemies)
	if target == null:
		return

	active_battler.play_attack_animation()
	await get_tree().create_timer(0.4).timeout

	var damage = int(_calculate_damage(active_battler) * skill.damage_multiplier)
	print("%s uses %s on %s for %d damage" % [active_battler.battler_name, skill.skill_name, target.battler_name, damage])
	target.take_damage(damage)
	_check_battle_end()

	awaiting_player_action = false
	if battle_over:
		return

	var enemy = _get_next_alive_enemy()
	if enemy != null:
		await get_tree().create_timer(0.4).timeout
		var counter_target = _get_first_alive(party)
		if counter_target != null:
			await _perform_attack(enemy, counter_target)

	if not battle_over:
		_start_next_player_turn()
		
func _on_fast_forward_pressed() -> void:
	Engine.time_scale = 1.0 if Engine.time_scale > 1.0 else 2.0

func _on_skip_battle_pressed() -> void:
	if battle_over:
		return
	for enemy in enemies:
		if enemy.current_hp > 0:
			enemy.current_hp = 0
	battle_over = true
	print("Victory! (skipped)")
	battle_ended.emit(true)
	_end_battle(true)
	
func _on_settings_button_pressed() -> void:
	if settings_instance != null:
		return

	settings_instance = SETTINGS_SCENE.instantiate()
	settings_instance.is_overlay = true
	settings_instance.closed.connect(func(): settings_instance = null)
	get_tree().root.add_child(settings_instance)
	get_tree().paused = true
	
func _start_next_player_turn() -> void:
	if battle_over:
		return

	active_battler = _get_next_alive_party_member()
	if active_battler == null:
		return  

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

	var enemy = _get_next_alive_enemy()
	if enemy != null:
		await get_tree().create_timer(0.4).timeout
		var counter_target = _get_first_alive(party)
		if counter_target != null:
			await _perform_attack(enemy, counter_target)

	if battle_over:
		return

	_start_next_player_turn()

func _on_skill_button_pressed() -> void:
	if not awaiting_player_action or battle_over:
		return

	var menu = SKILL_MENU_SCENE.instantiate()
	get_tree().root.add_child(menu)
	menu.skill_selected.connect(_on_skill_used)
	menu.open(active_battler.data)
	
func _on_flee_button_pressed() -> void:
	if battle_over or not awaiting_player_action:
		return

	battle_over = true
	awaiting_player_action = false
	sword_button.disabled = true
	Engine.time_scale = 1.0  

	GameState.set_flee_cooldown(GameState.pending_enemy_id, 3.0)
	SceneManager.go_back()
	
func _perform_attack(attacker: Battler, target: Battler) -> void:
	attacker.play_attack_animation()
	await get_tree().create_timer(0.4).timeout

	var damage = _calculate_damage(attacker)
	print("%s attacks %s for %d damage" % [attacker.battler_name, target.battler_name, damage])
	target.take_damage(damage)
	_check_battle_end()

func _calculate_damage(_attacker: Battler) -> int:
	var base = randi_range(15, 25)
	return int(base * 0.85) 


		
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
	if Time.get_ticks_msec() - ready_time_ms < 300:
		return 

	if pause_menu_instance != null:
		return

	pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
	pause_menu_instance.closed.connect(func(): pause_menu_instance = null)
	get_tree().root.add_child(pause_menu_instance)
	get_tree().paused = true
	
func _end_battle(victory: bool) -> void:
	awaiting_player_action = false
	sword_button.disabled = true
	Engine.time_scale = 1.0

	if victory:
		GameState.mark_defeated(GameState.pending_enemy_id)
		_award_exp()

	await get_tree().create_timer(1.5).timeout
	if victory:
		SceneManager.go_back()
	else:
		get_tree().change_scene_to_file("res://Scenes/game_over.tscn")

func _award_exp() -> void:
	for member in party:
		if member.current_hp <= 0:
			continue

		var needed = member.data.exp_to_next_level()
		var exp_percent = randf_range(0.01, 0.08)
		var exp_gained = int(needed * exp_percent)

		var result = member.data.gain_exp(exp_gained)
		print("%s gained %d EXP" % [member.data.character_name, exp_gained])

		if result.leveled_up:
			print("%s leveled up to %d!" % [member.data.character_name, member.data.level])
			member.current_hp = member.data.max_hp
			member.current_mp = member.data.max_mp
			member._update_ui()
