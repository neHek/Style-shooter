#Raycast from player's camera and player himself needs to be linked for this to work

extends Node
var collider
@onready var InteractRay = $"../Anchor/RayCast3D"
@onready var player = $".."
@onready var inventory_node = $"../InventoryNode"
@onready var active_item_spot = $"../Anchor/ActiveItemSpot"


func _ready():
	pass # Replace with function body.


func _process(_delta):
	if is_multiplayer_authority():
		handle_interactions()

func handle_interactions():
	collider = InteractRay.get_collider()
	$"../InventoryNode/DebugLabel".text = collider.name if collider else ''
	# Picking up
	if Input.is_action_just_pressed("interact") and collider:
		var pickupable = collider.find_child('Pickupable')
		var talkable = collider.find_child('ConversationNode')
		if pickupable:
			inventory_node.pick_up.rpc(collider.get_path())
			pickupable.interact.rpc(player.name)
			return
		if talkable:
			talkable.start_conversation()
			return
	# Interacting and pushing
		if collider.has_method('interact'):
			$"../InventoryNode/DebugLabel2".text = 'Interacted with ' + collider.name
			collider.interact()
			return
		else: if collider is RigidBody3D:
				var impulse = player.position.direction_to(collider.position).normalized()*50
				collider.apply_central_force(impulse)
				$"../InventoryNode/DebugLabel2".text = 'Pushed ' + collider.name
