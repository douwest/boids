extends Spatial

export var look_around_speed = 0.05
export var auto_rotate = false

func _physics_process(delta):
	if auto_rotate:
		rotate_object_local(Vector3(0,1,0), PI/6 * look_around_speed / 5)

func _input(event):
	if Input.is_action_pressed("ui_right"):
		rotate_object_local(Vector3(0,1,0), PI/6 * look_around_speed)	
	if Input.is_action_pressed("ui_left"):
		rotate_object_local(Vector3(0,1,0), -PI/6 * look_around_speed)
