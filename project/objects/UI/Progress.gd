extends Control


export(Vector2) var start_pos
export(Vector2) var end_pos

export(NodePath) var track
onready var _track = get_node(track)

onready var _progress = $Progress

func _ready():
	set_process(true)
	
func _process(delta):
	
	#Set position
	var position = lerp(start_pos, end_pos, _track.completion)
	_progress.rect_position = position


func _on_TrackFollower_track_completed():
	
	$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(-300, rect_position.y), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()