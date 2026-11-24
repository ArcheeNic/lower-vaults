extends Node3D

const WHEEL := preload("res://models/crankwheel.glb")
const METAL := preload("res://world/metal.gdshader")
static var palette := {}
static var primitives := {}
var batches := {}
var junction_dirs := {}
var body := StaticBody3D.new()
var drive := Node3D.new()
var ram := Node3D.new()
var furnace_light := OmniLight3D.new()
var cycle := 0.0

static func _prepare() -> void:
	if not palette.is_empty():
		return
	for pair in [["gunmetal","535655"],["oxide","89533b"],["deck","797568"],["trim","bea466"],["ochre","ac792b"]]:
		var m := ShaderMaterial.new()
		m.shader = METAL
		m.set_shader_parameter("paint",Color(pair[1]))
		m.set_shader_parameter("patina",preload("res://architecture/limestone.png"))
		m.set_shader_parameter("decking",pair[0]=="deck")
		palette[pair[0]] = m
	var hot := StandardMaterial3D.new()
	hot.albedo_color = Color("ffc35b")
	hot.emission_enabled = true
	hot.emission = Color("ff842f")
	hot.emission_energy_multiplier = 4
	palette["heat"] = hot
	primitives["box"] = BoxMesh.new()
	var drum := CylinderMesh.new()
	drum.radial_segments = 24
	drum.rings = 1
	drum.top_radius = .5
	drum.bottom_radius = .5
	drum.height = 1
	primitives["round"] = drum

func build(seed_value: int) -> void:
	_prepare()
	add_child(body)
	cycle = float(posmod(seed_value, 93))*.09
	var north := Vector3(0,0,-15)
	var south := Vector3(0,0,15)
	var west := Vector3(-18,0,0)
	var east := Vector3(18,0,0)
	for p: Vector3 in [north,south,west,east]:
		_junction(p)
	_path(Vector3(0,0,-24),north)
	_path(south,Vector3(0,0,24))
	_path(Vector3(-32,0,0),west)
	_path(east,Vector3(32,0,0))
	for sign_x in [-1,1]:
		var s := float(sign_x)
		var h := 2.4 if sign_x<0 else -1.65
		var a := Vector3(9.7*s,h,-6.7)
		var b := Vector3(9.7*s,h,6.7)
		var mid := Vector3(9.7*s,h,0)
		for p: Vector3 in [a,b,mid]:
			_junction(p)
		_path(north,a)
		_path(a,mid)
		_path(mid,b)
		_path(b,south)
		_path(west if sign_x<0 else east,mid)
	_close_platform_edges()
	_mill_frame()
	_engine()
	_finish_batches()

