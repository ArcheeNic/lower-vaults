extends Node3D

const LevelStair := preload("res://world/level_stair.gd")
const Gallery := preload("res://world/gallery.gd")
const SightGeometry := preload("res://suspense/sight_geometry.gd")
const CellNavigation := preload("res://world/cell_navigation.gd")
const Atlas := preload("res://world/atlas.gd")
const ThreeStoreys := preload("res://world/three_storeys.gd")
const Stage := preload("res://tableaux/stage.gd")
const Aperture := preload("res://world/aperture.gd")
const Hall := preload("res://architecture/hall.gd")
const Foreign := preload("res://realms/foreign.gd")
const Ironworks := preload("res://world/ironworks.gd")
const Walker := preload("res://walker/walker.gd")
const Soundscape := preload("res://sound/soundscape.gd")
const Atmosphere := preload("res://world/atmosphere.gd")
const Dressing := preload("res://world/dressing.gd")
const PROJECTED_SURFACES := [
	preload("res://architecture/masonry.gdshader"),preload("res://realms/surface.gdshader"),
	preload("res://world/metal.gdshader"),preload("res://tableaux/matter.gdshader")
]
const SIDES := 8
const HALF_DEPTH := 24.
const BEND := 6.
const ROW_HEIGHT := HALF_DEPTH + BEND
const RADIUS := 114.
const LOAD_DISTANCE := 104.
const RETAIN_DISTANCE := 128.

var atlas := Atlas.new()
var cells := {}
var galleries := {}
var pending: Array[Vector2i] = []
var origin_row := 0
var last_stream_point := Vector3.INF
var last_safe: Vector3
var safe_surface: Node3D
var safe_basis := Basis.IDENTITY
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
	var entrance := _room_frame(Atlas.ATRIUM_CELL)
	last_safe = entrance * Vector3(0,.08,14)
	safe_basis = entrance.basis
	for z in range(-1,2):
		for x in range(-1,2):
			_build_cell(Vector2i(x,z))
	walker.name = "Walker"
	walker.surface = cells[Atlas.ATRIUM_CELL]
	safe_surface = walker.surface
	walker.transform = Transform3D(safe_basis,last_safe)
	add_child(walker)
	atmosphere.set_view_distance(walker.camera.far)
	walker.camera.rotation.x = .055
	walker.exit_requested.connect(_quit_game)
	add_child(soundscape)
	soundscape.bind_player(walker,surface_route,stair_at_link,walking_distance)
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

# Eight faces surround the shaft. Four successive rows form an S in section:
# a floor, an inner wall, a ceiling and an outer wall. The next course starts
# one full storey higher and the same construction continues below the entrance.
func _wrap(cell: Vector2i) -> Vector2i:
	return Vector2i(posmod(cell.x+4,SIDES)-4,cell.y)

func _room_frame(cell: Vector2i) -> Transform3D:
	var face := Basis(Vector3.UP, cell.x * TAU / SIDES)
	var phase := posmod(cell.y,4)
	var angle: float = [0.,PI*.5,PI,PI*.5][phase]
	var radius: float = [RADIUS,RADIUS-ROW_HEIGHT,RADIUS,RADIUS+ROW_HEIGHT][phase]
	var at := face.z*radius - Vector3.BACK*RADIUS + Vector3.UP*(cell.y-origin_row)*ROW_HEIGHT
	return Transform3D(face*Basis(Vector3.RIGHT,angle),at)

func _cell_on(surface: Node3D, point: Vector3) -> Vector2i:
	if surface is Gallery:
		return surface.cells[0 if surface.coordinate(point) < (surface.points.size()-1)*.5 else 1]
	return surface.get_meta("cell")

func cell_of(point: Vector3) -> Vector2i:
	if point.is_equal_approx(walker.position) and is_instance_valid(walker.surface):
		return _cell_on(walker.surface,point)
	# Choose the nearest room footprint in 3D, including columns across the wrap.
	var row := origin_row+roundi(point.y/ROW_HEIGHT)
	var best := INF
	var chosen := Vector2i.ZERO
	for y in range(row-1,row+2):
		for x in range(-4,4):
			var cell := Vector2i(x,y)
			var p := _room_frame(cell).affine_inverse()*point
			var foot := Vector3(clampf(p.x,-32,32),0,clampf(p.z,-24,24))
			var distance := p.distance_squared_to(foot)
			if distance<best:
				best = distance
				chosen = cell
	return chosen

func kind_at(cell: Vector2i) -> int:
	return Atlas.climate(atlas.scene_at(cell))

