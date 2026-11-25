extends "res://tableaux/stage.gd"

const PITCH := 7.0
const THROAT_X := 15.
const HALF := 1.6
const NAMES := ["Колодец отливов", "Архив мер и весов", "Звёздная камера"]
const CLIMATES := [1,0,2]
const FLOORS := ["iron","wood","chalk"]
const RAILS := ["rust","brass","iron"]
var junctions := {}

func assemble() -> void:
	_prepare()
	add_child(_body)
	for storey in range(-1,2):
		var y := storey*PITCH
		for z: float in [-9.,9.]:
			var xs := [-10.,0.,7.,THROAT_X]
			if (z<0 and storey<1) or (z>0 and storey>-1):
				xs.push_front(-19.)
			for i in xs.size()-1:
				_connect(Vector3(xs[i],y,z),Vector3(xs[i+1],y,z))
		if storey==0:
			_connect(Vector3(-10,y,-9),Vector3(-10,y,9))
		else:
			_connect(Vector3(-10,y,-9),Vector3(-10,y,0))
			_connect(Vector3(-10,y,0),Vector3(-10,y,9))
		_connect(Vector3(THROAT_X,y,-9),Vector3(THROAT_X,y,9))
		_throat(storey)
		if storey<1:
			_connect(Vector3(-19,y,-9),Vector3(-19,y+PITCH,9))
	# The old axial walk still bends onto the neighbouring room. The two
	# lateral thresholds instead approach the shaft from different storeys.
	for z: float in [-9.,9.]:
		_connect(Vector3(0,0,z),Vector3(0,0,signf(z)*(24.-HALF)),true)
	_connect(Vector3(0,0,-9),Vector3(0,0,9))
	# The pump walk turns under the longitudinal archive bridge. Above them,
	# the observing deck crosses east-west beside the suspended instrument.
	_connect(Vector3(-10,-PITCH,0),Vector3(0,-PITCH,0))
	_connect(Vector3(0,-PITCH,0),Vector3(0,-PITCH,-9))
	_connect(Vector3(-10,PITCH,0),Vector3(7,PITCH,0))
	_connect(Vector3(7,PITCH,0),Vector3(7,PITCH,-9))
	_outer_aisle(Vector3(7,-PITCH,9),1.)
	_outer_aisle(Vector3(-10,PITCH,-9),-1.)
	for point: Vector3 in junctions:
		_landing(point)
	_cistern()
	_archive()
	_observatory()
	_finish_geometry()

func _outer_aisle(start: Vector3, side: float) -> void:
	var corner := Vector3(start.x,start.y,side*17.)
	var outer := Vector3(side*27.,0,corner.z)
	var bend := Vector3(outer.x,0,0)
	_connect(start,corner)
	_connect(corner,outer)
	_connect(outer,bend)
	_connect(bend,Vector3(side*(32.-HALF),0,0),true)

func _palette(y: float) -> void:
	var level := clampi(roundi(y/PITCH)+1,0,2)
	_floor = FLOORS[level]
	_handrail = RAILS[level]

func _port(p: Vector3, direction: Vector3) -> void:
	if not junctions.has(p):
		junctions[p] = []
	junctions[p].append(direction)

func _connect(a: Vector3,b: Vector3, open_end := false) -> void:
	var direction := (b-a).slide(Vector3.UP).normalized()
	_port(a,direction)
	_port(b,-direction)
	if open_end:
		_port(b,direction)
	var start := a+direction*HALF
	var end := b-direction*HALF
	_palette(a.y)
	var enclosed := a.x==THROAT_X and b.x==THROAT_X
	if enclosed:
		_floor = "basalt"
	if is_equal_approx(start.y,end.y):
		_floor_strip(start,end,HALF,HALF)
	else:
		_stair_flight(start,end)
	if not enclosed:
		var across := Vector3.UP.cross(direction)*(HALF-.05)
		for edge: float in [-1.,1.]:
			_guard(start+across*edge,end+across*edge)

