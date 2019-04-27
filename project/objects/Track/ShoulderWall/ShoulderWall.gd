extends Spatial

onready var shoulders = $Shoulders
onready var walls = $Walls

var max_shoulder_movement = 6

func _on_TrackFollower_turning(turn_amount):
	
	#Follow the track
	var new_x = turn_amount * 200
	
	#Make sure we don't go too far off the walls
	new_x = max(new_x, -max_shoulder_movement)
	new_x = min(new_x, max_shoulder_movement)
	
	shoulders.transform.origin.x = new_x
