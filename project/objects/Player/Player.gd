extends KinematicBody

const BloodParticle = preload("res://objects/Player/BloodParticle/BloodParticle.tscn")

signal player_died
signal player_force_brake(start)

#Grab nodes
onready var _idle_engine_player = $IdleEngine
onready var _boost_engine_player = $BoostEngine
onready var _skid_sound_player = $Skid
onready var _scrape_player = $ScrapePlayer
onready var _smoke_particles = $SmokeParticles
onready var _brake_timer = $BrakeTimer
onready var player_anim = 	$CarModel/PlayerModel/AnimationPlayer

onready var start_transform = $CarModel.transform

#What is the current movement state
class MovementState:
	var boost = false
	var brake = false
	var force_brake = false
	var left = false
	var right = false
	
	#When the track turns, the player also slides
	var slide = 0 #The amount to slide the player (negative is left)
	var bump = 0 # The amount to bump left or right
	
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

var is_paused = false

#Player health
var is_alive = true
var max_health = 100
var current_health = max_health
var health_loss =  3.5 #Health loss per second


#Turning speeds
var turn_speed = 15 #Left and right movement per second normally
var turn_boost_speed = 10
var turn_brake_speed = 18
var current_turn_speed = 0

#Forward speed things
var current_speed = 1
var current_acceleration = 0
var target_speed = 0

var max_speed = 13
var min_speed = 3
var acceleration = 4

#Boost stuff
var max_speed_boost = 15
var acceleration_boost = 5
var health_loss_boost = 4.5 #Health loss per second

#Brake stuff
var speed_brake = 3
var acceleration_brake = -12
var health_loss_brake = -15 #Health recovered per second

#SFX
var min_idle_pitch = 0.9
var max_idle_pitch = 1.4
var max_idle_pitch_speed = 15

var road_pitch_normal = 2
var road_db_normal = 10
var road_pitch_shoulder = 0.5
var road_db_shoulder = 15
var road_tween_time = 0.25

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Handle keyboard input
	set_process_unhandled_key_input(true)
	
	#Process every frame as well
	#set_process(true)
	set_physics_process(true)
	
	#Turn on the engine
	_idle_engine_player.playing = true

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
	
	#Handle engine sounds
	_process_engine_sfx(delta)
	
	#Handle particles
	_process_particles(delta)
	
	#Handle the brake timer
	_process_brake_timer(delta)

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
	current_speed = float(current_speed)
	
func _process_movement_turn(delta):
	if not is_alive:
		return
	
	#Which direction to move?
	var movement_direction = movement_state.get_movement_direction()
	var is_braking = movement_state.is_braking()
	var is_boosting = movement_state.is_boosting()
		
	if movement_direction > 0:
		player_anim.play("armature|armature|steer.R|armature|steer.R")
	elif movement_direction < 0:
		player_anim.play("armature|armature|steer.L|armature|steer.L")
	elif is_braking:
		player_anim.play("armature|armature|drawblood|armature|drawblood")
	elif is_boosting:
		player_anim.play("armature|armature|boost|armature|boost")
	else:
		player_anim.play("armature|armature|braking|armature|braking")
	
	#Determine current turning speed based on brake/boost
	var turning_speed = turn_speed
	if movement_state.is_braking():
		turning_speed = turn_brake_speed
	elif movement_state.is_boosting():
		turning_speed = turn_boost_speed
	
	#turning_speed *= current_speed
	
	if abs(movement_state.bump) > 7:
		turning_speed *= 0.5
	
	#Calculate turn movement
	current_turn_speed = turning_speed * movement_direction
	
	#Adjust for slide
	current_turn_speed += movement_state.slide
	
	# Adjust for any bumping
	current_turn_speed += movement_state.bump
	movement_state.bump -= ((movement_state.bump * 0.7) * delta)
	
	
	#Adjust based on frame delta
	var final_turn_speed = current_turn_speed * delta
	
	#Make a vector
	var movement_vector = Vector3(final_turn_speed, 0, 0)
	
	$CarModel.transform = start_transform.rotated(Vector3(0,1,0), (-1)*movement_vector.x)
	
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
		print(current_health)
		current_health = 0
		#emit_signal("player_died")
		#is_alive = false
		
		movement_state.force_brake = true
		emit_signal("player_force_brake", true)
		
		#TODO: Do player dead stuff

