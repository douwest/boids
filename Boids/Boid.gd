extends KinematicBody
class_name Boid

export var speed = 1
export var numCollisionRays = 5
export var collision_depth = 1
export var turn_fraction = .5
export var turn_speed = 10

var direction = Vector3.FORWARD
var velocity = Vector3.FORWARD

onready var collisionRays = $CollisionRays
onready var mesh = $MeshInstance
onready var rays: Array
onready var intent = make_ray(Vector3.FORWARD, true)

func _ready() -> void:
	randomize()
	generate_collision_rays(turn_fraction)
	intent.set_collision_mask(0)
	add_child(intent)

func _physics_process(delta) -> void:
	#translate the transform of the boid by the velocity times delta (new pos vec3)
	translate(velocity * speed * delta)
	direction = get_first_unobstructed_direction()
	rotate_x(sin(direction.x) * delta * turn_speed)
	rotate_y(sin(direction.y) * delta * turn_speed)

#Return the first unobstructed ray, or the one with the longest length.
#Returned as a direction vector local to the boid position.
func get_first_unobstructed_direction() -> Vector3:
	var furthest = 0
	var best_hit = Vector3.FORWARD
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

#Get the local direction vector of the provided ray
func get_direction(ray: RayCast) -> Vector3:
	return get_translation().direction_to(ray.get_cast_to()).normalized()

#Return the length of the ray that hit something, w.r.t. global coordinates
func get_hit_length(ray: RayCast) -> float:
	return get_translation().distance_to(ray.get_collision_point())

#Generate collision rays using golden ratio sunflower projection.
#Then prune using a z-plane.
func generate_collision_rays(turn: int) -> void:
	var forward = make_ray(Vector3.FORWARD, true)
	collisionRays.add_child(forward)
	
	for n in numCollisionRays:
		var phi: float = acos(1 - 2 * (n + turn_fraction) / numCollisionRays)
		var theta: float = PI * (1 + pow(5, turn_fraction)) * (n + turn_fraction)
		var x = sin(phi) * cos(theta)
		var y = sin(phi) * sin(theta)
		var z = cos(phi)
		var ray = make_ray(Vector3(x, y, z), true)
		collisionRays.add_child(ray)
	
	for ray in collisionRays.get_children():
		if ray.get_cast_to().z >= 0.5: #prune all rays behind this plane
			ray.queue_free()

#Create a ray, given a casting_position and flag it as enabled or disabled.
func make_ray(casting_pos: Vector3, enabled: bool) -> RayCast:
	var ray = RayCast.new()
	ray.set_enabled(enabled)
	ray.set_cast_to(casting_pos * collision_depth)
	return ray
