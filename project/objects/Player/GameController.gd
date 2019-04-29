extends Spatial

signal race_finished

onready var _tween = $Tween

#Keep track of the time
var time = 0
var finish_time = 0
var brake_state = false

#Grab nodes
onready var _fuel_meter = $FuelMeter


# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_process(true)
	


func _process(delta):
	
	#Update timer
	if finish_time == 0:
		time += delta
		var minutes = time/60
		var seconds = int(round(time))%60
		var time_stamp = "%02d : %02d" % [minutes, seconds]
		$TimerLabel.text = time_stamp
	
	
func _start_race():
	
	time = 0
	
func _end_race():
	
	#Lock the time
	finish_time = time
	
	#Emit signal for listeners
	#Let the player know they won
	emit_signal("race_finished")
	
	
	#Lock camera, move player off screen
	$PlayerCamera.cinematic = true
	$Player.sunset()


func _on_TrackFollower_track_completed():
	
	#Begin end-of-game sequence
	finish_time = time
	_end_race()

func _on_Player_player_force_brake(start):
	
	#Show the bloodletter
	$Bloodletting.set_show(start)
	pass # Replace with function body.

func _on_QuitButton_button_up():
	get_tree().quit()

func _on_Player_player_brake(start, forced):
	
	#Was the player forced to brake?
	if forced:
		#Move the bloodletting graphic?
		$Bloodletting.set_show(start)
	
	#Tell the health thing we're braking
	_fuel_meter.tilt(start)
	