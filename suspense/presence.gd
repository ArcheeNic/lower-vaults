extends Node3D

enum Kind { LANTERN, BELL, COLLECTOR, PALL, DIVER, PILGRIM, FRAME, WATCHMAN, SCRIBE, SPINDLE }

const MODELS: Array[PackedScene] = [
	preload("res://models/presences/lamplighter.glb"), preload("res://models/presences/bell_keeper.glb"),
	preload("res://models/presences/collector.glb"), preload("res://models/presences/pall_bearers.glb"),
	preload("res://models/presences/diver.glb"), preload("res://models/presences/returning_pilgrim.glb"),
	preload("res://models/presences/frame_porter.glb"), preload("res://models/presences/watchman.glb"),
	preload("res://models/presences/scribe.glb"), preload("res://models/presences/spindle.glb")
]
const VOICES: Array[AudioStream] = [
	preload("res://suspense/voices/lamplighter.ogg"), preload("res://suspense/voices/bell_keeper.ogg"),
	preload("res://suspense/voices/collector.ogg"), preload("res://suspense/voices/pall_bearers.ogg"),
	preload("res://suspense/voices/diver.ogg"), preload("res://suspense/voices/returning_pilgrim.ogg"),
	preload("res://suspense/voices/frame_porter.ogg"), preload("res://suspense/voices/watchman.ogg"),
	preload("res://suspense/voices/scribe.ogg"), preload("res://suspense/voices/spindle.ogg")
]
const HEIGHT := [2.58,1.98,1.23,2.32,2.24,2.39,3.17,3.26,2.48,2.32]
const CADENCE := [1.0,1.37,.70,1.26,1.49,1.18,1.12,1.64,.88,.97]
const CLOTH := preload("res://suspense/mooncloth.gdshader")
var kind := Kind.LANTERN
var height: float:
	get: return HEIGHT[kind]
var foot_voice: AudioStream:
	get: return VOICES[kind]
var cadence: float:
	get: return CADENCE[kind]

var _deck: Array[int] = []
var _draws := 0
var _rig: Node3D
var _left: Node3D
var _right: Node3D
var _prop: Node3D
var _wings: Array[Node3D] = []
var _pieces: Array[GeometryInstance3D] = []
var _shades := {}
var _light: OmniLight3D
var _wick_material: StandardMaterial3D
var _opacity := -1.0
var _beat := 0.0


func deal(dice: RandomNumberGenerator) -> void:
	if _deck.is_empty():
		for value in MODELS.size():
			_deck.append(value)
		for i in range(_deck.size() - 1, 0, -1):
			_swap_card(i, dice.randi_range(0, i))
		if _draws == 0:
			_swap_card(_deck.find(Kind.LANTERN), _deck.size() - 1)
		elif _deck.back() == kind:
			_swap_card(0, _deck.size() - 1)
	_draws += 1
	equip(_deck.pop_back())


func _swap_card(a: int, b: int) -> void:
	var old := _deck[a]
	_deck[a] = _deck[b]
	_deck[b] = old


func equip(value: int) -> void:
	kind = value as Kind
	if _rig:
		remove_child(_rig)
		_rig.queue_free()
	_pieces.clear()
	_wings.clear()
	_light = null
	_rig = MODELS[value].instantiate()
	add_child(_rig)
	_left = _rig.find_child("leg_l", true, false)
	_right = _rig.find_child("leg_r", true, false)
	_prop = _rig.find_child("equipment", true, false)
	for label in ["wing_l", "wing_r"]:
		var wing := _rig.find_child(label, true, false) as Node3D
		if wing:
			_wings.append(wing)
	for item in _rig.find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		_pieces.append(mesh)
		for i in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(i) as StandardMaterial3D
			if original:
				mesh.set_surface_override_material(i, _moon_fabric(original))
	if kind == Kind.LANTERN:
		_fit_wick()
	_beat = 0
	_opacity = -1
	set_opacity(0)


func _moon_fabric(original: StandardMaterial3D) -> Material:
	if not _shades.has(original):
		var shade := ShaderMaterial.new()
		shade.shader = CLOTH
		shade.set_shader_parameter("weathering", preload("res://architecture/limestone.png"))
		shade.set_shader_parameter("pigment", original.albedo_color)
		shade.set_shader_parameter("metal", original.metallic)
		shade.set_shader_parameter("grain", original.roughness)
		_shades[original] = shade
	return _shades[original]