# A right-hand ascent is paired with a left-hand descent on the next
# course. The same permutation in reverse makes every stair returnable.
func _stair_target(cell: Vector2i, hand: int) -> Vector2i:
	var row := cell.y if hand>0 else cell.y-1
	var twist := 1 if posmod(row,2)==0 else -1
	for offset: int in [1,-1,2,-2,3,-3,4]:
		var same_setting := false
		for x in range(-4,4):
			if atlas.scene_at(Vector2i(x,row))==atlas.scene_at(_wrap(Vector2i(x+offset*twist,row+1))):
				same_setting = true
				break
		if not same_setting:
			return _wrap(cell+Vector2i(offset*twist,1)*hand)
	return _wrap(cell+Vector2i(twist,1)*hand)

func _build_cell(cell: Vector2i) -> void:
	var scene_id := atlas.scene_at(cell)
	var tile := _make_scene(scene_id,0 if cell==Vector2i.ZERO else posmod(hash(cell),100003))
	tile.transform = _room_frame(cell)
	tile.set_meta("cell",cell)
	var stairs: Array[LevelStair] = []
	for hand in [-1,1]:
		var flight := LevelStair.new()
		flight.assemble(scene_id,hand,_stair_target(cell,hand))
		tile.add_child(flight)
		stairs.append(flight)
	tile.set_meta("stairs",stairs)
	for part: GeometryInstance3D in tile.find_children("*","GeometryInstance3D",true,false):
		var mat := part.material_override as ShaderMaterial
		if mat and mat.shader in PROJECTED_SURFACES:
			part.set_instance_shader_parameter("room_right",tile.basis.x)
			part.set_instance_shader_parameter("room_up",tile.basis.y)
	for body: StaticBody3D in tile.find_children("*","StaticBody3D",true,false):
		body.set_meta("walk_surface",tile)
	add_child(tile)
	var navigation := CellNavigation.new()
	navigation.build(tile)
	tile.add_child(navigation)
	tile.set_meta("navigation",navigation)
	var scenery := SightGeometry.new()
	scenery.build(tile)
	tile.add_child(scenery)
	var listener:=walker.global_position if walker.is_inside_tree() else last_safe
	for lamp:Light3D in tile.find_children("*","Light3D",true,false):
		if lamp.is_in_group("scene_lights"):
			_set_lamp(lamp,listener,0.)
	cells[cell] = tile
	for axis in [Vector2i.RIGHT,Vector2i.DOWN]:
		for start: Vector2i in [cell,_wrap(cell-axis)]:
			var end := _wrap(start+axis)
			var key := Vector3i(start.x,start.y,int(axis.x))
			if galleries.has(key) or not (cells.has(start) and cells.has(end)):
				continue
			var passage := Gallery.new()
			passage.cells.assign([start,end])
			passage.build(_room_frame(start),_room_frame(end),axis.x!=0)
			add_child(passage)
			galleries[key] = passage

func _make_scene(scene_id:int, seed_value:int) -> Node3D:
	var tile: Node3D
	match scene_id:
		Atlas.ATRIUM:
			var atrium := ThreeStoreys.new()
			atrium.assemble()
			tile = atrium
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
	var local := _room_frame(cell).affine_inverse()*walker.position
	var bounds := AABB(Vector3(-32,-12,-24),Vector3(64,46,48))
	return local.distance_to(local.clamp(bounds.position,bounds.end))

func _queue_surroundings() -> void:
	var here := cell_of(walker.position)
	last_stream_point = walker.position
	var keep := {}
	var resident: Node3D = walker.surface if is_instance_valid(walker.surface) else null
	if resident and resident.has_meta("stairs"):
		for stair: LevelStair in resident.get_meta("stairs"):
			if stair.threshold().distance_squared_to(walker.position)<12.*12.:
				keep[stair.destination] = true
	var follower: Node3D = soundscape.pursuer_surface()
	if follower is Gallery:
		for end: Vector2i in follower.cells:
			keep[end] = true
	elif is_instance_valid(follower) and follower.has_meta("cell"):
		keep[follower.get_meta("cell")] = true
	for key: Vector2i in cells.keys():
		if not keep.has(key) and _range_to(key)>RETAIN_DISTANCE:
			cells[key].queue_free()
			cells.erase(key)
	for key in galleries.keys():
		var link: Gallery = galleries[key]
		if not cells.has(link.cells[0]) or not cells.has(link.cells[1]):
			link.queue_free()
			galleries.erase(key)
	pending.clear()
	for y in range(here.y-5,here.y+6):
		for x in range(-4,4):
			var cell := Vector2i(x,y)
			if not cells.has(cell) and _range_to(cell)<LOAD_DISTANCE:
				pending.append(cell)
	pending.sort_custom(func(a:Vector2i,b:Vector2i): return _range_to(a)>_range_to(b))

