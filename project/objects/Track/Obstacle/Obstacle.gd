extends Area

#Possible sprites
const _possible_sprites = [
	preload("res://objects/Track/Obstacle/barricade.png"),
	preload("res://objects/Track/Obstacle/noparking.png"),
	preload("res://objects/Track/Obstacle/pylon.png"),
	preload("res://objects/Track/Obstacle/rock.png"),
	preload("res://objects/Track/Obstacle/cactus.png"),
]


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Pick a random sprite
	#Assign a random sprite
	var sprite_index = randi() % _possible_sprites.size()
	var target_sprite = _possible_sprites[sprite_index]
	$Sprite3D.texture = target_sprite
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _destroy():
	queue_free()

func _on_Obstacle_body_entered(body):
	
	#Did we hit the player?
	if body.is_in_group("player"):
		#Tell the player that we hit them
		body.hit_obstacle(self)
	
		#We should deactive/DIE
		_destroy()