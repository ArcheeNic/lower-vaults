extends Node3D

const Witness := preload("res://suspense/witness.gd")
const ROOMS: Array[AudioStreamOggVorbis] = [
	preload("res://sound/air.ogg"), preload("res://sound/cistern.ogg"),
	preload("res://sound/orbit.ogg"), preload("res://sound/machine.ogg")
]
const FOOT_BUS := &"Footfalls"
const LEVELS := [-12.0, -11.0, -10.5, -12.0]
const PRESSURE := preload("res://sound/pressure.ogg")
const SOLES: Array[AudioStream] = [
	preload("res://sound/stone_1.ogg"),
	preload("res://sound/stone_2.ogg"),
	preload("res://sound/stone_3.ogg"),
	preload("res://sound/stone_4.ogg"),
]
const STRAIN: AudioStream = preload("res://sound/strain.ogg")
const SETTLING: AudioStream = preload("res://sound/settling.ogg")

var _body: CharacterBody3D
var _last_position: Vector3
var _layers: Array[AudioStreamPlayer] = []
var _weights := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
var _mix := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
var _pressure: AudioStreamPlayer
var _witness := Witness.new()
var _footfalls: Array[AudioStreamPlayer3D] = []
var _far_voice: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()
var _next_foot := 0
var _last_sample := -1
var _left := false
var _stride := 0.0
var _moving := false
var _distant_in := 18.0


func _ready() -> void:
	_rng.randomize()
	for i in ROOMS.size():
		_layers.append(_loop(ROOMS[i], LEVELS[i] if i == 0 else -80.0))
	_pressure = _loop(PRESSURE, -80)
	add_child(_witness)
	if AudioServer.get_bus_index(FOOT_BUS) < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, FOOT_BUS)
		var felt := AudioEffectLowPassFilter.new()
		felt.cutoff_hz = 1950.0
		felt.resonance = .42
		AudioServer.add_bus_effect(bus, felt)
	for i in 4:
		var foot := _new_voice(1.6, 16.0)
		foot.bus = FOOT_BUS
		_footfalls.append(foot)
	_far_voice = _new_voice(7.0, 60.0)
	_distant_in = _rng.randf_range(13.0, 21.0)


func bind_player(body: CharacterBody3D, route: Callable) -> void:
	_witness.route_between_surfaces = route
	_body = body
	_last_position = body.global_position
	_moving = false
	_stride = .58


func set_realms(weights: PackedFloat32Array) -> void:
	if weights.size() == ROOMS.size():
		_weights = weights.duplicate()


func shift_origin(shift: Vector3) -> void:
	_last_position -= shift
	for foot in _footfalls:
		foot.global_position -= shift
		foot.reset_physics_interpolation()
	_far_voice.global_position -= shift
	_far_voice.reset_physics_interpolation()
	_witness.shift_origin(shift)


func get_tension() -> float:
	return _witness.tension


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return
	var offset := _body.global_position - _last_position
	_last_position = _body.global_position
	var in_walk := not _body.has_method("is_walking") or bool(_body.call("is_walking"))
	var travel := offset.slide(_body.up_direction).length()
	var walking := in_walk and _body.is_on_floor() and travel > delta * .21 and travel < 2.5
	var made_step := false
	if walking:
		var speed := travel / delta
		var pace := lerpf(1.18, 1.62, clampf((speed - 1.3) / 3.3, 0.0, 1.0))
		_stride += travel
		if _stride >= pace:
			_stride -= pace
			_emit_footstep(speed)
			made_step = true
	elif _moving:
		_stride = .58
	_moving = walking
	if in_walk:
		_witness.advance(delta, _body, walking, made_step)
		_distant_in -= delta
		if _distant_in <= 0.0 and get_tension() < .12:
			_distant_in = _rng.randf_range(25.0, 47.0)
			_emit_distant()
	var response := 1.0 - exp(-delta * 1.2)
	for i in _layers.size():
		_mix[i] = lerpf(_mix[i], clampf(_weights[i], 0, 1), response)
		_layers[i].volume_db = LEVELS[i] + linear_to_db(maxf(.00015, sqrt(_mix[i])))
	_pressure.volume_db = -4.5 + linear_to_db(maxf(.00015, get_tension() * get_tension()))


func _loop(clip: AudioStreamOggVorbis, gain: float) -> AudioStreamPlayer:
	var stream := clip.duplicate() as AudioStreamOggVorbis
	stream.loop = true
	var layer := AudioStreamPlayer.new()
	layer.stream = stream
	layer.volume_db = gain
	add_child(layer)
	layer.play(_rng.randf_range(0.0, stream.get_length()))
	return layer


func _new_voice(reference_distance: float, limit: float) -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.unit_size = reference_distance
	voice.max_distance = limit
	voice.max_db = 0.0
	voice.attenuation_filter_cutoff_hz = 3600.0
	voice.attenuation_filter_db = -9.0
	add_child(voice)
	return voice


func _emit_footstep(speed: float) -> void:
	var sample_index := (_last_sample + _rng.randi_range(1, SOLES.size() - 1)) % SOLES.size()
	_last_sample = sample_index
	var side := -0.13 if _left else 0.13
	_left = not _left
	var location := _body.global_position + _body.global_transform.basis.x * side + _body.up_direction * .12
	var level := float(_body.get_footstep_volume()) if _body.has_method("get_footstep_volume") else .8
	if level <= .001:
		return
	var run := clampf((speed-3.0)/2.25,0.0,1.0)
	var gain := -18.5 + clampf(speed-2.0,-1.5,2.0) - 1.55*run + linear_to_db(level)
	_play_at(_footfalls[_next_foot], SOLES[sample_index], location, gain, _rng.randf_range(.93, 1.06))
	_next_foot = (_next_foot + 1) % _footfalls.size()


func _emit_distant() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var location := _body.global_position + _body.global_basis * Vector3(cos(angle), 0.0, sin(angle)) * _rng.randf_range(14.0, 25.0)
	location += _body.up_direction * _rng.randf_range(-8.0, 10.0)
	var settling := _rng.randf() < .58 + .15 * _mix[1] - .24 * _mix[2] - .37 * _mix[3]
	var source := SETTLING if settling else STRAIN
	_play_at(_far_voice, source, location, _rng.randf_range(-10.0, -7.5), _rng.randf_range(.82, 1.04))


func _play_at(voice: AudioStreamPlayer3D, stream: AudioStream, location: Vector3, gain: float, pitch: float) -> void:
	voice.global_position = location
	voice.stream = stream
	voice.volume_db = gain
	voice.pitch_scale = pitch
	voice.play()
