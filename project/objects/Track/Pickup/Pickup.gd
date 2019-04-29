extends Spatial

#Possible sprites
const _possible_sprites = [
	preload("res://objects/Track/Pickup/bloodbag.png"),
	preload("res://objects/Track/Pickup/cauldron.png"),
	preload("res://objects/Track/Pickup/chalice.png"),
	preload("res://objects/Track/Pickup/doctor.png"),
]
const _splat_sprite = preload("res://objects/Track/Pickup/splat.png")

onready var sprite = $LoDSprite

const hover_up_height = 5
const hover_down_height = 3
const hover_time = 0.25
var hover_up = false


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
	
	
	#Make hover happen
	_hover()

func _hover():
	
	#Are we going up or down?
	var target = hover_up_height
	if not hover_up:
		target = hover_down_height
		
	#Animate to that position
	var start = sprite.transform.origin
	var end = Vector3(start.x,  target, start.z)
	$Tween.interpolate_property(sprite, "transform.origin", start, end, hover_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	#Switch direction
	hover_up = !hover_up
	_hover()

func _on_Area_body_entered(body):
	
	#Was it the player?
	if body.is_in_group('player'):
		#Tell the player to get some health
		body.hit_pickup(self)
		
		#DIE
		_die()
		
func _die():
	
	#Hide the sprite and shadow
	sprite.visible = false
	$Shadow.visible = false
	
	#Play a sound
	$SFX.play()
	yield($SFX, "finished")
	queue_free()
