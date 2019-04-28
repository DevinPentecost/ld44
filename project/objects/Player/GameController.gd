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
	if finish_time > 0:
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
	
	#Let the player know they won
	
	#Hide game-time UI elements
	_tween.interpolate_property($Progress, "rect_position.x", $Progress.rect_position.x, -100, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	
	#Show leaderboard info, let player submit
	$WinScreen.visible = true
	
	
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
	var submitScore = time
	var submitURL = "http://dreamlo.com/lb/BgYO9QhznU6z2dnGdcOcPQBcrAlcquwUyP5iKXLKk4vg/add/" + submitName + "/" + str(submitScore) + "/"
	$WinScreen/HTTPRequest.request(submitURL, PoolStringArray([]),false)
	
	$WinScreen/SubmitMsg.text = "SCORE SUBMITTED"
	$WinScreen/SubmitName.hide()
	$WinScreen/SubmitScore.hide()


func _on_ViewLB_button_up():
	# to update to webpage
	OS.shell_open("http://chilidog.faith/lb/growborally")


func _on_QuitButton_button_up():
	get_tree().quit()