extends Control


export(NodePath) var player
onready var _player = get_node(player)

const click_on = preload("res://objects/UI/click_on.ogg")
const click_off = preload("res://objects/UI/click_off.ogg")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_process(true)
	pass # Replace with function body.

func _process(delta):
	
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


func _on_BlinkTimer_timeout():
	
	#Toggle it
	$FuelMsg.visible = !$FuelMsg.visible
	$BlinkTimer.start()
	
	#Make a noise
	var sfx = click_on
	if not $FuelMsg.visible:
		sfx = click_off
	$SFX.stream = sfx
	$SFX.play()


func _on_TrackFollower_track_completed():
	
	#Hide
	$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-300, rect_position.y), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()