extends Node2D

# Контейнер, в который добавляются карточки игроков
@onready var players := $CanvasLayer/HBoxContainer/Panel/PlayersContainer

# Сцена информации об игроке
var player_preview = preload("res://scenes/player_preview.tscn")

# Глобальный список игроков
var player_names = NamesAutoload.player_names


func _ready() -> void:
	# Создаём отдельный PlayerInfo для каждого игрока
	for id in player_names:
		var player = player_preview.instantiate()
		players.add_child(player)

		# Добавляем пометку для себя
		if id == multiplayer.get_unique_id():
			player._setup(player_names[id] + "\n(you)", 5)

		# Добавляем пометку для хоста
		elif id == 1:
			player._setup(player_names[id] + "\n(host)", 5)

		# Обычный игрок
		else:
			player._setup(player_names[id], 5)
