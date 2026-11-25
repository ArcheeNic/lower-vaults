extends RefCounted

# The centre and extent of each room's signature architectural element, in
# its original scenery coordinates. They determine how to hang the scenery
# around the courts and wells drawn for this particular room.
const SUBJECTS := [
	[Vector3(0,0,0), Vector3(25,17,5)], # Vaulted arcade
	[Vector3(0,8,0), Vector3(11,21,11)], # Lighthouse
	[Vector3(0,-3,0), Vector3(18,11,18)], # Planetarium
	[Vector3(-3,6,0), Vector3(20,19,12)], # Crank and ram
	[Vector3(0,3,-6), Vector3(17,11,8)], # Niches
	[Vector3(0,14,-6), Vector3(20,30,6)], # Pointed nave
	[Vector3(0,3,-6), Vector3(17,12,8)], # Tidal stacks
	[Vector3(0,7,0), Vector3(38,17,9)], # Proscenium
	[Vector3(-25,5,-12), Vector3(8,15,17)], # Quarantine windows
	[Vector3(0,3,6), Vector3(20,10,10)], # Rope drums
	[Vector3(0,8,-19), Vector3(47,21,6)], # Scaena frons
	[Vector3(0,11,-9), Vector3(37,20,5)], # Sluice gate
	[Vector3(0,3,-6), Vector3(22,10,9)], # Desks
	[Vector3(0,3,0), Vector3(20,10,8)], # Looms
	[Vector3(0,4,6), Vector3(20,13,9)], # Sorting drawers
	[Vector3(24,8,-15), Vector3(9,21,10)], # Casting furnace
	[Vector3(25,8,-14), Vector3(10,24,10)], # Clock tower
	[Vector3(-11,12,-9), Vector3(6,10,18)], # Inverted carriage
	[Vector3(0,5,0), Vector3(22,20,18)], # Tuning forks
	[Vector3(0,3,0), Vector3(23,12,15)], # Clutch
	[Vector3(0,-3,2), Vector3(19,20,19)], # Meridians
	[Vector3(0,7,2), Vector3(17,11,38)], # Skull and ribs
	[Vector3(-.1,15.45,-1.22), Vector3(22.5,19.6,12)], # Ammonite
	[Vector3(0,4,0), Vector3(28,20,22)], # Ice pillars
	[Vector3(-7,13.8,-7.4), Vector3(18,18,10)], # Eclipse
	[Vector3(0,0,0), Vector3(20,17,14)], # Caldera
	[Vector3(0,9,0), Vector3(27,15,23)], # Jellyfish
	[Vector3(0,5,0), Vector3(29,16,23)], # Spore islands
	[Vector3(-4,12,-4), Vector3(40,20,25)], # Falling satellites
	[Vector3(0,5,0), Vector3(30,15,23)], # Geysers
	[Vector3(0,12,0), Vector3(44,13,30)], # Paper rays
	[Vector3(-16,10,-10), Vector3(16,12,12)], # Lunar honeycomb
	[Vector3(-7,2,-12), Vector3(19,6,4)], # Shelves, drawers and plumb line
]
const Stone := preload("res://tableaux/stone_atlas.gd")
const Wild := preload("res://tableaux/wild_atlas.gd")
const Stage := preload("res://tableaux/stage.gd")
const RoomLife := preload("res://tableaux/room_life.gd")
const Hall := preload("res://architecture/hall.gd")
const Foreign := preload("res://realms/foreign.gd")
const Ironworks := preload("res://world/ironworks.gd")
const Archive := preload("res://world/three_storeys.gd")
const SIDES := [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]


static func palette(id: int) -> Array:
	if id >= 4 and id < 18:
		return [Stone.FLOORS[id-4], Stone.GUARDS[id-4]]
	if id >= 18 and id < 32:
		return [Wild.FLOORS[id-18], Wild.RAILS[id-18]]
	match id:
		1: return ["wood", "rust"]
		2: return ["chalk", "brass"]
		3: return ["iron", "rust"]
		32: return ["wood", "brass"]
	return ["stone", "iron"]


