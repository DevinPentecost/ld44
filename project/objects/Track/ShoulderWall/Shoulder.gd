extends Area

func _on_Shoulder_body_entered(body):
	if body.is_in_group("player"):
		body.hit_shoulder(self, true)

func _on_Shoulder_body_exited(body):
	if body.is_in_group("player"):
		body.hit_shoulder(self, false)