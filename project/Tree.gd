extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	# We want to move this tree off the road!
	var random = randf() # Value between 0 and 1
	random = random * 10 # Value between 0 and 10
	random = random + 15 # Value between 15 and 25
	if randi() % 11 < 5:
		random = random * (-1)
	
	self.transform.origin += Vector3(random, 0, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
