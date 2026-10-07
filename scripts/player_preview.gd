extends Control

@onready var name_label = $VBoxContainer/NamePreview
@onready var cards_label = $VBoxContainer/CardNums

func _setup(player_name: String, cards_count: int) -> void:
	name_label.text = player_name
	cards_label.text = str(cards_count)
