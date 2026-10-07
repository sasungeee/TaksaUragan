extends Control


# ============================================================
# ОБЪЕКТЫ СЦЕНЫ
# ============================================================

@onready var container: VBoxContainer = $CanvasLayer/VBoxContainer
@onready var lobby_id: Label = $CanvasLayer/VBoxContainer/LobbyID
@onready var players_label: Label = $CanvasLayer/VBoxContainer/PanelContainer/ScrollContainer/Players
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton

@onready var exit_button: Button = $CanvasLayer/ExitButton

@onready var message_box: Panel = $CanvasLayer/Message
@onready var message_text: Label = $CanvasLayer/Message/VBoxContainer/Label


# ============================================================
# ПЕРЕМЕННЫЕ
# ============================================================

# Имя текущего игрока
var player_name: String

# Список готовых имён, доступный через Autoload
var player_names := NamesAutoload.player_names

# Исходные имена игроков
# Например: {1: "Влад", 5: "Влад", 8: "Петя"}
var original_names: Dictionary = {}

# Порядок подключения игроков
# Например: [1, 5, 8]
var player_order: Array[int] = []


# ============================================================
# ВХОД В СЦЕНУ
# ============================================================

func _ready() -> void:
	# Настройка интерфейса
	message_box.visible = false
	container.visible = true
	exit_button.visible = true

	# Загружаем имя игрока
	if FileAccess.file_exists("user://player_data.txt"):
		var file = FileAccess.open("user://player_data.txt", FileAccess.READ)
		player_name = file.get_as_text()

	# Подключаем сетевые сигналы
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_host_disconnected)

	# Показываем ID комнаты
	lobby_id.text = TubeClientAutoload.session_id.to_upper()

	# Хост регистрирует себя
	if multiplayer.is_server():
		var my_id = multiplayer.get_unique_id()

		if !player_order.has(my_id):
			player_order.append(my_id)

		original_names[my_id] = player_name

		_update_names_for_everyone()

	else:
		# Даём соединению немного времени установиться
		await get_tree().create_timer(0.5).timeout
		_send_my_name()

	# Обновляем список игроков
	_update_players_list()

	# Кнопка старта доступна только хосту
	start_button.disabled = !multiplayer.is_server()


# ============================================================
# РАБОТА С ИМЕНАМИ
# ============================================================

# Отправляет имя клиента хосту
func _send_my_name() -> void:
	var name_to_send = player_name

	if name_to_send.is_empty():
		name_to_send = "Игрок " + str(multiplayer.get_unique_id())

	_register_player_name.rpc_id(1, name_to_send)


# Получает имя клиента на стороне хоста
@rpc("any_peer", "reliable")
func _register_player_name(name: String) -> void:
	if !multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()

	# Если имя пустое, используем ID игрока
	if name.is_empty():
		name = "Игрок " + str(sender_id)

	# Сохраняем исходное имя
	original_names[sender_id] = name

	# Добавляем игрока в порядок подключения,
	# если он ещё не был добавлен
	if !player_order.has(sender_id):
		player_order.append(sender_id)

	# Пересчитываем имена и отправляем их всем
	_update_names_for_everyone()


# Формирует уникальные имена игроков
func _update_names_for_everyone() -> void:
	if !multiplayer.is_server():
		return

	var result: Dictionary = {}
	var counters: Dictionary = {}

	# Идём именно в порядке подключения
	for id in player_order:
		if !original_names.has(id):
			continue

		var original_name: String = original_names[id]

		# Считаем, сколько раз уже встретилось это имя
		if !counters.has(original_name):
			counters[original_name] = 1
		else:
			counters[original_name] += 1

		var number: int = counters[original_name]

		# Первому игроку суффикс не нужен
		if number == 1:
			result[id] = original_name
		else:
			result[id] = original_name + " " + str(number)

	# Отправляем готовый список всем игрокам
	_set_names.rpc(result)


# Получает готовый список имён
@rpc("authority", "reliable", "call_local")
func _set_names(names: Dictionary) -> void:
	# Обновляем глобальный список игроков
	NamesAutoload.player_names.clear()
	NamesAutoload.player_names.merge(names)

	# Обновляем список на экране
	_update_players_list()


# ============================================================
# СПИСОК ИГРОКОВ
# ============================================================

func _update_players_list() -> void:
	var text := "Players in the lobby:\n"

	# Получаем ID всех игроков
	var ids = player_names.keys()

	# Сортируем только для отображения списка
	ids.sort()

	for id in ids:
		var name_str: String = player_names[id]

		# Текущий игрок
		if id == multiplayer.get_unique_id():
			text += "• " + name_str + " (you)\n"

		# Хост
		elif id == 1:
			text += "• " + name_str + " (host)\n"

		# Остальные игроки
		else:
			text += "• " + name_str + "\n"

	players_label.text = text


# ============================================================
# ПОДКЛЮЧЕНИЕ ИГРОКА
# ============================================================

func _on_peer_connected(peer_id: int) -> void:
	if !multiplayer.is_server():
		return

	# Сохраняем порядок подключения
	if !player_order.has(peer_id):
		player_order.append(peer_id)

	print("Порядок игроков: ", player_order)


# ============================================================
# ОТКЛЮЧЕНИЕ ИГРОКА
# ============================================================

func _on_peer_disconnected(peer_id: int) -> void:
	if !multiplayer.is_server():
		return

	# Удаляем игрока из обоих списков
	original_names.erase(peer_id)
	player_order.erase(peer_id)

	# Пересчитываем имена оставшихся игроков
	_update_names_for_everyone()


# ============================================================
# ОТКЛЮЧЕНИЕ ХОСТА
# ============================================================

func _on_host_disconnected() -> void:
	# Покидаем сессию
	TubeClientAutoload.leave_session()

	# Показываем сообщение
	message_text.text = "The host has left the server."

	container.visible = false
	exit_button.visible = false
	message_box.visible = true


# ============================================================
# НАЧАЛО ИГРЫ
# ============================================================

@rpc("authority", "reliable", "call_local")
func _start_game() -> void:
	# Все игроки переходят на игровую сцену
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ============================================================
# КНОПКИ
# ============================================================

func _on_copy_button_pressed() -> void:
	# Копируем ID комнаты в буфер обмена
	DisplayServer.clipboard_set(lobby_id.text)


func _on_exit_button_pressed() -> void:
	# Покидаем сессию
	TubeClientAutoload.leave_session()

	# Возвращаемся в меню
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_start_button_pressed() -> void:
	# Начать игру может только хост
	if !multiplayer.is_server():
		return

	_start_game.rpc()
