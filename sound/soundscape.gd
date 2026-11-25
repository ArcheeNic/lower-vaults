extends Node3D

signal relocation_requested(to_start: bool)

const Witness := preload("res://suspense/witness.gd")
const Relic := preload("res://world/relic.gd")
const Presence := preload("res://suspense/presence.gd")
const TOUCH_NOTICES := {
	Presence.Kind.LANTERN: "Фонарщик погасил свет.",
	Presence.Kind.BELL: "Звон заглушил шум сводов.",
	Presence.Kind.COLLECTOR: "Собиратель украл звук ваших шагов.",
	Presence.Kind.PALL: "Носильщики переложили на вас свой груз.",
	Presence.Kind.DIVER: "Водолаз затопил ваш визор.",
	Presence.Kind.PILGRIM: "Паломник вернул вас к началу.",
	Presence.Kind.FRAME: "Рама перенесла вас в соседний зал.",
	Presence.Kind.WATCHMAN: "Часовой велел замереть.",
	Presence.Kind.SCRIBE: "Писец забрызгал чернилами края обзора.",
	Presence.Kind.SPINDLE: "Веретено развернуло вас.",
}
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
var _effect_kind := -1
var _effect_left := 0.0
var _effect_age := 0.0
var _dark_surface: Node3D
var _darkness := 0.
var _room_duck_db := 0.0
var _bell := AudioStreamPlayer.new()
var seal_charges := 0


func _ready() -> void:
	_rng.randomize()
	for i in ROOMS.size():
		_layers.append(_loop(ROOMS[i], LEVELS[i] if i == 0 else -80.0))
	_pressure = _loop(PRESSURE, -80)
	add_child(_witness)
	_witness.touched.connect(_on_touch)
	var ringing := Presence.VOICES[Presence.Kind.BELL].duplicate() as AudioStreamOggVorbis
	ringing.loop = true
	_bell.stream = ringing
	_bell.volume_db = -10.
	_bell.pitch_scale = .83
	add_child(_bell)
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


func pursuer_surface() -> Node3D:
	if _witness.phase!=Witness.Phase.QUIET and is_instance_valid(_witness._surface):
		return _witness._surface
	return null

func bind_player(body: CharacterBody3D, route: Callable, stair_link: Callable, distance: Callable) -> void:
	_witness.stair_at_link = stair_link
	_witness.walking_distance = distance
	_witness.route_between_surfaces = route
	_body = body
	_last_position = body.global_position
	_moving = false
	_stride = .58


func set_normal_mode(normal: bool) -> void:
	seal_charges = 0
	_clear_effect()
	_witness.reset_encounters(normal)
	_moving = false
	_stride = .58
	_far_voice.stop()
	for foot in _footfalls:
		foot.stop()


func lamp_power(lamp: Light3D) -> float:
	if _darkness > 0. and is_instance_valid(_dark_surface) and _dark_surface.is_ancestor_of(lamp):
		return 1. - _darkness
	return 1.


func _on_touch(kind: int) -> void:
	if seal_charges > 0:
		seal_charges -= 1
		_body.get("interface").show_notice("Печать раскололась и поглотила касание.")
		return
	_clear_effect()
	_effect_kind = kind
	match kind:
		Presence.Kind.LANTERN:
			_dark_surface = _body.get("surface")
			_effect_left = 7.
		Presence.Kind.DIVER, Presence.Kind.SCRIBE:
			_effect_left = 7.
		Presence.Kind.BELL:
			_effect_left = 10.
			_bell.play()
		Presence.Kind.COLLECTOR:
			_effect_left = 14.
			for foot in _footfalls:
				foot.stop()
		Presence.Kind.PALL:
			_effect_left = 8.
			_body.set("travel_multiplier", .55)
		Presence.Kind.WATCHMAN:
			_effect_left = 2.4
			_body.set("travel_multiplier", 0.)
			_body.velocity = _body.up_direction * _body.velocity.dot(_body.up_direction)
		Presence.Kind.PILGRIM, Presence.Kind.FRAME:
			relocation_requested.emit(kind == Presence.Kind.PILGRIM)
		Presence.Kind.SPINDLE:
			_body.rotate_object_local(Vector3.UP, PI)
			_body.reset_physics_interpolation()
	_body.get("interface").show_notice(TOUCH_NOTICES[kind])
	if _effect_left <= 0.:
		_clear_effect()


func accept_relic(kind: int) -> void:
	match kind:
		Relic.Kind.SEAL:
			seal_charges += 1
			_body.get("interface").show_notice("Янтарная печать защитит от одного касания.")
		Relic.Kind.HOURGLASS:
			_witness.banish(45.)
			_body.get("interface").show_notice("Песочные часы отогнали обитателей на 45 секунд.")


func _advance_effect(delta: float) -> void:
	if _effect_kind == -1:
		return
	_effect_left -= delta
	_effect_age += delta
	if _effect_left <= 0.:
		_clear_effect()
		return
	var weight := smoothstep(0., .35, _effect_age) * smoothstep(0., 1.2, _effect_left)
	var grade: ShaderMaterial = get_parent().get("grade")
	match _effect_kind:
		Presence.Kind.LANTERN:
			_darkness = weight
			var in_dark: bool = is_instance_valid(_dark_surface) and _body.get("surface") == _dark_surface
			grade.set_shader_parameter("lamplight_lost", weight if in_dark else 0.)
		Presence.Kind.DIVER:
			grade.set_shader_parameter("visor_water", Vector2(weight, _effect_age))
		Presence.Kind.SCRIBE:
			grade.set_shader_parameter("ink_stain", weight)
		Presence.Kind.BELL:
			_room_duck_db = -23. * weight
			_bell.volume_db = -10. + linear_to_db(maxf(.001, weight))


func _clear_effect() -> void:
	if _effect_kind == -1:
		return
	var grade: ShaderMaterial = get_parent().get("grade")
	match _effect_kind:
		Presence.Kind.LANTERN:
			grade.set_shader_parameter("lamplight_lost", 0.)
			_darkness = 0.
			_dark_surface = null
		Presence.Kind.DIVER: grade.set_shader_parameter("visor_water", Vector2.ZERO)
		Presence.Kind.SCRIBE: grade.set_shader_parameter("ink_stain", 0.)
		Presence.Kind.PALL, Presence.Kind.WATCHMAN: _body.set("travel_multiplier", 1.)
		Presence.Kind.BELL:
			_room_duck_db = 0.
			_bell.stop()
	_effect_kind = -1
	_effect_left = 0.
	_effect_age = 0.


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


func room_duck_db() -> float:
	return _room_duck_db


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
		_advance_effect(delta)
		_witness.advance(delta, _body, walking, made_step)
		_distant_in -= delta
		if _distant_in <= 0.0 and get_tension() < .12:
			_distant_in = _rng.randf_range(25.0, 47.0)
			_emit_distant()
	var response := 1.0 - exp(-delta * 1.2)
	for i in _layers.size():
		_mix[i] = lerpf(_mix[i], clampf(_weights[i], 0, 1), response)
		_layers[i].volume_db = LEVELS[i] + _room_duck_db + linear_to_db(maxf(.00015, sqrt(_mix[i])))
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
	if _effect_kind == Presence.Kind.COLLECTOR:
		return
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
