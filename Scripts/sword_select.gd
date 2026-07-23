extends Control

@onready var tooltip_box: TextureRect = $PanelBG/Content/TooltipBox
@onready var tooltip_label: Label = $PanelBG/Content/TooltipBox/TooltipLabel
@onready var collect_button: TextureButton = $PanelBG/Content/CollectButton

var sword_names := [
	"Iron Sword", "Gold Sword", "Steel Sword", "Dark Sword", "Sapphire Sword",
	"Emerald Sword", "Shadow Sword", "Ice Sword", "Blood Sword", "Fire Sword"
]

var slots: Array = []
var selected_slot: TextureButton = null
var selected_index: int = -1
var is_collected: bool = false

func _ready() -> void:
	tooltip_box.visible = false
	collect_button.disabled = true

	for i in range(10):
		var slot_node = get_node_or_null("PanelBG/Content/Slot%d" % (i + 1))
		if slot_node == null:
			continue
		var slot: TextureButton = slot_node
		slots.append(slot)
		slot.mouse_entered.connect(_on_hover.bind(i))
		slot.mouse_exited.connect(_on_exit)
		slot.pressed.connect(_on_pick.bind(slot, i))

	collect_button.pressed.connect(_on_collect)

func _on_hover(index: int) -> void:
	if is_collected:
		return
	tooltip_label.text = sword_names[index]
	tooltip_box.visible = true

	var slot: TextureButton = slots[index]
	var slot_rect: Rect2 = slot.get_global_rect()
	var tooltip_rect: Rect2 = tooltip_box.get_global_rect()

	var gap := 8.0
	var target_x := slot_rect.position.x + (slot_rect.size.x - tooltip_rect.size.x) / 2
	var target_y: float

	var is_top_row := index < 5

	if is_top_row:
		target_y = slot_rect.position.y + slot_rect.size.y + gap
	else:
		target_y = slot_rect.position.y - tooltip_rect.size.y - gap

	tooltip_box.global_position = Vector2(target_x, target_y)

func _on_exit() -> void:
	tooltip_box.visible = false

func _on_pick(slot: TextureButton, index: int) -> void:
	if is_collected:
		return

	# matiin slot lain yang sebelumnya kepilih
	if selected_slot and selected_slot != slot:
		selected_slot.button_pressed = false

	slot.button_pressed = true
	selected_slot = slot
	selected_index = index
	collect_button.disabled = false

func _on_collect() -> void:
	if selected_slot == null or is_collected:
		return

	is_collected = true

	# kunci semua slot biar gak bisa diganti lagi
	for slot in slots:
		slot.disabled = true

	collect_button.disabled = true
	tooltip_box.visible = false

	print("Item dipilih & dikoleksi: ", sword_names[selected_index])
	# TODO: simpan item ke inventory/save data kamu di sini, misal:
	# Inventory.add_sword(sword_names[selected_index])

	get_tree().change_scene_to_file("res://Scenes/store.tscn")
