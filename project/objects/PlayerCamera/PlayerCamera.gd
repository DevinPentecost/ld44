extends InterpolatedCamera

export(NodePath) var player
onready var _player = get_node(player)

#Variables related to camera shake
var shake_base = 0.01
var shake_amount = shake_base
var shake_speed_multiplier = 0.7
var shake_noise = OpenSimplexNoise.new()
var shake_period_base = 20
var shake_period_multiplier = 0.7
var shake_persistence_base = 0.1
var shake_persistence_multiplier = 0.0035

var target_position = null
var default_position = null


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Grab the current position, that's the start and target
	default_position = global_transform.origin
	target_position = default_position
	
	#Initialize noise
	_refresh_noise(0)
	
	#Check stuff every frame
	set_process(true)

func _refresh_noise(player_speed):
	
	#Calculate new params
	shake_noise.period = shake_period_base - (player_speed * shake_period_multiplier)
	shake_noise.persistence = shake_persistence_base + (player_speed * shake_persistence_multiplier)
	
	shake_amount = shake_base + (shake_base * shake_period_multiplier * player_speed)

func _process(delta):
	
	#Grab speed from the player
	var player_speed = _player.current_speed
	_refresh_noise(player_speed)
	
	_process_camera(delta)
	
	
	#Set up shake noise
	var debug_image = shake_noise.get_seamless_image(100)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(debug_image)
	$Sprite3D.texture = image_texture
	pass
	
func _process_camera(delta):
	
	#Move towards our desired location
	
	var final_position = target_position
	
	#Shake a little
	var time = OS.get_ticks_msec() / 15
	var x_shake = shake_noise.get_noise_2d(time, 0) * shake_amount
	var y_shake = shake_noise.get_noise_2d(time, 1) * shake_amount
	var z_shake = shake_noise.get_noise_2d(time, 2) * shake_amount
	
	#Offset our transform based on this
	final_position += Vector3(x_shake, y_shake, z_shake)
	
	#Finally, take this position
	transform.origin = final_position