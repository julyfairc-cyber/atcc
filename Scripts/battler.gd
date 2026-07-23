extends Node
class_name Battler

@export var sprite: AnimatedSprite2D
@export var data: CharacterData
@export var battler_name: String = "Battler"
@export var level: int = 1
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var is_enemy: bool = false

@export var name_label_path: NodePath
@export var level_label_path: NodePath
@export var hp_bar_path: NodePath
@export var mp_bar_path: NodePath
@export var hp_label_path: NodePath
@export var mp_label_path: NodePath

var current_hp: int
var current_mp: int

var name_label: Label
var level_label: Label
var hp_bar: TextureProgressBar
var mp_bar: TextureProgressBar
var hp_label: Label
var mp_label: Label

signal hp_changed(current: int, max: int)
signal mp_changed(current: int, max: int)
signal died

func _ready() -> void:
	name_label = get_node(name_label_path)
	level_label = get_node(level_label_path)
	hp_bar = get_node(hp_bar_path)
	mp_bar = get_node(mp_bar_path)
	hp_label = get_node(hp_label_path)
	mp_label = get_node(mp_label_path)

	current_hp = data.max_hp
	current_mp = data.max_mp
	_update_ui()

	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)

func scale_enemy_level(reference_level: int) -> void:
	if not is_enemy:
		return

	var level_offset = randi_range(1, 5)
	data.level = reference_level + level_offset

	var level_multiplier = 1.0 + (level_offset * 0.08) 
	data.max_hp = int(data.max_hp * level_multiplier)
	data.attack = int(data.attack * level_multiplier)
	data.defense = int(data.defense * level_multiplier)
	
func _on_animation_finished() -> void:
	if sprite.animation != "die":  
		sprite.play("idle")
		
func _update_ui() -> void:
	name_label.text = data.character_name
	level_label.text = "LV. %d" % data.level
	hp_bar.max_value = data.max_hp
	hp_bar.value = current_hp
	mp_bar.max_value = data.max_mp
	mp_bar.value = current_mp
func take_damage(amount: int) -> void:
	current_hp = clamp(current_hp - amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	_animate_hp()

	if current_hp <= 0:
		play_die_animation()
		died.emit()
		if is_enemy:
			await get_tree().create_timer(0.8).timeout 
			_on_defeated()
	else:
		play_hurt_animation()
		
func heal(amount: int) -> void:
	current_hp = clamp(current_hp + amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	_animate_hp()

func use_mp(amount: int) -> bool:
	if current_mp < amount:
		return false
	current_mp -= amount
	mp_changed.emit(current_mp, max_mp)
	_animate_mp()
	return true

func restore_mp(amount: int) -> void:
	current_mp = clamp(current_mp + amount, 0, max_mp)
	mp_changed.emit(current_mp, max_mp)
	_animate_mp()

func _on_defeated() -> void:
	queue_free()

func _animate_hp() -> void:
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.4).set_trans(Tween.TRANS_SINE)

func _animate_mp() -> void:
	var tween = create_tween()
	tween.tween_property(mp_bar, "value", current_mp, 0.4).set_trans(Tween.TRANS_SINE)

func play_attack_animation() -> void:
	if sprite:
		sprite.play("attack")

func play_hurt_animation() -> void:
	if sprite:
		sprite.play("hurt")

func play_die_animation() -> void:
	if sprite:
		sprite.play("die")
