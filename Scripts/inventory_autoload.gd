# inventory.gd
extends Node

# Dictionary of ItemData -> quantity
var items: Dictionary = {}

func add_item(item: ItemData, amount: int = 1) -> void:
	items[item] = items.get(item, 0) + amount

func remove_item(item: ItemData, amount: int = 1) -> void:
	if items.has(item):
		items[item] -= amount
		if items[item] <= 0:
			items.erase(item)

func get_quantity(item: ItemData) -> int:
	return items.get(item, 0)
