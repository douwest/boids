extends KinematicBody
class_name Boid

var direction = Vector3.FORWARD
var velocity = Vector3.FORWARD

onready var collisionRays = $CollisionRays
onready var detectionZone = $DetectionZone
onready var intent = make_ray(Vector3.FORWARD, BoidProperties.collision_depth * 1.5, true)

func _ready() -> void:
	generate_collision_rays()
	add_child(intent)

func _physics_process(delta) -> void:
	var acceleration = Vector3.ZERO
	var nearby_boids = get_nearby_boids()
	
	#for boid in nearby_boids: make this a loop for all behaviours so it runs much faster
	
	var cohesion_force = steer_towards(cohesion(nearby_boids)) * BoidProperties.cohesion_weight	
	var alignment_force = steer_towards(alignment(nearby_boids)) * BoidProperties.alignment_weight
	var separation_force = steer_towards(separation(nearby_boids)) * BoidProperties.separation_weight
	var avoidance_force = steer_towards(avoidance()) * BoidProperties.avoidance_weight
	
	acceleration += cohesion_force
	acceleration += alignment_force
	acceleration += separation_force
	acceleration += avoidance_force
	
	velocity += acceleration * delta
	direction = velocity.normalized()
	
	var turn_speed = direction.length_squared()
	var speed = clamp(velocity.length(), BoidProperties.min_speed, BoidProperties.max_speed)
	
	velocity = direction * speed
	
	var current_basis = Quat(transform.basis)
	var new_transform = transform.looking_at(transform.origin + direction, Vector3.UP)
	var new_basis = Quat(new_transform.basis)
	var interpolated_basis = current_basis.slerp(new_basis, clamp(turn_speed, BoidProperties.min_turn_speed, BoidProperties.max_turn_speed))
	transform.basis = Basis(interpolated_basis)
	
	velocity = move_and_slide(velocity)

# get offset of position wrt to average position of other nearby boids
func cohesion(boids: Array) -> Vector3:
	var avg = Vector3.ZERO
	if boids.size() > 0:
		for b in boids:
			avg += b.global_transform.origin 
		avg /= boids.size() #calculate the average position of all boids in the detection radius
		var dir = avg - global_transform.origin  #get the direction to the offset
		return dir
	else:
		return Vector3.ZERO
		
# get average direction vector of nearby boids
func alignment(boids: Array) -> Vector3:
	var avg_direction = Vector3.ZERO
	if boids.size() > 0:
		for b in boids:
			avg_direction += b.direction.normalized()
		return avg_direction
	else:
		return Vector3.ZERO

func separation(boids: Array) -> Vector3:
	var avg = Vector3.ZERO
	if boids.size() > 0:
		for b in boids:
			avg += b.global_transform.origin 
		avg /= boids.size() #calculate the average position of all boids in the detection radius
		var dir = avg - global_transform.origin  #get the direction to the offset
		return -dir
	else:
		return Vector3.ZERO

func avoidance() -> Vector3:
	if intent.is_colliding():
		enable_rays(true)
		return get_average_unobstructed_direction()
	else:
		enable_rays(false)
		return Vector3.ZERO
	
func get_nearby_boids() -> Array:
	var result: Array = []
	for body in detectionZone.get_overlapping_bodies():
		if body is KinematicBody:
			result.append(body)
	return result
	
func steer_towards(vector: Vector3) -> Vector3:
	return vector.normalized() * BoidProperties.max_speed - velocity

func get_average_unobstructed_direction() -> Vector3:
	var avg := Vector3.ZERO
	var best_hit = intent.get_cast_to()
	for ray in collisionRays.get_children():
		var dir: Vector3 = ray.get_cast_to()
		if ray.is_colliding() && ray.get_collider() is StaticBody:
			avg -= dir
		else:
			avg += dir
	return avg / collisionRays.get_children().size() #all are hit, return the best one

func enable_rays(enabled: bool) -> void:
	for ray in collisionRays.get_children():
		ray.set_enabled(enabled)

#Generate collision rays using golden ratio sunflower projection.
#Then prune using dot product of cast position compared to transform basis of z-axis
func generate_collision_rays() -> void:
	for n in BoidProperties.num_collision_rays:
		var phi: float = acos(1 - 2 * (n + BoidProperties.turn_fraction) / BoidProperties.num_collision_rays)
		var theta: float = PI * (1 + pow(5, BoidProperties.turn_fraction)) * (n + BoidProperties.turn_fraction)
		var x = sin(phi) * cos(theta)
		var y = sin(phi) * sin(theta)
		var z = cos(phi)
		var ray = make_ray(Vector3(x, y, z), BoidProperties.collision_depth, false)
		if ray.get_cast_to().dot(Vector3.FORWARD) > BoidProperties.look_back:
			collisionRays.add_child(ray)

#Create a ray, given a casting_position and flag it as enabled or disabled.
func make_ray(casting_pos: Vector3, length: float, enabled: bool) -> RayCast:
	var ray = RayCast.new()
	ray.set_cast_to(casting_pos * length)
	ray.set_enabled(enabled)
	return ray
