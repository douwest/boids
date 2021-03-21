extends Spatial


onready var Boid = preload("res://Boids/Boid.tscn")
onready var boids = $Boids

export var num_boids = 15

func _ready():
	randomize()
	for n in num_boids:
		var boid = Boid.instance()
		position_random(boid)
		rotate_random(boid)

func rotate_random(boid: Boid) -> void:
	boid.rotate_object_local(Vector3(0,1,0), deg2rad(randi() % 360))
	boid.rotate_object_local(Vector3(1,0,0), deg2rad(randi() % 360))

func position_random(boid: Boid) -> void:
	var x = rand_range(-2, 2)
	var y = rand_range(1, 5)
	var z = rand_range(-2, 1)
	boids.add_child(boid)
	boid.global_transform.origin = Vector3(x, y, z)
	while boid.test_move(boid.transform, Vector3(x, y, z)):
		x = rand_range(-2, 2)
		y = rand_range(1, 5)
		z = rand_range(-2, 1)
		boid.global_transform.origin = Vector3(x, y, z)
