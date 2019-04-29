extends StaticBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var horizontal_movement = 0
onready var vertical_movement = 0
onready var stunned = 0
onready var health_value = 15
var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _calculate_new_horizontal_movement(factor):
	var distance_from_center = self.transform.origin.x
	if abs(distance_from_center) > 0.3:
		# Too far away! Adjust movement to get closer
		if distance_from_center < 0:
			return 3 * factor
		else:
			return -3 * factor
		
	return 0
	
func _calculate_new_vertical_movement(factor):
	var distance_from_center = self.transform.origin.z
	if abs(distance_from_center) > 0.1:
		# Too far away! Adjust movement to get closer
		if distance_from_center < 0:
			return 3 * factor
		else:
			return -3 * factor
		
	return 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.transform.origin += Vector3(horizontal_movement * delta, 0, vertical_movement * delta)
	
	# Try and slide closer to the center
	if stunned < 0:
		horizontal_movement += _calculate_new_horizontal_movement(delta)
	else:
		stunned -= delta
	
	vertical_movement += _calculate_new_vertical_movement(delta)

func bump(magnitude):
	horizontal_movement = magnitude
	stunned = 1

func _on_Announcer_finished():
	get_parent().remove_child(self)

func _on_PlayerColllider_body_entered(body):
	if body.is_in_group("player"):
		body.hit_opponent(self, true)


func _on_PlayerColllider_body_exited(body):
	if body.is_in_group("player"):
		body.hit_opponent(self, false)


func _on_WallCollider_body_entered(body):
	if body.is_in_group("wall"):
		visible = false
		$Crash.playing = true
		$Announcer.playing = true
		remove_child($Area)
		player.hit_pickup(self)
