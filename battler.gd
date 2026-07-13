# battler.gd
extends Node
class_name Battler

@export var battler_name: String = "Battler"
@export var level: int = 1
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var is_enemy: bool = false  # controls death behavior

# Drag the correct nodes into these slots in the Inspector for each scene instance
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
	current_hp = max_hp
	current_mp = max_mp
	_update_ui()

func _update_ui() -> void:
	name_label.text = battler_name
	level_label.text = "LV. %d" % level
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	mp_bar.max_value = max_mp
	mp_bar.value = current_mp
	hp_label.text = "%d/%d" % [current_hp, max_hp]
	mp_label.text = "%d/%d" % [current_mp, max_mp]

func take_damage(amount: int) -> void:
	current_hp = clamp(current_hp - amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	_animate_hp()
	if current_hp <= 0:
		died.emit()
		if is_enemy:
			_on_defeated()

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
	hp_label.text = "%d/%d" % [current_hp, max_hp]

func _animate_mp() -> void:
	var tween = create_tween()
	tween.tween_property(mp_bar, "value", current_mp, 0.4).set_trans(Tween.TRANS_SINE)
	mp_label.text = "%d/%d" % [current_mp, max_mp]
