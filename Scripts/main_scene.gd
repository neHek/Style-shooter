extends Node3D

@export_category('Sound testing')
@export var disable_client_sound : bool = false
@export var disable_server_sound : bool = false

@export_category('Packed scenes')
@export var PlayerScene: PackedScene

func _enter_tree():
	Global.main_scene = self
	if disable_client_sound and !multiplayer.is_server():
		Global.audio_muted = true
	if disable_server_sound and multiplayer.is_server():
		Global.audio_muted = true

func _ready():
	if multiplayer.is_server():
		var spawn_points = get_tree().get_nodes_in_group('PlayerSpawnPoint')
		var index = 0
		for i in GameManager.Players:
			var playerToSpawn = PlayerScene.instantiate()
			var chosen_spawn = spawn_points[index]
			index += 1
			playerToSpawn.name = str(GameManager.Players[i].id)
			add_child(playerToSpawn)
			playerToSpawn.global_position = chosen_spawn.global_position
			print('Player spawned at: ', playerToSpawn.global_position)
		for player in get_tree().get_nodes_in_group('player'):
			spawn_player.rpc(str(player.name), player.global_position)
			set_player_authority.rpc(str(player.name))

@rpc('any_peer')
func spawn_player(player_name, passed_position):
	var playerToSpawn = PlayerScene.instantiate()
	playerToSpawn.name = player_name
	add_child(playerToSpawn)
	playerToSpawn.global_position = passed_position
	

@rpc("any_peer","call_local")
func set_player_authority(player_name):
	get_node(player_name).set_multiplayer_authority(int(player_name))
	if multiplayer.get_unique_id() == int(player_name): # If authority
		get_node(player_name).get_node("Anchor/Camera").make_current()
		Global.set_multiplayer_authority(int(player_name))
		Global.player = get_node(player_name) 
	else: # If not authority
		get_node(player_name).get_node('InventoryNode').visible = false
		for child in get_node(player_name).get_children():
			if child is Control:
				child.hide()
