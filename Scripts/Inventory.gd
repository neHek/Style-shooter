extends Node

# Define the maximum number of items the inventory can hold
var max_items: int = 5
@export var default_inventory_logo: Texture2D
@onready var drop_marker = $"../Anchor/Marker3D"
@onready var camera = $"../Anchor/Camera"


# This is the list that will store our inventory items
var storage: Array = []
var active_slot: int = 0

# Signal that will notify when the inventory changes
signal inventory_updated

func _process(_delta):
	process_input()
	held_item_process()

func _ready():
	set_multiplayer_authority(get_parent().get_multiplayer_authority())
	storage.resize(max_items)
	emit_signal('inventory_updated')


@rpc("authority","call_local","reliable")
func pick_up(item):
	item = get_node(item)
	item.set_multiplayer_authority(int(get_parent().name))
	if active_slot != -1 and storage[active_slot] == null:
		storage[active_slot] = item
		# Item is frozen in space somewhere far
		item.position.x = 500
		item.position.y = 500
		item.position.z = 500
		item.freeze = true
		emit_signal('inventory_updated')
		return true
	
	for i in range(0, 5):
		if storage[i] == null:
			storage[i] = item
			# Item is frozen in space somewhere far
			item.position.x = 500
			item.position.y = 500
			item.position.z = 500
			item.freeze = true
			print('Picked up: ', storage[i].name)
			emit_signal('inventory_updated')
			return true
	
	print('Inventory full')
	return false

@rpc("authority","call_local","reliable")
func drop():
	if active_slot == -1:
		print('Inactive slot')
		return
	if storage[active_slot] != null:
		var item = storage[active_slot]
		storage[active_slot] = null
		item.get_node('Pickupable').drop()
		item.global_transform = drop_marker.global_transform
		item.freeze = false
		
		# Push item
		var impulse = camera.global_position.direction_to(drop_marker.global_position).normalized()*300
		item.apply_central_force(impulse)
		
		print('Dropped: ', item.name)
		emit_signal('inventory_updated')

func process_input():
	if multiplayer.get_unique_id() != get_multiplayer_authority():
		return
	if Input.is_action_just_pressed("num_1"):
		if active_slot == 0:
			active_slot = -1
			emit_signal('inventory_updated')
		else:
			active_slot = 0
			emit_signal('inventory_updated')
	
	if Input.is_action_just_pressed("num_2"):
		if active_slot == 1:
			active_slot = -1
			emit_signal('inventory_updated')
		else:
			active_slot = 1
			emit_signal('inventory_updated')
	
	if Input.is_action_just_pressed("num_3"):
		if active_slot == 2:
			active_slot = -1
			emit_signal('inventory_updated')
		else:
			active_slot = 2
			emit_signal('inventory_updated')
	
	if Input.is_action_just_pressed("num_4"):
		if active_slot == 3:
			active_slot = -1
			emit_signal('inventory_updated')
		else:
			active_slot = 3
			emit_signal('inventory_updated')
	
	if Input.is_action_just_pressed("num_5"):
		if active_slot == 4:
			active_slot = -1
			emit_signal('inventory_updated')
		else:
			active_slot = 4
			emit_signal('inventory_updated')
	$ActiveSlot.text = 'Active slot: ' + str(active_slot)
	
	if Input.is_action_just_pressed("drop"):
		drop.rpc()

@rpc("any_peer","call_local","reliable")
func remove_item(item_name : String):
	for i in range(0, storage.size()):
		if storage[i] == null: continue
		if storage[i].name == item_name:
			storage[i] = null
	emit_signal('inventory_updated')

func _on_inventory_updated():
	$ActiveSlot.text = 'Active slot: ' + str(active_slot)
	var inv_slots = $InventoryUI.get_children()
	for slot in range(0, 5):
		inv_slots[slot].color = Color(1, 0, 0, 1)
		if storage[slot] != null:
			# inv_slots[slot].color = Color(0, 0, 1, 1)
			if storage[slot].find_child('Pickupable').Ui_texture != null:
				var sprite = inv_slots[slot].get_child(0)
				sprite.set_texture(storage[slot].find_child('Pickupable').Ui_texture)
			else:
				var sprite = inv_slots[slot].get_child(0)
				sprite.set_texture(default_inventory_logo)
		else:
			var sprite = inv_slots[slot].get_child(0)
			sprite.set_texture(null)
	if active_slot != -1:
		inv_slots[active_slot].color = Color(0, 1, 0, 1)

func held_item_process():
	if multiplayer.get_unique_id() != get_multiplayer_authority():
		return
	if active_slot != -1:
		if storage[active_slot] != null:
			if storage[active_slot].get_node('Pickupable').has_method('active_item_process'):
				storage[active_slot].get_node('Pickupable').active_item_process()
	
