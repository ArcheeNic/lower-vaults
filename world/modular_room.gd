extends "res://tableaux/stage.gd"

const Setting := preload("res://tableaux/room_setting.gd")
const LevelStair := preload("res://world/level_stair.gd")
const SIZE := Vector3(76, 20, 76)
const LATERAL := [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
const CENTER := Vector2i(1, 1)
const COURT_EDGES := [-23., -7., 7., 23.]
const SHELL_EDGES := [-38., -7., 7., 38.]
const WIDTH := 1.08 # Half-width of a stair flight.
const WELL_RADIUS := 4.4
const WELL_DEPTH := 4.9

var ports: Dictionary
var _courts := {}
var _skin := "basalt"
var _scene_id: int


static func port_at(face: Vector3i, zone: int) -> Vector3:
	var column := (zone % 3 - 1) * 14.
	var row := floori(zone / 3.) - 1
	if face.y:
		return Vector3(column, face.y * SIZE.y * .5, row * 14.)
	if face.x:
		return Vector3(face.x * SIZE.x * .5, row * 4., column)
	return Vector3(column, row * 4., face.z * SIZE.z * .5)


func spawn_at() -> Vector3:
	return Vector3(0, 0, 3.5)


func exit_at() -> Vector3:
	return Vector3(0, 0, 5.7)


func has_court(sector: Vector2i) -> bool:
	return _courts.has(sector)


func assemble(scene_id: int, openings: Dictionary) -> void:
	ports = openings
	_scene_id = scene_id
	_prepare()
	add_child(_body)
	var palette := Setting.palette(scene_id)
	_floor = palette[0]
	_handrail = palette[1]
	_skin = _floor if _floor in ["basalt","stone","chalk","salt","iron","rust","wood"] else "basalt"
	_courts[CENTER] = true
	for face: Vector3i in ports:
		for zone: int in ports[face]:
			var sector := _port_sector(face, zone)
			_join_courts(sector, (scene_id + sector.x + sector.y) % 2 == 0)
	for sector: Vector2i in _courts:
		_build_court(sector)
	for face: Vector3i in LATERAL:
		_build_shell_wall(face)
		for zone: int in ports.get(face, []):
			_side_flight(face, zone)
	for face: Vector3i in [Vector3i.DOWN, Vector3i.UP]:
		_build_cap(face)
		for zone: int in ports.get(face, []):
			_well_stairs(face, zone)
	if scene_id == 5:
		_cathedral_portals()
	Setting.dress(self, scene_id)
	_finish_geometry()


func _port_sector(face: Vector3i, zone: int) -> Vector2i:
	if face.x: return Vector2i(1 + face.x, zone % 3)
	if face.z: return Vector2i(zone % 3, 1 + face.z)
	return Vector2i(zone % 3, floori(zone / 3.))


func _join_courts(sector: Vector2i, x_first: bool) -> void:
	# A corner sector needs one of its two intervening courts to reach the nave.
	if sector.x != 1 and sector.y != 1:
		_courts[Vector2i(sector.x, 1) if x_first else Vector2i(1, sector.y)] = true
	_courts[sector] = true


func _solid_box(at: Vector3, sizes: Vector3, material: String) -> void:
	if sizes.x < .001 or sizes.y < .001 or sizes.z < .001: return
	box(at, sizes, material)
	var shape := BoxShape3D.new()
	shape.size = sizes
	_add_collider(shape, Transform3D(Basis.IDENTITY, at))


func _slab(rect: Rect2, height: float, thickness: float, material: String) -> void:
	if not rect.has_area(): return
	var middle := rect.get_center()
	_solid_box(Vector3(middle.x, height - thickness*.5, middle.y),
		Vector3(rect.size.x, thickness, rect.size.y), material)


func _cut_rect(rect: Rect2, hole: Rect2) -> Array[Rect2]:
	# Four disjoint pieces, in a common local plane.
	var cut := rect.intersection(hole)
	if not cut.has_area(): return [rect]
	return [
		Rect2(rect.position, Vector2(rect.size.x, cut.position.y - rect.position.y)),
		Rect2(rect.position.x, cut.end.y, rect.size.x, rect.end.y - cut.end.y),
		Rect2(rect.position.x, cut.position.y, cut.position.x - rect.position.x, cut.size.y),
		Rect2(cut.end.x, cut.position.y, rect.end.x - cut.end.x, cut.size.y)
	]


func _well_rect(zone: int) -> Rect2:
	var p := port_at(Vector3i.UP, zone)
	return Rect2(p.x - WELL_RADIUS - WIDTH, p.z - WELL_DEPTH - WIDTH,
		2. * (WELL_RADIUS + WIDTH), WELL_DEPTH + 2.*WIDTH)


func _sector_rect(sector: Vector2i, edges: Array) -> Rect2:
	var low := Vector2(edges[sector.x], edges[sector.y])
	return Rect2(low, Vector2(edges[sector.x+1], edges[sector.y+1]) - low)


func _build_court(sector: Vector2i) -> void:
	var rect := _sector_rect(sector, COURT_EDGES)
	var zone := sector.y*3 + sector.x
	if zone in ports.get(Vector3i.DOWN, []):
		var well := _well_rect(zone)
		for piece in _cut_rect(rect, well):
			_slab(piece, 0., .48, _floor)
		_well_rim(well, port_at(Vector3i.DOWN,zone).x)
	else:
		_slab(rect, 0., .48, _floor)
	for face: Vector3i in LATERAL:
		var step := Vector2i(face.x, face.z)
		if has_court(sector + step): continue
		var edge: float
		var low: float
		var high: float
		if face.x:
			edge = rect.position.x if face.x < 0 else rect.end.x
			low = rect.position.y
			high = rect.end.y
		else:
			edge = rect.position.y if face.z < 0 else rect.end.y
			low = rect.position.x
			high = rect.end.x
		var mouths: Array[float] = []
		if is_equal_approx(absf(edge), COURT_EDGES[-1]):
			for socket: int in ports.get(face, []):
				if _port_sector(face,socket) == sector:
					mouths.append(_mouth(socket))
		mouths.sort()
		for mouth in mouths:
			_edge_rail(face,edge,low,mouth-WIDTH)
			low = mouth+WIDTH
		_edge_rail(face,edge,low,high)


func _edge_rail(face: Vector3i, edge: float, low: float, high: float) -> void:
	if high - low < .03: return
	if face.x:
		_guard(Vector3(edge,0,low),Vector3(edge,0,high))
	else:
		_guard(Vector3(low,0,edge),Vector3(high,0,edge))


func _well_rim(well: Rect2, center_x: float) -> void:
	_edge_rail(Vector3i.RIGHT, well.position.x, well.position.y, well.end.y)
	_edge_rail(Vector3i.RIGHT, well.end.x, well.position.y, well.end.y)
	_edge_rail(Vector3i.BACK, well.position.y, well.position.x, well.end.x)
	_edge_rail(Vector3i.BACK, well.end.y, well.position.x, center_x-WIDTH)
	_edge_rail(Vector3i.BACK, well.end.y, center_x+WIDTH, well.end.x)


func _build_shell_wall(face: Vector3i) -> void:
	var y_edges := [-10., -.65, 3.35, 10.]
	var openings: PackedInt32Array = ports.get(face, PackedInt32Array())
	for zone in 9:
		var x_index := zone % 3
		var y_index := floori(zone / 3.)
		var panel := Rect2(SHELL_EDGES[x_index], y_edges[y_index],
			SHELL_EDGES[x_index+1] - SHELL_EDGES[x_index], y_edges[y_index+1] - y_edges[y_index])
		var pieces: Array[Rect2] = [panel]
		if zone in openings:
			var threshold := port_at(face,zone)
			var tangent := threshold.z if face.x else threshold.x
			pieces = _cut_rect(panel, Rect2(tangent-WIDTH-.12,threshold.y-.04,2.*WIDTH+.24,3.16))
		for piece in pieces:
			var c := piece.get_center()
			if face.x:
				_solid_box(Vector3(face.x*37.84,c.y,c.x),Vector3(.28,piece.size.y,piece.size.x),_skin)
			else:
				_solid_box(Vector3(c.x,c.y,face.z*37.84),Vector3(piece.size.x,piece.size.y,.28),_skin)


func _build_cap(face: Vector3i) -> void:
	var openings: PackedInt32Array = ports.get(face, PackedInt32Array())
	for zone in 9:
		var sector := Vector2i(zone % 3,floori(zone / 3.))
		var rect := _sector_rect(sector,SHELL_EDGES)
		var pieces: Array[Rect2] = [rect]
		if zone in openings:
			pieces = _cut_rect(rect, _well_rect(zone).grow(.19))
		for piece in pieces:
			_slab(piece, 9.98 if face.y > 0 else -9.70, .27, _skin)


func _mouth(zone: int) -> float:
	return (zone % 3 - 1)*14. + (floori(zone/3.)-1)*3.65


func _side_flight(face: Vector3i, zone: int) -> void:
	var normal := Vector3(face)
	var tangent := Vector3.BACK if face.x else Vector3.RIGHT
	var stop := port_at(face, zone)
	var lane := _mouth(zone)
	var foot := normal * 23. + tangent * lane
	# Parallel lanes acquire their full vertical clearance before converging.
	var ledge := normal * 31. + tangent * lane + Vector3.UP * stop.y
	if is_zero_approx(stop.y):
		var low := foot.lerp(ledge, .5) - Vector3.UP*.82
		_flight(foot, low)
		_flight(low, ledge)
	else:
		_flight(foot, ledge)
	var dock := stop - normal * 2.
	_deck(ledge, dock, tangent)
	_deck(dock, stop, tangent)
	_dress_flight(foot, ledge, -.82 if is_zero_approx(stop.y) else 0.)
	_fixture(ledge + tangent*(WIDTH+.10), 1.72)
	var crossbar := stop - normal*.52 + Vector3.UP*2.87
	beam(crossbar-tangent*(WIDTH+.12), crossbar+tangent*(WIDTH+.12), .14,.12,_handrail)
	for side: float in [-1.,1.]:
		var post := stop-normal*.52+tangent*side*(WIDTH+.12)
		beam(post, post+Vector3.UP*2.87, .11,.11,_handrail)


func _deck(a: Vector3, b: Vector3, tangent: Vector3) -> void:
	# Keep the edge perpendicular to the wall even on the converging landing.
	var edge := tangent * WIDTH
	var vertices := PackedVector3Array([a-edge,a+edge,b+edge,a-edge,b+edge,b-edge])
	# Godot source geometry is front-facing clockwise.
	if (vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).y > 0:
		vertices.reverse()
	_walk.append_array(vertices)
	var mesh_tool := SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in vertices:
		mesh_tool.set_normal(Vector3.UP)
		mesh_tool.add_vertex(point)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh_tool.commit()
	instance.material_override = materials[_floor]
	add_child(instance)
	beam(a-Vector3.UP*.23,b-Vector3.UP*.23,WIDTH*1.5,.38,_floor)
	_guard(a-edge,b-edge)
	_guard(a+edge,b+edge)


func _flight(a: Vector3, b: Vector3) -> void:
	var horizontal := (b-a).slide(Vector3.UP)
	var axis := horizontal.normalized()
	var side := Vector3.UP.cross(axis) * WIDTH
	var frame := Basis(side.normalized(),Vector3.UP,axis)
	_walk.append_array(PackedVector3Array([a-side,a+side,b+side,a-side,b+side,b-side]))
	var count := maxi(1, ceili(absf(b.y-a.y)/.185))
	var depth := horizontal.length()/count
	for i in count:
		var at := a.lerp(b,(i+.5)/count)
		_part("box",_floor,at-Vector3.UP*.12,Vector3(WIDTH*2.,.24,depth+.015),frame)
		_part("box",_handrail,at-axis*(depth*.5-.032),Vector3(WIDTH*2.,.023,.064),frame)
	_guard(a-side,b-side)
	_guard(a+side,b+side)


func _well_stairs(face: Vector3i, zone: int) -> void:
	var seam := port_at(face,zone)
	var base := Vector3(seam.x, minf(0.,seam.y), seam.z)
	var points: Array[Vector3] = [
		base, base + Vector3.RIGHT*WELL_RADIUS,
		base + Vector3(WELL_RADIUS,0,-WELL_DEPTH),
		base + Vector3(-WELL_RADIUS,0,-WELL_DEPTH),
		base + Vector3.LEFT*WELL_RADIUS, base
	]
	# One complete turn climbs half a storey. Matching turns meet on the seam.
	var run := 4.*WELL_RADIUS + 2.*WELL_DEPTH - 10.*WIDTH
	var climbed := 0.
	for i in range(points.size()-1):
		var dir := points[i].direction_to(points[i+1])
		var a := points[i] + dir*WIDTH + Vector3.UP*climbed
		var b := points[i+1] - dir*WIDTH
		climbed += b.slide(Vector3.UP).distance_to(a.slide(Vector3.UP)) * (SIZE.y*.5/run)
		b.y = base.y + climbed
		_flight(a,b)
		if i == 2:
			_dress_flight(a,b,0.)
		if i < points.size()-2:
			_well_corner(points[i+1] + Vector3.UP*climbed,dir,points[i+1].direction_to(points[i+2]))
	_fixture(base + Vector3(0,SIZE.y*.25,-WELL_DEPTH-WIDTH-.10), 1.6)
	# Each adjoining room owns its half of the landing at the boundary.
	var seam_side := -1. if face.y>0 else 1.
	var seam_rect := Rect2(seam.x+minf(0.,seam_side*WIDTH),seam.z-WIDTH,WIDTH,WIDTH*2.)
	_slab(seam_rect,seam.y,.23,_floor)
	for zsign: float in [-1.,1.]:
		_guard(seam+Vector3.BACK*zsign*WIDTH,seam+Vector3(seam_side*WIDTH,0,zsign*WIDTH))
	if face.y<0:
		# Flush with the opening in the central floor. The southern side stays open.
		var center := Vector3(seam.x,0,seam.z)
		_slab(Rect2(seam.x-WIDTH,seam.z-WIDTH,WIDTH*2.,WIDTH*2.),0.,.24,_floor)
		_guard(center+Vector3(-WIDTH,0,-WIDTH),center+Vector3(WIDTH,0,-WIDTH))
		if zone not in ports.get(Vector3i.UP, []):
			_guard(center+Vector3(WIDTH,0,-WIDTH),center+Vector3(WIDTH,0,WIDTH))


func _well_corner(at: Vector3, incoming: Vector3, outgoing: Vector3) -> void:
	_slab(Rect2(at.x-WIDTH,at.z-WIDTH,2.*WIDTH,2.*WIDTH),at.y,.24,_floor)
	for outward in [incoming, -outgoing]:
		var across := Vector3.UP.cross(outward)*WIDTH
		var edge: Vector3 = at + outward * WIDTH
		_guard(edge-across,edge+across)


func _cathedral_portals() -> void:
	# The apparition offers a shortcut across two already connected courts.
	if _courts.size() < 2: return
	var farthest: Vector2i = CENTER
	for sector: Vector2i in _courts:
		if sector.distance_squared_to(CENTER) > farthest.distance_squared_to(CENTER):
			farthest = sector
	var offset := Vector3((farthest.x-1)*14.,0,(farthest.y-1)*14.)
	var first := Vector3(-3.8, 1.32, 4.4)
	for back in [false, true]:
		var frame := FoldWell.new()
		frame.position = first + (offset if back else Vector3.ZERO)
		frame.rotation.x = -PI*.5 if back else PI*.5
		frame.displacement = frame.basis.inverse() * (-offset if back else offset)
		add_child(frame)
		var width := FoldWell.HALF_OPENING
		for sign_x: float in [-1.,1.]:
			var pier := frame.position + Vector3.RIGHT * sign_x * (width+.12)
			column(pier,Vector3(.23,2.64,.23),"chalk")
			box(pier-Vector3.UP*1.2,Vector3(.40,.19,.40),"basalt")
		beam(frame.position+Vector3(-width-.22,width,0),frame.position+Vector3(width+.22,width,0),.22,.19,"brass")


func _fixture(base: Vector3, height: float) -> void:
	var at := base + Vector3.UP * height
	beam(base, at, .10, .10, _handrail)
	box(at, Vector3(.31,.41,.31), "pearl")
	for y: float in [-.22,.22]:
		box(at+Vector3.UP*y,Vector3(.39,.065,.39), _handrail)
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = Color("ffdfa8")
	lamp.light_energy = 3.2
	lamp.omni_range = 10.
	lamp.light_volumetric_fog_energy = .35
	lamp.set_meta("steady_power",lamp.light_energy)
	lamp.add_to_group("scene_lights")
	add_child(lamp)


func _dress_flight(a: Vector3, b: Vector3, dip: float) -> void:
	# Fit this setting's authored staircase ornament to the length and gradient
	# of the active flight. Batch it with the room's stonework and railings.
	var art := LevelStair.new()
	var style: Script = LevelStair.Original
	var index := _scene_id
	if _scene_id >= 4 and _scene_id < 18:
		style = LevelStair.Stone
		index -= 4
	elif _scene_id >= 18 and _scene_id < 32:
		style = LevelStair.Wild
		index -= 18
	var delta := b-a
	var plan := delta.slide(Vector3.UP)
	var scale_y := .72
	art.profile = PackedVector2Array([Vector2.ZERO, Vector2(4.,(delta.y*.5+dip)/scale_y), Vector2(8.,delta.y/scale_y)])
	style.dress(art,index)
	var forward := plan.normalized()
	var basis3 := Basis(Vector3.UP.cross(forward)*.77, Vector3.UP*scale_y, forward*plan.length()/8.)
	var placement := Transform3D(basis3,a)
	for key: String in art._parts:
		if not _parts.has(key):
			_parts[key] = []
		var mesh_bounds: AABB = meshes[key.get_slice("/",0)].get_aabb()
		var batch: Array = _parts[key]
		for detail: Transform3D in art._parts[key]:
			var fitted := placement * detail
			var bounds := fitted * mesh_bounds
			if bounds.end.y < SIZE.y*.5-.30 and bounds.position.y > -SIZE.y*.5+.30:
				batch.append(fitted)
	art._body.free()
	art.free()
