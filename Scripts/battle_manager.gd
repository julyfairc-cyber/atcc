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
@export var message_label: RichTextLabel

signal battle_ended(victory: bool)
var active_party: Array[Battler] = []
var current_party_index: int = 0
var current_enemy_index: int = 0
var active_battler: Battler = null
var awaiting_player_action: bool = false
var battle_over: bool = false
var ready_time_ms: int = 0
const SKILL_MENU_SCENE = preload("res://Scenes/skill_menu.tscn")
const PAUSE_MENU_SCENE = preload("res://Scenes/pause_menu.tscn")
const SETTINGS_SCENE = preload("res://Scenes/settings.tscn")
const MAX_LOG_LINES = 5

const COLOR_DAMAGE = "#ff4d4d"
const COLOR_SUPER_EFFECTIVE = "#ffaa33"
const COLOR_NOT_EFFECTIVE = "#999999"
const COLOR_VICTORY = "#ffd700"
const COLOR_EXP = "#66ccff"
const COLOR_LEVELUP = "#ffd700"
const COLOR_STATS = "#66ff99"

var settings_instance: Control = null
var pause_menu_instance: CanvasLayer = null

func _colored(text: String, hex_color: String) -> String:
	return "[color=%s]%s[/color]" % [hex_color, text]

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

	active_party = [party[0]]

	await _show_intro_message()

func _show_intro_message() -> void:
	if enemies.size() == 1:
		_show_message("%s is blocking your way!" % enemies[0].battler_name)
	else:
		var names = []
		for enemy in enemies:
			names.append(enemy.battler_name)
		_show_message("%s are blocking your way!" % ", ".join(names))

	await get_tree().create_timer(1.5).timeout

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
		var counter_target = _get_first_alive(active_party)
		if counter_target != null:
			await _perform_attack(enemy, counter_target)

	if not battle_over:
		_start_next_player_turn()

func _show_message(text: String) -> void:
	message_label.text = text + "\n" + message_label.text
	_trim_log()

func _trim_log() -> void:
	var lines = message_label.text.split("\n")
	if lines.size() > MAX_LOG_LINES:
		lines = lines.slice(0, MAX_LOG_LINES)
		message_label.text = "\n".join(lines)

func _show_message_delayed(text: String, delay: float = 1.0) -> void:
	_show_message(text)
	await get_tree().create_timer(delay).timeout
	
func _on_skill_used(skill: SkillData) -> void:
	if not active_battler.use_mp(skill.mp_cost):
		_show_message("Not enough MP!")
		return

	var target = _get_first_alive(enemies)
	if target == null:
		return

	active_battler.play_attack_animation()
	_show_message("%s uses %s!" % [active_battler.battler_name, skill.skill_name])
	await get_tree().create_timer(0.4).timeout

	var base_damage = randi_range(15, 25)
	var type_multiplier = ElementTypes.get_multiplier(skill.element, target.data.element)
	var damage = int(base_damage * skill.damage_multiplier * type_multiplier)

	target.take_damage(damage)

	if type_multiplier > 1.0:
		_show_message("%s %s takes %s!" % [
			_colored("It's super effective!", COLOR_SUPER_EFFECTIVE),
			target.battler_name,
			_colored("%d damage" % damage, COLOR_DAMAGE)
		])
	elif type_multiplier < 1.0:
		_show_message("%s %s takes %s" % [
			_colored("It's not very effective...", COLOR_NOT_EFFECTIVE),
			target.battler_name,
			_colored("%d damage." % damage, COLOR_DAMAGE)
		])
	else:
		_show_message("%s takes %s!" % [target.battler_name, _colored("%d damage" % damage, COLOR_DAMAGE)])

	await get_tree().create_timer(0.8).timeout
	_check_battle_end()

	awaiting_player_action = false
	if battle_over:
		return

	var enemy = _get_next_alive_enemy()
	if enemy != null:
		await get_tree().create_timer(0.4).timeout
		var counter_target = _get_first_alive(active_party)
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
	_show_message("%s's turn - choose an action" % active_battler.battler_name)
	
func _get_next_alive_party_member() -> Battler:
	var attempts = 0
	while attempts < active_party.size():
		var candidate = active_party[current_party_index % active_party.size()]
		current_party_index = (current_party_index + 1) % active_party.size()
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
		var counter_target = _get_first_alive(active_party)
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
	menu.closed.connect(func(): pass)  
	menu.open(active_battler.data, active_battler.current_mp)
	
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
	_show_message("%s attacks %s!" % [attacker.battler_name, target.battler_name])
	await get_tree().create_timer(0.4).timeout

	var damage = _calculate_damage(attacker)
	target.take_damage(damage)
	_show_message("%s takes %s!" % [target.battler_name, _colored("%d damage" % damage, COLOR_DAMAGE)])

	if attacker in party:
		var mp_restore = int(attacker.data.max_mp * 0.05)
		attacker.restore_mp(mp_restore)

	await get_tree().create_timer(0.8).timeout
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
	_show_message("%s has been defeated!" % battler.battler_name)

	if battler in active_party:
		active_party.erase(battler)
		_promote_next_reserve()

	_check_battle_end()

func _promote_next_reserve() -> void:
	for member in party:
		if member.current_hp > 0 and not member in active_party:
			active_party.append(member)
			_show_message("%s steps in to fight!" % member.battler_name)
			current_party_index = active_party.size() - 1  
			break
	
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
		await _award_exp_with_messages()
	else:
		_show_message("Defeated...")
		await get_tree().create_timer(1.5).timeout

	if victory:
		SceneManager.go_back()
	else:
		get_tree().change_scene_to_file("res://Scenes/game_over.tscn")

func _clear_log() -> void:
	message_label.text = ""
	
func _award_exp_with_messages() -> void:
	_clear_log()
	_show_message(_colored("Victory!", COLOR_VICTORY))
	await get_tree().create_timer(1.2).timeout

	_clear_log()  

	for member in party:
		if member.current_hp <= 0:
			continue

		var needed = member.data.exp_to_next_level()
		var exp_percent = randf_range(0.01, 0.08)
		var exp_gained = int(needed * exp_percent)

		var old_stats = {
			"hp": member.data.max_hp,
			"mp": member.data.max_mp,
			"attack": member.data.attack,
			"defense": member.data.defense,
			"speed": member.data.speed
		}

		var result = member.data.gain_exp(exp_gained)

		_show_message("%s gained %s!" % [member.data.character_name, _colored("%d EXP" % exp_gained, COLOR_EXP)])
		await get_tree().create_timer(1.2).timeout

		if result.leveled_up:
			_clear_log()
			_show_message(_colored("%s leveled up to Lv. %d!" % [member.data.character_name, member.data.level], COLOR_LEVELUP))
			await get_tree().create_timer(1.2).timeout

			member.current_hp = member.data.max_hp
			member.current_mp = member.data.max_mp
			member._update_ui()

			var stat_gains = "HP +%d, MP +%d, ATK +%d, DEF +%d, SPD +%d" % [
				member.data.max_hp - old_stats.hp,
				member.data.max_mp - old_stats.mp,
				member.data.attack - old_stats.attack,
				member.data.defense - old_stats.defense,
				member.data.speed - old_stats.speed
			]

			_clear_log()
			_show_message(_colored(stat_gains, COLOR_STATS))
			await get_tree().create_timer(1.5).timeout
