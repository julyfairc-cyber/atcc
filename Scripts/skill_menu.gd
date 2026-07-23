# skill_menu.gd
extends CanvasLayer

@export var skill_list_container: VBoxContainer

signal skill_selected(skill: SkillData)
signal closed

func open(character_data: CharacterData) -> void:
	_populate_skills(character_data)

func _populate_skills(character_data: CharacterData) -> void:
	# Clear any old buttons first
	for child in skill_list_container.get_children():
		child.queue_free()

	if character_data.skills.is_empty():
		var label = Label.new()
		label.text = "No skills available"
		skill_list_container.add_child(label)
		return

	for skill in character_data.skills:
		var button = Button.new()
		button.text = "%s (MP: %d)" % [skill.skill_name, skill.mp_cost]
		button.pressed.connect(_on_skill_chosen.bind(skill))
		skill_list_container.add_child(button)

func _on_skill_chosen(skill: SkillData) -> void:
	skill_selected.emit(skill)
	closed.emit()
	queue_free()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
