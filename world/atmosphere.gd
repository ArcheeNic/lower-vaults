extends WorldEnvironment

# Palette channels: horizon, zenith, sunlight, ambient and distant haze.
const PALETTES := [
	["394955","111b2c","b9cee1","8293a8","394a5a"],
	["3f565a","142a36","a4c8ce","88a3ac","344e56"],
	["212239","070c1d","b7c1e0","888dab","30344c"],
	["55443e","201b25","d3b6a4","a2979a","55433c"]
]
var previous := PackedFloat32Array()
var sky_paint := ShaderMaterial.new()
var sun := DirectionalLight3D.new()
var mist := FogVolume.new()
var mist_material := ShaderMaterial.new()

func _ready() -> void:
	environment = Environment.new()
	sky_paint.shader = preload("res://world/sky.gdshader")
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_paint
	environment.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	environment.sky.radiance_size = Sky.RADIANCE_SIZE_64
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.54
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.ssao_enabled = true
	environment.ssao_radius = 1.7
	environment.ssao_intensity = 2.35
	environment.ssao_detail = 0.55
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_density = 1.0
	environment.fog_aerial_perspective = 0.7
	environment.fog_sky_affect = 0.3
	environment.fog_light_energy = 0.65
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.009
	environment.volumetric_fog_albedo = Color("d2c7b4")
	environment.volumetric_fog_length = 80.0
	environment.volumetric_fog_ambient_inject = 0.12
	environment.volumetric_fog_sky_affect = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.22
	environment.glow_bloom = 0.0
	sun.light_energy = 2.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 105.0
	sun.shadow_bias = 0.045
	sun.light_volumetric_fog_energy = 1.35
	sun.shadow_normal_bias = .65
	sun.directional_shadow_blend_splits = true
	add_child(sun)
	mist_material.shader = preload("res://world/ground_mist.gdshader")
	mist_material.set_shader_parameter("strata",preload("res://architecture/limestone.png"))
	mist.size = Vector3(105,5.4,105)
	mist.position.y = -.35
	mist.material = mist_material
	add_child(mist)
	set_realms(PackedFloat32Array([1,0,0,0]))

func set_view_distance(far_clip: float) -> void:
	environment.fog_depth_begin = far_clip * 0.28
	environment.fog_depth_end = far_clip * 0.90

func move_mist(frame:Transform3D) -> void:
	mist.global_transform = Transform3D(frame.basis, frame.origin - frame.basis.y*.35)

func set_realms(weights: PackedFloat32Array) -> void:
	if weights == previous:
		return
	previous = weights.duplicate()
	var colors: Array[Color] = []
	for channel in range(5):
		var mixed := Color(0,0,0,0)
		for i in weights.size():
			mixed += Color(PALETTES[i][channel])*weights[i]
		colors.append(mixed)
	sky_paint.set_shader_parameter("horizon",colors[0])
	sky_paint.set_shader_parameter("zenith",colors[1])
	sky_paint.set_shader_parameter("night",weights[2])
	sun.light_color = colors[2]
	environment.ambient_light_color = colors[3]
	environment.fog_light_color = colors[4]
	environment.fog_depth_curve = 1.0 - 0.25*weights[1] + 0.5*weights[2]
	environment.volumetric_fog_density = .009 + .005*weights[1] - .006*weights[2]
	environment.volumetric_fog_albedo = colors[4].lightened(.30)
	mist_material.set_shader_parameter("mist_color",colors[3])
	mist_material.set_shader_parameter("density",.041+.033*weights[1]-.033*weights[2])
	environment.ambient_light_energy = .38 + .12*weights[2]
	sun.light_energy = 1.11 - .19*weights[2] + .04*weights[1]
	sun.rotation_degrees = Vector3(-23.-4.*weights[2],-127.+16.*weights[1],0)
	sky_paint.set_shader_parameter("moon_dir",sun.basis.z)
