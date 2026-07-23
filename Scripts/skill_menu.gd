# skill_menu.gd
extends CanvasLayer

@export var skill_list_container: VBoxContainer
@export var backdrop: Button
var custom_font = preload("res://Assets/Pixellari.ttf")
signal skill_selected(skill: SkillData)
signal closed

func _ready() -> void:
	backdrop.pressed.connect(_on_close_pressed)
	
func open(character_data: CharacterData, current_mp: int) -> void:
	_populate_skills(character_data, current_mp)

func _populate_skills(character_data: CharacterData, current_mp: int) -> void:
	for child in skill_list_container.get_children():
		if child.name != "HeaderRow":
			child.queue_free()

	if character_data.skills.is_empty():
		var label = Label.new()
		label.text = "No skills available"
		skill_list_container.add_child(label)
		return

	var has_valid_skill = false

	for skill in character_data.skills:
		if skill == null:
			continue

		has_valid_skill = true
		var button = Button.new()
		button.text = "%s (MP: %d)" % [skill.skill_name, skill.mp_cost]
		button.pressed.connect(_on_skill_chosen.bind(skill))

		if current_mp < skill.mp_cost:
			button.disabled = true

		skill_list_container.add_child(button)

	if not has_valid_skill:
		var label = Label.new()
		label.text = "No skills available"
		skill_list_container.add_child(label)

func _on_skill_chosen(skill: SkillData) -> void:
	skill_selected.emit(skill)
	closed.emit()
	queue_free()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
