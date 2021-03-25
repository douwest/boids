extends Spatial


onready var Boid = preload("res://Animals/Fish.tscn")
onready var boids = $Boids

export var num_boids = 15

func _ready():
	randomize()
	for n in num_boids:
		var boid = Boid.instance()
		position_random(boid)

func position_random(boid: Boid) -> void:
	var x = rand_range(-2, 2)
	var y = rand_range(1, 5)
	var z = rand_range(-2, -2)
	boids.add_child(boid)
	boid.transform.origin = Vector3(x, y, z)
	while boid.test_move(boid.transform, Vector3(x, y, z)):
		x = rand_range(-2, 2)
		y = rand_range(1, 5)
		z = rand_range(-2, 1)
		boid.transform.origin = Vector3(x, y, z)
