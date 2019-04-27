extends Position3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var original_basis

# Called when the node enters the scene tree for the first time.
func _ready():
	original_basis = self.transform.basis

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_TrackFollower_position_update(new_transform):
	var new_rotation = new_transform.basis.get_euler()
	self.transform.basis = original_basis.rotated(Vector3(0,1,0), (-1) * new_rotation[1])
