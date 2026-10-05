extends Control

#Объявление объектов на сцене
@onready var container: VBoxContainer = $CanvasLayer/VBoxContainer
@onready var lobby_id: Label = $CanvasLayer/VBoxContainer/LobbyID
@onready var players_label: Label = $CanvasLayer/VBoxContainer/PanelContainer/ScrollContainer/Players
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton

@onready var exit_button: Button = $CanvasLayer/ExitButton

@onready var message_box: Panel = $CanvasLayer/Message
@onready var message_text: Label =  $CanvasLayer/Message/VBoxContainer/Label

#Объявление переменных
var player_name: String
var player_names := {}



#Функции



#Вход на сцену
func _ready() -> void:
	
	#Настройка видимости объектов
	message_box.visible = false 
	container.visible = true
	exit_button.visible = true
	
	#Получаю имя игрока
	var file = FileAccess.open("user://player_data.txt", FileAccess.READ)
	player_name = file.get_as_text()
	
	#Подключаю мультплеерные вызовы в функцию
	TubeClientAutoload.peer_connected.connect(_on_peer_connected)
	TubeClientAutoload.peer_disconnected.connect(_on_peer_disconnected)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_host_disconnected)
	
	#Вывожу пятизначное ID сервера
	lobby_id.text = TubeClientAutoload.session_id.to_upper()
	
	#Обновляю список игроков
	_update_players_list()
	
	#Отключаю кнопку старта, если игрок - не хост
	if TubeClientAutoload.is_server == true:
		$CanvasLayer/VBoxContainer/StartButton.disabled = false
	else:
		$CanvasLayer/VBoxContainer/StartButton.disabled = true



#Список Игроков



func _update_players_list() -> void:
	#Добавляю имя в общий список
	_ensure_my_name()
	
	#Начальный текст
	var text := "Players in the lobby:\n"
	
	# Сортируем по ID
	var ids = player_names.keys()
	ids.sort()
	
	#Добавляем все имена в список
	for id in ids:
		var x = 0
		var original_name = player_names[id]
		var name_str = original_name
		
		#Добавляем "х" в конец имени при повторе
		for i in ids:
			if i == id:
				break
			elif player_names[i] == original_name:
				x += 1
			
			if x > 0:
				name_str = original_name + " " + str(x)
		
		#Помечаю списком все имена и указываю статусы
		if id == multiplayer.get_unique_id():
			text += "• " + name_str + " (you)\n"
		elif id == 1:
			text += "• " + name_str + " (host)\n"
		else:
			text += "• " + name_str + "\n"
	
	#Задаю текст лейбла
	players_label.text = text

func _ensure_my_name() -> void:
	
	#Получаю ID игрока
	var my_id = multiplayer.get_unique_id()
	if my_id == 0:
		return
	
	#Задаю имя игрока
	var my_name = player_name
	if my_name.is_empty():
		my_name = "Игрок " + str(my_id)
	
	#Прикрепляю имя определённому ID
	player_names[my_id] = my_name

func _send_my_name_to_everyone() -> void:
	#Добавляю имя в общий список
	_ensure_my_name()
	
	#Получаю имя
	var my_name = player_names[multiplayer.get_unique_id()]
	
	#Регестрирую имя игрока
	register_player_name.rpc(my_name)

#удалённый вызов ф-ции регистрации
#    любой игрок|должно дойти 100%|вызывается на моем ПК тоже
@rpc("any_peer", "reliable", "call_local")
func register_player_name(player_name_str: String) -> void:
	#Получаю айдти игрока
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Когда call_local — sender_id будет 0
	if sender_id == 0:
		#Получаю айдти игрока
		sender_id = multiplayer.get_unique_id()
	
	#Задаю введённое имя в общий список
	player_names[sender_id] = player_name_str
	
	#Обновляю список игроков
	_update_players_list()



#Обработчики мультиплеерных событий



func _on_peer_connected(peer_id: int) -> void:
	# Сразу добавляем себя в список
	_ensure_my_name()
	
	# Если это удалённый игрок — пока ставим временное имя
	if peer_id != multiplayer.get_unique_id():
		if not player_names.has(peer_id):
			player_names[peer_id] = "Игрок " + str(peer_id)
	
	#Обновляю список игроков
	_update_players_list()
	
	# Небольшая задержка, чтобы RPC точно работал
	await get_tree().create_timer(1.0).timeout
	_send_my_name_to_everyone()

func _on_peer_disconnected(peer_id: int) -> void:
	#удаляю имя игрока
	player_names.erase(peer_id)
	#Обновляю список игроков
	_update_players_list()

func _on_host_disconnected() -> void:
	#Покинуть сессию
	TubeClientAutoload.leave_session()
	#Причина кика
	message_text.text = "The host has left the server."
	#Показать сообщение
	container.visible = false
	exit_button.visible = false
	message_box.visible = true



#Обработчики сигналов



func _on_copy_button_pressed() -> void:
	#копирую ID с лейбла
	DisplayServer.clipboard_set(lobby_id.text)

func _on_exit_button_pressed() -> void:
	#Покидаю сессию
	TubeClientAutoload.leave_session()
	#Выхожу в главное меню
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
