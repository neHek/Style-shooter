extends State
#TODO: Fine-tune the friction
#TODO: Align the player model with the floor's normal
#PRIORITY: Implement sliding at an angle

func _ready() -> void:
	walk_friction = 5

func Enter():
	walk_vel = StateMachine.walk_vel
	grav_vel = StateMachine.grav_vel
	play_animation.rpc('Sliding', false)

func Exit():
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	play_animation.rpc('Sliding', true)

func Update(_delta): # Transition condition is different for each state
	if player.velocity.length() <= 1 or Input.is_action_just_released("crouch"): # Length in m/s? 
		Transitioned.emit(self, 'Walking')
	player.velocity = _walk(_delta) + _gravity(_delta) + _jump(_delta)
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel
