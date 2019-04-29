extends Control


export(NodePath) var player
onready var _player = get_node(player)

const click_on = preload("res://objects/UI/click_on.ogg")
const click_off = preload("res://objects/UI/click_off.ogg")


var locked = false
var tilting = false
onready var _tween = $Tween


# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_process(true)
	pass # Replace with function body.

func _process(delta):
	if locked:
		return
	
	#Check player health
	var health = _player.current_health
	$FuelBar.value = health
	$Syringe/Syringe_bar.value = health
	
	#Is it low?
	if health < 25:
		#Is the timer already going?
		if $BlinkTimer.is_stopped():
			$BlinkTimer.start()
	else:
		#We don't show
		$BlinkTimer.stop()
		$FuelMsg.visible = false

func tilt(enable):
	if locked:
		return
	
	#Get the angle
	var target_angle = 27
	if not enable:
		target_angle = 0
		
	#Perform animation
	_tween.interpolate_property(self, "rect_rotation", rect_rotation, target_angle, 0.25, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_tween.start()

func _show(showing):
	if locked:
		return
	
	#Always hide because I'm lazy
	#Hide
	$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-300, rect_position.y), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	
func _on_BlinkTimer_timeout():
	if locked:
		return
	
	#Toggle it
	$FuelMsg.visible = !$FuelMsg.visible
	$BlinkTimer.start()
	
	#Make a noise
	var sfx = click_on
	if not $FuelMsg.visible:
		sfx = click_off
	$SFX.stream = sfx
	$SFX.play()


func _on_MainGame_race_finished():
	_show(false)
	locked = true
	pass # Replace with function body.
