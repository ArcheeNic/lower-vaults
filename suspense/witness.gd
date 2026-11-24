extends Node3D

const Presence := preload("res://suspense/presence.gd")
const SCRAPE := preload("res://sound/strain.ogg")

const SIGHT_MASK := 1 | preload("res://suspense/sight_geometry.gd").LAYER
const Trail := preload("res://suspense/footprint_trail.gd")

enum Phase { QUIET, ADVANCE, LEAVE }

const SPAWN_MIN := 5.0
const LEAVE_DISTANCE := 20.0
const GAZE_SECONDS := 5.0
const GAZE_COS := .95
const STOP_DISTANCE := 1.45

var tension := 0.0
var phase := Phase.QUIET
var _elapsed := 0.0
var _quiet_for := 9.4
var _gaze := 0.0
var _next_step := 0.0
var _opacity := 0.0
var _route := PackedVector3Array()
var _waypoint := 0
var _repath_in := 0.0
var _destination := Vector3.INF
var _player_rid: RID
var _rng := RandomNumberGenerator.new()

var _actor := Node3D.new()
var _presence := Presence.new()
var _foot_voices: Array[AudioStreamPlayer3D] = []
var _lead_voice := AudioStreamPlayer3D.new()
var _foot_index := 0
var _trail := Trail.new()
var _encounters := 0


func _ready() -> void:
	_rng.randomize()
	add_child(_actor)
	_actor.add_child(_presence)
	_actor.hide()
	# Each step stays where it rang while the next one advances through the hall.
	for i in 4:
		var foot := AudioStreamPlayer3D.new()
		foot.unit_size = 9.0
		foot.max_distance = 58.0
		foot.attenuation_filter_cutoff_hz = 3200
		foot.max_db = -3.0
		add_child(foot)
		_foot_voices.append(foot)
	_lead_voice.unit_size = 10
	_lead_voice.max_distance = 75
	add_child(_lead_voice)


func advance(delta: float, body: CharacterBody3D, walking: bool, made_step: bool) -> void:
	var camera := body.get_viewport().get_camera_3d()
	if not camera:
		return
	_player_rid = body.get_rid()
	var player := body.global_position
	_trail.record(delta, player, made_step)
	_elapsed += delta
	if phase == Phase.QUIET:
		tension = move_toward(tension, 0.0, delta * .3)
		if _elapsed >= _quiet_for:
			_try_spawn(body, camera)
		return

	var distance := player.distance_to(_actor.global_position)
	var focus := _actor.global_position + Vector3.UP * _presence.height * .61
	var observed := _in_gaze(camera)
	if phase == Phase.ADVANCE:
		_gaze = _gaze + delta if observed else 0.0
		if _gaze - GAZE_SECONDS > .000001 or distance > LEAVE_DISTANCE:
			phase = Phase.LEAVE
			_elapsed = 0.0
			_plan_retreat(player)
		else:
			_repath_in -= delta
			if _repath_in <= 0 and (player.distance_to(_destination) > .45 or _waypoint >= _route.size()):
				_set_route(_path(_actor.global_position, player))
				_destination = player
				_repath_in = .4

	var withdrawing := phase == Phase.LEAVE
	var want := 1.0 - smoothstep(.65, 3.0, _elapsed) if withdrawing else lerpf(.35, 1.0, 1.0 - smoothstep(2., 16., distance))
	tension = move_toward(tension, want, delta * .51)
	var moved := false
	if withdrawing or distance > STOP_DISTANCE or not _ray(focus, camera.global_position, SIGHT_MASK).is_empty():
		var speed := 1.85 if withdrawing else _presence.pursuit_speed(_elapsed, walking)
		moved = _follow(delta * speed)
	var toward := player - _actor.global_position
	if Vector2(toward.x, toward.z).length_squared() > .001:
		_actor.rotation.y = lerp_angle(_actor.rotation.y, atan2(toward.x,toward.z), minf(1.,delta*4.))
	_next_step -= delta
	if moved and _next_step <= 0:
		_step(lerpf(-9.,-1.,want), _rng.randf_range(.76,.92))
		_next_step = .78 * _presence.cadence
	_presence.pose(delta, moved, false, observed, withdrawing)
	_opacity = minf(want, _opacity) if withdrawing else move_toward(_opacity, 1.0, delta * 2.5)
	_presence.set_opacity(_opacity)
	if withdrawing and _elapsed >= 3.0:
		_actor.hide()
		phase = Phase.QUIET
		_elapsed = 0
		_quiet_for = _rng.randf_range(14., 25.)


func _in_gaze(camera: Camera3D) -> bool:
	var eye := camera.global_position
	var look := -camera.global_basis.z
	for fraction: float in [.61,.90,.30]:
		var point := _actor.global_position + Vector3.UP * (_presence.height*fraction)
		if look.dot(eye.direction_to(point)) > GAZE_COS and _ray(eye, point, SIGHT_MASK).is_empty():
			return true
	return false


