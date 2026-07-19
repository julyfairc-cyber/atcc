# character_data.gd
extends Resource
class_name CharacterData

@export var character_name: String = "Character"
@export var level: int = 1
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10
@export var portrait: Texture2D
@export var element: ElementTypes.Element = ElementTypes.Element.PHYSICAL  # this character's own elemental type (for being attacked)
@export var skills: Array[SkillData] = []
