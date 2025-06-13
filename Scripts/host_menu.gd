extends Control

const PORT = 20200
const MAX_CLIENTS = 4
@export_enum('res://Scenes/main_scene.tscn', "res://Scenes/matrix_lobby.tscn") var scene_to_load : String = 'res://Scenes/matrix_lobby.tscn'
var Address = '127.0.0.1'
var port = 8910
var peer = null

@onready var logNode = $Log
@export_category('Debug')
@export var autoconnect : bool = false


#signal player_connected(peer_id, player_info)
#signal player_disconnected(peer_id)
#signal server_disconnected

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.main_scene = self
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	if autoconnect:
		logNode.text += 'Autoconnecting...\n'
		for argument in OS.get_cmdline_args():
			if argument == '--host':
				$Name.text = 'Host'
				_on_host_button_down()
			elif argument == '--client':
				$Name.text = 'Client'
				DisplayServer.window_set_current_screen(2)
				var timer = Timer.new()
				timer.wait_time = .5
				timer.one_shot = true
				add_child(timer)
				timer.start()
				await timer.timeout
				_on_join_button_down()
				timer.start()
				await timer.timeout
				_on_start_game_button_down()
				

func _process(_delta):
	pass

func peer_connected(id):
	print('Player connected, id: ', id)
	if multiplayer.is_server():
		logNode.text += 'Player joined, id: ' + str(id) + '\n'
		update_state()

func peer_disconnected(id):
	logNode.text += 'Player disconnected, id: ' + str(id) + '\n'
	if multiplayer.is_server():
		remove_player.rpc(id)
	if id == 1:
		logNode.text += 'Host disconnected, resetting \n'
		$StartGame.disabled = true
		var timer = Global.create_timer(1, true)
		await timer.timeout
		_on_reset_pressed()


func connected_to_server():
	print('Connected to server')
	SendPlayerInformation.rpc_id(1, $Name.text, multiplayer.get_unique_id())
	logNode.text += 'Succesfully connected to server. ' + '\n'
	update_state()

func connection_failed():
	print('Connection failed')

@rpc("any_peer")
func SendPlayerInformation(player_name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name" : player_name,
			'id' : id
		}
	update_state()
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)

@rpc("any_peer", "call_local")
func StartGame():
	if $Name.text != '':
		Global.player_name = $Name.text
	else: Global.player_name = 'Noname'
	var scene = load(scene_to_load).instantiate()
	get_tree().root.add_child(scene)
	update_state()
	$"..".close_menu()
	self.hide()

func _on_host_button_down():
	if multiplayer.is_server() and peer != null:
		logNode.text += "Can\'t host, already hosting \n"
		return
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	if error != OK:
		logNode.text += "Can't host, error: " + str(error) + '\n'
		print("Can't host: ", error )
		return
	else:
		logNode.text += '[color=green]Server started, port: ' + str(port) + '[/color]\n'
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	SendPlayerInformation($Name.text, multiplayer.get_unique_id())
	update_state()
	

func _on_join_button_down():
	if $IP.text != '':
		Address = $IP.text
	peer = ENetMultiplayerPeer.new()
	var _error = peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	logNode.text += 'Trying to join at ' + str(Address,':',port) + '\n'
	GameManager.Players.clear()


func _on_start_game_button_down():
	StartGame.rpc()

func _on_reset_pressed() -> void:
	if peer and peer.get_connection_status() == 2:
		peer.close()
	peer = null
	GameManager.Players.clear()
	logNode.text = ''
	update_state()


@rpc("any_peer","call_local","reliable")
func remove_player(id):
	GameManager.Players.erase(id)
	update_state()

func update_state() -> void:
	# Update list of players
	$PlayerList.text = '[center][b]Players[/b][/center]\n'
	for player in GameManager.Players:
		if GameManager.Players[player]['id'] == 1: $PlayerList.text += '(host) '
		$PlayerList.text += '[color=green]' + GameManager.Players[player]['name'] + ':' + str(GameManager.Players[player]['id']) + '[/color]\n'
	
	if GameManager.Players.size() > 0:
		$StartGame.disabled = false
	else:
		$StartGame.disabled = true
