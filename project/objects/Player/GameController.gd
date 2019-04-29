extends Spatial

signal race_finished

onready var _tween = $Tween

#Keep track of the time
var time = 0
var finish_time = 0
var brake_state = false
var start_state = false

onready var player_anim = $Player/CarModel/PlayerModel/AnimationPlayer

#Grab nodes
onready var _fuel_meter = $FuelMeter


# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_process(true)
	player_anim.play("armature|armature|intro.idle|armature|intro.idle")
	$Player.movement_state.locked = true
	$TrackFollower.locked = true
	$FuelMeter.locked = true
	$PlayerCamera.cinematic = true
	


func _process(delta):
	if start_state:
		#Update timer
		if finish_time == 0:
			time += delta
			var minutes = time/60
			var seconds = int(round(time))%60
			var time_stamp = "%02d : %02d" % [minutes, seconds]
			$TimerLabel.text = time_stamp
	
	
func _start_race():
	
	player_anim.play("armature|armature|braking|armature|braking")
	start_state = true
	
	$TrackFollower.locked = false
	$Player.movement_state.locked = false
	$FuelMeter.locked = false
	$PlayerCamera.cinematic = false
	
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
	$StartMenu
	
	
	$FuelMeter/Syringe/Syringe_bar.value = 100
	$Tween.interpolate_property($FuelMeter, "rect_position", $FuelMeter.rect_position, $FuelMeter.rect_position + Vector2(200,0), 3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	
	
	player_anim.play("armature|armature|intro.walk|armature|intro.walk")
	yield(player_anim, "animation_finished" )
	_start_race()