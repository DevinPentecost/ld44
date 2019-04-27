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

var movement_state = MovementState.new()

class CollisionState:
	var shoulder = false
	var wall = false
	
	var obstacle_speed #How much to slow down to if you hit an obstacle (instant)
	
	var wall_speed_adjust = -7 #How slow to go when hitting the wall
	var wall_acceleration = 8 #How quickly to slow down when hitting the wall
	
	var shoulder_speed_adjust = -4 #Speed is reduced by this much on the shoulder
	
	func is_colliding_shoulder():
		return shoulder and not wall

var collision_state = CollisionState.new()


#Turning speeds
var turn_speed = 10 #Left and right movement per second normally
var turn_boost_speed = 6
var turn_brake_speed = 3
var current_turn_speed = 0

#Forward speed things
var current_speed = 1
var current_acceleration = 0
var target_speed = 0


var max_speed = 10
var min_speed = 1
var acceleration = 4

var max_speed_boost = 15
var acceleration_boost = 5

var speed_brake = 3
var acceleration_brake = -9


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Handle keyboard input
	set_process_unhandled_key_input(true)
	
	#Process every frame as well
	#set_process(true)
	set_physics_process(true)

func connect_to_terrain_areas(shoulders, walls):
	#Each shoulder needs to connect it's body entered function to call our callback
	for shoulder in shoulders:
		shoulder.connect("body_entered", self, "_on_shoulder_body_entered")
		shoulder.connect("body_exited", self, "_on_shoulder_body_exited")
	
	#Each shoulder needs to connect it's body entered function to call our callback
	for wall in walls:
		wall.connect("body_entered", self, "_on_wall_body_entered")
		wall.connect("body_exited", self, "_on_wall_body_exited")
	
func _physics_process(delta):
	
	#Are we moving?
	_process_movement_turn(delta)
	
	#Are we speeding?
	_process_movement_forward(delta)

func _process_movement_forward(delta):
	
	#Are we boosting or braking?
	if movement_state.is_braking():
		#We need to start slowing down
		target_speed = speed_brake
		current_acceleration = acceleration_brake
		
	elif movement_state.is_boosting():
		#We start speeding up!
		target_speed = max_speed_boost
		current_acceleration = acceleration_boost
	
	else:
		#Regular movemement
		target_speed = max_speed
		current_acceleration = acceleration
		
	
	#Are we hitting a wall?
	if collision_state.wall:
		#Slow way down!
		target_speed += collision_state.wall_speed_adjust
		target_speed = max(target_speed, min_speed)
		current_acceleration = collision_state.wall_acceleration
	
	#If we are hitting the shoulder, slow down a bit
	if collision_state.is_colliding_shoulder():
		target_speed += collision_state.shoulder_speed_adjust
		target_speed = max(target_speed, min_speed)
	
	#Are we going too fast?
	if current_speed > target_speed:
		current_acceleration = -abs(acceleration)
	
	#Increment our velocity according to our acceleration (adjusted by frame delta)
	var velocity_change = current_acceleration * delta
	current_speed += velocity_change
	
	#We can't go past our target
	if current_acceleration > 0:
		#We are speeding up
		if current_speed > target_speed:
			current_speed = target_speed
			
	elif current_acceleration < 0:
		#We are slowing down
		if current_speed < target_speed:
			current_speed = target_speed
			
	#Make sure we don't accidentally go too slow
	current_speed = max(current_speed, min_speed)
	
func _process_movement_turn(delta):
	
	#Which direction to move?
	var movement_direction = movement_state.get_movement_direction()
	
	#Determine current turning speed based on brake/boost
	var turning_speed = turn_speed
	if movement_state.is_braking():
		turning_speed = turn_brake_speed
	elif movement_state.is_boosting():
		turning_speed = turn_boost_speed
		
	
	current_turn_speed = turning_speed * movement_direction
	
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

func _on_shoulder_body_entered(body):
	#Check we're the one who is affected
	if body == self:
		collision_state.shoulder = true
		

func _on_shoulder_body_exited(body):
	#Check if we're the one who is affected
	if body == self:
		collision_state.shoulder = false

func _on_wall_body_entered(body):
	#Check we're the one who is affected
	if body == self:
		collision_state.wall = true
		

func _on_wall_body_exited(body):
	#Check if we're the one who is affected
	if body == self:
		collision_state.wall = false