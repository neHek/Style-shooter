extends Node

@export var initial_state : State
var current_state : State
var states : Dictionary = {}

@export_category("Player")
@export var player : CharacterBody3D
@onready var anchor = $"../Anchor"
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export_range(0.1, 1, 0.1) var crouching_speed_scale: float = 0.5 
@export var mouse_captured: bool = false
var look_dir: Vector2 # Input direction for look/aim

@export_category("Movement")
@export_range(0.1, 3.0, 0.1) var jump_height: float = 2 # m
@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 60 # m/s^2
@export_range(0, 100, 1) var walk_friction: float = 60 # m/s^2
@export_range(0, 100, 1) var gravity_friction: float = 60 # m/s^2
@export_range(0, 100, 1) var jump_friction: float = 60 # m/s^2

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var move_dir: Vector2 # Input direction for movement
var jump_vel: Vector3 # Jumping velocity

# Multiplayer sync
@export var sync_pos : Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	capture_mouse()
	player.set_floor_max_angle(deg_to_rad(75)) 
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
		$"../CurrentState".text = current_state.name

func _physics_process(delta):
	current_state.check_transitions()
	if current_state:
		current_state.Physics_Update(delta)
	# So we don't get stuck to walls
	for i in range(0, player.get_slide_collision_count() - 1):
		var collision_normal = player.get_slide_collision(i).get_normal()
		if walk_vel.dot(collision_normal) <= 0:
			current_state.walk_vel = walk_vel.slide(collision_normal)
		if jump_vel.dot(collision_normal) <= 0:
			current_state.jump_vel = jump_vel.slide(collision_normal)
	if is_multiplayer_authority():
		player.move_and_slide()
		sync_pos = player.global_position
	else:
		player.global_position = sync_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_state:
		current_state.Update(delta)


func on_child_transition(state, new_state_name):
	if state != current_state:
		return
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
	if new_state == current_state:
		return
	if current_state:
		current_state.Exit()
	new_state.Enter()
	current_state = new_state
	#print('Transitioned to: ', new_state_name)
	$"../CurrentState".text = current_state.name
	print('Transitioned ', state, ' ', new_state)

# Mouse controls
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	
func _rotate_camera(sens_mod: float = 1.0) -> void:
	player.rotation.y -= look_dir.x * camera_sens * sens_mod
	anchor.rotation.x = clamp(anchor.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)
	
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
