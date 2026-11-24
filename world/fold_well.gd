extends Node3D

# The floor of the cathedral balcony opens into the air above its side aisle.
const HALF_OPENING := 1.26
const DISPLACEMENT := Vector3(9.7, 10.5, 0)
const WELL_LAYER := 1 << 16
var view: SubViewport
var eye: Camera3D

func _ready() -> void:
	add_to_group("fold_wells")
	view = SubViewport.new()
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	view.world_3d = get_world_3d()
	add_child(view)
	eye = Camera3D.new()
	eye.cull_mask &= ~WELL_LAYER
	view.add_child(eye)
	var opening := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * HALF_OPENING * 2.
	opening.mesh = plane
	opening.layers = WELL_LAYER
	opening.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://world/fold_view.gdshader")
	surface.set_shader_parameter("view_through",view.get_texture())
	opening.material_override = surface
	add_child(opening)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var offset := to_local(camera.global_position)
	var active := offset.y > -.2 and offset.length_squared() < 32.*32. and camera.is_position_in_frustum(global_position)
	# Keep the view alive when its centre has passed the edge of the screen but
	# the walker is still looking through part of the opening.
	active = active or (offset.y > -.2 and offset.length_squared() < 5.*5.)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if active:
		var size_px := Vector2i(Vector2(get_viewport().get_texture().get_size()) * .65).max(Vector2i(2,2))
		if view.size != size_px:
			view.size = size_px
		eye.fov = camera.fov
		eye.near = camera.near
		eye.far = camera.far
		eye.global_transform = camera.global_transform.translated(global_basis * DISPLACEMENT)

func crosses(eye_position: Vector3, vertical_speed: float) -> bool:
	var p := to_local(eye_position)
	return vertical_speed < 0. and p.y <= 0. and p.y >= -.8 and absf(p.x) < HALF_OPENING and absf(p.z) < HALF_OPENING
