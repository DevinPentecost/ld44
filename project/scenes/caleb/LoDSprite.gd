extends Sprite3D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(NodePath) var reference
export(Texture) var tex_furthest
export(Texture) var tex_lod0
export(Texture) var tex_lod1
export(Texture) var tex_closest

export(float) var lod0_start = 100
export(float) var lod1_start = 60
export(float) var closest_start = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var targetNode = get_node(reference)
	# Get the distance from this node and the reference node
	var targetLocation = targetNode.get_global_transform().origin
	var selfLoacation = self.get_global_transform().origin
	var distance = selfLoacation.distance_squared_to(targetLocation)
	
	# What distance bucket are we in?
	if (distance < (closest_start * closest_start)):
		# Switch to closest texture
		self.texture = tex_closest
	elif (distance < (lod1_start * lod1_start)):
		self.texture = tex_lod1
	elif (distance < (lod0_start * lod0_start)):
		self.texture = tex_lod0
	else:
		self.texture = tex_furthest
	
	look_at(targetLocation, Vector3(0,1,0))