extends Control

func _ready() -> void:
	
	$CanvasLayer/Panel.visible = false
	$CanvasLayer/VBoxContainerBG.visible = true
	
	if FileAccess.file_exists("user://player_data.txt"):
		var file = FileAccess.open("user://player_data.txt", FileAccess.READ)
		$CanvasLayer/VBoxContainerBG/EnterName.text = file.get_as_text()
	
	if $CanvasLayer/VBoxContainerBG/EnterName.text != "":
		$CanvasLayer/VBoxContainerBG/JoinGame.disabled = false
		$CanvasLayer/VBoxContainerBG/CreateGame.disabled = false
	else:
		$CanvasLayer/VBoxContainerBG/JoinGame.disabled = true
		$CanvasLayer/VBoxContainerBG/CreateGame.disabled = true
	
	TubeClientAutoload.session_created.connect(_on_session_created)
	TubeClientAutoload.session_joined.connect(_on_session_joined)

func _on_enter_name_text_changed(new_text: String) -> void:
	var file = FileAccess.open("user://player_data.txt", FileAccess.WRITE)
	file.store_string($CanvasLayer/VBoxContainerBG/EnterName.text)
	
	if $CanvasLayer/VBoxContainerBG/EnterName.text != "":
		$CanvasLayer/VBoxContainerBG/JoinGame.disabled = false
		$CanvasLayer/VBoxContainerBG/CreateGame.disabled = false
	else:
		$CanvasLayer/VBoxContainerBG/JoinGame.disabled = true
		$CanvasLayer/VBoxContainerBG/CreateGame.disabled = true

func _on_create_game_pressed() -> void:
	TubeClientAutoload.create_session()

func _on_join_game_pressed() -> void:
	$CanvasLayer/VBoxContainerBG.visible = false
	$CanvasLayer/Panel.visible = true

func _on_exit_button_pressed() -> void:
	$CanvasLayer/Panel.visible = false
	$CanvasLayer/VBoxContainerBG.visible = true

func _on_enter_id_text_changed(new_text: String) -> void:
	if $CanvasLayer/Panel/VBoxContainerPAN/EnterID.text != "":
		$CanvasLayer/Panel/VBoxContainerPAN/JoinLobby.disabled = false
	else:
		$CanvasLayer/Panel/VBoxContainerPAN/JoinLobby.disabled = true

func _on_join_lobby_pressed() -> void:
	TubeClientAutoload.join_session($CanvasLayer/Panel/VBoxContainerPAN/EnterID.text)

func _on_session_created():
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_session_joined():
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