func _path(start: Vector3, goal: Vector3) -> PackedVector3Array:
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(map, start, goal, true)


func _set_route(points: PackedVector3Array) -> void:
	_route = points
	_waypoint = 0


func _try_spawn(body: CharacterBody3D, camera: Camera3D) -> void:
	# A failed search stays silent and retries from the player's new position.
	_elapsed = 0.0
	_quiet_for = .6
	var player := body.global_position
	var ahead := -body.global_basis.z
	var candidates := PackedVector3Array()
	var entry := _trail.find_start(player, ahead)
	if _encounters % 2 == 1 and entry >= 0:
		candidates.append(_trail.position_at(entry))
	var hand := -1.0 if _rng.randf() < .5 else 1.0
	for angle in [.0, .37, -.55, .9, -1.3, 1.8, -2.4, PI]:
		for reach in [13., 8., 6.]:
			candidates.append(player + ahead.rotated(Vector3.UP, angle * hand) * reach)
	for sample in candidates:
		var hit := _ray(sample + Vector3.UP*2.8, sample - Vector3.UP*5.)
		if hit.is_empty() or hit.normal.y < .66:
			continue
		var foot: Vector3 = hit.position
		var distance := foot.distance_to(player)
		if distance < SPAWN_MIN or distance > LEAVE_DISTANCE:
			continue
		var points := _path(foot, player)
		if points.is_empty() or points[0].distance_to(foot) > .45 or points[-1].distance_to(player) > .65:
			continue
		if not _ray(foot + Vector3.UP*.12, foot + Vector3.UP*3.35).is_empty():
			continue
		if not _ray(camera.global_position, foot + Vector3.UP*1.25, SIGHT_MASK).is_empty():
			continue
		_presence.deal(_rng)
		_actor.global_position = foot
		_actor.rotation.y = atan2(player.x-foot.x,player.z-foot.z)
		_actor.reset_physics_interpolation()
		_set_route(points)
		_destination = player
		_repath_in = .4
		_gaze = 0.0
		_opacity = .15
		_presence.set_opacity(_opacity)
		_actor.show()
		phase = Phase.ADVANCE
		_encounters += 1
		_next_step = .25
		_lead_voice.stream = SCRAPE if _presence.kind == Presence.Kind.LANTERN else _presence.foot_voice
		_lead_voice.global_position = foot + Vector3.UP
		_lead_voice.volume_db = -6.5
		_lead_voice.play()
		return


func _plan_retreat(player: Vector3) -> void:
	var start := _actor.global_position
	var away := player.direction_to(start)
	away.y = 0
	away = away.normalized() if away.length_squared() > .001 else Vector3.FORWARD
	var best := PackedVector3Array()
	var best_score := -INF
	for angle in [0., .6, -.6, 1.3, -1.3, 2., -2., PI]:
		var points := _path(start, start + away.rotated(Vector3.UP,angle)*6.)
		if points.size() < 2:
			continue
		var score := points[-1].distance_to(player)
		if score > best_score:
			best = points
			best_score = score
	_set_route(best)


func _follow(budget: float) -> bool:
	var start := _actor.global_position
	var p := start
	while budget > 0. and _waypoint < _route.size():
		var target := _route[_waypoint]
		# A vertical navigation link joins the two copies of a folded landing.
		if _waypoint > 0 and absf(target.y-_route[_waypoint-1].y) > 5. and Vector2(target.x-p.x,target.z-p.z).length() < .4:
			p.y = target.y
		var offset := Vector2(target.x-p.x,target.z-p.z)
		var length := offset.length()
		var step := minf(budget, length)
		if length > .0001:
			p = p.lerp(target, step/length)
		budget -= step
		if length <= step:
			_waypoint += 1
		else:
			break
	if start.distance_squared_to(p) < .000001:
		return false
	var floor_hit := _ray(p + Vector3.UP*.32, p - Vector3.UP*.7)
	if floor_hit.is_empty():
		_repath_in = 0
		_destination = Vector3.INF
		return false
	_actor.global_position = floor_hit.position
	return true


func shift_origin(shift: Vector3) -> void:
	_trail.shift_origin(shift)
	_destination -= shift
	for i in _route.size():
		_route[i] -= shift
	for node: Node3D in [_actor, _lead_voice]:
		node.global_position -= shift
		node.reset_physics_interpolation()
	for voice in _foot_voices:
		voice.global_position -= shift
		voice.reset_physics_interpolation()


func _ray(from: Vector3, to: Vector3, mask := 1) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, [_player_rid])
	return get_world_3d().direct_space_state.intersect_ray(query)


func _step(gain: float, pitch: float) -> void:
	var voice := _foot_voices[_foot_index]
	_foot_index = (_foot_index + 1) % _foot_voices.size()
	voice.global_position = _actor.global_position + Vector3.UP * .15
	voice.stream = _presence.foot_voice
	voice.volume_db = gain
	voice.pitch_scale = pitch
	voice.play()
