class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2
@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export_range(0.1, 1, 0.1) var crouching_speed_scale: float = 0.5 

var jumping: bool = false
@export var crouching: bool = false
var mouse_captured: bool = false

# audio 
@onready var step_emitter = $AudioStreamPlayer3D
var step_sounds : Dictionary
var floorMaterial : String
const stepSoundTimer = 0.3
var currentStepSoundTimer = stepSoundTimer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var sync_pos = Vector3.ZERO
@onready var camera: Camera3D = $Anchor/Camera
@onready var anchor = $Anchor

func _ready() -> void:
	if !multiplayer.is_server():
		$HostPeer.text = 'PEER'
	capture_mouse()
	# Load the step sound randomizers
	var randomizers = Global.get_all_resources_in_folder("res://assets/SFX/footsteps")
	for item in randomizers:
		var material = item.get_slice('_',0)
		step_sounds[material] = randomizers[item]
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed("jump"): jumping = true


func _physics_process(delta: float) -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		sync_pos = global_position
		velocity = _walk(delta) + _gravity(delta) + _jump(delta)
		crouch()
		move_and_slide()
		# Processing step sounds
		if walk_vel != Vector3.ZERO and is_on_floor():
			walking_sound.rpc(delta)
	else:
		global_position = global_position.lerp(sync_pos, 0.5)

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	rotation.y -= look_dir.x * camera_sens * sens_mod
	anchor.rotation.x = clamp(anchor.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	var target_speed = walk_dir * speed * move_dir.length()
	if crouching: target_speed *= crouching_speed_scale
	walk_vel = walk_vel.move_toward(target_speed, acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func crouch() -> void:
	if Input.is_action_just_pressed("crouch"): 
		crouching = true
		play_animation.rpc("Crouching")
	if Input.is_action_just_released("crouch"): 
		crouching = false
		play_animation.rpc("Crouching", true)

@rpc("authority","call_local")
func walking_sound(delta):
	if currentStepSoundTimer <= 0:
		step_emitter.play()
		currentStepSoundTimer = stepSoundTimer
	else:
		if crouching: 
			currentStepSoundTimer -= delta * crouching_speed_scale
			step_emitter.set_volume_db(-30)
		else: 
			currentStepSoundTimer -= delta
			step_emitter.set_volume_db(0)
	if $floorRayCast3D.is_colliding():
		var floorNode = $floorRayCast3D.get_collider()
		if "SurfaceType" in floorNode:
			if floorMaterial == floorNode.SurfaceType: return
			step_emitter.stream = step_sounds[floorNode.SurfaceType]
			floorMaterial = floorNode.SurfaceType

@rpc("authority","call_local")
func play_animation(animation_name:String, backwards:bool = false):
	if !backwards:
		$AnimationPlayer.play(animation_name)
	else:
		$AnimationPlayer.play_backwards(animation_name)
