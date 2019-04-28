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
	#rotate_y(original_transform.basis.get_euler()[1] - new_transform.basis.get_euler()[1])
	#rotate_y(PI)
	#var newBasis = self.transform.basis
	#newBasis = Basis(Vectoy3(0,1,0), PI) * new_transform.basis
	#var new_rotation = new_transform.basis.get_euler()
	var degrees = deg2rad(new_transform.basis.get_euler()[1])
	degrees = new_transform.basis.get_euler()[1]
	self.transform = original_transform.rotated(Vector3(0, 1, 0), (-1) * degrees)
	pass