static func dress(room: Node3D, id: int) -> void:
	var source: Array = SUBJECTS[id]
	var clearances: Array[AABB] = []
	var sites := _sites(room, clearances)
	var focus := Vector3.ZERO
	var life := RoomLife.new()
	if id == 32:
		focus = _archive(room, sites, clearances, life)
	else:
		var art := _scenery(id)
		art.name = "Scenery"
		art.transform = _place_subject(source[0], source[1], sites)
		_fit_art(art, art.transform, clearances)
		room.add_child(art)
		focus = art.transform * source[0]
	life.assemble(room,id,focus)
	room.add_child(life)
	var climate: int = preload("res://world/atlas.gd").climate(id)
	var tints := [Color("ffd7a4"),Color("b1dbca"),Color("cbd7ff"),Color("ffad78")]
	# A raking light gives the object relief. The second pool lights the
	# adjoining floor from the room side, irrespective of the route to the exit.
	_lamp(room,focus.move_toward(Vector3.ZERO,5.)+Vector3.UP*4.,tints[climate],7.0,23.)
	_lamp(room,Vector3(1.5,6.5,2),tints[climate].lerp(Color.WHITE,.45),5.,21.)


static func _lamp(room: Node3D, at: Vector3, tint: Color, power: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = tint
	lamp.light_energy = power
	lamp.omni_range = reach
	lamp.light_volumetric_fog_energy = .55
	lamp.add_to_group("scene_lights")
	lamp.set_meta("steady_power", power)
	room.add_child(lamp)


static func _scenery(id: int) -> Node3D:
	# Only build the authored scenery pass. Floors, old approaches and
	# portal triggers all belong to the sandbox's separate circulation pass.
	match id:
		0:
			var hall := Hall.new()
			hall._prepare_resources()
			hall._rng.seed = 923
			# A complete three-bay arcade fits below the neighbouring storey.
			for bay in 3:
				var x := (bay-1)*8.
				hall._arch(Vector3(x,1.4,0),3.35,2.1)
			for x: float in [-12.,-4.,4.,12.]:
				hall._pier(x,0,-8.3,1.4,1.6,2.35)
			hall._box(Vector3(0,5.9,0),Vector3(25.7,.55,2.65),"trim")
			hall._flush()
			hall._body.free()
			return hall
		1, 2:
			var realm := Foreign.new()
			realm._prepare()
			realm._random.seed = 19811
			realm._water = id == 1
			if realm._water:
				realm._cistern()
			else:
				realm._observatory()
			realm._flush()
			realm._body.free()
			return realm
		3:
			var mill := Ironworks.new()
			mill._prepare()
			mill._mill_frame()
			mill._engine()
			mill._finish_batches()
			mill.body.free()
			return mill
	var stage := Stage.new()
	stage.keep_furnishings_together = true
	stage._prepare()
	if id < 18:
		Stone.dress(stage, id-4)
	else:
		Wild.dress(stage, id-18)
	stage._flush_parts()
	stage._body.free()
	return stage


# Keep each case, its shelves, books and drawer pulls on the same masonry
# footing. Alcoves on different elevations never leave loose books behind.
static func _archive(room: Node3D, sites: Array[Rect2], clearances: Array[AABB], life: RoomLife) -> Vector3:
	var art := Archive.new()
	art.name = "Scenery"
	art._body.free()
	art._prepare()
	room.add_child(art)
	var positions: Array[Vector2] = []
	var focus := Vector3.ZERO
	sites.sort_custom(func(a: Rect2,b: Rect2): return a.get_center().length_squared() < b.get_center().length_squared())
	for site in sites:
		var center := site.get_center()
		if positions.any(func(p: Vector2): return p.distance_squared_to(center) < 8.*8.):
			continue
		# Shelves face inward on both sides, with drawers facing the aisle.
		var at := Vector3(center.x,0,center.y)
		var yaw := Basis(Vector3.UP,roundf(atan2(at.x,at.z)/(PI*.5))*PI*.5)
		var frame := Transform3D(yaw,at)
		var bounds := frame * AABB(Vector3(-4.25,-9.6,-1.6),Vector3(8.5,16.,3.2))
		if not _visible_rect(bounds,clearances):
			continue
		var bank := Archive.new()
		bank._body.free()
		bank.transform = frame
		art.add_child(bank)
		bank.archive_shelf(.68,.35)
		bank.archive_drawers(Vector3(-3.60,2.04,0))
		# The front rides out with its open tray, exposing the stored notes.
		var tray := life.pieces(Vector3(-3.05,2.04+(positions.size()%3)*.79,0),bank)
		tray.box(Vector3(-.28,-.28,0),Vector3(.60,.085,.87),"wood")
		tray.box(Vector3(0,0,0),Vector3(.10,.72,.93),"wood")
		tray.box(Vector3(.065,-.06,0),Vector3(.045,.058,.30),"brass")
		tray.box(Vector3(-.25,-.17,0),Vector3(.37,.13,.60),"chalk")
		for edge: float in [-1.,1.]:
			tray.box(Vector3(-.28,-.13,edge*.41),Vector3(.59,.35,.055),"wood")
		tray.position.x += .36
		life.oscillate(tray,5.8+positions.size()*.37,positions.size()*1.93,Vector3.RIGHT*.32)
		bank.box(Vector3(-.35,-.26,0),Vector3(7.96,.5,3.),"stone")
		for x: float in [-3.,2.58]:
			bank.box(Vector3(x,-4.9,0),Vector3(1.18,9.1,2.),"basalt")
			bank.box(Vector3(x,-.66,0),Vector3(1.5,.31,2.3),"brass")
		if positions.size()%3 == 0:
			var crown := Vector3(.68,5.55,0)
			for ring in 3:
				bank.ring(crown, .86-ring*.12,.044,"brass", Vector3(.5+ring*.48,.7*ring,.36+ring*.5))
			bank.ball(crown,Vector3.ONE*.38,"pearl")
			bank.column(crown-Vector3.UP*.8,Vector3(.17,1.26,.17),"brass")
		bank._flush_parts()
		if positions.is_empty():
			focus = at + Vector3.UP*2.
		positions.append(center)
		if positions.size() == 9:
			break
	return focus


static func _sites(room: Node3D, clearances: Array[AABB]) -> Array[Rect2]:
	var sites: Array[Rect2] = []
	# Adjacent unused courts can take one whole nave, engine, or skeleton.
	for row in 3:
		for col in 3:
			var court := Vector2i(col,row)
			if room.has_court(court):
				var zone := row*3+col
				var shaft: bool = zone in room.ports.get(Vector3i.UP,[]) or zone in room.ports.get(Vector3i.DOWN,[])
				var edges: Array = room.COURT_EDGES
				var lower := Vector3(edges[col]-.20,-9.85 if shaft else -.8,edges[row]-.20)
				var upper := Vector3(edges[col+1]+.20,9.85 if shaft else 3.7,edges[row+1]+.20)
				clearances.append(AABB(lower, upper-lower))
				continue
			for h in range(1,4-row):
				for w in range(1,4-col):
					var vacant := true
					for y in range(row,row+h):
						for x in range(col,col+w):
							if room.has_court(Vector2i(x,y)):
								vacant = false
					if vacant:
						sites.append(Rect2(col*14.-20.6,row*14.-20.6,w*14.-.8,h*14.-.8))
	for face: Vector3i in SIDES:
		var along_x := face.x == 0
		var sign_axis := face.z if along_x else face.x
		var strip := Rect2(-36.,24.8 if sign_axis > 0 else -36.,72.,11.2)
		if not along_x:
			strip = Rect2(strip.position.y,strip.position.x,strip.size.y,strip.size.x)
		if not room.ports.has(face):
			sites.append(strip)
		else:
			# Reserve the exterior corridor for the matching port column,
			# including the return flights that lead up to high wall sockets.
			for zone: int in room.ports[face]:
				var lateral := ((zone % 3)-1)*14.
				var near_edge := 20.5 if sign_axis > 0 else -38.
				var base := Vector3(lateral-7.3,-10.,near_edge) if along_x else Vector3(near_edge,-10.,lateral-7.3)
				var size3 := Vector3(14.6,20.,17.5) if along_x else Vector3(17.5,20.,14.6)
				clearances.append(AABB(base,size3))
	for x in [-36.,25.]:
		for z in [-36.,25.]:
			sites.append(Rect2(x,z,11.,11.))
	return sites


static func _place_subject(focus: Vector3, extent: Vector3, sites: Array[Rect2]) -> Transform3D:
	var best := -INF
	var result := Transform3D.IDENTITY
	for site in sites:
		var center := site.get_center()
		for quarter in 4:
			var yaw := Basis(Vector3.UP,quarter*PI*.5)
			var span := (yaw * extent).abs()
			var factor := minf(1.2,minf(16./span.y,minf(site.size.x/span.x,site.size.y/span.z)))
			var outward := yaw.z
			var facing := Vector2(outward.x,outward.z).dot(-center.normalized())
			var score := factor - .010*center.length() - .002*center.y + .016*facing
			if score > best:
				best = score
				var axes := yaw.scaled(Vector3.ONE * factor)
				result = Transform3D(axes,Vector3(center.x,1.5,center.y) - axes*focus)
	return result


static func _visible_rect(bounds: AABB, clearances: Array[AABB]) -> bool:
	if not AABB(Vector3(-37.9,-9.95,-37.9),Vector3(75.8,19.9,75.8)).encloses(bounds):
		return false
	for clearance in clearances:
		if clearance.intersects(bounds):
			return false
	return true


static func _fit_art(node: Node3D, frame: Transform3D, clearances: Array[AABB]) -> void:
	# Discard complete mesh instances in pedestrian space, including hanging
	# props over a shaft. Rebatch the remaining masonry without changing its
	# material, texture coordinates or individual weathering.
	var excluded := {}
	for child in node.get_children():
		if not child.has_meta("furnishings"): continue
		var groups: PackedInt32Array = child.get_meta("furnishings")
		var batch: MultiMesh = child.multimesh
		var basis: Transform3D = frame * child.transform
		var shape := batch.mesh.get_aabb()
		for i in groups.size():
			if groups[i] and not excluded.has(groups[i]) and not _visible_rect(basis * batch.get_instance_transform(i) * shape, clearances):
				excluded[groups[i]] = true
	for child: Node3D in node.get_children():
		var xf := frame * child.transform
		if child is MultiMeshInstance3D:
			var batch: MultiMesh = child.multimesh
			var bounds := batch.mesh.get_aabb()
			var indices := PackedInt32Array()
			var groups: PackedInt32Array = child.get_meta("furnishings", PackedInt32Array())
			if not groups.is_empty():
				child.remove_meta("furnishings")
			for i in batch.instance_count:
				if not groups.is_empty() and excluded.has(groups[i]):
					continue
				if _visible_rect((xf * batch.get_instance_transform(i)) * bounds, clearances):
					indices.append(i)
			if indices.is_empty():
				child.free()
			elif indices.size() != batch.instance_count:
				var trimmed := MultiMesh.new()
				trimmed.transform_format = MultiMesh.TRANSFORM_3D
				trimmed.use_colors = batch.use_colors
				trimmed.use_custom_data = batch.use_custom_data
				trimmed.mesh = batch.mesh
				trimmed.instance_count = indices.size()
				for i in indices.size():
					var source := indices[i]
					trimmed.set_instance_transform(i,batch.get_instance_transform(source))
					if trimmed.use_colors:
						trimmed.set_instance_color(i,batch.get_instance_color(source))
					if trimmed.use_custom_data:
						trimmed.set_instance_custom_data(i,batch.get_instance_custom_data(source))
				child.multimesh = trimmed
		elif child is MeshInstance3D and child.mesh:
			child.visible = _visible_rect(xf * child.get_aabb(),clearances)
		else:
			_fit_art(child, xf, clearances)
