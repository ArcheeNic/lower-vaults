extends Node3D

const MERIDIAN := preload("res://models/meridian.glb")
const BELL := preload("res://models/passing_bell.glb")
const UpperWalk := preload("res://world/upper_walk.gd")
const WATER := preload("res://world/water.gdshader")
const VIGIL := preload("res://models/vigil.glb")
var pendulum := Node3D.new()
var phase := 0.0
var local_time := 0.0

func build(index: int, layer: int) -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = hash(Vector2i(index, layer))
	phase = dice.randf() * TAU
	var mirror := 1 if posmod(index + layer, 2) == 0 else -1
	var motif := posmod(index + 3 * layer, 5)
	var with_bells := motif == 1 or motif == 4
	var instrument: Node3D = BELL.instantiate() if with_bells else MERIDIAN.instantiate()
	if (layer != 0 and posmod(index, 3) != 2) or motif == 3:
		var upper := UpperWalk.new()
		add_child(upper)
		upper.build(mirror,index+layer*17)
	if motif == 2 or motif == 4:
		_cistern()
	add_child(pendulum)
	pendulum.position = Vector3(mirror * 6.3, 19, -5.0)
	pendulum.add_child(instrument)
	instrument.position.y = -13
	instrument.rotation.y = dice.randf_range(-0.45,0.45)
	var scale_factor := dice.randf_range(0.88, 1.08)
	instrument.scale = Vector3.ONE * scale_factor
	if with_bells:
		for i in range(2):
			var bell: Node3D = BELL.instantiate()
			add_child(bell)
			bell.position = Vector3(-mirror * (5.7 + 1.85*i), 8.6 + 4.1 * i, 6.0 + 4.9 * i)
			bell.scale = Vector3.ONE * (0.72 + i * 0.43)
	var lamp: Node3D = VIGIL.instantiate()
	lamp.position = Vector3(-mirror * 2.05, 0, -13.2)
	add_child(lamp)
	_light(lamp.position + Vector3(.21*mirror,1.63,.09), 3.3, 8.8)

func _cistern() -> void:
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(63.8,47.8)
	surface.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = WATER
	surface.material_override = material
	surface.position.y = -8.8
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)

func _light(at: Vector3, power: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color("ffb765")
	light.light_energy = power
	light.omni_range = reach
	light.light_volumetric_fog_energy = 1.7
	light.shadow_enabled = true
	light.shadow_bias = .04
	light.set_meta("steady_power", power)
	light.add_to_group("scene_lights")
	add_child(light)

func _process(delta: float) -> void:
	local_time += delta
	pendulum.rotation.z = sin(local_time * 0.17 + phase) * 0.055
	pendulum.rotation.y = sin(local_time * 0.089 + phase) * 0.33
