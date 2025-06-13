extends State

var crouch_speed_scale : float = 0.5


func _ready() -> void:
	speed *= crouch_speed_scale

func Enter():
	walk_vel = StateMachine.walk_vel
	grav_vel = StateMachine.grav_vel
	play_animation.rpc("Crouching")

func Exit():
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	play_animation.rpc("Crouching", true)

func Update(_delta): # Transition condition is different for each state
	if Input.is_action_just_released("crouch"): 
		Transitioned.emit(self, 'Idle')
	player.velocity = _walk(_delta) + _gravity(_delta) + _jump(_delta)
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel
