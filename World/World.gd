extends Spatial


onready var Boid = preload("res://Boids/Boid.tscn")
onready var boids = $Boids

export var num_boids = 15

func _ready():
	randomize()
	for n in num_boids:
		var boid = Boid.instance()
		var x = rand_range(-2, 2)
		var y = rand_range(1, 5)
		var z = rand_range(-2, 1)
		boids.add_child(boid)
		boid.global_transform.origin = Vector3(x, y, z)

