extends Position3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var original_transform
var children_original_transforms = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	original_transform = self.transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_TrackFollower_position_update(new_transform):
	# First, adjust the origin of every child node to compensate for movement
	for node in get_children():
		if children_original_transforms.has(node) == false:
			children_original_transforms[node] = node.transform
		
		node.transform.origin = children_original_transforms[node].origin - new_transform.origin
	
	# Now rotate the whole set
	var new_rotation = new_transform.basis.get_euler()
	self.transform.basis = original_transform.basis.rotated(Vector3(0,1,0), (-1) * new_rotation[1])
