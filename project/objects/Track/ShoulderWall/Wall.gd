extends StaticBody


func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		body.hit_wall(self, true)

func _on_Area_body_exited(body):
	if body.is_in_group("player"):
		body.hit_wall(self, false)