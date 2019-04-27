extends KinematicBody

#What is the current movement state
class MovementState:
	var boost = false
	var brake = false
	var left = false
	var right = false
	
	func get_movement_direction():
		"""
		Determines the direction the player is trying to move
		-1 = left
		0 = neither
		1 = right
		"""
		var move_direction = 0
		if left and not right:
			move_direction = -1
		elif right and not left:
			move_direction = 1
		return move_direction
		
	func is_boosting():
		#Can't boost if you're using the brake
		return boost and not brake
	func is_braking():
		#You can always brake
		return brake
		

#The player's movement state object
var movement_state = MovementState.new()

#Turning speeds
var turn_speed = 10 #Left and right movement per second normally
var turn_boost_speed = 6
var turn_brake_speed = 3

#Forward speed things
var max_speed = 10
var acceleration = 3
var max_speed_boost = 15
var boost_acceleration = 5
var brake_speed = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Handle keyboard input
	set_process_unhandled_key_input(true)
	
	#Process every frame as well
	set_process(true)
	
func _process(delta):
	#Are we moving?
	_process_movement(delta)
	
func _process_movement(delta):
	
	#Which direction to move?
	var movement_direction = movement_state.get_movement_direction()
	
	#Determine current turning speed based on brake/boost
	var turning_speed = turn_speed
	if movement_state.is_braking():
		turning_speed = turn_brake_speed
	elif movement_state.is_boosting():
		turning_speed = turn_boost_speed
	
	var movement_vector = Vector3(turning_speed, 0, 0) * movement_direction
	
	#Adjust based on frame delta
	movement_vector = movement_vector * delta
	
	#Move the player left and right accordingly
	move_and_collide(movement_vector)
	
func _unhandled_key_input(event):
	
	#We respond to various movement commands
	if event.is_action_pressed("move_left"):
		movement_state.left = true
	elif event.is_action_released("move_left"):
		movement_state.left = false
	elif event.is_action_pressed("move_right"):
		movement_state.right = true
	elif event.is_action_released("move_right"):
		movement_state.right = false
	elif event.is_action_pressed("boost"):
		movement_state.boost = true
	elif event.is_action_released("boost"):
		movement_state.boost = false
	elif event.is_action_pressed("brake"):
		movement_state.brake = true
	elif event.is_action_released("brake"):
		movement_state.brake = false
	