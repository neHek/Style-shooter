extends State

#TODO: Adjust acceleration, double jump constants to feel more fluid
#TODO: Fix the speed drop on transition into jump
# Jump only when entering the state
var first_jump : bool = false
var first_wall_jump : bool = false
# How much control do we have mid-flight
@export var jump_control : float = 1
@export var air_friction : float = 0.01
# Vars for coyote time
var coyote_time : float = 0.3 # Seconds
var coyote_time_left : float = 0
var pressed_jump : bool = false

func Enter():
	walk_vel = StateMachine.walk_vel
	grav_vel = StateMachine.grav_vel 
	jump_vel = StateMachine.jump_vel
	first_wall_jump = true
	if Input.is_action_pressed("jump"):
		first_jump = true
		coyote(0)
	else:
		first_jump = false

func Exit():
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel
	coyote_time_left = 0
	pressed_jump = false

func Physics_Update(_delta):
	coyote(_delta)
	player.velocity = _walk(_delta) + _gravity(_delta) + _jump(_delta)
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel

func _walk(delta: float) -> Vector3: 
	move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if move_dir != Vector2.ZERO:
		var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
		var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
		var target_speed = walk_dir * speed * move_dir.length()
		walk_vel = walk_vel.rotated(Vector3.UP, walk_vel.signed_angle_to(target_speed,Vector3.UP) * jump_control * delta)
		if target_speed.length() <= walk_vel.length():
			walk_vel = walk_vel.move_toward(target_speed, acceleration * delta * air_friction*10)
		else:
			walk_vel = walk_vel.move_toward(target_speed, acceleration * delta * air_friction*60)
		if player.is_on_floor(): walk_vel.y = 0
	return walk_vel

func _jump(delta: float) -> Vector3: 
	#$"../../DebugLabel".text = str(player.is_on_floor()) + str(pressed_jump) + str(first_jump)
	if player.is_on_floor() and pressed_jump and first_jump: 
		jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		first_jump = false
		coyote(delta, true)
	else: jump_vel = Vector3.ZERO if player.is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	
	if player.is_on_wall_only() and pressed_jump and first_wall_jump: # Wall jump
		var bounce_direction = Vector3()
		for i in range(0, player.get_slide_collision_count()):
			var collision_point = player.get_slide_collision(i).get_position()
			bounce_direction += ($"../../CollisionShapeStanding".global_position - collision_point)
		
		#bounce_direction.y = 0
		bounce_direction = bounce_direction.normalized()
		jump_vel = bounce_direction * jump_height * Vector3(10, -3, 10)
		first_wall_jump = false
		grav_vel = Vector3.ZERO
		return jump_vel
	
	return jump_vel

func coyote(_delta, reset: bool = false):
	if Input.is_action_just_pressed("jump"):
		pressed_jump = true
		coyote_time_left = coyote_time
	else:
		coyote_time_left -= _delta
	
	if coyote_time_left <= 0 or reset:
		pressed_jump = false
		coyote_time_left = 0

func check_transitions():
	if player.is_on_floor() and !(pressed_jump and first_jump) and !Input.is_action_pressed("sprint"):
		Transitioned.emit(self, 'Walking')
	if player.is_on_floor() and !pressed_jump and Input.is_action_pressed("sprint"):
		Transitioned.emit(self, 'Sprinting')
