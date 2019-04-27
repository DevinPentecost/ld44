extends KinematicBody

signal player_died
signal player_force_brake(start)

#What is the current movement state
class MovementState:
	var boost = false
	var brake = false
	var force_brake = false
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
		return boost and not (brake or force_brake)
	func is_braking():
		#You can always brake
		return brake or force_brake

var movement_state = MovementState.new()

class CollisionState:
	var shoulder = false
	var wall = false
	
	var obstacle_speed = 1 #How much to slow down to if you hit an obstacle (instant)
	var obstacle_health_damage = 10 #How much health is lost per obstacle
	
	var wall_health_loss = 15 #How much health to lose per second when hitting the wall
	var wall_speed_adjust = -7 #How slow to go when hitting the wall
	var wall_acceleration = 8 #How quickly to slow down when hitting the wall
	
	var shoulder_health_loss = 7 #How much health we lose in the shoulder per second
	var shoulder_speed_adjust = -4 #Speed is reduced by this much on the shoulder
	
	func is_colliding_shoulder():
		return shoulder and not wall

var collision_state = CollisionState.new()

#Player health
var is_alive = true
var max_health = 100
var current_health = max_health
var health_loss =  3.5 #Health loss per second


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

#Boost stuff
var max_speed_boost = 15
var acceleration_boost = 5
var health_loss_boost = 4.5 #Health loss per second

#Brake stuff
var speed_brake = 3
var acceleration_brake = -9
var health_loss_brake = -15 #Health recovered per second

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
	
	#Do we have to force being braked?
	
	#Are we moving?
	_process_movement_turn(delta)
	
	#Are we speeding?
	_process_movement_forward(delta)
	
	#Handle health effects
	_process_health(delta)

func _process_movement_forward(delta):
	if not is_alive:
		return
	
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
	if not is_alive:
		return
	
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

func _process_health(delta):
	if not is_alive:
		return
	
	#How much health to lose?
	var health_to_lose = health_loss
	
	#Are we boosting?
	if movement_state.is_boosting():
		health_to_lose = health_loss_boost
	elif movement_state.is_braking():
		health_to_lose = health_loss_brake
		
	#Adjust for being in the shoulder
	if collision_state.wall:
		health_to_lose = collision_state.wall_health_loss
	elif collision_state.is_colliding_shoulder():
		health_to_lose = collision_state.shoulder_health_loss
	
	#Adjust for the frame rate
	health_to_lose *= delta
	
	#Lose the health
	current_health -= health_to_lose
	
	#Can't go over max
	if current_health >= max_health:
		current_health = min(current_health, max_health)
		movement_state.force_brake = false
		emit_signal("player_force_brake", false)
		
	#Did we go under?
	if current_health < 0:
		
		#emit_signal("player_died")
		#is_alive = false
		
		movement_state.force_brake = true
		emit_signal("player_force_brake", true)
		
		#TODO: Do player dead stuff

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

func hit_obstacle(obstacle):
	
	#We need to slow down!
	current_speed = collision_state.obstacle_speed
	
	#Handle being hit (lose health)
	current_health -= collision_state.obstacle_health_damage
	
	#Play an animation for getting hit or something
	#TODO: MAKE IT HAPPEN!

func hit_pedestrian(pedestrian):
	
	#Was this a good pedestrian or bad?
	var is_good = pedestrian.health_loss <= 0 and pedestrian.speed_loss <= 0
	
	#Take the health hit
	current_health -= pedestrian.health_loss
	
	#Slow down if it was bad
	current_speed -= pedestrian.speed_loss
	
	#TODO: Animate if it was bad or good or whatever

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