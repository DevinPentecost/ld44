extends Spatial

var offset = 0 #The offset this was created at

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var width = 10

func _get_random_position(margin=0.2):
	
	#Get a value within the width
	var total_width = width - (margin*2)
	var position = rand_range(0, total_width)
	
	#Offset
	position -= width/2
	return Vector3(position, 0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
