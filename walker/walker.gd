extends CharacterBody3D

signal exit_requested

const WalkInterface := preload("res://walker/walk_interface.gd")
const OPTIONS_PATH := "user://walk_settings.cfg"
const WALK_SPEED := 3.0
const RUN_SPEED := 5.25
const EYE_HEIGHT := 1.62

enum Mode { ENTRANCE, WALK, PAUSE }
var mode := Mode.ENTRANCE
var sensitivity := 1.0
var volume := 0.8
var footstep_volume := 0.8
var camera: Camera3D
var interface: CanvasLayer
var _look_remaining := Vector2.ZERO
var _foot_phase := 0.0
var _bob := 0.0
var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	floor_snap_length = 0.4
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(49)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.29
	capsule.height = 1.78
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = capsule.height * 0.5
	add_child(collider)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = EYE_HEIGHT
	camera.fov = 72.0
	camera.near = 0.055
	camera.far = 650.0
	camera.current = true
	add_child(camera)
	_load_settings()
	interface = WalkInterface.new()
	add_child(interface)
	interface.configure(sensitivity, volume, footstep_volume)
	interface.enter_requested.connect(enter_walk)
	interface.exit_requested.connect(exit_requested.emit)
	interface.sensitivity_changed.connect(_set_sensitivity)
	interface.volume_changed.connect(_set_volume)
	interface.steps_changed.connect(func(value: float): footstep_volume = value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func enter_walk() -> void:
	if mode == Mode.WALK:
		return
	var first_entry := mode == Mode.ENTRANCE
	if mode == Mode.PAUSE:
		get_tree().paused = false
		_save_settings()
	mode = Mode.WALK
	interface.show_walk(first_entry)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_walking() -> bool:
	return mode == Mode.WALK


func pause_walk() -> void:
	if mode != Mode.WALK:
		return
	mode = Mode.PAUSE
	_look_remaining = Vector2.ZERO
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interface.show_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		pause_walk()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and mode != Mode.ENTRANCE:
			if mode == Mode.WALK:
				pause_walk()
			else:
				enter_walk()
			get_viewport().set_input_as_handled()
			return
		if mode == Mode.ENTRANCE and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			enter_walk()
			get_viewport().set_input_as_handled()
			return
	if mode == Mode.ENTRANCE and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			enter_walk()
			get_viewport().set_input_as_handled()
	elif mode == Mode.WALK and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_remaining += event.screen_relative * sensitivity * 0.0021


func _process(delta: float) -> void:
	if mode != Mode.WALK:
		return
	var angle := _look_remaining * (1.0 - exp(-43.0 * delta))
	_look_remaining -= angle
	rotate_y(-angle.x)
	camera.rotation.x = clampf(camera.rotation.x - angle.y, deg_to_rad(-85.0), deg_to_rad(85.0))


func _physics_process(delta: float) -> void:
	if mode != Mode.WALK:
		return
	var axis := Vector2(
		float(_pressed(KEY_D, KEY_RIGHT)) - float(_pressed(KEY_A, KEY_LEFT)),
		float(_pressed(KEY_S, KEY_DOWN)) - float(_pressed(KEY_W, KEY_UP))
	).limit_length()
	var speed := RUN_SPEED if Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED
	var desired := global_basis * Vector3(axis.x, 0, axis.y) * speed
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(Vector2(desired.x, desired.z), 17.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()
	var ground_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length() if is_on_floor() else 0.0
	_foot_phase += ground_speed * delta * 3.6
	_bob = move_toward(_bob, minf(ground_speed / WALK_SPEED, 1.0), 4.5 * delta)
	camera.position.y = EYE_HEIGHT + sin(_foot_phase) * 0.012 * _bob


func _pressed(key: Key, alternate: Key) -> bool:
	return Input.is_physical_key_pressed(key) or Input.is_physical_key_pressed(alternate)


func _set_sensitivity(value: float) -> void:
	sensitivity = value


func _set_volume(value: float) -> void:
	volume = value
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master, is_zero_approx(volume))
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(volume, 0.001)))


func get_footstep_volume() -> float:
	return footstep_volume


func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(OPTIONS_PATH) == OK:
		sensitivity = clampf(float(settings.get_value("controls", "sensitivity", sensitivity)), 0.25, 3.0)
		volume = clampf(float(settings.get_value("audio", "volume", volume)), 0.0, 1.0)
		footstep_volume = clampf(float(settings.get_value("audio", "footstep_volume", footstep_volume)), 0.0, 1.0)
	_set_volume(volume)


func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("controls", "sensitivity", sensitivity)
	settings.set_value("audio", "volume", volume)
	settings.set_value("audio", "footstep_volume", footstep_volume)
	settings.save(OPTIONS_PATH)


func _exit_tree() -> void:
	if mode == Mode.PAUSE:
		_save_settings()
		get_tree().paused = false
	if is_inside_tree() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