func _process_engine_sfx(delta):
	
	#Change idle pitch based on speed
	var idle_pitch_weight = current_speed/max_idle_pitch_speed
	var idle_pitch = lerp(min_idle_pitch, max_idle_pitch, idle_pitch_weight)
	_idle_engine_player.pitch_scale = idle_pitch
	
	#Are we boosting?
	if _boost_engine_player.playing:
		if not movement_state.is_boosting():
			_boost_engine_player.playing = false
	else:
		if movement_state.is_boosting():
			_boost_engine_player.playing = true

func _process_particles(delta):
	
	#Smoke speed depends on player speed
	_smoke_particles.initial_velocity = current_speed

func _process_brake_timer(delta):
	
	#Is the timer currently running
	if _brake_timer.is_stopped():
		#Restart it if braking
		if movement_state.is_braking():
			_brake_timer.start()
	else:
		#Are we no longer braking?
		if not movement_state.is_braking():
			_brake_timer.stop()

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
		#player_anim.play("armature|armature|braking|armature|braking")
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

func hit_pickup(pickup):
	
	#Spawn a bunch of blood (GROSSSSSS)
	var count = 7
	count += randi() % 6
	_spawn_blood(count)
	
	#Play a pickup sound
	
	#Gain some health
	current_health += pickup.health_value

func hit_pedestrian(pedestrian):
	
	#Was this a good pedestrian or bad?
	var is_good = pedestrian.health_change <= 0 and pedestrian.speed_change <= 0
	
	#Take the health hit
	current_health += pedestrian.health_change
	
	#Slow down if it was bad
	current_speed += pedestrian.speed_change
	
	#TODO: Animate if it was bad or good or whatever

func hit_shoulder(shoulder, enter):
	#Change state accordingly
	collision_state.shoulder = enter
	
	#Set up the SFX to match
	var target_db = road_db_normal
	var target_pitch = road_pitch_normal
	if enter:
		target_db = road_db_shoulder
		target_pitch = road_pitch_shoulder
		
	$Tween.interpolate_property($RoadSound, "unit_db", $RoadSound.unit_db, target_db, road_tween_time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.interpolate_property($RoadSound, "pitch_scale", $RoadSound.pitch_scale, target_pitch, road_tween_time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()

func hit_wall(wall, enter):
	#Change state accordingly
	collision_state.wall = enter
	
	#Make sparks?
	if enter:
		var side = 0.8
		if wall.global_transform.origin.x < global_transform.origin.x:
			side = -side
		$SparkParticles.transform.origin.x = side
	$SparkParticles.emitting = enter
	
	#Check the SFX too
	_scrape_player.playing = enter

func hit_opponent(oppo, enter):
	#Make sparks?
	if enter:
		var side = 0.8
		if oppo.global_transform.origin.x < global_transform.origin.x:
			side = -side
		$SparkParticles.transform.origin.x = side
		oppo.bump(3 * side)
		movement_state.bump = -15 * side
	$SparkParticles.emitting = enter
	
	#Check the SFX too
	_scrape_player.playing = enter

func _on_TrackFollower_turning(turn_amount):
	
	var slideMultiplier = 8
	#Slide the player that much
	if movement_state.is_braking():
		slideMultiplier = 5
	elif movement_state.is_boosting():
		slideMultiplier = 10
	movement_state.slide = turn_amount * (-150) * slideMultiplier
	
	if _skid_sound_player.playing:
		pass
		#if abs(movement_state.slide) <= 5:
		#	_skid_sound_player.playing = false
	else:
		if abs(movement_state.slide) > 8:
			_skid_sound_player.playing = true
	


func _on_BrakeTimer_timeout():
	
	#The brake timer needs to keep going
	_brake_timer.start()
	
	_spawn_blood()

func _spawn_blood(amount=1):
	
	#Make 'em!
	for blood in range(amount):
		
		#Spawn a new blood boy
		var blood_particle = BloodParticle.instance()
		add_child(blood_particle)