func _process(_delta: float) -> void:
	if not pending.is_empty() and not closing:
		_build_cell(pending.pop_back())

func _paired(stair: LevelStair) -> LevelStair:
	return cells[stair.destination].get_meta("stairs")[0 if stair.side>0 else 1]

func _walk_stairs() -> void:
	if not is_instance_valid(walker.surface) or not walker.surface.has_meta("stairs"):
		return
	for stair: LevelStair in walker.surface.get_meta("stairs"):
		if stair.threshold().distance_squared_to(walker.position)>8.*8.:
			continue
		if not cells.has(stair.destination):
			pending.erase(stair.destination)
			_build_cell(stair.destination)
		if not stair.has_crossed(walker.position):
			continue
		var other := _paired(stair)
		var passage := stair.passage_to(other)
		walker.global_transform = passage*walker.global_transform
		# A point exactly on the cut belongs to the arriving half.
		walker.position -= other.global_basis.x*.0005
		walker.velocity = passage.basis*walker.velocity
		walker.up_direction = other.global_basis.y
		walker.surface = cells[stair.destination]
		walker.reset_physics_interpolation()
		last_safe = walker.position+walker.up_direction*.08
		safe_surface = walker.surface
		safe_basis = walker.basis
		_queue_surroundings()
		return

func _physics_process(delta: float) -> void:
	_walk_stairs()
	for well in get_tree().get_nodes_in_group("fold_wells"):
		if well.crosses(walker.camera.global_position, walker.velocity.dot(well.global_basis.y)):
			walker.position += well.global_basis * well.DISPLACEMENT
			walker.reset_physics_interpolation()
			break
	var current := cell_of(walker.position)
	var hall := walker.surface as Hall
	if hall:
		var fold := hall.fold_offset(hall.to_local(walker.position))
		if fold != 0.:
			walker.position += hall.global_basis.y * fold
			walker.reset_physics_interpolation()
	if absi(current.y-origin_row)>64:
		var shift := Vector3.UP*(current.y-origin_row)*ROW_HEIGHT
		origin_row = current.y
		for tile: Node3D in cells.values():
			tile.position -= shift
			tile.reset_physics_interpolation()
		for bridge: Gallery in galleries.values():
			bridge.position -= shift
			bridge.reset_physics_interpolation()
		walker.position -= shift
		walker.reset_physics_interpolation()
		soundscape.shift_origin(shift)
		last_safe -= shift
	if walker.position.distance_squared_to(last_stream_point)>16:
		_queue_surroundings()
	if walker.is_on_floor() and is_instance_valid(walker.surface):
		last_safe = walker.position + walker.up_direction*.1
		safe_surface = walker.surface
		safe_basis = walker.basis
	elif walker.position.distance_to(last_safe)>19. and is_instance_valid(safe_surface):
		walker.position = last_safe
		walker.surface = safe_surface
		walker.basis = safe_basis
		walker.up_direction = safe_basis.y
		walker.velocity = Vector3.ZERO
		walker.reset_physics_interpolation()
	mix_clock -= delta
	if mix_clock<=0:
		mix_clock = .075
		_update_mix()

func _update_mix() -> void:
	var here := cell_of(walker.position)
	var place := Atlas.title(atlas.scene_at(here))
	var weights := PackedFloat32Array([0.,0.,0.,0.])
	var bridge := walker.surface as Gallery
	if bridge:
		var blend := smoothstep(0.,1.,bridge.coordinate(walker.position)/(bridge.points.size()-1))
		weights[kind_at(bridge.cells[0])] += 1.-blend
		weights[kind_at(bridge.cells[1])] += blend
	elif walker.surface is ThreeStoreys:
		var at := walker.surface.to_local(walker.global_position)
		weights = walker.surface.climate_at(at)
		place = walker.surface.title_at(at)
	else:
		weights[kind_at(here)] = 1.
	walker.interface.set_place(place)
	atmosphere.set_realms(weights)
	soundscape.set_realms(weights)
	var pressure := soundscape.get_tension()
	grade.set_shader_parameter("pressure",pressure)
	# Distant fixtures go dark before more lamps are enabled. The smooth envelope
	# is independent of chunk loading and the moving lighthouse keeps its own aim.
	atmosphere.move_mist(walker.global_transform)
	for lamp: Light3D in get_tree().get_nodes_in_group("scene_lights"):
		_set_lamp(lamp,walker.global_position,pressure)

func _set_lamp(lamp:Light3D,listener:Vector3,pressure:float) -> void:
	var distance := listener.distance_to(lamp.global_position)
	var power := 1.-smoothstep(19,31,distance)
	lamp.visible = power>.001
	lamp.light_energy = float(lamp.get_meta("steady_power"))*power*(1.-.30*pressure)

