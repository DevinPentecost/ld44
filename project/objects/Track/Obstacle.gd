extends Area

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _destroy():
	queue_free()

func _on_Obstacle_body_entered(body):
	
	#Did we hit the player?
	if body.is_in_group("player"):
		#Tell the player that we hit them
		body.hit_obstacle(self)
	
		#We should deactive/DIE
		_destroy()