func _piece(shape: String, mat: String, at: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var key := shape + "/" + mat
	if not batches.has(key):
		batches[key] = []
	batches[key].append(Transform3D(basis.scaled_local(size),at))

func _finish_batches() -> void:
	for key: String in batches:
		var names := key.split("/")
		var data: Array = batches[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = primitives[names[0]]
		mm.instance_count = data.size()
		for i in data.size():
			mm.set_instance_transform(i,data[i])
		var mesh := MultiMeshInstance3D.new()
		mesh.multimesh = mm
		mesh.material_override = palette[names[1]]
		add_child(mesh)
	batches.clear()

func _solid(at: Vector3, basis: Basis, shape: Shape3D) -> void:
	var slot := body.create_shape_owner(body)
	body.shape_owner_set_transform(slot,Transform3D(basis,at))
	body.shape_owner_add_shape(slot,shape)

func _bar(a: Vector3, b: Vector3, width: float, thick: float, mat: String, solid := false) -> void:
	var z := (b-a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var basis := Basis(x,z.cross(x),z)
	var dims := Vector3(width,thick,a.distance_to(b))
	_piece("box",mat,(b+a)*.5,dims,basis)
	if solid:
		var box := BoxShape3D.new()
		box.size = dims
		_solid((b+a)*.5,basis,box)

func _junction(p: Vector3) -> void:
	junction_dirs[p] = []
	_piece("round","deck",p-Vector3.UP*.25,Vector3(4.52,.5,4.52))
	var pad := CylinderShape3D.new()
	pad.radius = 2.26
	pad.height = .5
	_solid(p-Vector3.UP*.25,Basis.IDENTITY,pad)
	_piece("round","oxide",p-Vector3.UP*6.28,Vector3(.65,12,.65))

func _path(a: Vector3,b: Vector3) -> void:
	var plan := Vector3(b.x-a.x,0,b.z-a.z).normalized()
	var side := Vector3.UP.cross(plan)
	var u := a
	var v := b
	if not is_equal_approx(a.y,b.y):
		u += plan*2.62
		v -= plan*2.62
		_floor_strip(a,u)
		_floor_strip(v,b)
	_floor_strip(u,v)
	for pt: Vector3 in [a,b]:
		if junction_dirs.has(pt):
			var away := plan if pt==a else -plan
			junction_dirs[pt].append(atan2(away.z,away.x))
	var trim := sqrt(2.26*2.26-1.99*1.99)
	var start_pad := trim if junction_dirs.has(a) else .07
	var end_pad := trim if junction_dirs.has(b) else .07
	for hand in [-1.,1.]:
		var offset: Vector3 = side*1.99*hand
		var start := a+plan*start_pad+offset
		var end := b-plan*end_pad+offset
		if not is_equal_approx(a.y,b.y):
			_guard(start,u+offset)
			_guard(u+offset,v+offset)
			_guard(v+offset,end)
		else:
			_guard(start,end)

func _close_platform_edges() -> void:
	var mouth := asin(1.99/2.26)
	for p: Vector3 in junction_dirs:
		var angles: Array = junction_dirs[p]
		angles.sort()
		for i in angles.size():
			var a: float = angles[i]+mouth
			var b: float = angles[(i+1)%angles.size()]-mouth
			if i==angles.size()-1:
				b += TAU
			if b<=a+.012:
				continue
			var count := ceili((b-a)/.45)
			for j in count:
				var start := lerpf(a,b,float(j)/count)
				var end := lerpf(a,b,float(j+1)/count)
				_guard(p+Vector3(cos(start),0,sin(start))*2.26,p+Vector3(cos(end),0,sin(end))*2.26)
	junction_dirs.clear()

func _guard(start: Vector3,end: Vector3) -> void:
	_bar(start+Vector3.UP*.96,end+Vector3.UP*.96,.10,.1,"ochre")
	var diff := end-start
	var dir := diff.normalized()
	var x := Vector3.UP.cross(dir).normalized()
	var basis := Basis(x,dir.cross(x),dir)
	var barrier := BoxShape3D.new()
	barrier.size = Vector3(.10,1.03,diff.length())
	_solid((start+end)*.5+Vector3.UP*.52,basis,barrier)
	_bar(start+Vector3.UP*.46,end+Vector3.UP*.46,.06,.08,"gunmetal")
	var count := maxi(1,ceili(start.distance_to(end)/2.35))
	for i in range(count+1):
		_piece("box","oxide",start.lerp(end,float(i)/count)+Vector3.UP*.52,Vector3(.095,1.04,.095))

func _floor_strip(a: Vector3,b: Vector3) -> void:
	var z := (b-a).normalized()
	var n := z.cross(Vector3.UP.cross(z).normalized())
	_bar(a-n*.18,b-n*.18,4.15,.36,"deck",true)
	_bar(a-n*.47,b-n*.47,3.88,.25,"oxide")

func _mill_frame() -> void:
	# Rows of boiler vessels leave the four entrances open below the pipe racks.
	for hand in [-1.,1.]:
		for end in [-1.,1.]:
			var x: float = hand*22.2
			var z: float = end*14.6
			var h: float = 12.+posmod(roundi(x+z),6)
			_piece("round","gunmetal",Vector3(x,h*.5-4,z),Vector3(7.2,h+8.,7.2))
			for y in [-4.,-.4,3.2,6.8,h-.8,h]:
				_piece("round","oxide",Vector3(x,y,z),Vector3(7.42,.31,7.42))
			for j in range(13):
				var angle := j*TAU/13
				_piece("round","trim",Vector3(x+3.54*cos(angle),h*.5,z+3.54*sin(angle)),Vector3(.11,h,.11))
			for j in range(3):
				var px: float = x+hand*(4.2+j*.67)
				var height: float = h+5.2-j*1.25
				_piece("round","oxide",Vector3(px,height*.5-3,z+end*j*.51),Vector3(.52,height+6.,.52))
				_piece("round","trim",Vector3(px,height,z+end*j*.51),Vector3(.70,.28,.70))
			_bar(Vector3(x,10,z),Vector3(hand*13.,10,z),.57,.59,"oxide")
	for z in [-9.,9.]:
		for x in [-14.,14.]:
			_piece("box","gunmetal",Vector3(x,5,z),Vector3(.76,29,.85))
			_piece("box","oxide",Vector3(x,5,z),Vector3(1.11,29,.26))
		_bar(Vector3(-14,16,z),Vector3(14,16,z),.64,.62,"oxide")
		_bar(Vector3(-14,18,z),Vector3(14,18,z),.64,.62,"oxide")
		for j in range(8):
			var x := -14.+j*3.5
			_bar(Vector3(x,16.2 if j%2==0 else 17.8,z),Vector3(x+3.5,17.8 if j%2==0 else 16.2,z),.22,.24,"ochre")
	for i in range(8):
		var z := -7.+i*2.
		_piece("box","heat",Vector3(0,-6.4,z),Vector3(7.7,.14,.13))
	_piece("box","gunmetal",Vector3(0,-7,0),Vector3(8.5,1.1,17.5))
	for x in [-4.1,4.1]:
		_piece("box","oxide",Vector3(x,-6.15,0),Vector3(.45,.55,17.7))

func _engine() -> void:
	# The rotating drive and overhead ram share one crank phase.
	var wheel_frame := Node3D.new()
	wheel_frame.position = Vector3(1,6,0)
	wheel_frame.rotation = Vector3(PI/2,.38,0)
	add_child(wheel_frame)
	wheel_frame.add_child(drive)
	drive.add_child(WHEEL.instantiate())
	for s in [-1.,1.]:
		var pillar := Vector3(-9.7+s*2.85,7.,0)
		_piece("round","gunmetal",pillar,Vector3(.67,22.,.67))
		_piece("round","trim",pillar+Vector3.UP*4.,Vector3(.83,1.1,.83))
	_piece("box","oxide",Vector3(-9.7,14.8,0),Vector3(7.1,2.7,5.4))
	for x in [-11.9,-7.5]:
		_piece("box","heat",Vector3(x,13.42,0),Vector3(.12,.09,3.5))
	ram.position = Vector3(-9.7,9.1,0)
	add_child(ram)
	for data: Array in [[Vector3(0,0,0),Vector3(4.5,1.2,4.3),"gunmetal"],[Vector3(0,-.67,0),Vector3(4.74,.22,4.45),"ochre"],[Vector3(0,5.7,0),Vector3(1.12,10.5,1.12),"trim"]]:
		var piece := MeshInstance3D.new()
		piece.mesh = primitives["box"]
		piece.position = data[0]
		piece.scale = data[1]
		piece.material_override = palette[data[2]]
		ram.add_child(piece)
	furnace_light.position = Vector3(0,-4,0)
	furnace_light.light_color = Color("ff8036")
	furnace_light.omni_range = 21
	furnace_light.shadow_enabled = true
	furnace_light.light_volumetric_fog_energy = 1.5
	furnace_light.add_to_group("scene_lights")
	furnace_light.set_meta("steady_power",4.0)
	add_child(furnace_light)

func _process(delta: float) -> void:
	cycle += delta*.57
	drive.rotation.y = -cycle
	ram.position.y = 5.65 + 5.2*(.5+.5*cos(cycle))
	furnace_light.set_meta("steady_power",4.+.95*sin(cycle*2.))
