extends State


func Enter():
	walk_vel = StateMachine.walk_vel
	grav_vel = StateMachine.grav_vel
	jump_vel = StateMachine.jump_vel

func Exit():
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel

func Physics_Update(_delta): # Transition condition is different for each state
	# Transition to sliding
	player.velocity = _walk(_delta) + _gravity(_delta) + _jump(_delta)
	StateMachine.walk_vel = walk_vel
	StateMachine.grav_vel = grav_vel
	StateMachine.jump_vel = jump_vel

func check_transitions() -> void:
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, 'Jumping')
	if !player.is_on_floor():
		Transitioned.emit(self, 'Jumping')
	
	if Input.is_action_pressed("crouch") and player.velocity.length() > 10: 
		Transitioned.emit(self, 'Sliding')
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") == Vector2.ZERO:
		Transitioned.emit(self, 'Idle')
	if Input.is_action_pressed("crouch"):
		Transitioned.emit(self, 'Crouching')
	if Input.is_action_pressed("sprint"):
		Transitioned.emit(self, 'Sprinting')
