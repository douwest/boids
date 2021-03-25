extends KinematicBody
class_name Boid

var direction = Vector3.FORWARD
var velocity = Vector3(-0.1,0,-1)

onready var collisionRays = $CollisionRays
onready var detectionZone = $DetectionZone
onready var debug = $Debug
onready var geom = $Debug/ImmediateGeometry
onready var velocity_ray = make_ray(Vector3(0,0,0), 1, true)

func _ready() -> void:
	$Debug.add_child(velocity_ray)
#	for n in BoidUtils.ray_directions.size():
#		geom.begin(Mesh.PRIMITIVE_LINES)
#		geom.add_vertex(collisionRays.transform.origin) 
#		geom.add_vertex(collisionRays.transform.origin + BoidUtils.ray_directions[n])	
#		geom.end()

func _physics_process(delta):
	var acceleration = Vector3.ZERO
	var nearby_boids = get_nearby_boids()

	var average_offset = Vector3.ZERO
	var average_heading = Vector3.ZERO

	var cohesion_direction = Vector3.ZERO
	var separation_direction = Vector3.ZERO
	var alignment_direction = Vector3.ZERO

	var number_of_boids = nearby_boids.size()
	
	if number_of_boids > 0:
		for boid in nearby_boids:
			average_offset += boid.global_transform.origin
			average_heading += boid.direction
		average_offset /= number_of_boids

		cohesion_direction = average_offset - global_transform.origin
		separation_direction = -(average_offset - global_transform.origin)
		alignment_direction = average_heading.normalized()

	var cohesion_force = steer_towards(cohesion_direction) * BoidProperties.cohesion_weight	
	var alignment_force = steer_towards(alignment_direction) * BoidProperties.alignment_weight
	var separation_force = steer_towards(separation_direction) * BoidProperties.separation_weight
	var avoidance_force = steer_towards(avoidance(direction)) * BoidProperties.avoidance_weight
		
	acceleration += cohesion_force
	acceleration += alignment_force
	acceleration += separation_force
	acceleration += avoidance_force
	
	velocity += acceleration * delta
	var speed = velocity.length()
	direction = velocity.normalized()
	speed = clamp(speed, BoidProperties.min_speed, BoidProperties.max_speed)
	velocity = direction * speed
	var turn_speed = clamp((direction * direction).length(), BoidProperties.min_turn_speed, BoidProperties.max_turn_speed)
	velocity_ray.set_cast_to((global_transform.origin + direction) * 3)
	
	"""
	it experiences gimbal lock when it has been rotated and is pointing to the -z direction
	"""
	#print('avoid: ', avoidance_force, 'dir: ', direction, 'vel: ', velocity, 'turn: ', turn_speed)
	move_and_collide(velocity * delta)
	smooth_rotate(direction, turn_speed)

func smooth_rotate(dir: Vector3, turn_speed: float):
	var target = transform.origin + dir
	var current_basis = Quat(transform.basis)
	var new_transform = transform.looking_at(target, Vector3.UP)
	var new_basis = Quat(new_transform.basis)
	var rotated_basis = current_basis.slerp(new_basis, turn_speed)
	transform.basis = Basis(rotated_basis)

func avoidance(direction: Vector3) -> Vector3:
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(transform.origin, transform.origin + direction * 2, [self])
	if result:
		#print('colliding!')
		return get_average_unobstructed_direction()
	else:
		return Vector3.ZERO

func get_nearby_boids() -> Array:
	var result: Array = []
	for body in detectionZone.get_overlapping_bodies():
		if body is KinematicBody:
			result.append(body)
		if result.size() > 5:
			break
	return result

func steer_towards(vector: Vector3) -> Vector3:
	return vector.normalized() * BoidProperties.max_speed - velocity

func get_average_unobstructed_direction() -> Vector3:
	var avg := Vector3.ZERO
	var space_state = get_world().direct_space_state	
	for dir in BoidUtils.ray_directions:
		#print(dir)
		var result = space_state.intersect_ray(transform.origin, transform.origin + dir, [self])
		#print('intersect ray result: ', result)
		if !result:
			avg += dir
	#print('avg: ', avg)
	return avg
	
#Create a ray, given a casting_position and flag it as enabled or disabled.
func make_ray(casting_pos: Vector3, length: float, enabled: bool) -> RayCast:
	var ray = RayCast.new()
	ray.set_cast_to(casting_pos * length)
	ray.set_enabled(enabled)
	return ray
