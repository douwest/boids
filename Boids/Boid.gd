extends KinematicBody
class_name Boid

export var speed = 1
export var numCollisionRays = 25
export var collision_depth = 2
export var turn_fraction = .5
export var turn_speed = 1.0
export var prune_z = 0.1 #when to prune from z (sphere > cone raycast parameter)

export var cohesion_weight: float = 0.4
export var avoidance_weight: float = 1
export var alignment_weight: float = 0.3
export var separation_weight: float = 0.1

var direction = Vector3.FORWARD
var velocity = Vector3.FORWARD
var rotate_x = 0
var rotate_y = 0

onready var mesh = $MeshInstance
onready var collisionRays = $CollisionRays
onready var collisionShape = $CollisionShape
onready var detectionZone = $DetectionZone
onready var intent = make_ray(Vector3.FORWARD, collision_depth, true)

func _ready() -> void:
	generate_collision_rays()
	add_child(intent)

func _physics_process(delta) -> void:
	var acceleration = Vector3.ZERO	
	var old_dir = direction
	var nearby_boids = get_nearby_boids()
	
	var cohesion_force = steer_towards(cohesion(nearby_boids)) * cohesion_weight	
	var alignment_force = steer_towards(alignment(nearby_boids)) * alignment_weight
	var separation_force = steer_towards(separation(nearby_boids)) * separation_weight
	var avoidance_force = steer_towards(avoidance()) * avoidance_weight
	
	acceleration += cohesion_force
	acceleration += alignment_force
	acceleration += separation_force
	acceleration += avoidance_force
	
	velocity += acceleration * delta
	direction = velocity.normalized()
	
	velocity = direction * speed
	velocity = move_and_slide(velocity)
	turn_speed = direction.length_squared()
	transform.basis = Basis()
	transform.basis.z = -(old_dir.slerp(direction, turn_speed)).normalized()
	transform.orthonormalized()

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
		return Vector3.FORWARD
	
func get_nearby_boids() -> Array:
	var result: Array = []
	for body in detectionZone.get_overlapping_bodies():
		if body is KinematicBody:
			result.append(body)
	return result
	
func steer_towards(vector: Vector3) -> Vector3:
	return vector.normalized() * speed - velocity

"""
func avoid_collisions(delta) -> Vector3:
	if intent.is_colliding():
		enable_rays(true)
		direction = get_average_unobstructed_direction()
		rotate_x += atan(direction.x) * delta * turn_speed
		rotate_y += atan(direction.y) * delta * turn_speed
		transform.basis = Basis()
		rotate_object_local(Vector3(0,1,0), rotate_x)
		rotate_object_local(Vector3(1,0,0), rotate_y)
		velocity = -transform.basis.z * speed * 0.7
	else:
		enable_rays(false)
		velocity = -transform.basis.z * speed
	velocity = move_and_slide(velocity)
"""

func get_average_unobstructed_direction() -> Vector3:
	var avg := Vector3.ZERO
	var best_hit = intent.get_cast_to()
	for ray in collisionRays.get_children():
		var dir: Vector3 = ray.get_cast_to()
		if ray.is_colliding():
			avg -= dir
		else:
			avg += dir
	return avg / collisionRays.get_children().size() #all are hit, return the best one

func enable_rays(enabled: bool) -> void:
	for ray in collisionRays.get_children():
		ray.set_enabled(enabled)

#Get the local direction vector of the provided ray
func get_direction(ray: RayCast) -> Vector3:
	return get_translation().direction_to(ray.get_cast_to()).normalized()

#Return the length of the ray that hit something, w.r.t. global coordinates
func get_hit_length(ray: RayCast) -> float:
	return get_translation().distance_to(ray.get_collision_point())

#Generate collision rays using golden ratio sunflower projection.
#Then prune using dot product of cast position compared to transform basis of z-axis
func generate_collision_rays() -> void:
	for n in numCollisionRays:
		var phi: float = acos(1 - 2 * (n + turn_fraction) / numCollisionRays)
		var theta: float = PI * (1 + pow(5, turn_fraction)) * (n + turn_fraction)
		var x = sin(phi) * cos(theta)
		var y = sin(phi) * sin(theta)
		var z = cos(phi)
		var ray = make_ray(Vector3(x, y, z), collision_depth, false)
		if ray.get_cast_to().dot(transform.basis.z) < prune_z:
			collisionRays.add_child(ray)

#Create a ray, given a casting_position and flag it as enabled or disabled.
func make_ray(casting_pos: Vector3, length: float, enabled: bool) -> RayCast:
	var ray = RayCast.new()
	ray.set_cast_to(casting_pos * length)
	ray.set_enabled(enabled)
	return ray
