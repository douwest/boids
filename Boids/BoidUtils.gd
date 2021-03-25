extends Node

var ray_directions: Array = generate_collision_rays()

func generate_collision_rays() -> Array:
	var result = []
	result.resize(BoidProperties.num_collision_rays)
	for n in BoidProperties.num_collision_rays:
		var phi: float = acos(1 - 2 * (n + 0.5) / BoidProperties.num_collision_rays)
		var theta: float = PI * (1 + pow(5, 0.5)) * (n + 0.5)
		var x = sin(phi) * cos(theta)
		var y = sin(phi) * sin(theta)
		var z = cos(phi)
		result[n] = Vector3(x,y,z)
	return result
