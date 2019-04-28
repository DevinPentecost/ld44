extends Spatial

onready var _tween = $Tween

#Keep track of the time
var time = 0
var finish_time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_process(true)
	
	pass # Replace with function body.

func _process(delta):
	
	#Update timer
	time += delta

func _start_race():
	
	time = 0
	
func _end_race():
	
	#Lock the time
	finish_time = time
	
	#Let the player know they won
	
	#Hide game-time UI elements
	_tween.interpolate_property($Progress, "rect_position.x", $Progress.rect_position.x, -100, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	#Show leaderboard info, let player submit
	
	#Lock camera, move player off screen
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TrackFollower_track_completed():
	pass # Replace with function body.


func _on_Player_player_force_brake(start):
	
	#Show the bloodletter
	$Bloodletting.set_show(start)
	pass # Replace with function body.
