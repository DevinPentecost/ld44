extends Spatial

onready var _path_follow = $Path/PathFollow

var launch_min = Vector3(-5, 3, -1)
var launch_max = Vector3(5, 4, 1)

var top_min = Vector3(-3, 7, 0)
var top_max = Vector3(3, 8, 0)

var return_min = Vector3(-1, 0, -1)
var return_max = Vector3(1, 0, 1)

var delay_range = Vector2(0, 0.25)
var lifetime = Vector2(0.75, 2)
var duration = 0

#SFX
var slurp_pitch_range = Vector2(0.85, 1.5)

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	#Get a random speed
	_generate_path()
	
	#Kick off a tween
	var life = rand_range(lifetime.x, lifetime.y)
	var delay = rand_range(delay_range.x, delay_range.y)
	$Tween.interpolate_method(self, "_update_position", 0.0, 1.0, life, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN, delay)
	$Tween.start()

func _generate_path():
	
	#Make a new path
	var curve = Curve3D.new()
	
	#Generate 'launch' point
	var out_x = rand_range(launch_min.x, launch_max.x)
	var out_y = rand_range(launch_min.y, launch_max.y)
	var out_z = rand_range(launch_min.z, launch_max.z)
	curve.add_point(Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(out_x, out_y, out_z))
	
	#Add the top point
	var point_x = rand_range(top_min.x, top_max.x)
	var point_y = rand_range(top_min.y, top_max.y)
	var point_z = rand_range(top_min.z, top_max.z)
	curve.add_point(Vector3(point_x, point_y, point_z))
	
	#Add the return
	var in_x = rand_range(return_min.x, return_max.x)
	var in_y = rand_range(return_min.y, return_max.y)
	var in_z = rand_range(return_min.z, return_max.z)
	curve.add_point(Vector3(0, 0, 0), Vector3(in_x, in_y, in_z))
	
	#Give the curve
	$Path.curve = curve

func _update_position(value):
	
	#Get the new position
	_path_follow.unit_offset = value
	var position = _path_follow.transform.origin
	$BloodParticles.transform.origin = position

func _on_Tween_tween_completed(object, key):
	
	#Play the sound
	var pitch = rand_range(slurp_pitch_range.x, slurp_pitch_range.y)
	$Slurp.pitch_scale = pitch
	$Slurp.playing = true
	


func _on_Slurp_finished():
	#Stop and DIE
	$Slurp.playing = false
	
	#We can go away
	queue_free()
