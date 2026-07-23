extends CanvasLayer

@export var skill_list_container: VBoxContainer
@export var backdrop: Button
@export var panel: PanelContainer

signal skill_selected(skill: SkillData)
signal closed

func _ready() -> void:
	backdrop.pressed.connect(_on_close_pressed)

func open(character_data: CharacterData, current_mp: int) -> void:
	_populate_skills(character_data, current_mp)
	_animate_open()

func _populate_skills(character_data: CharacterData, current_mp: int) -> void:
	for child in skill_list_container.get_children():
		child.queue_free()

	if character_data.skills.is_empty():
		_add_label("No skill learned.")
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
		_add_label("No skills available")

func _add_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	skill_list_container.add_child(label)

func _animate_open() -> void:
	await get_tree().process_frame

	panel.pivot_offset = Vector2(panel.size.x / 2.0, panel.size.y)
	panel.scale = Vector2(1.0, 0.0)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3)

func _animate_close() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "scale", Vector2(1.0, 0.0), 0.2)
	await tween.finished

func _on_skill_chosen(skill: SkillData) -> void:
	skill_selected.emit(skill)
	await _animate_close()
	closed.emit()
	queue_free()

func _on_close_pressed() -> void:
	await _animate_close()
	closed.emit()
	queue_free()