func _link_between(a: Vector2i,b: Vector2i) -> Gallery:
	if b not in [_wrap(a+Vector2i.RIGHT),_wrap(a+Vector2i.LEFT),a+Vector2i.DOWN,a+Vector2i.UP]:
		return null
	var across := a.y==b.y
	var forward := Vector2i.RIGHT if across else Vector2i.DOWN
	var first := a if _wrap(a+forward)==b else b
	return galleries.get(Vector3i(first.x,first.y,int(across)))

func _room_chain(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var previous := {start:start}
	for cell in queue:
		if cell == end:
			var route: Array[Vector2i] = [end]
			while route[0] != start:
				route.push_front(previous[route[0]])
			return route
		for delta: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next := _wrap(cell+delta)
			if not previous.has(next) and _link_between(cell,next):
				previous[next] = cell
				queue.append(next)
		for stair: LevelStair in cells[cell].get_meta("stairs"):
			if cells.has(stair.destination) and not previous.has(stair.destination):
				previous[stair.destination] = cell
				queue.append(stair.destination)
	return []

func surface_route(start: Vector3, goal: Vector3, source: Node3D, target: Node3D) -> PackedVector3Array:
	if not is_instance_valid(source) or not is_instance_valid(target):
		return PackedVector3Array()
	if source == target:
		if source is Gallery:
			var section: PackedVector3Array = source.section(source.coordinate(start),source.coordinate(goal))
			section.insert(0,start)
			section.append(goal)
			return section
		return source.get_meta("navigation").route(start,goal)
	var starts: Array = source.cells if source is Gallery else [source.get_meta("cell")]
	var ends: Array = target.cells if target is Gallery else [target.get_meta("cell")]
	var best := PackedVector3Array()
	var shortest := INF
	for first: Vector2i in starts:
		for last: Vector2i in ends:
			var chain := _room_chain(first,last)
			if chain.is_empty():
				continue
			var route := PackedVector3Array([start])
			if source is Gallery:
				var exit_index: int = 0 if source.cells[0]==first else source.points.size()-1
				route.append_array(source.section(source.coordinate(start),exit_index))
			var exit := goal
			var suffix := PackedVector3Array()
			if target is Gallery:
				var entry: int = 0 if target.cells[0]==last else target.points.size()-1
				exit = target.to_global(target.points[entry])
				suffix = target.section(entry,target.coordinate(goal))
				suffix.append(goal)
			var reachable := true
			for i in chain.size():
				var bridge: Gallery
				var stair: LevelStair
				var entry := 0
				var door := exit
				if i+1<chain.size():
					bridge = _link_between(chain[i],chain[i+1])
					if bridge:
						entry = 0 if bridge.cells[0]==chain[i] else bridge.points.size()-1
						door = bridge.to_global(bridge.points[entry])
					else:
						stair = cells[chain[i]].get_meta("stairs")[int(chain[i+1].y>chain[i].y)]
						door = stair.threshold()
				var nav: CellNavigation = cells[chain[i]].get_meta("navigation")
				var section := nav.route(route[-1],door)
				if section.is_empty() or section[-1].distance_to(door)>1.15:
					reachable = false
					break
				route.append_array(section)
				if bridge:
					route.append(door)
					route.append_array(bridge.section(entry,bridge.points.size()-1-entry))
				elif stair:
					route.append(door)
					route.append(_paired(stair).threshold())
			if reachable:
				route.append_array(suffix)
				var length := 0.
				for i in range(1,route.size()):
					length += route[i-1].distance_to(route[i])
				if length < shortest:
					shortest = length
					best = route
	return best

# The route contains one exact pair of thresholds for a stair fold. Ordinary
# navigation points never change the pursuer's frame.
func stair_at_link(a: Vector3,b: Vector3,source: Node3D) -> Node3D:
	if is_instance_valid(source) and source.has_meta("stairs"):
		for stair: LevelStair in source.get_meta("stairs"):
			if stair.threshold().distance_squared_to(a)<.0001 and cells.has(stair.destination):
				var other := _paired(stair)
				if other.threshold().distance_squared_to(b)<.0001:
					return other
	return null

func walking_distance(a: Vector3,b: Vector3,source: Node3D,target: Node3D) -> float:
	var distance := a.distance_to(b)
	if source!=target and is_instance_valid(source) and is_instance_valid(target) and source.has_meta("stairs") and target.has_meta("cell"):
		for stair: LevelStair in source.get_meta("stairs"):
			if stair.destination==target.get_meta("cell"):
				distance = minf(distance,a.distance_to(stair.threshold())+b.distance_to(_paired(stair).threshold()))
	return distance

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