func _fit_wick() -> void:
	var wick := MeshInstance3D.new()
	var lens := SphereMesh.new()
	lens.radius = .082
	lens.height = .22
	wick.mesh = lens
	_wick_material = StandardMaterial3D.new()
	_wick_material.albedo_color = Color("ffe7ac")
	_wick_material.emission_enabled = true
	_wick_material.emission = Color("ffc06e")
	wick.material_override = _wick_material
	wick.position = Vector3(0,-.28,0)
	_prop.add_child(wick)
	_pieces.append(wick)
	_light = OmniLight3D.new()
	_light.light_color = Color("ffc06c")
	_light.omni_range = 5.35
	_light.omni_attenuation = 1.12
	wick.add_child(_light)


func set_opacity(value: float) -> void:
	if absf(value - _opacity) > .0002:
		_opacity = value
		for piece in _pieces:
			piece.transparency = 1.0 - value
	if _light:
		var flame := 1.0 + .043 * sin(_beat * 4.6)
		_light.light_energy = 2.95 * value * flame
		_wick_material.emission_energy_multiplier = 3.2 * value * flame


func pursuit_speed(time: float, walking: bool) -> float:
	var pulse := .5 + .5 * sin(time * 4.0 / cadence)
	if kind == Kind.COLLECTOR:
		return (.95 if walking else .72) + pulse
	return (.92 + .46 * pulse) / sqrt(cadence)


func pose(delta: float, moving: bool, frozen: bool, seen: bool, withdrawing: bool) -> void:
	if frozen:
		return
	var speed := 5.2 / cadence if moving else 1.18
	if kind == Kind.WATCHMAN and seen:
		speed = .67
	_beat += delta * speed
	var swing := sin(_beat)
	var lift := absf(swing)
	var gait := 1.0 if moving else .09
	var stride := .26 * gait
	var bob := .028 * lift * gait
	var lean := .015 * swing * gait
	var turn := 0.0
	match kind:
		Kind.LANTERN:
			_prop.rotation.x = -.17 * swing * gait
		Kind.BELL:
			_prop.rotation.z = sin(_beat-.65) * .27 * gait
			lean = -.044 + swing*.036*gait
			stride *= .68
		Kind.COLLECTOR:
			_left.rotation.z = swing*.16*gait
			_right.rotation.z = swing*.15*gait
			stride *= .89
			bob = -.103 * (1.0-gait) + lift*.032*gait
		Kind.PALL:
			_prop.rotation.z = .039 * swing
			lean = sin(_beat*.51)*.038
			stride *= .57
		Kind.DIVER:
			_prop.rotation.z = .06 * sin(_beat*.56)
			bob = .09 * (.5 + .5*sin(_beat*.6))
			stride *= 1.20
			turn = sin(_beat*.52)*.13
		Kind.PILGRIM:
			turn = PI
			stride *= -1.12
			_prop.rotation.z = .11 * swing
		Kind.FRAME:
			_prop.rotation.y = .55*sin(_beat*.74) if not seen else .10*sin(_beat*.32)
			_prop.rotation.z = -.12 + .09 * swing
			lean = -.054
		Kind.WATCHMAN:
			_prop.rotation.y = .48 * sin(_beat*.68)
			stride = 0 if seen else .22*gait
			bob = 0
			lean = 0
		Kind.SCRIBE:
			for i in _wings.size():
				var hand := -1 if i == 0 else 1
				_wings[i].rotation.z = hand * ((.18 if seen else -.13) + .13*sin(_beat*.75))
				_wings[i].rotation.y = hand * (.15 + .09*swing)
			_prop.rotation.x = .13*sin(_beat*.58)
			bob *= .42
		Kind.SPINDLE:
			_prop.rotation.z = -_beat*.48
			lean = sin(_beat*.45)*.065
			turn = sin(_beat*.5)*.22
	if withdrawing and kind != Kind.PILGRIM:
		turn += .35
	_rig.rotation.y = lerp_angle(_rig.rotation.y, turn, minf(1.0,delta*6.0))
	_rig.rotation.z = lean
	_rig.position.y = bob
	_left.rotation.x = swing * stride
	_right.rotation.x = -swing * stride
