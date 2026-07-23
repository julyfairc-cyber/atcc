extends Control

@onready var purchase_popup = $PurchasePopUp

func _ready() -> void:
	$"scroll/content wrapper/Add more coins/Textbox_price1".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/Add more coins/Textbox_price2".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/Add more coins/Textbox_price3".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/weapon-bundle/Textbox_price4".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/weapon-bundle/Textbox_price5".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/character bundle/Textbox_price6".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/character bundle/Textbox_price7".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/item bundle/Textbox_price8".pressed.connect(_on_buy_pressed)
	$"scroll/content wrapper/item bundle/Textbox_price9".pressed.connect(_on_buy_pressed)

func _on_buy_pressed() -> void:
	var success := true
	if success:
		purchase_popup.show_success()
	else:
		purchase_popup.show_failed()
