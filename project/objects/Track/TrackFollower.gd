extends Position3D

var PedestrianSpawn = preload("res://objects/Track/Pedestrian.gd").PedestrianSpawn
var PedestrianScene = preload("res://objects/Track/Pedestrian.tscn")

onready var nodescene = preload("res://objects/Track/Debug/RedNode.tscn")
onready var blueScene = preload("res://objects/Track/Debug/BlueNode.tscn")
onready var purpScene = preload("res://objects/Track/Debug/PurpleNode.tscn")
onready var roadscene = preload("res://objects/Track/Road.tscn")
onready var treescene = preload("res://scenes/caleb/Tree.tscn")
onready var dirtscene = preload("res://scenes/caleb/Dirt.tscn")

onready var trackDefinition = _generateTrackLayout()
onready var nodes = []
onready var trackDemo = nodescene.instance()

signal position_update(new_transform)
signal turning(turn_amount)

export var speed = 30

onready var pathNode = $trackPath/PathFollow
onready var _follow_track = $FollowTrack




# Produces a track layout, which is an object.
# The layout has a dictionary of information
# as well as a big list of track nodes
func _generateTrackLayout():
	var track = {}
	
	var trackDefinition = []
	#trackDefinition.append([100,0])
	#trackDefinition.append([100,20])
	#trackDefinition.append([100,40])
	#trackDefinition.append([100,60])
	#trackDefinition.append([100,80])
	#trackDefinition.append([100,100])
	#trackDefinition.append([100,120])
	#trackDefinition.append([100,140])
	#trackDefinition.append([100,160])
	#trackDefinition.append([100,180])
	#trackDefinition.append([100,200])
	#trackDefinition.append([100,220])
	#trackDefinition.append([100,240])
	#trackDefinition.append([100,260])
	#trackDefinition.append([100,280])
	#trackDefinition.append([100,300])
	#trackDefinition.append([100,320])
	#trackDefinition.append([100,340])
	#trackDefinition.append([100,360])
	trackDefinition.append([100,0])
	trackDefinition.append([100,45])
	trackDefinition.append([100,0])
	trackDefinition.append([100,10])
	trackDefinition.append([100,350])
	trackDefinition.append([100,300])
	trackDefinition.append([100,0])
	trackDefinition.append([100,15])
	trackDefinition.append([100,5])
	trackDefinition.append([100,355])
	trackDefinition.append([100,285])
	trackDefinition.append([100,345])
	trackDefinition.append([75,20])
	trackDefinition.append([75,340])
	trackDefinition.append([100,0])
	track["layout"] = trackDefinition
	
	# Count the "length" of the track
	var length = 0
	for segment in track["layout"]:
		length += segment[0]
	track["length"] = length
	
	# Also generate obstacles that will go into this track
	# [0] will be the location of the obstacle in track length
	# [1] will be the obstacle scene to place into the track
	track["obstacles"] = _generateObstacles(length)
	
	#Get the pedestrian objects for this course
	track['pedestrians'] = _generate_pedestrians(length)
	
	# Give this dictionary to the caller
	return track

# Produces obstacles to fit within the given track length
func _generateObstacles(length):
	var obstacleList = []
	# Whats a good way to do this...
	# Basically, we will spawn an obstacle for every ? units
	# The obstacle type will have even distribution
	# Obstacles will get more dense as the track goes on?
	
	var numObstacles = length / 50
	var obstaclesToPlace = []
	
	# Spawn a bucket of obstacles
	var numToSpawm = 0
	while numToSpawm < numObstacles:
		obstaclesToPlace.append(nodescene.instance())
		obstaclesToPlace.append(blueScene.instance())
		obstaclesToPlace.append(purpScene.instance())
		#var sprite = spritescene.instance()
		#sprite.reference = get_parent().get_node("Camera").get_path()
		#sprite.tex_closest = load("res://assets/closestLod.png")
		#sprite.tex_lod0 = load("res://assets/lod0.png")
		#sprite.tex_lod1 = load("res://assets/lod1.png")
		#sprite.tex_furthest = load("res://assets/furthestLod.png")
		#obstaclesToPlace.append(sprite)
		numToSpawm += 3
	
	# Lets figure out where to put these
	# TODO: Just doing even distribution for now
	var averageDistribution = length / numObstacles
	for dist in range(0, numObstacles):
		obstaclesToPlace.shuffle()
		obstacleList.append([dist * averageDistribution, obstaclesToPlace.pop_back()])
	
	return obstacleList

func _generate_pedestrians(length):
	
	var pedestrians = []
	
	#Generate some number of bad pedestrians (non-blood-bearing)
	pass
	
	#Generate some number of good pedestrians (blood-bearing)
	var good_pedestrian = PedestrianSpawn.new()
	good_pedestrian.track_segment = 50
	good_pedestrian.health_change = 35
	good_pedestrian.move_speed = 4
	good_pedestrian.start_position = 0
	pedestrians.append(good_pedestrian)
	
	#Generate some number of powerups (blood but no impact)
	pass
	
	return pedestrians

