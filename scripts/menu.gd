extends Control

#Объявление объектов на сцене
@onready var container_bg: VBoxContainer = $CanvasLayer/VBoxContainerBG
@onready var enter_name: LineEdit = $CanvasLayer/VBoxContainerBG/EnterName
@onready var join_game_button: Button = $CanvasLayer/VBoxContainerBG/JoinGame
@onready var create_game_button: Button = $CanvasLayer/VBoxContainerBG/CreateGame

@onready var join_game_panel: Panel = $CanvasLayer/JoinGamePanel
@onready var enter_id: LineEdit = $CanvasLayer/JoinGamePanel/VBoxContainerPAN/EnterID
@onready var join_lobby_button: Button = $CanvasLayer/JoinGamePanel/VBoxContainerPAN/JoinLobby

@onready var exit_button_join: Button =  $CanvasLayer/JoinGamePanel/ExitButton

@onready var message_box: Panel = $CanvasLayer/Message
@onready var message_text: Label =  $CanvasLayer/Message/VBoxContainer/Label
@onready var exit_button_message: Button =  $CanvasLayer/Message/VBoxContainer/ExitButton2



#Функции


#Вход на сцену
func _ready() -> void:
	
	#Настройка видимости объектов
	join_game_panel.visible = false
	container_bg.visible = true
	exit_button_message.visible = false
	message_box.visible = false
	
	#Получаю имя игрока
	if FileAccess.file_exists("user://player_data.txt"):
		var file = FileAccess.open("user://player_data.txt", FileAccess.READ)
		enter_name.text = file.get_as_text()
	
	#Проверяю наличие имени, для запуска/создания игры
	if enter_name.text != "":
		join_game_button.disabled = false
		create_game_button.disabled = false
	else:
		join_game_button.disabled = true
		create_game_button.disabled = true
	
	#Подключаю мультплеерные вызовы в функцию
	TubeClientAutoload.session_created.connect(_on_session_created)
	TubeClientAutoload.session_joined.connect(_on_session_joined)
	TubeClientAutoload.error_raised.connect(_on_tube_error)



#Обработка мультиплеерных событий



func _on_session_created():
	#Захожу в лобби
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_session_joined():
	#Захожу в лобби
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_tube_error(code: int, message: String):
	#Обработка ошибок
	match code:
		TubeClientAutoload.SessionError.JOIN_SESSION_FAILED:
			message_text.text = "Joining error"
			join_game_panel.visible = false
			message_box.visible = true
			exit_button_message.visible = true
		TubeClient.SessionError.CREATE_SESSION_FAILED:
			message_text.text = "Creating error"
			join_game_panel.visible = false
			message_box.visible = true
			exit_button_message.visible = true



#Обработка сигналов



func _on_enter_name_text_changed(new_text: String) -> void:
	#Сохраняю имя в файл
	var file = FileAccess.open("user://player_data.txt", FileAccess.WRITE)
	file.store_string(enter_name.text)
	
	#Проверяю наличие имени, для запуска/создания игры
	if enter_name.text != "":
		join_game_button.disabled = false
		create_game_button.disabled = false
	else:
		join_game_button.disabled = true
		create_game_button.disabled = true

func _on_join_game_pressed() -> void:
	#Настройка видимости объектов
	container_bg.visible = false
	join_game_panel.visible = true

func _on_create_game_pressed() -> void:
	#Показ уведомления о создании
	message_text.text = "Creating..."
	container_bg.visible = false
	exit_button_message.visible = false
	message_box.visible = true
	
	#Создаю мультиплеерную сессию
	TubeClientAutoload.create_session()



func _on_enter_id_text_changed(new_text: String) -> void:
	#Проверяю наличие 5 символов в поле "ID"
	if enter_id.text.length() == 5:
		join_lobby_button.disabled = false
	else:
		join_lobby_button.disabled = true

func _on_join_lobby_pressed() -> void:
	#Показ уведомления о присоиденении
	message_text.text = "Joining..."
	join_game_panel.visible = false
	exit_button_message.visible = false
	message_box.visible = true
	
	#Захожу в созданую сессию
	TubeClientAutoload.join_session(enter_id.text.to_lower())

func _on_exit_button_pressed() -> void:
	#Настройка видимости объектов
	join_game_panel.visible = false
	message_box.visible = false
	exit_button_message.visible = false
	container_bg.visible = true
