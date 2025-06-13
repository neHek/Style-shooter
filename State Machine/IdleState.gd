extends State

func Enter():
	walk_vel = StateMachine.walk_vel
	grav_vel = StateMachine.grav_vel
	jump_vel = StateMachine.jump_vel

func Exit():
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel

func Physics_Update(_delta):
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		Transitioned.emit(self, 'Walking')
	if Input.is_action_pressed("crouch"):
		Transitioned.emit(self, 'Crouching')
	player.velocity = _walk(_delta) + _gravity(_delta) + _jump(_delta)
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel
