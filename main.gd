extends Node3D

const PLAYER_HEIGHT := 1.65
const HAND_RADIUS := 0.10
const MAX_HAND_SPEED := 8.0
const GRAVITY := 9.8

var body: CharacterBody3D
var left_hand: Area3D
var right_hand: Area3D
var left_controller: XRController3D
var right_controller: XRController3D
var velocity := Vector3.ZERO
var grabbing_left := false
var grabbing_right := false
var last_left := Vector3.ZERO
var last_right := Vector3.ZERO
var initialized := false

func _ready() -> void:
	_setup_environment()
	_setup_xr()
	_setup_player()
	_setup_hands()
	initialized = true

func _physics_process(delta: float) -> void:
	if not initialized:
		return
	var left_pos := left_hand.global_position
	var right_pos := right_hand.global_position
	var left_velocity: Vector3 = ((left_pos - last_left) / max(delta, 0.0001)).limit_length(MAX_HAND_SPEED)
	var right_velocity: Vector3 = ((right_pos - last_right) / max(delta, 0.0001)).limit_length(MAX_HAND_SPEED)
	var left_pressed := _grip_pressed(left_controller)
	var right_pressed := _grip_pressed(right_controller)

	if left_pressed and not grabbing_left and _hand_can_grab(left_hand):
		grabbing_left = true
	if right_pressed and not grabbing_right and _hand_can_grab(right_hand):
		grabbing_right = true
	if not left_pressed:
		grabbing_left = false
	if not right_pressed:
		grabbing_right = false

	var push_velocity := Vector3.ZERO
	var active_grabs := 0
	if grabbing_left:
		push_velocity -= left_velocity
		active_grabs += 1
	if grabbing_right:
		push_velocity -= right_velocity
		active_grabs += 1

	if active_grabs > 0:
		velocity = velocity.lerp(push_velocity / float(active_grabs), 0.45)
	else:
		velocity.y -= GRAVITY * delta
		velocity.x = lerp(velocity.x, 0.0, min(delta * 2.0, 1.0))
		velocity.z = lerp(velocity.z, 0.0, min(delta * 2.0, 1.0))

	if body.is_on_floor():
		velocity.y = max(velocity.y, 0.0)
	body.velocity = velocity
	body.move_and_slide()
	velocity = body.velocity
	last_left = left_pos
	last_right = right_pos

func _grip_pressed(controller: XRController3D) -> bool:
	if controller == null:
		return false
	return controller.is_button_pressed("grip") or controller.is_button_pressed("trigger_click")

func _hand_can_grab(hand: Area3D) -> bool:
	return hand.has_overlapping_bodies() or hand.has_overlapping_areas()

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.065, 0.085)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.70, 0.80)
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.1
	add_child(sun)

	_make_static_box(Vector3(0, -0.15, 0), Vector3(14, 0.3, 14), Color(0.16, 0.18, 0.21))
	_make_static_box(Vector3(0, 2.2, -4.5), Vector3(14, 4.5, 0.3), Color(0.20, 0.24, 0.29))
	_make_static_box(Vector3(-5, 2.0, 0), Vector3(0.3, 4.0, 8), Color(0.18, 0.25, 0.21))
	_make_static_box(Vector3(5, 2.0, 0), Vector3(0.3, 4.0, 8), Color(0.18, 0.25, 0.21))

	for i in range(6):
		var x := -4.0 + i * 1.6
		_make_static_box(Vector3(x, 0.7 + (i % 2) * 0.45, -1.0), Vector3(1.1, 1.4, 1.1), Color(0.28, 0.22, 0.16))

	_make_static_box(Vector3(0, 3.5, 2.2), Vector3(5.5, 0.25, 1.8), Color(0.24, 0.18, 0.28))
	_make_static_box(Vector3(-3.8, 2.8, 2.5), Vector3(1.4, 0.25, 3.2), Color(0.17, 0.24, 0.31))

func _make_static_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var static_body := StaticBody3D.new()
	static_body.position = pos
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	static_body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var primitive := BoxMesh.new()
	primitive.size = size
	mesh.mesh = primitive
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	static_body.add_child(mesh)
	add_child(static_body)
	return static_body

func _setup_xr() -> void:
	var openxr := XRServer.find_interface("OpenXR")
	if openxr:
		openxr.initialize()

	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	add_child(origin)

	var camera := XRCamera3D.new()
	camera.position = Vector3(0, PLAYER_HEIGHT, 0)
	origin.add_child(camera)

	left_controller = XRController3D.new()
	left_controller.tracker = "left_hand"
	left_controller.name = "LeftController"
	origin.add_child(left_controller)

	right_controller = XRController3D.new()
	right_controller.tracker = "right_hand"
	right_controller.name = "RightController"
	origin.add_child(right_controller)

func _setup_player() -> void:
	body = CharacterBody3D.new()
	body.name = "PlayerBody"
	body.position = Vector3(0, PLAYER_HEIGHT, 4.0)
	add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.25
	capsule.radius = 0.32
	collision.position.y = -0.45
	collision.shape = capsule
	body.add_child(collision)

func _setup_hands() -> void:
	left_hand = _make_hand("LeftHand", left_controller)
	right_hand = _make_hand("RightHand", right_controller)
	last_left = left_hand.global_position
	last_right = right_hand.global_position

func _make_hand(hand_name: String, controller: XRController3D) -> Area3D:
	var hand := Area3D.new()
	hand.name = hand_name
	hand.collision_layer = 2
	hand.collision_mask = 1
	hand.monitoring = true
	controller.add_child(hand)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HAND_RADIUS
	collision.shape = sphere
	hand.add_child(collision)
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = HAND_RADIUS
	sphere_mesh.height = HAND_RADIUS * 2.0
	mesh.mesh = sphere_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.55, 0.15)
	mesh.material_override = material
	hand.add_child(mesh)
	return hand
