extends Control

@onready var status_icon: TextureRect = $Popupbox/status_icon
@onready var great_and_failed: Label = $Popupbox/great_and_failed
@onready var message_label: Label = $Popupbox/message_label
@onready var back_button: TextureButton = $Popupbox/back_button

func _ready() -> void:
	back_button.pressed.connect(hide_popup)
	hide()

func show_success() -> void:
	status_icon.texture = load("res://Assets/Store/great icon.png")
	great_and_failed.text = "GREAT!"
	message_label.text = "Thanks, for your purchase is Success!"
	show()

func show_failed() -> void:
	status_icon.texture = load("res://Assets/Store/failed icon.png")
	great_and_failed.text = "FAILED!"
	message_label.text = "Something went wrong.\nPlease try again."
	show()

func hide_popup() -> void:
	hide()
