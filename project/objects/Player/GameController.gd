extends Spatial

signal race_finished

onready var _tween = $Tween

const thanks = preload("res://scenes/thanks.ogg")

#Keep track of the time
var time = 0
var finish_time = 0
var brake_state = false
var start_state = false

onready var player_anim = $Player/CarModel/PlayerModel/AnimationPlayer

#Grab nodes
onready var _fuel_meter = $FuelMeter

#BGM
var volume = {true: -40, false: -30}


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$Music.volume_db = volume[true]
	
	set_process(true)
	player_anim.play("armature|armature|intro.idle|armature|intro.idle")
	$Player.movement_state.locked = true
	$TrackFollower.locked = true
	$FuelMeter.locked = true
	$PlayerCamera.cinematic = true
	
	set_process_unhandled_key_input(true)
	


func _process(delta):
	if start_state:
		#Update timer
		if finish_time == 0:
			
			#Are we locked?
			if not $TrackFollower.locked:
				
				time += delta
				var minutes = time/60
				var seconds = int(round(time))%60
				var time_stamp = "%02d : %02d" % [minutes, seconds]
				$TimerLabel.text = time_stamp
				
	
func _start_race():
	$StartMenu.hide()
	player_anim.play("armature|armature|braking|armature|braking")
	start_state = true
	
	$TrackFollower.locked = false
	$Player.movement_state.locked = false
	$FuelMeter.locked = false
	$PlayerCamera.cinematic = false
	$Player.current_health = 100
	$FuelMeter/FuelBar.value = 100
	
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
	

func _on_Button_button_up():
	$StartMenu/StartButton.disabled = true
	$StartMenu/LBButton.disabled = true
	
	
	$FuelMeter/Syringe/Syringe_bar.value = 100
	$Tween.interpolate_property($FuelMeter, "rect_position", $FuelMeter.rect_position, $FuelMeter.rect_position + Vector2(200,0), 3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.interpolate_property($StartMenu, "modulate", Color(1,1,1,1), Color(1,1,1,0),2,Tween.TRANS_LINEAR, Tween.EASE_OUT)
		
	$Tween.interpolate_property($Music, "volume_db", $Music.volume_db, volume[false], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	
	player_anim.play("armature|armature|intro.walk|armature|intro.walk")
	yield(player_anim, "animation_finished" )
	_start_race()

func _quit():
	
	#Say Thanks!
	$SFX.stream = thanks
	$SFX.play()
	yield($SFX, "finished")
	
	#They really mean it
	get_tree().quit()
	

func _pause(paused):
	
	#Game not even started?
	if not start_state:
		_quit()
		return
	
	#Lock and unlock accordingly
	$TrackFollower.locked = paused
	$Player.movement_state.locked = paused
	$FuelMeter.locked = paused
	$PlayerCamera.cinematic = paused
	
	#Show/hide accordingly
	$PauseMenu.show(paused)
	
	#Change music
	$Tween.interpolate_property($Music, "volume_db", $Music.volume_db, volume[paused], 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func _on_WinScreen_quit_pressed():
	
	#Ask user if they are sure
	_pause(true)


func _on_WinScreen_restart_pressed():
	
	#Reload this scene
	get_tree().reload_current_scene()


func _on_PauseMenu_quit_pressed():
	
	_quit()


func _on_PauseMenu_restart_pressed():
	
	#Reload this scene
	get_tree().reload_current_scene()


func _on_PauseMenu_resume_pressed():
	
	#Unlock everything
	_pause(false)

func _unhandled_key_input(event):
	#We respond to various movement commands
	if event.is_action_pressed("pause"):
		#Toggle pause
		_pause(not $TrackFollower.locked)
	

func _on_LBButton_button_up():
	OS.shell_open("http://chilidog.faith/lb/ld44")
