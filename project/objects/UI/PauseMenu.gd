extends Control

signal resume_pressed
signal restart_pressed
signal quit_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show(showing=true):
	
	var target = Vector2(0, 0)
	if not showing:
		target = Vector2(0, -280)
		
	$Tween.interpolate_property(self, "rect_position", rect_position, target, 0.25, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()
	
	#Make some noise
	$SFX.play()

func _on_ResumeButton_pressed():
	emit_signal("resume_pressed")

func _on_RestartButton_pressed():
	emit_signal("restart_pressed")


func _on_QuitButton_pressed():
	emit_signal("quit_pressed")
