extends Node3D

const SightGeometry := preload("res://suspense/sight_geometry.gd")
const CellNavigation := preload("res://world/cell_navigation.gd")
const Atlas := preload("res://world/atlas.gd")
const Stage := preload("res://tableaux/stage.gd")
const Aperture := preload("res://world/aperture.gd")
const Hall := preload("res://architecture/hall.gd")
const Foreign := preload("res://realms/foreign.gd")
const Ironworks := preload("res://world/ironworks.gd")
const Walker := preload("res://walker/walker.gd")
const Soundscape := preload("res://sound/soundscape.gd")
const Atmosphere := preload("res://world/atmosphere.gd")
const Dressing := preload("res://world/dressing.gd")
const SIZE := Vector2(64,48)
const BLEND_WIDTH := 11.0
const LOAD_DISTANCE := 95.0
const RETAIN_DISTANCE := 116.0

var atlas := Atlas.new()
var cells := {}
var pending: Array[Vector2i] = []
var origin := Vector2i.ZERO
var last_stream_point := Vector2.ZERO
var last_safe := Vector3(0,.1,-9)
var atmosphere := Atmosphere.new()
var walker := Walker.new()
var soundscape := Soundscape.new()
var grade := ShaderMaterial.new()
var closing := false
var mix_clock := 0.0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, .2)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, .1)
	add_child(atmosphere)
	for z in range(-1,2):
		for x in range(-1,2):
			_build_cell(Vector2i(x,z))
	walker.name = "Walker"
	walker.position = last_safe
	add_child(walker)
	walker.camera.far = 87.0
	walker.camera.rotation.x = .055
	walker.exit_requested.connect(_quit_game)
	add_child(soundscape)
	soundscape.bind_player(walker)
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var paper := ColorRect.new()
	layer.add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.shader = preload("res://world/plate.gdshader")
	paper.material = grade
	_queue_surroundings()
	_update_mix()

func cell_of(pos: Vector3) -> Vector2i:
	return origin + Vector2i(floori(pos.x/SIZE.x+.5),floori(-pos.z/SIZE.y+.5))

func _center(cell: Vector2i) -> Vector3:
	var local := cell-origin
	return Vector3(local.x*SIZE.x,0,-local.y*SIZE.y)

func kind_at(cell: Vector2i) -> int:
	return Atlas.climate(atlas.scene_at(cell))

func _build_cell(cell: Vector2i) -> void:
	var scene_id := atlas.scene_at(cell)
	var tile := _make_scene(scene_id,0 if cell==Vector2i.ZERO else posmod(hash(cell),100003))
	tile.position = _center(cell)
	add_child(tile)
	var navigation := CellNavigation.new()
	navigation.build(tile)
	tile.add_child(navigation)
	var scenery := SightGeometry.new()
	scenery.build(tile)
	tile.add_child(scenery)
	var listener:=walker.global_position if walker.is_inside_tree() else last_safe
	for lamp:Light3D in tile.find_children("*","Light3D",true,false):
		if lamp.is_in_group("scene_lights"):
			_set_lamp(lamp,listener,0.)
	cells[cell] = tile

func _make_scene(scene_id:int, seed_value:int) -> Node3D:
	var tile: Node3D
	match scene_id:
		0:
			var hall := Hall.new()
			hall.build(seed_value)
			var decor := Dressing.new()
			hall.add_child(decor)
			decor.build(seed_value,0)
			tile = hall
		1, 2:
			var foreign := Foreign.new()
			foreign.build(scene_id,seed_value)
			tile = foreign
		3:
			var mill := Ironworks.new()
			mill.build(seed_value)
			tile = mill
		_:
			var stage := Stage.new()
			stage.build(Atlas.Stone if scene_id<18 else Atlas.Wild,
				(scene_id-4) if scene_id<18 else (scene_id-18),Atlas.climate(scene_id))
			if scene_id in [4,5,7,12]:
				var light := Aperture.new()
				var target := _near_aisle(stage.landings)
				light.build(target,scene_id)
				stage.add_child(light)
			tile = stage
	tile.set_meta("scene_id",scene_id)
	return tile

func _near_aisle(landings:Array[Vector3]) -> Vector3:
	var chosen:=landings[0]
	for landing in landings:
		if landing.distance_squared_to(Vector3(0,2,8))<chosen.distance_squared_to(Vector3(0,2,8)):
			chosen=landing
	return chosen

