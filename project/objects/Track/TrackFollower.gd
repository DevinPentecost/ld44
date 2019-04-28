extends Position3D

signal position_update(new_transform)
signal turning(turn_amount)
signal track_completed

var PedestrianSpawn = preload("res://objects/Track/Pedestrian.gd").PedestrianSpawn
var PedestrianScene = preload("res://objects/Track/Pedestrian.tscn")
var SegmentScene = preload("res://objects/Track/Segment/Segment.tscn")

export(NodePath) var player
onready var _player = get_node(player)
export(NodePath) var player_camera
onready var _player_camera = get_node(player_camera)

onready var nodescene = preload("res://objects/Track/Debug/RedNode.tscn")
onready var blueScene = preload("res://objects/Track/Debug/BlueNode.tscn")
onready var purpScene = preload("res://objects/Track/Debug/PurpleNode.tscn")
onready var roadscene = preload("res://objects/Track/Road.tscn")
onready var treescene = preload("res://scenes/caleb/Tree.tscn")
onready var dirtscene = preload("res://scenes/caleb/Dirt.tscn")

onready var trackDefinition = _generateTrackLayout()
var unused_segments = []
var next_generate_offset = 0.001
var segment_create_distance = 400 #How far away to deterime segment neccessity
var segment_despawn_distance = 20 #How far past to remove old segments
var segment_length = 2.25
var nodes = []
var segments = []
onready var trackDemo = nodescene.instance()

var is_paused = false

onready var _path = $trackPath
onready var pathNode = $trackPath/PathFollow
onready var _follow_track = $FollowTrack
onready var _progress_follow = $trackPath/ProgressFollow

var old_rotation = 0
var startingTransform = null

var completion = 0 setget , _get_completion
var race_over = false

func _get_completion():
	
	#Ask the path how far we are
	return pathNode.unit_offset

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
	var track_length = 5 #50
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
	
	_build_curve()
	
	
	# Generate a path from this curve
	self.get_node("trackPath")
	pathNode.add_child(trackDemo)
	pathNode.set_offset(0)
	startingTransform = pathNode.transform
	
	# Reset the path
	pathNode.set_offset(0)
	pathNode.transform = startingTransform
	
	#Set the progress follower
	_progress_follow.set_offset(0)
	_progress_follow.transform = startingTransform

func _build_curve():
	
	#Make a new curve
	var track_curve = Curve3D.new()
	
	# Instance a new scene and give it the same start point as the track follower/generator
	var start_track = nodescene.instance()
	start_track.transform.origin = transform.origin - Vector3(0, 0, -100)
	
	# Append to associated lists
	nodes.append(start_track)
	track_curve.add_point(start_track.transform.origin)
	add_child(start_track)
	
	#Start making segments shooting off
	var segments = trackDefinition['layout']
	var previous_angle = 0
	var segment_count = segments.size()
	for segment_index in range(segment_count):
		
		#Get the segment
		var segment = segments[segment_index]
		
		# We want to start with the same origin point as the previous node
		var old_origin = track_curve.get_point_position(segment_index)
		var new_origin = old_origin
		
		# We know the hypoteneuse and the angle -- lets determine the other angles
		
		var radians = deg2rad(segment[1])
		radians += previous_angle
		var dim1ToAdd = sin(radians) * segment[0]
		var dim2ToAdd = cos(radians) * segment[0]
		
		#Offset based on previous
		var add_amount = Vector3(dim1ToAdd, 0, (-1) * dim2ToAdd)
		new_origin = new_origin + add_amount
		previous_angle = radians
		
		# Thats all we need to determine the new node position
		# Lets also determine the bezier curve out
		# Take our current vector and multiply it -- that will be out out vector
		var old_in = (-100 * add_amount.normalized())
		var new_out = (100 * add_amount.normalized())
		
		# My new node's curve input should be a continuation of my current angle!
		track_curve.add_point(new_origin, (-1) * new_out, new_out)
		
		# The previous node's curve input is also a form of continuation of my current angle
		var index_of_previous = track_curve.get_point_count() - 1
		track_curve.set_point_in(index_of_previous, old_in)
	
	_path.set_curve(track_curve)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	_process_movement(delta)

	
	#Create nodes as needed so we aren't making too many
	_create_needed_track()
	
	#Remove nodes as needed so we aren't making too many
	_remove_old_track()
	
	var new_rotation = _progress_follow.transform.basis.get_euler()
	var turn_amount = old_rotation - new_rotation[1]
	old_rotation = new_rotation[1]
	emit_signal("turning", turn_amount)
	
	#Are we close to the end?
	if _progress_follow.unit_offset >= 0.98:
		#We should play an end cinematic and stuff
		emit_signal("track_completed")
		race_over = true
		
		set_process(false)

func _process_movement(delta):
	#Move the progress follower up
	var current_offset = _progress_follow.get_offset()
	var speed_adjust = 10 + _player.current_speed * 4
	
	var new_offset = current_offset + (delta * speed_adjust)
	_progress_follow.set_offset(new_offset)
	emit_signal("position_update", _progress_follow.transform)

func _create_needed_track():
	
	#Where are we at?
	var current_offset = _progress_follow.get_offset()
	
	#Step from the previous offset to the current
	while next_generate_offset < current_offset + segment_create_distance:
		
		#Did we go too far?
		var transform_1 = pathNode.transform
		pathNode.offset = next_generate_offset
		transform_1 = pathNode.transform
		if pathNode.unit_offset >= 1:
			break		
		
		#Make one at this offset
		var new_road = roadscene.instance()
		new_road.transform = pathNode.transform
		new_road.offset = next_generate_offset
		_follow_track.add_section(new_road)
		
		#Do we need to add any doodads?
		var make_dirt = (randf() * 100) < 5
		if make_dirt:
			var dirt = dirtscene.instance()
			var sprite = dirt.get_node("LoDSprite")
			sprite.reference = player_camera
			#new_road.add_child(dirt)
		
		var make_tree = (randf() * 100) < 10
		if make_tree:
			var tree = treescene.instance()
			var sprite = tree.get_node("LoDSprite")
			sprite.reference = _player_camera
			#new_road.add_child(tree)
		
		#TODO: Reimplement adding obstacles
		"""
		for remaining_obstacle in trackDefinition['obstacles']:
			if remaining_obstacle[0] <= next_generate_offset:
				#Make a new 
		"""
		
		#TODO: Reimplement pedestrians
		"""
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
		"""
		
		#Take a step forward
		next_generate_offset += segment_length
		
	
	#We're done for this frame
	pass
	return


func _remove_old_track():
	
	#How far back to remove?
	var current_offset = _progress_follow.offset
	var remove_offset = current_offset - segment_despawn_distance
	
	#Go through all track
	for track in _follow_track.get_sections():
		
		#Is this child too near?
		if track.offset >= remove_offset:
			break
		
		#It's too far, remove it
		track.queue_free()

