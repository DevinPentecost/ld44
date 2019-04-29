extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var locked = false
var start_pos = null

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Store where we're at for later
	start_pos = rect_position
	
	#Hide by default
	set_show(false, true)
	
func set_show(showing, instant=false):
	
	#Are we locked?
	if locked:
		return
	
	#Should we show or not?
	$Tween.stop_all()
	
	var time = 0.25
	if instant:
		time = 0.01
	
	#Show or hide
	if showing:
		$Tween.interpolate_property(self, "rect_position", rect_position, start_pos, time, Tween.TRANS_BOUNCE,Tween.EASE_OUT)
		
		#TODO: Play a sound
		
	else:
		$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(rect_position.x, rect_position.y + 300), time, Tween.TRANS_BOUNCE, Tween.EASE_OUT)

	$Tween.start()

func _on_MainGame_race_finished():
	
	#Show, and keep it that way
	set_show(false)
	locked = true
	
	pass # Replace with function body.
