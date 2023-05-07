extends CharacterBody3D

# Signals
signal health_changed(health_value)


# References
@onready var camera = $Camera3D
@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

var health = 3

# Constants 
const SPEED = 10.0
const JUMP_VELOCITY = 10.0
const CAMERA_ROTATION_SPEED = 0.005
const MAXIMUM_CAMERA_ROTATION = PI/2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

# Functions
func _ready():
	if not is_multiplayer_authority(): return
	
	# Captures the mouse to the middle of the screen
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	# Handling camera movement
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * CAMERA_ROTATION_SPEED)
		camera.rotate_x(-event.relative.y * CAMERA_ROTATION_SPEED)
		camera.rotation.x = clamp(camera.rotation.x, -MAXIMUM_CAMERA_ROTATION, MAXIMUM_CAMERA_ROTATION)
		
	# Shooting animation logic
	if Input.is_action_just_pressed("shoot") \
			and animation_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Animation logic
	if animation_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animation_player.play("move")
	else:
		animation_player.play("idle")

	move_and_slide()

@rpc("call_local") # we want to call it remotely (RPC) and locally (call local)
func play_shoot_effects():
	# Stops any animation and plays shooting animation
	animation_player.stop()
	animation_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer") # we are calling it from the player that is dealing damage, so 
# it doesn't have the authority
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if animation_player.current_animation == "shoot":
		animation_player.play("idle")
