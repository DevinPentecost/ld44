extends Area


class PedestrianSpawn:
	var track_segment =  0
	var start_position = 0.5
	var move_speed = -5
	var health_change = -15
	var speed_change = -7
	var is_powerup = false



#These should be set by the map generator
#An item is just a non-moving pedestrian
var active = false
var active_distance_squared = 9500 #Within this distance (squared) the pedestrian will activate
var move_speed = 10
var health_change = 10 #Make this positive to gain health for powerups
var speed_change = -7
var is_powerup = false #Whether to treat it as a generic pickup or actual pedestrian

func apply_pedestrian_spawn(pedestrian_spawn):
	#Set some params up
	move_speed = pedestrian_spawn.move_speed
	health_change = pedestrian_spawn.health_change
	speed_change = pedestrian_spawn.speed_change
	is_powerup = pedestrian_spawn.is_powerup
	
	#Adjust position, we should already be relative to parent
	var start_x = (pedestrian_spawn.start_position - 1) * 5
	transform.origin.x = start_x
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
	
	#Should we activate?
	if not active:
		#Check distance to player
		var player = get_tree().get_nodes_in_group("player")[0]
		var player_location = player.global_transform.origin
		var location = global_transform.origin
		var distance_squared = location.distance_squared_to(player_location)
		if distance_squared < active_distance_squared:
			#We can go
			active = true
		return
	
	#Move according to our speed
	var speed = move_speed * delta
	var movement = Vector3(speed, 0, 0)
	transform.origin += movement
	
func _destroy():
	
	#Play an animation or something
	queue_free()
	pass

func _on_Pedestrian_body_entered(body):
	
	#Did we hit the player?
	if body.is_in_group("player"):
		#We behave accordingly
		
		#Player got HIT
		body.hit_pedestrian(self)
		
		#Act accordingly
		_destroy()
		pass
	pass # Replace with function body.
