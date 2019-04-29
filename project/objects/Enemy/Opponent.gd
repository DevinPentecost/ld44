extends StaticBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var horizontal_movement = 0
onready var vertical_movement = 0
onready var stunned = 0
onready var health_value = 15
var player = null
var spin = 0
var spin_speed = 10

onready var _player_anim = $Enemy/Car/Enemy/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _calculate_new_horizontal_movement(factor):
	var distance_from_center = self.transform.origin.x
	if abs(distance_from_center) > 0.3:
		# Too far away! Adjust movement to get closer
		if distance_from_center < 0:
			return 5 * factor
		else:
			return -5 * factor
		
	return 0
	
func _calculate_new_vertical_movement(factor):
	var distance_from_center = self.transform.origin.z
	if abs(distance_from_center) > 0.1:
		# Too far away! Adjust movement to get closer
		if distance_from_center < 0:
			return 5 * factor
		else:
			return -5 * factor
		
	return 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.transform.origin += Vector3(horizontal_movement * delta, 0, vertical_movement * delta)
	
	# Try and slide closer to the center
	if stunned < 0:
		horizontal_movement += _calculate_new_horizontal_movement(delta)
	else:
		stunned -= delta
	
	vertical_movement += _calculate_new_vertical_movement(delta)
	
	if spin != 0:
		rotate_y(spin_speed * delta)
		_player_anim.play("armature|armature|hit|armature|hit")
		vertical_movement = 10
	else:
		#Moving far left or right?
		if abs(horizontal_movement) > 5:
			if sign(horizontal_movement) > 0:
				_player_anim.play("armature|armature|steer.R|armature|steer.R")
			else:
				_player_anim.play("armature|armature|steer.L|armature|steer.L")
		else:
			if sign(vertical_movement) > 0:
				_player_anim.play("armature|armature|braking|armature|braking")
			else:
				_player_anim.play("armature|armature|boost|armature|boost")

func bump(magnitude):
	if sign(horizontal_movement) == sign(magnitude):
		horizontal_movement += magnitude
	else:
		horizontal_movement = magnitude
		
	stunned = 0.5

func _on_Announcer_finished():
	get_parent().remove_child(self)

func _on_PlayerColllider_body_entered(body):
	if body.is_in_group("player"):
		body.hit_opponent(self, true)


func _on_PlayerColllider_body_exited(body):
	if body.is_in_group("player"):
		body.hit_opponent(self, false)

func _burnout(announce=true):
	
	#Can't hit the wall any more
	remove_child($WallCollider)
	
	$Crash.playing = true
	
	if announce:
		$Announcer.playing = true
	
	#Animate it too
	spin = randi() % 2
	if not spin:
		spin = -1
		
	#Die after a bit
	var timer = Timer.new()
	add_child(timer)
	timer.start(3)
	yield(timer, "timeout")
	
	#We can now go away
	queue_free()

func _on_WallCollider_body_entered(body):
	if body.is_in_group("wall"):
		
		#Spin away
		_burnout()
		player.hit_pickup(self)
		
		

func _on_TrackFollower_track_completed():
	
	#If you ain't winnin, ya losin
	_burnout(false)
