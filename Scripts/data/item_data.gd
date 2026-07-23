# item_data.gd
extends Resource
class_name ItemData

enum EffectType { HEAL_HP, HEAL_MP }

@export var item_name: String = "Potion"
@export var description: String = ""
@export var icon: Texture2D
@export var effect_type: EffectType = EffectType.HEAL_HP
@export var amount: int = 30
