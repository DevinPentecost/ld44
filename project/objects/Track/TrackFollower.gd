extends Position3D

var PedestrianSpawn = preload("res://objects/Track/Pedestrian.gd").PedestrianSpawn
var PedestrianScene = preload("res://objects/Track/Pedestrian.tscn")
var SegmentScene = preload("res://objects/Track/Segment/Segment.tscn")

onready var nodescene = preload("res://objects/Track/Debug/RedNode.tscn")
onready var blueScene = preload("res://objects/Track/Debug/BlueNode.tscn")
onready var purpScene = preload("res://objects/Track/Debug/PurpleNode.tscn")
onready var roadscene = preload("res://objects/Track/Road.tscn")

onready var trackDefinition = _generateTrackLayout()
onready var nodes = []
var segments = []
onready var trackDemo = nodescene.instance()

signal position_update(new_transform)
signal turning(turn_amount)

export var speed = 30

onready var pathNode = $trackPath/PathFollow
onready var _follow_track = $FollowTrack


var old_rotation = null



# Produces a track layout, which is an object.
# The layout has a dictionary of information
# as well as a big list of track nodes
func _generateTrackLayout():
	var track = {}
	
	#Make some noise patterns
	var height_noise = OpenSimplexNoise.new()
	height_noise.persistence = 0.8
	height_noise.period = 10
	height_noise.octaves = 4
	var min_height = -200
	var max_height = -min_height
	var step_height = 5
	
	var distance_noise = OpenSimplexNoise.new()
	var min_distance = 100
	var max_distance = 200
	
	#Generate a track
	var tracks = []
	var track_length = 100
	for track_index in range(track_length):
		
		#Figure out how far this guy goes
		var distance = min_distance + (max_distance-min_distance)*(distance_noise.get_noise_2d(track_index, 0) + 1)/2
		
		#Determine which height to use
		var height_weight = (height_noise.get_noise_2d(track_index, 0) + 1) / 2
		var height = lerp(min_height, max_height, height_weight)
		
		#Now 'step' it so we have more discreet heights
		#height = floor(height / step_height)
		
		#Add this section of track
		tracks.append([distance, height])
	
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
	
	#For now, make one for every few steps
	var obstacle_rate = 1/4
	var obstacle_count = length * obstacle_rate
	
	#For each obstacle
	for obstacle_index in range(obstacle_count):
		pass
	"""
	var numObstacles = length / 50
	var obstaclesToPlace = []
	
	# Spawn a bucket of obstacles
	var numToSpawm = 0
	while numToSpawm < numObstacles:
		obstaclesToPlace.append(nodescene.instance())
		obstaclesToPlace.append(blueScene.instance())
		obstaclesToPlace.append(purpScene.instance())
		numToSpawm += 3
	
	# Lets figure out where to put these
	# TODO: Just doing even distribution for now
	var averageDistribution = length / numObstacles
	for dist in range(0, numObstacles):
		obstaclesToPlace.shuffle()
		obstacleList.append([dist * averageDistribution, obstaclesToPlace.pop_back()])
	"""
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
	
	#Create the path for the pieces to use
	_create_path()
	
	#Add all the nodes to the path
	_create_track_nodes()
	
	#Add pedestrians
	_create_pedestrians()
	
	#Add obstacles
	_create_obstacles()
	
	# Reset the path
	pathNode.set_offset(0)
	pathNode.transform = Transform()
	
func _create_path():
	
	#We have a sequence of X distance and Y height to make our path from
	var total_z = 0
	var total_height = 0
	var previous_track = null
	var new_curve = Curve3D.new()
	var tracks = trackDefinition['layout']
	for track_index in range(tracks.size()):
		
		#Get that track
		var track = tracks[track_index]
		
		#Get the X distance and height from it
		var distance = track[0]
		var height = track[1]
		
		#We want to create a node and put it here
		var new_point = Vector3(total_height, 0, total_z)
		new_curve.add_point(new_point)
		
		#Create the in and out vectors for this node
		if previous_track != null:
			
			#The in angle of this one will be the out point of the previous with
			var previous_position = new_curve.get_point_position(previous_track)
			var previous_out = new_curve.get_point_out(previous_track)
			var _in = new_point - (previous_position + previous_out)
			new_curve.set_point_in(track_index, -_in)
			
			#The out angle of this one will be the in angle, with flipped X and new Z
			var out = _in
			out.x = -out.x
			out.z = -distance/2
			new_curve.set_point_out(track_index, out)
		else:
			#Start by going straight
			var out = Vector3(0, 0, -distance/2)
			new_curve.set_point_out(track_index, out)
			
		#Adjust new position
		total_z -= distance
		total_height += height
		previous_track = track_index
	
	#Assign the curve
	$trackPath.curve = new_curve

func _create_track_nodes():
	
	#For each point in the curve
	var path_follow = $trackPath/PathFollow
	var curve = $trackPath.curve
	for point_index in range(curve.get_point_count()-1):
		
		#Get the end index
		var end_index = point_index + 1
		
		#Get points
		var start_point = curve.get_point_position(point_index)
		var end_point = curve.get_point_position(end_index)
		
		#We want to make a segment for this
		var segment = SegmentScene.instance()
		segments.append(segment)
		
		#Store the parent path
		segment.path_follow = path_follow
		
		#Set it at the first point
		segment.start_index = point_index
		segment.end_index = end_index
		
		#Get the offsets
		segment.start_offset = curve.get_closest_offset(start_point)
		segment.end_offset = curve.get_closest_offset(end_point)
		
		#Add it
		_follow_track.add_child(segment)
		
		#Position it accordingly
		#segment.transform.origin = start_point
		
		
		
		
func _create_pedestrians():
	
	#Go through each pedestrian
	var all_track_nodes = _follow_track.get_children()
	for pedestrian_spawn in trackDefinition['pedestrians']:
		
		#Determine which track section owns it
		var segment = segments[pedestrian_spawn.track_segment]
		segment.add_pedestrian(pedestrian_spawn)
	
func _create_obstacles():
	
	#For each obstacle defined...
	var obstacles = trackDefinition['obstacles']
	for obstacle_index in range(obstacles.size()):
		"""
		#Get the obstacle
		var obstacle = obstacles[obstacle_index]
		
		
	
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
	"""
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	_process_movement(delta)
	
	_process_turn(delta)
	
	return
	var currentOffset = pathNode.get_offset()
	var speed_adjust = 10 + speed * 4
	pathNode.set_offset(currentOffset + (delta * speed_adjust))
	emit_signal("position_update", pathNode.transform)
	
	var new_rotation = pathNode.transform.basis.get_euler()
	var turn_amount = old_rotation - new_rotation[1]
	old_rotation = new_rotation[1]
	emit_signal("turning", turn_amount)

func _process_movement(delta):
	
	#How far forward should we move
	var speed_adjust = speed * 4 * delta
	
	#We move the offset up this much
	pathNode.offset += speed_adjust
	
	#Now move the path node to make it seem like it's at zero
	_follow_track.transform = pathNode.transform.inverse()
	
	# Now rotate the whole set
	var new_rotation = pathNode.transform.basis.get_euler()
	_follow_track.transform.basis = Transform().basis.rotated(Vector3(0,1,0), (-1) * new_rotation[1])


func _process_turn(delta):
	
	#Get the current rotation
	var current_rotation = pathNode.transform.basis.get_euler()[1]
	print(current_rotation)
	#Figure out how much we've rotated since last time
	if old_rotation != null:
		var rotate_amount = old_rotation - current_rotation
		emit_signal("turning", rotate_amount)
		
	#Update the old rotation
	old_rotation = current_rotation
