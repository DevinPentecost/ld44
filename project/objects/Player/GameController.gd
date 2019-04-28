extends Spatial

onready var _tween = $Tween

#Keep track of the time
var time = 0
var finish_time = 0
var brake_state = false

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
		
		
		if brake_state != $Player.movement_state.is_braking():
			brake_state = !brake_state
			var fuel_angle = $FuelMeter.rect_rotation
			_tween.stop_all()
			if brake_state:
				_tween.interpolate_property($FuelMeter, "rect_rotation", fuel_angle, 27, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
			else:
				_tween.interpolate_property($FuelMeter, "rect_rotation", fuel_angle ,0, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
			_tween.start()
			
		
	#TEST TO END GAME EARLY
	#if time > 11 and finish_time == 0:
	#	_end_race()


func _start_race():
	
	time = 0
	
func _end_race():
	
	#Lock the time
	finish_time = time
	
	#Let the player know they won
	
	#Hide game-time UI elements
	_tween.interpolate_property($Progress, "rect_position.x", $Progress.rect_position.x, -100, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	
	#Show leaderboard info, let player submit
	$WinScreen.visible = true
	
	
	_tween.interpolate_property($WinScreen, "rect_position", Vector2(0,0), Vector2(0,400), 1, Tween.TRANS_QUAD,Tween.EASE_OUT)
	_tween.start()
	
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


func _on_SubmitScore_button_up():
	var submitName = $WinScreen/SubmitName.text
	if submitName == '':
		submitName = 'Anon'
	var submitTime = finish_time
	var submitURL = "http://dreamlo.com/lb/BgYO9QhznU6z2dnGdcOcPQBcrAlcquwUyP5iKXLKk4vg/add/" + submitName + "/0/" + str(submitTime) + "/"
	$WinScreen/HTTPRequest.request(submitURL, PoolStringArray([]),false)
	
	$WinScreen/SubmitMsg.text = "TIME SUBMITTED"
	$WinScreen/SubmitName.hide()
	$WinScreen/SubmitScore.hide()


func _on_ViewLB_button_up():
	# to update to webpage
	OS.shell_open("http://chilidog.faith/lb/growborally")


func _on_QuitButton_button_up():
	get_tree().quit()