extends KinematicBody
class_name Boid

export var speed = 2
export var numCollisionRays = 25
export var collision_depth = .4
export var turn_fraction = .5
export var turn_speed = 25
export var prune_z = 0.1 #when to prune from z (sphere > cone raycast parameter)

var direction = Vector3.FORWARD
var velocity = Vector3.FORWARD
var rotate_x = 0
var rotate_y = 0

onready var mesh = $MeshInstance
onready var collisionRays = $CollisionRays
onready var collisionShape = $CollisionShape
onready var intent = make_ray(Vector3.FORWARD, collision_depth * 1.5, true)

func _ready() -> void:
	generate_collision_rays()
	add_child(intent)

func _physics_process(delta) -> void:
	avoid_collisions(delta)

func avoid_collisions(delta) -> void:
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
#Then prune using a z-plane.
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


"""
NOT USED BUT DO NOT WANT TO REMOVE YET
"""
func avoid_collisions_dfs(delta) -> void:
	if intent.is_colliding():#test_move(transform, -transform.basis.z):
		enable_rays(true)
		direction = get_first_unobstructed_direction()
		rotate_x += atan(direction.x) * delta * turn_speed
		rotate_y += atan(direction.y) * delta * turn_speed
		transform.basis = Basis()
		rotate_object_local(Vector3(0,1,0), rotate_x)
		rotate_object_local(Vector3(1,0,0), rotate_y)
	else:
		enable_rays(false)
	velocity = -transform.basis.z * speed
	velocity = move_and_slide(velocity)


#Return the first unobstructed ray, or the one with the longest length.
#Returned as a direction vector local to the boid position.
func get_first_unobstructed_direction() -> Vector3:
	var furthest = 0
	var best_hit = intent.get_cast_to()
	for ray in collisionRays.get_children():
		var dir: Vector3 = ray.get_cast_to()
		if ray.is_colliding():
			var hit_distance = get_hit_length(ray)
			if hit_distance > furthest:
				furthest = hit_distance
				best_hit = dir
		else:
			return dir
	return best_hit #all are hit, return the best one
