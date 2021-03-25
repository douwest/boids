extends Node

var ray_directions: Array = []

func _ready():
	generate_collision_rays()

#Generate collision rays using golden ratio sunflower projection.
#Then prune using dot product of cast position compared to transform basis of z-axis
func generate_collision_rays_flat() -> void:
	ray_directions.resize(BoidProperties.num_collision_rays)
	for n in BoidProperties.num_collision_rays:
		var angle = n * 2 * PI /BoidProperties.num_collision_rays
		ray_directions[n] = Vector3.FORWARD.rotated(Vector3(0, 1, 0), angle)

#Generate collision rays using golden ratio sunflower projection.
#Then prune using dot product of cast position compared to transform basis of z-axis
func generate_collision_rays() -> void:
	ray_directions.resize(BoidProperties.num_collision_rays)
	for n in BoidProperties.num_collision_rays:
		var phi: float = acos(1 - 2 * (n + BoidProperties.turn_fraction) / BoidProperties.num_collision_rays)
		var theta: float = PI * (1 + pow(5, BoidProperties.turn_fraction)) * (n + BoidProperties.turn_fraction)
		var x = sin(phi) * cos(theta)
		var y = sin(phi) * sin(theta)
		var z = cos(phi)
		ray_directions[n] = Vector3(x,y,z)

