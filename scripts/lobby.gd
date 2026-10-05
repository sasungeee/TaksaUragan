extends Control

@onready var lobby_id: Label = $CanvasLayer/VBoxContainer/LobbyID
@onready var players_label: Label = $CanvasLayer/VBoxContainer/PanelContainer/ScrollContainer/Players
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton

var player_name
var player_names := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$CanvasLayer/Panel.visible = false
	$CanvasLayer/VBoxContainer.visible = true
	$CanvasLayer/ExitButton.visible = true
	
	var file = FileAccess.open("user://player_data.txt", FileAccess.READ)
	player_name = file.get_as_text()
	
	TubeClientAutoload.peer_connected.connect(_on_peer_connected)
	TubeClientAutoload.peer_disconnected.connect(_on_peer_disconnected)
	
	# Также слушаем стандартные сигналы (на всякий случай)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	lobby_id.text = TubeClientAutoload.session_id
	print("Сессия создана: ", TubeClientAutoload.session_id)
	
	_update_players_list()
	
	if TubeClientAutoload.is_server == true:
		$CanvasLayer/VBoxContainer/StartButton.disabled = false
	else:
		$CanvasLayer/VBoxContainer/StartButton.disabled = true

func _on_peer_connected(peer_id: int) -> void:
	print("Подключился peer: ", peer_id)
	
	# Сразу добавляем себя в список
	_ensure_my_name()
	
	# Если это удалённый игрок — пока ставим временное имя
	if peer_id != multiplayer.get_unique_id():
		if not player_names.has(peer_id):
			player_names[peer_id] = "Игрок " + str(peer_id)
	
	await get_tree().create_timer(1.0).timeout
	_update_players_list()
	
	# Небольшая задержка, чтобы RPC точно работал
	await get_tree().create_timer(1.0).timeout
	_send_my_name_to_everyone()

func _on_peer_disconnected(peer_id: int) -> void:
	print("Отключился peer: ", peer_id)
	player_names.erase(peer_id)
	
	if peer_id == 1 or not multiplayer.is_server():
		TubeClientAutoload.leave_session()
		$CanvasLayer/Panel/VBoxContainer/Label.text = "The host has left the server."
		$CanvasLayer/VBoxContainer.visible = false
		$CanvasLayer/ExitButton.visible = false
		$CanvasLayer/Panel.visible = true
	else:
		_update_players_list()

func _ensure_my_name() -> void:
	var my_id = multiplayer.get_unique_id()
	if my_id == 0:
		return
	
	var my_name = player_name
	if my_name.is_empty():
		my_name = "Игрок " + str(my_id)
	
	player_names[my_id] = my_name

func _send_my_name_to_everyone() -> void:
	_ensure_my_name()
	var my_name = player_names[multiplayer.get_unique_id()]
	register_player_name.rpc(my_name)   # отправляем всем + себе (call_local)

@rpc("any_peer", "reliable", "call_local")
func register_player_name(player_name_str: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Когда call_local — sender_id будет 0
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	
	player_names[sender_id] = player_name_str
	_update_players_list()
	print("Игрок ", sender_id, " теперь: ", player_name_str)

func _update_players_list() -> void:
	_ensure_my_name()
	
	var text := "Players in the lobby:\n"
	
	# Сортируем по ID, чтобы порядок был стабильный
	var ids = player_names.keys()
	ids.sort()
	
	for id in ids:
		var x = 0
		var original_name = player_names[id]
		var name_str = original_name
		
		for i in ids:
			if i == id:
				break
			elif player_names[i] == original_name:
				x += 1
			
			if x > 0:
				name_str = original_name + " " + str(x)

		if id == multiplayer.get_unique_id():
			text += "• " + name_str + " (you)\n"
		elif id == 1:
			text += "• " + name_str + " (host)\n"
		else:
			text += "• " + name_str + "\n"
	
	players_label.text = text

func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set($CanvasLayer/VBoxContainer/LobbyID.text)


func _on_exit_button_pressed() -> void:
	TubeClientAutoload.leave_session()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