func _range_to(cell: Vector2i) -> float:
	var near_edge := walker.position-_center(cell)
	return Vector2(maxf(0,absf(near_edge.x)-SIZE.x*.5),maxf(0,absf(near_edge.z)-SIZE.y*.5)).length()

func _queue_surroundings() -> void:
	var here := cell_of(walker.position)
	last_stream_point = Vector2(walker.position.x,walker.position.z)
	for key: Vector2i in cells.keys():
		if _range_to(key)>RETAIN_DISTANCE:
			cells[key].queue_free()
			cells.erase(key)
	pending.clear()
	for y in range(here.y-3,here.y+4):
		for x in range(here.x-2,here.x+3):
			var cell := Vector2i(x,y)
			if not cells.has(cell) and _range_to(cell)<LOAD_DISTANCE:
				pending.append(cell)
	pending.sort_custom(func(a: Vector2i,b: Vector2i): return _range_to(a)>_range_to(b))

func _process(_delta: float) -> void:
	if not pending.is_empty() and not closing:
		_build_cell(pending.pop_back())

func _physics_process(delta: float) -> void:
	for well in get_tree().get_nodes_in_group("fold_wells"):
		if well.crosses(walker.camera.global_position, walker.velocity.y):
			walker.position += well.DISPLACEMENT
			walker.reset_physics_interpolation()
			break
	var p := walker.position
	var current := cell_of(p)
	var hall := cells.get(current) as Hall
	if hall:
		var fold := hall.fold_offset(p - _center(current))
		if fold != 0.:
			walker.position.y += fold
			walker.reset_physics_interpolation()
			p = walker.position
			last_safe = p+Vector3.UP*.1
	if maxi(absi(current.x-origin.x),absi(current.y-origin.y))>64:
		# A pure translation of the complete scene, thousands of metres from spawn.
		var shift := _center(current)
		origin = current
		for key: Vector2i in cells:
			cells[key].position = _center(key)
			cells[key].reset_physics_interpolation()
		walker.position -= shift
		walker.reset_physics_interpolation()
		soundscape.shift_origin(shift)
		last_safe -= shift
		p = walker.position
	if Vector2(p.x,p.z).distance_squared_to(last_stream_point)>16:
		_queue_surroundings()
	if walker.is_on_floor() and p.y > -10:
		last_safe = p+Vector3.UP*.1
	elif p.y < -18:
		walker.position = last_safe
		walker.velocity = Vector3.ZERO
		walker.reset_physics_interpolation()
	mix_clock -= delta
	if mix_clock<=0:
		mix_clock = .075
		_update_mix()

func _update_mix() -> void:
	var here := cell_of(walker.position)
	walker.interface.set_place(Atlas.title(atlas.scene_at(here)))
	var p := walker.position-_center(here)
	var east := Vector2i(1 if p.x>0 else -1,0)
	var north := Vector2i(0,1 if p.z<0 else -1)
	var a := .5*(1.-smoothstep(0.,BLEND_WIDTH,SIZE.x*.5-absf(p.x)))
	var b := .5*(1.-smoothstep(0.,BLEND_WIDTH,SIZE.y*.5-absf(p.z)))
	var weights := PackedFloat32Array([0.,0.,0.,0.])
	weights[kind_at(here)] += (1-a)*(1-b)
	weights[kind_at(here+east)] += a*(1-b)
	weights[kind_at(here+north)] += (1-a)*b
	weights[kind_at(here+east+north)] += a*b
	atmosphere.set_realms(weights)
	soundscape.set_realms(weights)
	var pressure := soundscape.get_tension()
	grade.set_shader_parameter("pressure",pressure)
	# Distant fixtures go dark before more lamps are enabled. The smooth envelope
	# is independent of chunk loading and the moving lighthouse keeps its own aim.
	atmosphere.move_mist(walker.position)
	for lamp: Light3D in get_tree().get_nodes_in_group("scene_lights"):
		_set_lamp(lamp,walker.global_position,pressure)

func _set_lamp(lamp:Light3D,listener:Vector3,pressure:float) -> void:
	var distance := listener.distance_to(lamp.global_position)
	var power := 1.-smoothstep(19,31,distance)
	lamp.visible = power>.001
	lamp.light_energy = float(lamp.get_meta("steady_power"))*power*(1.-.30*pressure)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		_quit_game()

func _quit_game() -> void:
	if closing:
		return
	closing = true
	set_physics_process(false)
	soundscape.queue_free()
	await get_tree().create_timer(0.28,true,false,true).timeout
	get_tree().quit()
