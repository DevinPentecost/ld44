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
		
	#TEST TO END GAME EARLY
	if time > 3 and finish_time == 0:
		_end_race()
	
func _start_race():
	
	time = 0
	
func _end_race():
	
	#Lock the time
	finish_time = time
	
	#Emit signal for listeners
	emit_signal("race_finished")
	
	#Let the player know they won
	
	#Lock camera, move player off screen
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TrackFollower_track_completed():
	
	#Begin end-of-game sequence
	_end_race()

func _on_Player_player_force_brake(start):
	
	#Show the bloodletter
	$Bloodletting.set_show(start)
	pass # Replace with function body.


func _on_SubmitScore_button_up():
	
	# get used entered name
	var submitName = $WinScreen/WinBG/SubmitName.text
	if submitName == '':
		submitName = 'Anon'
	var submitTime = finish_time
	#submit score to LB
	var submitURL = "http://dreamlo.com/lb/BgYO9QhznU6z2dnGdcOcPQBcrAlcquwUyP5iKXLKk4vg/add/" + submitName + "/0/" + str(submitTime) + "/"
	
	# no error handling for submission failures
	$WinScreen/HTTPRequest.request(submitURL, PoolStringArray([]),false)
	$WinScreen/WinBG/SubmitScore.text = "TIME SUBMITTED"
	$WinScreen/WinBG/SubmitName.hide()
	$WinScreen/WinBG/SubmitScore.disabled = true


func _on_ViewLB_button_up():
	OS.shell_open("http://chilidog.faith/lb/ld44")


func _on_QuitButton_button_up():
	get_tree().quit()

func _on_Player_player_brake(start, forced):
	
	#Was the player forced to brake?
	if forced:
		#Move the bloodletting graphic?
		$Bloodletting.set_show(start)
	
	#Tell the health thing we're braking
	_fuel_meter.tilt(start)
	