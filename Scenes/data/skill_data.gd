# skill_data.gd
extends Resource
class_name SkillData

@export var skill_name: String = "Fireball"
@export var description: String = ""
@export var icon: Texture2D
@export var mp_cost: int = 10
@export var damage_multiplier: float = 1.5
@export var element: ElementTypes.Element = ElementTypes.Element.PHYSICAL
