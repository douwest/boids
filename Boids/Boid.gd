extends KinematicBody
class_name Boid

var direction = Vector3.FORWARD
var velocity = Vector3(-0.1,0,-1)
var speed = 0

onready var collisionRays = $CollisionRays
onready var detectionZone = $DetectionZone

"""
TODO:
	- 	Add periodic functions to cohesion/alignment/separation weights to 
		simulate fish school behaviours. (0.5 + sin(0.5 + t) + cos(0.5 + t))
	-	Low/high separation leads to schooling behaviour 
	-	Add targeting behaviour (for chasing player etc.)
"""


func _ready():
	speed = (BoidProperties.min_speed + BoidProperties.max_speed) / 2

func _physics_process(delta):
	var space_state = get_world().direct_space_state
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
	var avoidance_force = steer_towards(avoidance(direction, space_state)) * BoidProperties.avoidance_weight
		
	acceleration += cohesion_force
	acceleration += alignment_force
	acceleration += separation_force
	acceleration += avoidance_force
	
	velocity += acceleration * delta
	var speed = velocity.length() # this is always between 0 and 1. This should be scaled\
	direction = velocity.normalized()
	speed = clamp(speed, BoidProperties.min_speed, BoidProperties.max_speed)
	velocity = direction * speed
	move_and_collide(velocity * delta)
	smooth_rotate(direction, 1)

func steer_towards(vector: Vector3) -> Vector3:
	return vector.normalized() * BoidProperties.max_speed - velocity
	
func smooth_rotate(dir: Vector3, turn_speed: float):
	var target = transform.origin + dir
	var current_basis = Quat(transform.basis)
	var rotated_transform = transform.looking_at(target, Vector3.UP)
	var rotated_basis = Quat(rotated_transform.basis)
	var interpolated_basis = current_basis.slerp(rotated_basis, turn_speed)
	transform.basis = Basis(interpolated_basis)

func avoidance(direction: Vector3, space_state: PhysicsDirectSpaceState) -> Vector3:
	var result = space_state.intersect_ray(transform.origin, transform.origin + direction * 2, [self])
	if result:
		return get_average_unobstructed_direction(space_state)
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

func get_average_unobstructed_direction(space_state: PhysicsDirectSpaceState) -> Vector3:
	var avg := Vector3.ZERO
	for dir in BoidUtils.ray_directions:
		var result = space_state.intersect_ray(transform.origin, transform.origin + dir, [self])
		if !result:
			avg += dir
	return avg
