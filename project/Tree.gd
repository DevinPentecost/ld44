extends Spatial

#The offset this tree was made at
var offset = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# We want to move this tree off the road!
	var random = randf() # Value between 0 and 1
	random = random * 20 # Value between 0 and 20
	random = random + 15 # Value between 15 and345
	if randi() % 11 < 5:
		random = random * (-1)
	
	self.transform.origin += Vector3(random, 0, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
