extends Node3D

enum Kind { SEAL, HOURGLASS }

const REACH := 1.25

var _body := Node3D.new()
var _age := 0.0


func assemble(kind: int, at: Vector3) -> void:
	name = "Relic"
	position = at
	var bronze := _metal(Color("986a41"))
	var basalt := _metal(Color("57555c"))
	var tint := Color("ffc667") if kind == Kind.SEAL else Color("70d9ed")
	var glow := _metal(tint, 1.9)
	_cylinder(self, Vector3(0,.10,0), .43, .5, .20, basalt)
	_cylinder(self, Vector3(0,.34,0), .27, .33, .30, bronze)
	_cylinder(self, Vector3(0,.55,0), .40, .27, .12, bronze)
	_cylinder(self, Vector3(0,.62,0), .37, .37, .025, glow)
	add_child(_body)
	if kind == Kind.SEAL:
		_make_seal(bronze, glow)
	else:
		_make_hourglass(bronze, glow)
	var light := OmniLight3D.new()
	light.position.y = 1.35
	light.light_color = tint
	light.light_energy = 1.4
	light.omni_range = 4.5
	light.light_volumetric_fog_energy = .28
	add_child(light)
	_pose()


static func site_in(room: Node3D, cell: Vector2i, seed_value: int) -> Vector3:
	# These pockets stay well inside a court's rails and clear its central
	# stairwell. The south-east pocket also stays clear of a cathedral portal.
	var sites: Array[Vector3] = []
	var entrances: Array[Vector3] = []
	for face: Vector3i in room.ports:
		for zone: int in room.ports[face]:
			entrances.append(room.port_at(face,zone))
	for row in 3:
		for col in 3:
			if not room.has_court(Vector2i(col,row)):
				continue
			var center := Vector3((col-1)*14.,0,(row-1)*14.)
			sites.append(center + Vector3(4.6,0,4.8))
			if room.get_meta("scene_id") != 5:
				sites.append(center + Vector3(-4.6,0,4.8))
			var zone := row*3+col
			if zone not in room.ports.get(Vector3i.UP,[]) and zone not in room.ports.get(Vector3i.DOWN,[]):
				sites.append(center + Vector3(4.2,0,-4.5))
				sites.append(center + Vector3(-4.2,0,-4.5))
	sites.sort_custom(func(a:Vector3,b:Vector3):
		return _nearest_door(a,entrances) > _nearest_door(b,entrances))
	# Vary the hiding place among the pockets deeper inside the dead end.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ hash(cell)
	return sites[rng.randi_range(0, ceili(sites.size()*.5) - 1)]


static func _nearest_door(at: Vector3, entrances: Array[Vector3]) -> float:
	var nearest := INF
	for door in entrances:
		nearest = minf(nearest, at.distance_squared_to(door))
	return nearest


func _make_seal(bronze: Material, glow: Material) -> void:
	var disk := _cylinder(_body, Vector3.ZERO, .28, .28, .085, bronze)
	disk.rotation.x = PI*.5
	var rim := TorusMesh.new()
	rim.inner_radius = .21
	rim.outer_radius = .255
	rim.rings = 24
	rim.ring_segments = 8
	for side: float in [-1., 1.]:
		var ring := _piece(_body, rim, Vector3(0,0,side*.045), glow)
		ring.rotation.x = PI*.5
		var cut := BoxMesh.new()
		cut.size = Vector3(.17,.17,.025)
		var stamp := _piece(_body, cut, Vector3(0,0,side*.05), glow)
		stamp.rotation.z = PI*.25
	var hanger := _piece(_body, rim, Vector3(0,.29,0), bronze)
	hanger.rotation.x = PI*.5
	hanger.scale = Vector3.ONE*.35


func _make_hourglass(bronze: Material, glow: Material) -> void:
	var glass := _metal(Color(.32,.80,.91,.32))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.metallic = 0.
	_cylinder(_body, Vector3(0,.15,0), .20, .025, .30, glass)
	_cylinder(_body, Vector3(0,-.15,0), .025, .20, .30, glass)
	_cylinder(_body, Vector3(0,.09,0), .115, .017, .18, glow)
	_cylinder(_body, Vector3(0,-.25,0), .025, .145, .10, glow)
	_cylinder(_body, Vector3(0,-.105,0), .012, .012, .21, glow)
	for y: float in [-.32,.32]:
		_cylinder(_body, Vector3(0,y,0), .235, .235, .052, bronze)
	for i in 3:
		var a := i * TAU / 3.
		_cylinder(_body, Vector3(cos(a)*.20,0,sin(a)*.20), .019, .019, .64, bronze)


func _process(delta: float) -> void:
	_age += delta
	_pose()


func _pose() -> void:
	_body.position.y = 1.18 + .055 * sin(_age * 1.7)
	_body.rotation.y = .3 + _age*.65


func _metal(tint: Color, emission := 0.) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = .52
	mat.roughness = .35
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = emission
	return mat


func _cylinder(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 0
	return _piece(parent, mesh, at, mat)


func _piece(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item
