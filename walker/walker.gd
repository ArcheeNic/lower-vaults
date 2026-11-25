extends CharacterBody3D

signal exit_requested
signal run_started(rules: Expedition.Rules, map_size: Expedition.MapSize, room: String)
signal run_ended

const Expedition := preload("res://world/expedition.gd")
const WalkInterface := preload("res://walker/walk_interface.gd")
const OPTIONS_PATH := "user://walk_settings.cfg"
const WALK_SPEED := 3.0
const RUN_SPEED := 5.25
const BODY_HEIGHT := 1.78
const EYE_HEIGHT := 1.62

enum Mode { ENTRANCE, WALK, PAUSE, RESULT }
var mode := Mode.ENTRANCE
var rules := Expedition.Rules.SANDBOX
var travel_multiplier := 1.0
var sensitivity := 1.0
var volume := 0.8
var footstep_volume := 0.8
var surface: Node3D
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
	capsule.height = BODY_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = capsule.height * 0.5
	add_child(collider)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = EYE_HEIGHT
	camera.fov = 72.0
	camera.near = 0.055
	camera.far = 87.0
	camera.current = true
	add_child(camera)
	_load_settings()
	interface = WalkInterface.new()
	add_child(interface)
	interface.configure(sensitivity, volume, footstep_volume)
	interface.start_requested.connect(start_run)
	interface.resume_requested.connect(enter_walk)
	interface.menu_requested.connect(return_to_menu)
	interface.language_changed.connect(func(locale: String):
		_apply_language(locale)
		_save_settings())
	interface.exit_requested.connect(exit_requested.emit)
	interface.sensitivity_changed.connect(_set_sensitivity)
	interface.volume_changed.connect(_set_volume)
	interface.steps_changed.connect(func(value: float): footstep_volume = value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func start_run(new_rules: Expedition.Rules, map_size: Expedition.MapSize, room := "") -> void:
	if mode != Mode.ENTRANCE and mode != Mode.RESULT:
		return
	rules = new_rules
	get_tree().paused = false
	_look_remaining = Vector2.ZERO
	_foot_phase = 0.0
	_bob = 0.0
	camera.position.y = EYE_HEIGHT
	camera.rotation.x = .055
	velocity = Vector3.ZERO
	mode = Mode.WALK
	run_started.emit(rules, map_size, room)
	interface.show_walk(true, rules)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func enter_walk() -> void:
	if mode == Mode.ENTRANCE:
		start_run(Expedition.Rules.NORMAL, interface.selected_size())
		return
	if mode != Mode.PAUSE:
		return
	get_tree().paused = false
	_save_settings()
	mode = Mode.WALK
	interface.show_walk(false, rules)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_walking() -> bool:
	return mode == Mode.WALK


func finish_run(won := true) -> void:
	if mode != Mode.WALK or rules == Expedition.Rules.SANDBOX:
		return
	mode = Mode.RESULT
	run_ended.emit()
	get_tree().paused = true
	_look_remaining = Vector2.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interface.show_result(won, rules)


func return_to_menu() -> void:
	if mode != Mode.PAUSE and mode != Mode.RESULT:
		return
	var ended_from_pause := mode == Mode.PAUSE
	_save_settings()
	mode = Mode.ENTRANCE
	rules = Expedition.Rules.SANDBOX
	get_tree().paused = false
	if ended_from_pause:
		run_ended.emit()
	interface.show_entrance()


func pause_walk() -> void:
	if mode != Mode.WALK:
		return
	mode = Mode.PAUSE
	_look_remaining = Vector2.ZERO
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interface.show_pause(rules)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		pause_walk()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and mode != Mode.ENTRANCE:
			if mode == Mode.WALK:
				pause_walk()
			elif mode == Mode.PAUSE:
				enter_walk()
			else:
				return_to_menu()
			get_viewport().set_input_as_handled()
			return
	if mode == Mode.WALK and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_remaining += event.screen_relative * sensitivity * 0.0021


func _unhandled_input(event: InputEvent) -> void:
	if mode != Mode.ENTRANCE or get_viewport().gui_get_focus_owner():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			enter_walk()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if mode != Mode.WALK:
		return
	var angle := _look_remaining * (1.0 - exp(-43.0 * delta))
	_look_remaining -= angle
	rotate_object_local(Vector3.UP, -angle.x)
	camera.rotation.x = clampf(camera.rotation.x - angle.y, deg_to_rad(-85.0), deg_to_rad(85.0))


func _physics_process(delta: float) -> void:
	if mode != Mode.WALK:
		return
	var axis := Vector2(
		float(_pressed(KEY_D, KEY_RIGHT)) - float(_pressed(KEY_A, KEY_LEFT)),
		float(_pressed(KEY_S, KEY_DOWN)) - float(_pressed(KEY_W, KEY_UP))
	).limit_length()
	var speed := RUN_SPEED if Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED
	var desired := global_basis * Vector3(axis.x, 0, axis.y) * speed * travel_multiplier
	var normal_speed := velocity.dot(up_direction)
	var tangent := velocity.slide(up_direction).move_toward(desired,17.0*delta)
	var grounded := is_on_floor()
	normal_speed = minf(normal_speed,-_gravity*delta) if grounded else normal_speed-_gravity*delta
	velocity = tangent + up_direction*normal_speed
	var before := global_position
	move_and_slide()
	if is_instance_valid(surface) and surface.has_method("fold_between"):
		var shift: float = surface.fold_between(surface.to_local(before),surface.to_local(global_position))
		if shift != 0.:
			global_position += surface.global_basis.y*shift
			reset_physics_interpolation()
	if grounded and not is_on_floor():
		apply_floor_snap()
	if is_on_floor():
		var probe := PhysicsRayQueryParameters3D.create(global_position+up_direction*.28,global_position-up_direction*.56,1,[get_rid()])
		var ground := get_world_3d().direct_space_state.intersect_ray(probe)
		if not ground.is_empty() and ground.collider.has_meta("walk_surface"):
			surface = ground.collider.get_meta("walk_surface")
	if is_instance_valid(surface):
		var new_up: Vector3 = surface.up_at(global_position) if surface.has_method("up_at") else surface.global_basis.y
		align_up(new_up)
	var ground_speed := get_real_velocity().slide(up_direction).length() if is_on_floor() else 0.0
	_foot_phase += ground_speed * delta * 3.6
	_bob = move_toward(_bob, minf(ground_speed / WALK_SPEED, 1.0), 4.5 * delta)
	camera.position.y = EYE_HEIGHT + sin(_foot_phase) * 0.012 * _bob


func align_up(normal: Vector3) -> void:
	if up_direction.distance_squared_to(normal) < .00000001:
		return
	var turn := Basis(Quaternion(up_direction, normal))
	global_basis = (turn * global_basis).orthonormalized()
	velocity = turn * velocity
	up_direction = normal


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
	var locale := TranslationServer.get_locale()
	if settings.load(OPTIONS_PATH) == OK:
		sensitivity = clampf(float(settings.get_value("controls", "sensitivity", sensitivity)), 0.25, 3.0)
		volume = clampf(float(settings.get_value("audio", "volume", volume)), 0.0, 1.0)
		footstep_volume = clampf(float(settings.get_value("audio", "footstep_volume", footstep_volume)), 0.0, 1.0)
		locale = str(settings.get_value("interface", "language", locale))
	_apply_language(locale)
	_set_volume(volume)


func _apply_language(locale: String) -> void:
	var language := TranslationServer.standardize_locale(locale).get_slice("_", 0)
	match language:
		"zh": language = "zh_Hans"
		"pt": language = "pt_BR"
	TranslationServer.set_locale(language if WalkInterface.LANGUAGES.has(language) else "en")
	get_window().title = tr("Нижние своды")


func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("controls", "sensitivity", sensitivity)
	settings.set_value("audio", "volume", volume)
	settings.set_value("audio", "footstep_volume", footstep_volume)
	settings.set_value("interface", "language", TranslationServer.get_locale())
	settings.save(OPTIONS_PATH)


func _exit_tree() -> void:
	if mode == Mode.PAUSE or mode == Mode.RESULT:
		_save_settings()
		get_tree().paused = false
	if is_inside_tree() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
