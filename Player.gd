extends CharacterBody3D

# References
@onready var camera = $Camera3D

# Constants 
const SPEED = 10.0
const JUMP_VELOCITY = 10.0
const CAMERA_ROTATION_SPEED = 0.005
const MAXIMUM_CAMERA_ROTATION = PI/2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

# Functions
func _ready():
	# Captures the mouse to the middle of the screen
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Handling camera movement
		rotate_y(-event.relative.x * CAMERA_ROTATION_SPEED)
		camera.rotate_x(-event.relative.y * CAMERA_ROTATION_SPEED)
		camera.rotation.x = clamp(camera.rotation.x, -MAXIMUM_CAMERA_ROTATION, MAXIMUM_CAMERA_ROTATION)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
