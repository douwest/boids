extends RayCast

func get_push_vector() -> Vector3:
	var point = self.get_collision_point()
	var push_vector = Vector3.ZERO
	if is_colliding():
		push_vector = point.direction_to(self.translation)
		push_vector = push_vector.normalized()
	return push_vector
