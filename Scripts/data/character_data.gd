extends Resource
class_name CharacterData

@export var character_name: String = "Character"
@export var level: int = 1
@export var max_level: int = 100

@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10
@export var portrait: Texture2D
@export var element: ElementTypes.Element = ElementTypes.Element.PHYSICAL
@export var skills: Array[SkillData] = []

@export var current_exp: int = 0

@export var hp_growth: int = 5
@export var mp_growth: int = 3
@export var attack_growth: int = 2
@export var defense_growth: int = 1
@export var speed_growth: int = 1

func exp_to_next_level() -> int:
	return int(50 * pow(level, 1.5))

func gain_exp(amount: int) -> Dictionary:
	var leveled_up = false
	var levels_gained = 0

	current_exp += amount

	while level < max_level and current_exp >= exp_to_next_level():
		current_exp -= exp_to_next_level()
		level += 1
		levels_gained += 1
		leveled_up = true
		_apply_level_up_stats()

	if level >= max_level:
		current_exp = 0 

	return {"leveled_up": leveled_up, "levels_gained": levels_gained}

func _apply_level_up_stats() -> void:
	max_hp += hp_growth
	max_mp += mp_growth
	attack += attack_growth
	defense += defense_growth
	speed += speed_growth
