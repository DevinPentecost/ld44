extends Spatial

#Possible sprites
const _possible_sprites = [
	preload("res://objects/Track/Pickup/bloodbag.png"),
	preload("res://objects/Track/Pickup/cauldron.png"),
	preload("res://objects/Track/Pickup/chalice.png"),
]
const _splat_sprite = preload("res://objects/Track/Pickup/splat.png")

onready var sprite = $LoDSprite

#They have a health value
var health_value = 35

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#Assign a random sprite
	var sprite_index = randi() % _possible_sprites.size()
	var target_sprite = _possible_sprites[sprite_index]
	sprite.tex_furthest = target_sprite
	sprite.tex_closest = target_sprite
	sprite.tex_lod0 = target_sprite
	sprite.tex_lod1 = target_sprite
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area_body_entered(body):
	
	#Was it the player?
	if body.is_in_group('player'):
		#Tell the player to get some health
		body.hit_pickup(self)
		
		#DIE
		_die()
		
func _die():
	
	#Change sprite
	var target_sprite = _splat_sprite
	sprite.tex_furthest = target_sprite
	sprite.tex_closest = target_sprite
	sprite.tex_lod0 = target_sprite
	sprite.tex_lod1 = target_sprite
	
	#Play a sound
	$SFX.play()
	yield($SFX, "finished")
	queue_free()
