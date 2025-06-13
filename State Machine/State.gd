extends Node
class_name State
signal Transitioned
@onready var StateMachine = get_parent()
@onready var player : CharacterBody3D = StateMachine.get_parent()
@onready var jump_height: float = StateMachine.jump_height # m
@onready var speed: float = StateMachine.speed # m/s
@onready var acceleration: float = StateMachine.acceleration  # m/s^2
@onready var gravity: float = StateMachine.gravity # m/s^2
@onready var walk_friction: float = StateMachine.walk_friction  # m/s^2
@onready var gravity_friction: float = StateMachine.gravity_friction # m/s^2
@onready var jump_friction: float = StateMachine.jump_friction # m/s^2
var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity
var move_dir: Vector2 # Input direction for movement
@onready var camera: Camera3D = $"../../Anchor/Camera"

func Enter():
	pass

func Exit():
	pass

func Update(_delta):
	pass

func Physics_Update(_delta):
	pass

func _jump(delta: float) -> Vector3:
	jump_vel = Vector3.ZERO if player.is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if player.is_on_floor() else grav_vel.move_toward(Vector3(0, player.velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	var target_speed = walk_dir * speed * move_dir.length()
	if target_speed.length() < 1:
		walk_vel = walk_vel.move_toward(target_speed, walk_friction * delta)
	else:
		walk_vel = walk_vel.move_toward(target_speed, acceleration * delta)
	return walk_vel

@rpc("authority","call_local")
func play_animation(animation_name:String, backwards:bool = false):
	if !backwards:
		$"../../AnimationPlayer".play(animation_name)
	else:
		$"../../AnimationPlayer".play_backwards(animation_name)

func check_transitions() -> void:
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, 'Jumping')
	if !player.is_on_floor():
		Transitioned.emit(self, 'Jumping')
