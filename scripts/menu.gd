extends Control


# ============================================================
# ОБЪЕКТЫ СЦЕНЫ
# ============================================================

@onready var container_bg: VBoxContainer = $CanvasLayer/VBoxContainerBG
@onready var enter_name: LineEdit = $CanvasLayer/VBoxContainerBG/EnterName
@onready var join_game_button: Button = $CanvasLayer/VBoxContainerBG/JoinGame
@onready var create_game_button: Button = $CanvasLayer/VBoxContainerBG/CreateGame

@onready var join_game_panel: Panel = $CanvasLayer/JoinGamePanel
@onready var enter_id: LineEdit = $CanvasLayer/JoinGamePanel/VBoxContainerPAN/EnterID
@onready var join_lobby_button: Button = $CanvasLayer/JoinGamePanel/VBoxContainerPAN/JoinLobby

@onready var exit_button_join: Button = $CanvasLayer/JoinGamePanel/ExitButton

@onready var message_box: Panel = $CanvasLayer/Message
@onready var message_text: Label = $CanvasLayer/Message/VBoxContainer/Label
@onready var exit_button_message: Button = $CanvasLayer/Message/VBoxContainer/ExitButton2


# ============================================================
# ВХОД В СЦЕНУ
# ============================================================

func _ready() -> void:
	# Настраиваем начальную видимость
	join_game_panel.visible = false
	container_bg.visible = true
	exit_button_message.visible = false
	message_box.visible = false

	# Загружаем сохранённое имя игрока
	if FileAccess.file_exists("user://player_data.txt"):
		var file = FileAccess.open("user://player_data.txt", FileAccess.READ)
		enter_name.text = file.get_as_text()

	# Включаем кнопки, если имя уже указано
	_update_game_buttons()

	# Подключаем сигналы Tube
	TubeClientAutoload.session_created.connect(_on_session_created)
	TubeClientAutoload.session_joined.connect(_on_session_joined)
	TubeClientAutoload.error_raised.connect(_on_tube_error)


# ============================================================
# МУЛЬТИПЛЕЕРНЫЕ СОБЫТИЯ
# ============================================================

func _on_session_created() -> void:
	# После создания комнаты переходим в лобби
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_session_joined() -> void:
	# После подключения к комнате переходим в лобби
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_tube_error(code: int, message: String) -> void:
	# Обрабатываем ошибки подключения
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


# ============================================================
# ИМЯ ИГРОКА
# ============================================================

func _on_enter_name_text_changed(new_text: String) -> void:
	# Сохраняем имя в файл
	var file = FileAccess.open("user://player_data.txt", FileAccess.WRITE)
	file.store_string(enter_name.text)

	# Обновляем состояние кнопок
	_update_game_buttons()


func _update_game_buttons() -> void:
	# Кнопки доступны только при наличии имени
	var has_name := enter_name.text != ""

	join_game_button.disabled = !has_name
	create_game_button.disabled = !has_name


# ============================================================
# СОЗДАНИЕ И ПОДКЛЮЧЕНИЕ К ИГРЕ
# ============================================================

func _on_join_game_pressed() -> void:
	# Показываем окно ввода ID комнаты
	container_bg.visible = false
	join_game_panel.visible = true


func _on_create_game_pressed() -> void:
	# Показываем сообщение о создании комнаты
	message_text.text = "Creating..."

	container_bg.visible = false
	exit_button_message.visible = false
	message_box.visible = true

	# Создаём мультиплеерную сессию
	TubeClientAutoload.create_session()


func _on_enter_id_text_changed(new_text: String) -> void:
	# ID комнаты должен содержать ровно 5 символов
	join_lobby_button.disabled = enter_id.text.length() != 5


func _on_join_lobby_pressed() -> void:
	# Показываем сообщение о подключении
	message_text.text = "Joining..."

	join_game_panel.visible = false
	exit_button_message.visible = false
	message_box.visible = true

	# Подключаемся к комнате
	TubeClientAutoload.join_session(enter_id.text.to_lower())


# ============================================================
# КНОПКА ВЫХОДА
# ============================================================

func _on_exit_button_pressed() -> void:
	# Возвращаем главное меню
	join_game_panel.visible = false
	message_box.visible = false
	exit_button_message.visible = false
	container_bg.visible = true