func _stair_flight(a: Vector3, b: Vector3) -> void:
	var lower := a if a.y < b.y else b
	var upper := b if a.y < b.y else a
	var run := (upper-lower).slide(Vector3.UP)
	var forward := run.normalized()
	var frame := Basis(Vector3.UP.cross(forward),Vector3.UP,forward)
	var side := frame.x*HALF
	# The stringers and guards follow the same continuous incline as the
	# navigation and capsule. The horizontal treads meet both landing edges.
	_walk.append_array(PackedVector3Array([lower-side,lower+side,upper+side,
		lower-side,upper+side,upper-side]))
	var count := ceili((upper.y-lower.y)/.18)
	var rise := (upper.y-lower.y)/count
	var going := run.length()/count
	for i in count:
		var foot := lower+run*((i+.5)/count)+Vector3.UP*(rise*(i+.5))
		_part("box",_floor,foot-Vector3.UP*.095,Vector3(2.*HALF,.19,going),frame)
		var lip := foot-forward*(going*.5-.027)
		_part("box",_handrail,lip+Vector3.UP*.002,Vector3(2.*HALF,.012,.054),frame)
		_part("box",_handrail,lip-Vector3.UP*(rise*.55),Vector3(2.*HALF-.06,rise*.83,.045),frame)
	for hand: float in [-1.,1.]:
		var edge := side*hand*.93-Vector3.UP*.24
		beam(lower+edge,upper+edge,.16,.36,_handrail)

func _landing(p: Vector3) -> void:
	_palette(p.y)
	if p.x==THROAT_X:
		_floor = "basalt"
	_floor_strip(p-Vector3.BACK*HALF,p+Vector3.BACK*HALF,HALF,HALF)
	for normal: Vector3 in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
		if normal not in junctions[p] and p.x!=THROAT_X:
			var edge := p+normal*(HALF-.05)
			var tangent := Vector3.UP.cross(normal)*HALF
			_guard(edge-tangent,edge+tangent)

func _wall(at: Vector3, size: Vector3, mat: String) -> void:
	box(at,size,mat)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_collider(shape,Transform3D(Basis.IDENTITY,at))

func _throat(storey: int) -> void:
	var y := storey*PITCH
	# Both doors face west. At the seam the observer can see only matching
	# enamel, lamps and end walls, even when backing across or looking up.
	_wall(Vector3(13.3,y+1.75,0),Vector3(.27,3.5,14.8),"basalt")
	_wall(Vector3(16.73,y+1.75,0),Vector3(.27,3.5,21.5),"basalt")
	_wall(Vector3(15,y+3.57,0),Vector3(3.7,.22,21.5),"iron")
	for z: float in [-10.74,10.74]:
		_wall(Vector3(15,y+1.75,z),Vector3(3.7,3.5,.28),"basalt")
	for z: float in [-9.,-4.,0.,4.,9.]:
		box(Vector3(16.54,y+2.35,z),Vector3(.06,.12,.72),"pearl")
		_lamp(Vector3(16.2,y+2.32,z),"f4ddb7",1.5,4.)
	for z: float in [-7.29,7.29]:
		box(Vector3(13.11,y+1.65,z),Vector3(.22,3.3,.22),"brass")
		box(Vector3(13.11,y+3.22,z+signf(z)*1.67),Vector3(.24,.26,3.55),"brass")
	for side: float in [-1.,1.]:
		var link := NavigationLink3D.new()
		link.bidirectional = false
		link.start_position = Vector3(THROAT_X,y+.12,side*.85)
		link.end_position = Vector3(THROAT_X,next_height(storey)+.12,-side*.85)
		add_child(link)

static func next_height(storey: int) -> float:
	return (posmod(storey+2,3)-1)*PITCH

func prepare_navigation(source: NavigationMeshSourceGeometryData3D) -> void:
	# The physical floor is continuous underfoot. The pathfinder must use
	# the directed links to get across this strip, just like the player.
	var cut := PackedVector3Array([Vector3(12.9,0,-.48),Vector3(17.,0,-.48),
		Vector3(17.,0,.48),Vector3(12.9,0,.48)])
	source.add_projected_obstruction(cut,-PITCH-1.,2.*PITCH+2.,true)

func fold_between(previous: Vector3, current: Vector3) -> float:
	if (previous.z<0.)==(current.z<0.) or absf(current.x-THROAT_X)>HALF or absf(previous.x-THROAT_X)>HALF:
		return 0.
	var level := roundi(current.y/PITCH)
	if absi(level)>1 or absf(current.y-level*PITCH)>.55:
		return 0.
	return next_height(level)-level*PITCH