# Called when the node enters the scene tree for the first time.
func _ready():
	var trackCurve = Curve3D.new()
	var currentNode = 0
	
	# Instance a new scene and give it the same start point as the track follower/generator
	var newNode = nodescene.instance()
	newNode.transform.origin = self.transform.origin
	
	# Append to associated lists
	nodes.append(newNode)
	trackCurve.add_point(newNode.transform.origin)
	add_child(newNode)
	
	# Create a collection of node objects to represent the layout
	for segment in self.trackDefinition["layout"]:
		# Move to the next node
		currentNode += 1
		
		# We want to start with the same origin point as the previous node
		var oldOrigin = nodes[currentNode - 1].transform.origin
		var newOrigin = oldOrigin
		
		# We know the hypoteneuse and the angle -- lets determine the other angles
		
		var radians = deg2rad(segment[1])
		var dim1ToAdd = sin(radians) * segment[0]
		var dim2ToAdd = cos(radians) * segment[0]
		var addedAmount = Vector3(dim1ToAdd, 0, (-1) * dim2ToAdd)
		newOrigin = newOrigin + addedAmount
		
		# Thats all we need to determine the new node position
		# Lets also determine the bezier curve out
		# Take our current vector and multiply it -- that will be out out vector
		var oldInVector = (-0.50 * addedAmount)
		var newOutVector = (0.50 * addedAmount)
		
		# Create a new node and give it the same position as the old node
		newNode = nodescene.instance()
		newNode.transform.origin = newOrigin
		
		# Apply this node to the scene
		nodes.append(newNode)
		add_child(newNode)
		
		# My new node's curve input should be a continuation of my current angle!
		trackCurve.add_point(newNode.transform.origin, (-1) * newOutVector, newOutVector)
		
		# The previous node's curve input is also a form of continuation of my current angle
		var index_of_previous = trackCurve.get_point_count() - 1
		trackCurve.set_point_in(index_of_previous, oldInVector)
		
	
	# Generate a path from this curve
	self.get_node("trackPath").set_curve(trackCurve)
	self.get_node("trackPath/PathFollow").add_child(trackDemo)
	self.get_node("trackPath/PathFollow").set_offset(0)
	
	# Create "road" scenes througought the path
	var pathNode = self.get_node("trackPath/PathFollow")
	var unitoffset = pathNode.get_unit_offset()
	while (unitoffset) < 1:
		# Create a road scene and add
		var roadPiece = roadscene.instance()
		roadPiece.transform = pathNode.transform
		_follow_track.add_child(roadPiece)
		
		var currentOffset = pathNode.get_offset()
		pathNode.set_offset(currentOffset + 2.25)
		unitoffset = pathNode.get_unit_offset()
		
		# There's always a chance of having a dirt clod or tree
		var dirtHappened = randf() * 100
		if dirtHappened < 5:
			var dirt = dirtscene.instance()
			var sprite = dirt.get_node("LoDSprite")
			sprite.reference = get_parent().get_node("Camera").get_path()
			roadPiece.add_child(dirt)
		
		var treeHappened = randf() * 100
		if treeHappened < 10:
			var tree = treescene.instance()
			var sprite = tree.get_node("LoDSprite")
			sprite.reference = get_parent().get_node("Camera").get_path()
			roadPiece.add_child(tree)
		
		# Add any baddies supposed to be here?
		var baddiesToAdd = [] # list of array indices
		for currObstacle in self.trackDefinition["obstacles"]:
			if currObstacle[0] <= currentOffset:
				# Add this baddy to the road segment
				baddiesToAdd.append(self.trackDefinition["obstacles"].find(currObstacle))
		
		
		
		# Start popping from the list!
		var baddiesPopped = 0
		for baddie in baddiesToAdd:
			var element = self.trackDefinition["obstacles"][baddie - baddiesPopped]
			self.trackDefinition["obstacles"].remove(baddie - baddiesPopped)
			baddiesPopped += 1
			
			var obstacleScene = element[1]
			obstacleScene.transform.origin = Vector3(0, 0.25, 0)
			obstacleScene.show()
			roadPiece.add_child(obstacleScene)
			
	
	#Go through each pedestrian
	var all_track_nodes = _follow_track.get_children()
	for pedestrian_spawn in trackDefinition['pedestrians']:
		
		#Make a new pedestrian
		var new_pedestrian = PedestrianScene.instance()
		
		#Apply variables from the spawn
		new_pedestrian.apply_pedestrian_spawn(pedestrian_spawn)
		
		#Give it to the correct node
		var track_node = all_track_nodes[pedestrian_spawn.track_segment]
		track_node.add_child(new_pedestrian)
	
	# Reset the path
	self.get_node("trackPath/PathFollow").set_offset(0)
	
var old_rotation = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var currentOffset = pathNode.get_offset()
	var speed_adjust = 10 + speed * 4
	pathNode.set_offset(currentOffset + (delta * speed_adjust))
	emit_signal("position_update", pathNode.transform)
	
	var new_rotation = pathNode.transform.basis.get_euler()
	var turn_amount = old_rotation - new_rotation[1]
	old_rotation = new_rotation[1]
	emit_signal("turning", turn_amount)
	
