extends Position3D

var PedestrianSpawn = preload("res://objects/Track/Pedestrian.gd").PedestrianSpawn
var PedestrianScene = preload("res://objects/Track/Pedestrian.tscn")
var SegmentScene = preload("res://objects/Track/Segment/Segment.tscn")

onready var nodescene = preload("res://objects/Track/Debug/RedNode.tscn")
onready var blueScene = preload("res://objects/Track/Debug/BlueNode.tscn")
onready var purpScene = preload("res://objects/Track/Debug/PurpleNode.tscn")
onready var roadscene = preload("res://objects/Track/Road.tscn")
onready var treescene = preload("res://scenes/caleb/Tree.tscn")
onready var dirtscene = preload("res://scenes/caleb/Dirt.tscn")

onready var trackDefinition = _generateTrackLayout()
onready var nodes = []
var segments = []
onready var trackDemo = nodescene.instance()

signal position_update(new_transform)
signal turning(turn_amount)

export var speed = 30

onready var pathNode = $trackPath/PathFollow
onready var _follow_track = $FollowTrack

var old_rotation = 0
var startingTransform = null




# Produces a track layout, which is an object.
# The layout has a dictionary of information
# as well as a big list of track nodes
func _generateTrackLayout():
	var track = {}
	
	#Make some noise patterns
	var direction_noise = OpenSimplexNoise.new()
	direction_noise.persistence = 0.8
	direction_noise.period = 5
	direction_noise.octaves = 5
	var base_direction = 5
	var min_direction = -55
	var max_direction = -min_direction
	var direction_deadzone = 0.1
	
	var distance_noise = OpenSimplexNoise.new()
	var min_distance = 250
	var max_distance = 500
	
	#Generate a track
	var tracks = []
	var track_length = 50
	var total_angle = 0
	for track_index in range(track_length):
		
		#Figure out how far this guy goes
		var distance = min_distance + (max_distance-min_distance)*(distance_noise.get_noise_2d(track_index, 0) + 1)/2
		
		#Determine which height to use
		var direction = 0
		var direction_weight = direction_noise.get_noise_2d(track_index, 0)
		if abs(direction_weight) >= direction_deadzone:
			direction = (base_direction*abs(direction_weight)) + lerp(min_direction, max_direction, (direction_weight + 1))
		
		#Accommodate angle so we can't go backwards...
		total_angle += direction
		if abs(total_angle) > 100:
			print("FLOP")
			direction -= total_angle
			total_angle = 0
		
		#Add this section of track
		tracks.append([distance, direction])
	
	track["layout"] = tracks
	track["length"] = track_length
	
	# Also generate obstacles that will go into this track
	# [0] will be the location of the obstacle in track length
	# [1] will be the obstacle scene to place into the track
	track["obstacles"] = _generateObstacles(track_length)
	
	#Get the pedestrian objects for this course
	track['pedestrians'] = _generate_pedestrians(track_length)
	
	# Give this dictionary to the caller
	return track

# Produces obstacles to fit within the given track length
func _generateObstacles(length):
	var obstacleList = []
	# Whats a good way to do this...
	# Basically, we will spawn an obstacle for every ? units
	# The obstacle type will have even distribution
	# Obstacles will get more dense as the track goes on?
	
	var numObstacles = length
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
	good_pedestrian.track_segment = 5
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
	newNode.transform.origin = self.transform.origin - Vector3(0, 0, -100)
	
	# Append to associated lists
	nodes.append(newNode)
	trackCurve.add_point(newNode.transform.origin)
	add_child(newNode)
	
	var previousAnglePhi = 0
	
	# Create a collection of node objects to represent the layout
	for segment in self.trackDefinition["layout"]:
		# Move to the next node
		currentNode += 1
		
		# We want to start with the same origin point as the previous node
		var oldOrigin = nodes[currentNode - 1].transform.origin
		var newOrigin = oldOrigin
		
		# We know the hypoteneuse and the angle -- lets determine the other angles
		
		var radians = deg2rad(segment[1])
		radians = previousAnglePhi + radians 
		var dim1ToAdd = sin(radians) * segment[0]
		var dim2ToAdd = cos(radians) * segment[0]
		var addedAmount = Vector3(dim1ToAdd, 0, (-1) * dim2ToAdd)
		newOrigin = newOrigin + addedAmount
		previousAnglePhi = radians
		
		# Thats all we need to determine the new node position
		# Lets also determine the bezier curve out
		# Take our current vector and multiply it -- that will be out out vector
		var oldInVector = (-100 * addedAmount.normalized())
		var newOutVector = (100 * addedAmount.normalized())
		
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
	pathNode.add_child(trackDemo)
	pathNode.set_offset(0)
	startingTransform = pathNode.transform
	
	# Create "road" scenes througought the path
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
			sprite.reference = get_parent().get_node("PlayerCamera").get_path()
			roadPiece.add_child(dirt)
		
		var treeHappened = randf() * 100
		if treeHappened < 10:
			var tree = treescene.instance()
			var sprite = tree.get_node("LoDSprite")
			sprite.reference = get_parent().get_node("PlayerCamera").get_path()
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
	pathNode.set_offset(0)
	pathNode.transform = startingTransform
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Are we looping?
	if pathNode.get_unit_offset() > 1:
		pathNode.set_offset(0)
		pathNode.transform = startingTransform
	
	
	var currentOffset = pathNode.get_offset()
	
	var speed_adjust = 10 + speed * 4
	pathNode.set_offset(currentOffset + (delta * speed_adjust))
	emit_signal("position_update", pathNode.transform)
	
	var new_rotation = pathNode.transform.basis.get_euler()
	var turn_amount = old_rotation - new_rotation[1]
	old_rotation = new_rotation[1]
	emit_signal("turning", turn_amount)
	