func is_fold_link(a: Vector3,b: Vector3) -> bool:
	var p := to_local(a)
	var q := to_local(b)
	return absf(p.x-THROAT_X)<.35 and absf(q.x-THROAT_X)<.35 and absf(p.z)<1.2 and absf(q.z)<1.2 and absf(q.y-p.y)>PITCH-.5

func climate_at(p: Vector3) -> PackedFloat32Array:
	var floor_number := clampf(p.y/PITCH+1.,0.,2.)
	var lower := floori(floor_number)
	var blend := smoothstep(.25,.75,floor_number-lower)
	var weights := PackedFloat32Array([0.,0.,0.,0.])
	weights[CLIMATES[lower]] = 1.-blend
	weights[CLIMATES[mini(lower+1,2)]] += blend
	if absf(p.x-THROAT_X)<1.85:
		var outside := smoothstep(2.,7.4,absf(p.z))
		for i in weights.size():
			weights[i] *= outside
		weights[0] += 1.-outside
	return weights

func title_at(p: Vector3) -> String:
	return NAMES[clampi(roundi(p.y/PITCH)+1,0,2)]

func _lamp(at: Vector3, tint: String, power: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = Color(tint)
	lamp.omni_range = reach
	lamp.light_energy = power
	lamp.set_meta("steady_power",power)
	lamp.add_to_group("scene_lights")
	add_child(lamp)

func _cistern() -> void:
	var basin := MeshInstance3D.new()
	var water := PlaneMesh.new()
	water.size = Vector2(46,37)
	basin.mesh = water
	var skin := ShaderMaterial.new()
	skin.shader = preload("res://tableaux/stone_assets/flood.gdshader")
	basin.material_override = skin
	basin.position.y = -8.65
	add_child(basin)
	for z: float in [-13.3,13.3]:
		for x: float in [-7.5,-2.5,2.5,7.5]:
			var pipe := Vector3(x,-6.7,z)
			column(pipe,Vector3(.92,5.7,.92),"rust")
			for h: float in [-1.4,.0,1.3]:
				column(pipe+Vector3.UP*h,Vector3(1.16,.15,1.16),"brass")
			ring(pipe+Vector3(0,1.7,-signf(z)*.72),.67,.082,"rust",Vector3(PI/2,0,0))
			beam(pipe+Vector3.UP*2.7,pipe+Vector3(4.95,2.7,0),.55,.55,"iron")
		_lamp(Vector3(3,-4.7,z),"68dfde",5.,12.)
	# The edge of the basin retains the water. High arched culverts and their
	# grilles give the low-level path an enclosed, wet horizon.
	for z: float in [-19.5,19.5]:
		box(Vector3(0,-7.8,z),Vector3(45,2.5,1.2),"basalt")
		for x: float in [-17.,-10.,-3.,4.,11.,18.]:
			box(Vector3(x,-5.8,z),Vector3(1.35,5.7,1.45),"stone")
			box(Vector3(x,-3.05,z),Vector3(1.7,.35,1.7),"salt")
			if x<18.:
				var spring := Vector3(x+3.5,-5.9,z)
				for i in 12:
					var t := i*PI/12.
					var u := (i+1)*PI/12.
					beam(spring+Vector3(cos(t)*3.4,sin(t)*2.4,0),spring+Vector3(cos(u)*3.4,sin(u)*2.4,0),.6,.85,"stone")
				for j in 9:
					box(spring+Vector3((j-4)*.60,-.70,0),Vector3(.075,4.15,.12),"iron")
	var axle := Vector3(-2.2,-5.67,-1.91)
	column(axle-Vector3.UP*.91,Vector3(.7,1.7,.7),"iron")
	ring(axle,.82,.095,"rust",Vector3(PI/2,0,0))
	for i in 6:
		var t := i*TAU/6.
		beam(axle,axle+Vector3(.76*cos(t),.76*sin(t),0),.08,.09,"brass")
	for x: float in [-5.,5.]:
		box(Vector3(x,-7.2,0),Vector3(.26,4.6,.35),"chalk")
		for tick in 11:
			box(Vector3(x,-8.9+tick*.34,.19),Vector3(.22 if tick%3==0 else .12,.045,.035),"basalt")

func archive_shelf(x: float, z: float) -> void:
	var covers := ["rust","bone","wood","moss","basalt"]
	for end: float in [-2.62,2.62]:
		box(Vector3(x+end,2.06,z),Vector3(.18,4.42,1.36),"wood")
	for row in 5:
		var h := .19+row*.88
		box(Vector3(x,h,z),Vector3(5.37,.14,1.46),"brass")
		for i in 15:
			var p := Vector3(x-2.35+i*.33,h+.40,z)
			var height := .48+.073*posmod(i*3+row,5)
			box(p,Vector3(.28,height,.98),covers[posmod(i+row,5)])
			box(p+Vector3(0,-height*.21,-signf(z)*.50),Vector3(.19,.048,.022),"bone")

func archive_drawers(back: Vector3) -> void:
	box(back,Vector3(1.,4.4,3.4),"wood")
	for row in 5:
		for col in 3:
			var face := back+Vector3(.54,(row-2)*.79,(col-1)*1.02)
			box(face,Vector3(.1,.72,.93),"rust" if row%3==1 else "wood")
			box(face+Vector3(.065,-.06,0),Vector3(.045,.058,.30),"brass")
			box(face+Vector3(.063,.14,0),Vector3(.035,.105,.24),"bone")

func _archive() -> void:
	for z: float in [-12.2,12.2]:
		for x: float in [-7.,5.]:
			archive_shelf(x,z)
			_lamp(Vector3(x,2.8,z-signf(z)*1.4),"ffc784",4.,8.)
	for z: float in [-7.,-3.5,0.,3.5,7.]:
		archive_drawers(Vector3(-12.2,2.04,z))
	# A single plumb line can be followed by eye through all three galleries.
	var weight := Vector3(-5.2,-5.5,3.8)
	beam(weight,weight+Vector3.UP*20.,.065,.065,"brass")
	cone(weight,Vector3(.9,1.45,.9),"brass",Vector3(PI,0,0))

func _observatory() -> void:
	var center := Vector3(-5.2,10.2,3.8)
	for i in 4:
		ring(center,3.1-i*.31,.103 if i==0 else .072,"brass",Vector3(.44+i*.57,.26+i*.59,.35+i*.54))
	ball(center,Vector3.ONE*.81,"pearl")
	for i in 12:
		var angle := TAU*i/12.
		var radial := Vector3(cos(angle),0,sin(angle))
		beam(center+radial*2.88,center+radial*3.29,.085,.09,"bone")
	for z: float in [-12.,12.]:
		for x: float in [-10.,0.,9.8]:
			column(Vector3(x,9.8,z),Vector3(.64,6.5,.64),"chalk")
			column(Vector3(x,12.91,z),Vector3(1.10,.38,1.10),"brass")
		beam(Vector3(-10,13.3,z),Vector3(10,13.3,z),.5,.55,"chalk")
		for i in 18:
			box(Vector3(-10+i*1.16,13.03,z-signf(z)*.28),Vector3(.10,.20,.08),"pearl")
	# The drum is open to the sky. Broken meridian ribs frame a star chart
	# that can be approached along the transverse upper deck.
	for i in 21:
		var t := lerpf(.14,PI-.14,i/21.)
		var u := lerpf(.14,PI-.14,(i+1)/21.)
		var a := Vector3(11.8*cos(t),12.9+5.1*sin(t),-12.)
		var b := Vector3(11.8*cos(u),12.9+5.1*sin(u),-12.)
		beam(a,b,.34,.42,"brass")
		beam(a+Vector3.BACK*19.,b+Vector3.BACK*19.,.24,.28,"iron")
		if i%3==0:
			beam(a,a+Vector3.BACK*19.,.09,.12,"iron")
	for z: float in [-12.8,12.8]:
		box(Vector3(0,10.4,z),Vector3(18.,4.7,.22),"basalt")
		for i in 56:
			var x := 16.6*(fposmod(i*.618034,1.)-.5)
			var h := 8.45+3.88*fposmod(sin(i*47.2)*7921.57,1.)
			var star := Vector3(x,h,z-signf(z)*.14)
			ball(star,Vector3.ONE*(.07+.046*(i%3)),"pearl")
		for r: float in [.6,1.25,1.9]:
			ring(Vector3(0,10.4,z-signf(z)*.16),r,.033,"brass",Vector3(PI/2,0,0))
	_lamp(center+Vector3(0,1.3,1.4),"b2caff",7.,14.)
