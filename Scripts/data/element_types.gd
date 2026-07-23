# element_types.gd
extends Node
class_name ElementTypes

enum Element { PHYSICAL, WATER, FIRE, LEAF }

# Returns a damage multiplier for attacker_element vs defender_element
static func get_multiplier(attacker_element: Element, defender_element: Element) -> float:
	if attacker_element == Element.PHYSICAL or defender_element == Element.PHYSICAL:
		return 1.0  # Physical never has advantage/disadvantage

	match attacker_element:
		Element.WATER:
			if defender_element == Element.FIRE:
				return 1.5  # super effective
			elif defender_element == Element.LEAF:
				return 0.67  # not very effective
		Element.FIRE:
			if defender_element == Element.LEAF:
				return 1.5
			elif defender_element == Element.WATER:
				return 0.67
		Element.LEAF:
			if defender_element == Element.WATER:
				return 1.5
			elif defender_element == Element.FIRE:
				return 0.67

	return 1.0  # same element or no relationship
