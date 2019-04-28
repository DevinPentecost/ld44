extends Spatial

const RoadScene = preload("res://objects/Track/Road.tscn")
const PedestrianScene = preload("res://objects/Track/Pedestrian.tscn")
const ObstacleScene = preload("res://objects/Track/Obstacle.tscn")

#The curve we are a part of
var path_follow = null
var start_index = null
var end_index = null
var start_offset = null
var end_offset = null

var road_step_size = 2.25 #Magic number
var road_width = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#The origin of this segment is at the START point in the curve!
	path_follow.offset = start_offset
	var start_point = path_follow.transform
	
	#Where are we starting vs ending
	path_follow.offset = end_offset
	var end_point = path_follow.transform
	
	#Build road segments
	var road_count = 0
	var current_offset = start_offset
	while current_offset <= end_offset:
		
		#Where should we put it?
		path_follow.offset = current_offset
		var new_transform = path_follow.transform
		
		#Make a new road section
		var new_road = RoadScene.instance()
		add_child(new_road)
		new_road.transform = new_transform
		#new_road.transform.basis = new_transform.basis
		
		#Increment the offset
		current_offset += road_step_size
		road_count += 1
	
	path_follow.offset = end_offset
	path_follow.transform = end_point

func add_obstacle(obstacle_spawn):
	
	#Set it up and add it to the correct location
	pass
	
func add_pedestrian(pedestrian_spawn):
	
	#Make the new pedestrian
	var pedestrian = PedestrianScene.instance()
	pedestrian.apply_pedestrian_spawn(pedestrian_spawn)
	
	#Set it up and add it to the correct location
	var offset = pedestrian_spawn.start_depth
	path_follow.offset = offset
	pedestrian.global_transform = path_follow.transform
	
	#Add the pedestrian
	add_child(pedestrian)
	
	#Give it a specific X offset
	var x = (pedestrian_spawn.start_position - 0.5) * road_width
	pedestrian.transform.origin.x += x
