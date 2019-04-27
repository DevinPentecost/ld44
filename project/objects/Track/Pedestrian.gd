extends Area

#These should be set by the map generator
#An item is just a non-moving pedestrian
var move_left = true
var move_speed = 10
var health_loss = 10 #Make this positive to gain health for powerups
var speed_loss = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
	
	#Move this guy
	var speed = move_speed
	if not move_left:
		speed = -speed
	var movement = Vector3(speed, 0, 0)
	
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
