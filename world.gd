extends Node

# References
@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const Player = preload("res://player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

#server
func _on_host_button_pressed():
	main_menu.hide()
	
	# Creates the server
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	
	# Adds the player
	add_player(multiplayer.get_unique_id())

#client
func _on_join_button_pressed():
	main_menu.hide()
	
	# Creates the client
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
