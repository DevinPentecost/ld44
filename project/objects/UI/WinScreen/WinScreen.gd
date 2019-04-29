extends Control

signal restart_pressed
signal quit_pressed

export(NodePath) var game_controller
onready var _game_controller = get_node(game_controller)

const target_positions = {
	true: Vector2(761, -37),
	false: Vector2(761, -732.136),
}
const tween_time = 1.0

onready var _tween = $Tween

const voice_sequence = [
	preload("res://objects/UI/WinScreen/congrats.ogg"),
	preload("res://objects/UI/WinScreen/score.ogg"),
]

func _show(visible):
	
	#Tween to desired state
	var target = target_positions[visible]
	var start = rect_position
	
	_tween.interpolate_property(self, "rect_position", start, target, tween_time, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	_tween.start()
	
	#Also play some SFX
	$SFX.play()
	
	#Play voices
	for voice_clip in voice_sequence:
		#Play it
		$Voice.stream = voice_clip
		$Voice.play()
		yield($Voice, "finished")

func _submit_score():
	
	#Get player name
	var player_name = $WinBG/SubmitName.text
	var player_time = _game_controller.finish_time
	print("Submitting Score: ", player_name, " ", player_time)
	
	#Send the score
	# no error handling for submission failures
	var submit_url = "http://dreamlo.com/lb/BgYO9QhznU6z2dnGdcOcPQBcrAlcquwUyP5iKXLKk4vg/add/" + player_name + "/0/" + str(int(1000*player_time)) + "/"	
	$HTTPRequest.request(submit_url, PoolStringArray([]), false)
	$WinBG/SubmitScore.text = "TIME SUBMITTED"
	$WinBG/SubmitName.editable = true
	$WinBG/SubmitScore.disabled = true

func _on_MainGame_race_finished():
	
	#Show!
	_show(true)

func _on_SubmitName_text_changed(new_text):
	
	#Enable submit button when the user enters at least something
	$WinBG/SubmitScore.disabled = false


func _on_SubmitName_text_entered(new_text):
	
	#User hit enter?
	#Act like the submit button was pressed
	_submit_score()


func _on_SubmitScore_pressed():
	_submit_score()

func _on_ViewLB_pressed():
	#Open the leaderboard in your favorite web browser
	OS.shell_open("http://chilidog.faith/lb/ld44")


func _on_QuitButton_pressed():
	
	#Quit the game?
	#Quit to main menu?
	emit_signal("quit_pressed")

func _on_ReplayButton_pressed():
	
	#Restart the scene maybe
	emit_signal("restart_pressed")
