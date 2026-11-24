extends Node3D

const SURFACE := preload("res://realms/surface.gdshader")
const TIDE := preload("res://realms/tide.gdshader")
const BEAM := preload("res://realms/beam.gdshader")
const NOISE := preload("res://architecture/limestone.png")
const DOCK_RADIUS := 2.95
const WIDTH := 4.3
const WET_POINTS := [
	Vector3(0,0,-24), Vector3(0,0,-13), Vector3(-12,0,-9), Vector3(-18,0,2),
	Vector3(-11,0,12), Vector3(0,0,16), Vector3(0,0,24), Vector3(12,0,-8),
	Vector3(18,0,2), Vector3(11,0,12), Vector3(-32,0,0), Vector3(32,0,0),
	Vector3(-25,0,0), Vector3(25,0,0), Vector3(0,0,8.6)]
const SKY_POINTS := [
	Vector3(0,0,-24), Vector3(0,0,-16), Vector3(-9,3,-10), Vector3(-13,6,0),
	Vector3(-9,3,10), Vector3(0,0,16), Vector3(0,0,24), Vector3(9,3,-10),
	Vector3(13,6,0), Vector3(9,3,10), Vector3(-32,0,0), Vector3(32,0,0),
	Vector3(-24,2,0), Vector3(24,2,0)]
const RING_EDGES := [[0,1],[1,2],[2,3],[3,4],[4,5],[5,6],[1,7],[7,8],[8,9],[9,5]]

static var _mesh := {}
static var _mat := {}
static var _beam_mat: ShaderMaterial
static var _water_mat: ShaderMaterial
var _parts := {}
var _treads := PackedVector3Array()
var _body := StaticBody3D.new()
var _random := RandomNumberGenerator.new()
var _water := false
var _motif := 0
var _rotor: Node3D
var _orbiter: Node3D
var _orbit_tilt := Basis.IDENTITY
var _phase := 0.0
var _clock := 0.0

func build(kind: int, value: int) -> void:
	_prepare()
	_random.seed = value
	_motif = posmod(value,4)
	_phase = _random.randf_range(0,TAU)
	_water = kind == 1
	add_child(_body)
	var layout: Array = WET_POINTS if _water else SKY_POINTS
	var edges := RING_EDGES.duplicate()
	edges.append_array([[3,12],[12,10],[8,13],[13,11]])
	if _water:
		edges.append_array([[3,14],[14,8],[5,14]])
	_walkways(layout,edges)
	if _water:
		_cistern()
	else:
		_observatory()
	_flush()

static func _surface(color: String, kind: int, metalness: float, glow := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURFACE
	m.set_shader_parameter("tint",Color(color))
	m.set_shader_parameter("grain",NOISE)
	m.set_shader_parameter("kind",kind)
	m.set_shader_parameter("metalness",metalness)
	m.set_shader_parameter("glow",glow)
	return m

static func _cylinder(rad_top: float, rad_bottom: float, segments: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius=rad_top
	c.bottom_radius=rad_bottom
	c.height=1.0
	c.radial_segments=segments
	c.rings=0
	return c

static func _prepare() -> void:
	if not _mesh.is_empty():
		return
	var cube := BoxMesh.new()
	cube.size=Vector3.ONE
	_mesh.box=cube
	_mesh.barge=_barge_hull()
	_mesh.drum=_cylinder(1,1,32)
	_mesh.oct=_cylinder(1,1,8)
	_mesh.stem=_cylinder(.73,1,48)
	_mesh.cone=_cylinder(.015,1,36)
	var sphere := SphereMesh.new()
	sphere.radius=1
	sphere.height=2
	sphere.radial_segments=40
	sphere.rings=20
	_mesh.sphere=sphere
	var hoop := TorusMesh.new()
	hoop.inner_radius=.982
	hoop.outer_radius=1.018
	hoop.rings=64
	hoop.ring_segments=8
	_mesh.hoop=hoop
	_mat.salt=_surface("919c86",0,.10)
	_mat.moss=_surface("526e62",0,.08)
	_mat.wood=_surface("916f4d",1,.10)
	_mat.hull=_surface("326458",2,.46)
	_mat.rust=_surface("ad7246",2,.50)
	_mat.rope=_surface("aaa080",1,.05)
	_mat.lens=_surface("ffc367",5,.2,1.9)
	_mat.night=_surface("30384c",3,.46)
	_mat.ivory=_surface("a5abbb",3,.55)
	_mat.copper=_surface("ab8265",3,.57)
	_mat.glass=_surface("93adc9",5,.15,.15)
	_mat.window=_surface("c19673",5,.1,.33)
	_mat.planet=_surface("8f739b",4,.14,.14)
	_mat.moon=_surface("bb8c67",4,.19,.12)
	_mat.cobalt=_surface("6784a9",4,.20,.19)
	_water_mat = ShaderMaterial.new()
	_water_mat.shader=TIDE
	_water_mat.set_shader_parameter("wave",NOISE)
	_beam_mat=ShaderMaterial.new()
	_beam_mat.shader=BEAM

func _piece(mesh: String, mat: String, center: Vector3, size: Vector3, rotation := Basis.IDENTITY, tone := 1.0) -> void:
	var key := mesh+"/"+mat
	if not _parts.has(key):
		_parts[key]=[]
	_parts[key].append([Transform3D(rotation.scaled_local(size),center),tone])

func _flush() -> void:
	for key: String in _parts:
		var paths := key.split("/")
		var entries: Array = _parts[key]
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors=true
		batch.use_custom_data=true
		batch.mesh=_mesh[paths[0]]
		batch.instance_count=entries.size()
		for i in entries.size():
			var xf: Transform3D = entries[i][0]
			var c: float = entries[i][1]
			batch.set_instance_transform(i,xf)
			batch.set_instance_color(i,Color(c,c,c,1))
			batch.set_instance_custom_data(i,Color(xf.origin.x,xf.origin.y,xf.origin.z,1))
		var graphic := MultiMeshInstance3D.new()
		graphic.multimesh=batch
		graphic.material_override=_mat[paths[1]]
		add_child(graphic)
	_parts.clear()

func _collider(shape: Shape3D, center: Vector3, axes := Basis.IDENTITY) -> void:
	var slot := _body.create_shape_owner(_body)
	_body.shape_owner_set_transform(slot,Transform3D(axes,center))
	_body.shape_owner_add_shape(slot,shape)

func _solid_box(center: Vector3, size: Vector3, axes := Basis.IDENTITY) -> void:
	var shape := BoxShape3D.new()
	shape.size=size
	_collider(shape,center,axes)

func _frame(a: Vector3,b: Vector3) -> Basis:
	var z := (b-a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	return Basis(x,z.cross(x),z)

func _bar(a: Vector3,b: Vector3,width: float,thickness: float,m: String) -> void:
	_piece("box",m,(a+b)*.5,Vector3(width,thickness,a.distance_to(b)),_frame(a,b))

func _post(p: Vector3) -> void:
	if _water:
		_piece("drum","rust",p+Vector3.UP*.51,Vector3(.085,1.02,.085))
		_piece("drum","hull",p+Vector3.UP*.11,Vector3(.16,.22,.16))
	else:
		_piece("box","copper",p+Vector3.UP*.48,Vector3(.105,.97,.15))
		_piece("box","glass",p+Vector3.UP*.80,Vector3(.15,.12,.17))

func _guard(a: Vector3,b: Vector3, post_at_end := true) -> void:
	var distance := a.distance_to(b)
	var bays := maxi(1,ceili(distance/3.25))
	for i in bays:
		var p := a.lerp(b,float(i)/bays)
		var q := a.lerp(b,float(i+1)/bays)
		_post(p)
		if _water:
			var sag := minf(.17,p.distance_to(q)*.045)
			var middle := (p+q)*.5+Vector3.UP*(.97-sag)
			_bar(p+Vector3.UP*.97,middle,.052,.052,"rope")
			_bar(middle,q+Vector3.UP*.97,.052,.052,"rope")
		else:
			_bar(p+Vector3.UP*.98,q+Vector3.UP*.98,.075,.065,"ivory")
			_bar(p+Vector3.UP*.41,q+Vector3.UP*.41,.045,.055,"copper")
	if post_at_end:
		_post(b)
	_solid_box((a+b)*.5+Vector3.UP*.54,Vector3(.11,1.08,distance),_frame(a,b))

func _walkways(points: Array, edges: Array) -> void:
	var joints := []
	for i in points.size():
		joints.append([])
	var hw := WIDTH*.5
	var trim := sqrt(DOCK_RADIUS*DOCK_RADIUS-hw*hw)
	for edge: Array in edges:
		var ia:int=edge[0]
		var ib:int=edge[1]
		var a:Vector3=points[ia]
		var b:Vector3=points[ib]
		var dir:=Vector3(b.x-a.x,0,b.z-a.z).normalized()
		var lateral:=Vector3.UP.cross(dir)*hw
		joints[ia].append(atan2(dir.z,dir.x))
		joints[ib].append(atan2(-dir.z,-dir.x))
		var start:=a if ia in [0,6,10,11] else a+dir*trim
		var end:=b if ib in [0,6,10,11] else b-dir*trim
		if not is_equal_approx(start.y,end.y):
			var ramp_a:=a+dir*(DOCK_RADIUS+.06)
			var ramp_b:=b-dir*(1.35 if ib in [10,11] else DOCK_RADIUS+.06)
			_guarded_strip(start,ramp_a,lateral)
			_guarded_strip(ramp_a,ramp_b,lateral)
			_guarded_strip(ramp_b,end,lateral)
		elif _water:
			_strip(start,end)
			for side in [-1.0,1.0]:
				var offset:Vector3=lateral*side
				var cut_a:=_rope_cut(points,edges,ia,ib,offset,trim)
				var cut_b:=_rope_cut(points,edges,ib,ia,offset,trim)
				if cut_a+cut_b<a.distance_to(b)-.05:
					_guard(a+dir*cut_a+offset,b-dir*cut_b+offset)
		else:
			_guarded_strip(start,end,lateral)

	for i in points.size():
		if i in [0,6,10,11]: continue
		var p:Vector3 = points[i]
		var floor_mat:="wood" if _water else "ivory"
		_piece("drum",floor_mat,p-Vector3.UP*.15,Vector3(DOCK_RADIUS,.30,DOCK_RADIUS))
		_piece("drum","hull" if _water else "night",p-Vector3.UP*.42,Vector3(DOCK_RADIUS*.98,.34,DOCK_RADIUS*.98))
		for k in range(64):
			var angle:=TAU*k/64.
			var next:=TAU*(k+1)/64.
			var rim_a:=p+Vector3(cos(angle),0,sin(angle))*DOCK_RADIUS
			var rim_b:=p+Vector3(cos(next),0,sin(next))*DOCK_RADIUS
			_treads.append_array(PackedVector3Array([p,rim_a,rim_b]))
		var angles:Array=joints[i]
		angles.sort()
		var mouth:=asin(hw/DOCK_RADIUS)
		for j in angles.size():
			var start:float=angles[j]+mouth
			var end:float=angles[(j+1)%angles.size()]-mouth
			if j==angles.size()-1: end+=TAU
			if end-start<.07: continue
			var n:=maxi(1,ceili((end-start)/.48))
			for k in n:
				var a:=lerpf(start,end,float(k)/n)
				var b:=lerpf(start,end,float(k+1)/n)
				_guard(p+Vector3(cos(a),0,sin(a))*DOCK_RADIUS,
					p+Vector3(cos(b),0,sin(b))*DOCK_RADIUS,false)

	# Only shared walking surfaces take part in floor collisions. Box end faces
	# otherwise catch the capsule at the crown of steep deck-to-landing joints.
	var walking_surface:=ConcavePolygonShape3D.new()
	walking_surface.backface_collision=true
	walking_surface.set_faces(_treads)
	_collider(walking_surface,Vector3.ZERO)
	_treads.clear()

# At acute forks two gangways overlap past the round landing. Their inside ropes
# meet at the intersection of the offset edges, outside both walking surfaces.
func _rope_cut(points:Array,edges:Array,joint:int,target:int,offset:Vector3,trim:float) -> float:
	if joint in [0,6,10,11]:
		return 0.0
	var p:Vector3=points[joint]
	var direction:Vector3=p.direction_to(points[target])
	var retreat:=trim
	for edge:Array in edges:
		if joint not in edge or target in edge:
			continue
		var neighbor:int=edge[1] if edge[0]==joint else edge[0]
		var other:Vector3=p.direction_to(points[neighbor])
		if other.dot(offset)>.0001:
			retreat=maxf(retreat,offset.length()/tan(direction.angle_to(other)*.5))
	return retreat

func _guarded_strip(a:Vector3,b:Vector3,lateral:Vector3) -> void:
	_strip(a,b)
	for side in [-1.0,1.0]:
		_guard(a+lateral*side,b+lateral*side)

func _strip(a: Vector3,b: Vector3) -> void:
	var axes:=_frame(a,b)
	var span:=a.distance_to(b)
	var center:=(a+b)*.5
	var across:=axes.x*(WIDTH*.5)
	_treads.append_array(PackedVector3Array([a-across,a+across,b+across,a-across,b+across,b-across]))
	if _water:
		_piece("box","hull",center-Vector3.UP*.39,Vector3(WIDTH-.21,.57,span+.025),axes)
		var n:=ceili(span/.30)
		for i in n:
			var p:=a.lerp(b,(i+.5)/n)
			_piece("box","wood",p-Vector3.UP*.08,Vector3(WIDTH,.16,span/n-.015),axes,_random.randf_range(.70,1.04))
	else:
		_piece("box","ivory",center-axes.y*.13,Vector3(WIDTH,.26,span+.03),axes)
		_piece("box","night",center-axes.y*.38,Vector3(WIDTH-.16,.26,span+.02),axes)
		for s in [-1.0,1.0]:
			var lip: Vector3=axes.x*(WIDTH*.5-.30)*s
			_piece("box","glass",center+lip+axes.y*.008,Vector3(.045,.015,span),axes)

func _light(p:Vector3, color:Color, power:float, reach:float) -> void:
	var l:=OmniLight3D.new()
	l.position=p
	l.light_color=color
	l.light_energy=power
	l.omni_range=reach
	l.light_volumetric_fog_energy=1.4
	l.shadow_enabled=true
	l.set_meta("steady_power",power)
	l.add_to_group("scene_lights")
	add_child(l)

func _individual(parent:Node3D, mesh:Mesh, material:Material, pos:Vector3, size:Vector3, axes:=Basis.IDENTITY) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	node.transform=Transform3D(axes.scaled_local(size),pos)
	parent.add_child(node)
	return node

func _cistern() -> void:
	var water_plane:=PlaneMesh.new()
	water_plane.size=Vector2(64,48)
	var water:=_individual(self,water_plane,_water_mat,Vector3(0,-.82,0),Vector3.ONE)
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_piece("box","moss",Vector3(0,-14,0),Vector3(63.99,.48,47.99))
	var center:=Vector3(_random.randf_range(-1.6,1.6),0,_random.randf_range(-1,1))
	match _motif:
		0: _lighthouse(center)
		1: _wreck(center)
		2: _diving_bell(center)
		3: _tidewheel(center)
	# Isolated pumping caissons emerge from the water at the four corners.
	for side in [-1.,1.]:
		for front in [-1.,1.]:
			var x:float=side*_random.randf_range(21,25)
			var z:float=front*_random.randf_range(13.4,17.0)
			var h:=_random.randf_range(4.7,8.8)
			var core:=Vector3(x,h*.5-1.35,z)
			_piece("box","moss",core,Vector3(5.65,h,4.55))
			_piece("box","salt",Vector3(x,h-1.28,z),Vector3(6.04,.46,5.07))
			_piece("box","hull",Vector3(x,h-.91,z),Vector3(5.37,.31,4.18))
			for t in [-1.,1.]:
				_piece("box","salt",core+Vector3(t*2.51,0,-front*2.24),Vector3(.64,h,.55))
			for slat in range(8):
				_piece("box","hull",Vector3(x+(slat-3.5)*.44,h*.47,z-front*2.32),Vector3(.27,2.52,.23))
			# Mouth of an intake pipe with a chamfered flange and grille.
			var face:=Basis(Vector3.RIGHT,PI/2)
			var mouth:=Vector3(x-.5*side,.35,z-front*3.92)
			_piece("drum","rust",mouth+Vector3(0,0,front*.94),Vector3(1.14,1.92,1.14),face)
			_piece("drum","hull",mouth,Vector3(1.34,.22,1.34),face)
			for bar in range(5):
				_piece("box","rust",mouth+Vector3((bar-2)*.40,0,-front*.14),Vector3(.078,2.1,.06))
			for i in range(5):
				_piece("box","rust",Vector3(x+side*1.65,.5+i*.48,z-front*2.58),Vector3(.61,.07,.21))
	_sluice(1.0 if _random.randi()%2 else -1.0)
	for i in range(7):
		var a:=i*TAU/7.0+.3
		var p:=center+Vector3(cos(a)*6.6,.36,sin(a)*6.3)
		_piece("drum","hull",p-Vector3.UP*.57,Vector3(.29,2.39,.29))
		_piece("drum","salt",p+Vector3.UP*.49,Vector3(.31,.21,.31))

func _sluice(hand:float) -> void:
	# Crane bridge over the lateral shipping lane; every opening stays clear
	# underneath, including the east or west pedestrian entrance.
	var x:=hand*25.4
	var y:=9.6
	for z in [-13.6,13.6]:
		for dx in [-1.34,1.34]:
			var at:=Vector3(x+dx,y*.5-1.,z)
			_piece("box","salt",at,Vector3(.81,y+2,.86))
			_piece("box","hull",Vector3(x+dx,y,z),Vector3(1.18,.72,1.26))
		_piece("box","rust",Vector3(x,y+.36,z),Vector3(3.95,.33,.87))
	for dx in [-1.34,1.34]:
		var px:float=x+dx
		for dy in [0.0,1.34]:
			_bar(Vector3(px,y+dy,-14.3),Vector3(px,y+dy,14.3),.20,.16,"hull")
		for i in range(12):
			var z:float=-14.1+i*2.35
			var lift:float=1.34 if i%2==0 else 0.
			_bar(Vector3(px,y+lift,z),Vector3(px,y+1.34-lift,z+2.35),.13,.12,"rust")
	var wheel:=Vector3(x-hand*1.66,y+1.5,-7.)
	var face:=Basis(Vector3.BACK,PI/2)
	_piece("hoop","rust",wheel,Vector3(2.40,3.0,2.40),face)
	_piece("drum","hull",wheel,Vector3(.43,.85,.43),face)
	for i in range(8):
		var theta:=TAU*(i+.40)/8.
		var end:=wheel+Vector3(0,sin(theta),cos(theta))*2.30
		_bar(wheel,end,.10,.13,"rust")
	for dx in [-.61,.61]:
		_piece("drum","rust",Vector3(x+dx,y-3.03,-6.1),Vector3(.050,5.9,.050))
	_piece("box","moss",Vector3(x,y-6.25,-6.1),Vector3(2.2,1.,.93))

func _beacon_part(mesh:String,mat:String,center:Vector3,size:Vector3,basis:=Basis.IDENTITY) -> void:
	_piece(mesh,mat,center,size,basis)
	# A submerged reverse elevation gives the translucent surface a stable mirror
	# image even while the lantern, shaft or gallery is outside the view frustum.
	var mirrored:=Vector3(center.x,-1.64-center.y,center.z)
	var reflection:=Basis.from_scale(Vector3(1,-1,1))*basis*Basis.from_scale(Vector3(-1,1,1))
	_piece(mesh,mat,mirrored,size,reflection,.56)

func _lighthouse(base:Vector3) -> void:
	var tower_height:=_random.randf_range(12.6,15.4)
	_beacon_part("oct","salt",base+Vector3.UP*.15,Vector3(5.1,2.0,5.1))
	_beacon_part("drum","hull",base+Vector3.UP*1.30,Vector3(4.18,.43,4.18))
	_beacon_part("stem","salt",base+Vector3.UP*(1.4+tower_height*.5),Vector3(3.30,tower_height,3.30))
	for band in [0.14, .46, .79]:
		var radius:float=3.3*(1.-.27*band)
		_beacon_part("stem","rust",base+Vector3.UP*(1.4+tower_height*band),Vector3(radius*1.057,.64,radius*1.057))
	for i in range(5):
		var theta:=i*1.13
		var y:=3.+i*1.97
		var radius:=3.3*(1.-.27*((y-1.4)/tower_height))
		var out:=Vector3(sin(theta),0,cos(theta))
		_beacon_part("box","hull",base+out*radius+Vector3.UP*y,Vector3(.84,1.43,.18),Basis(Vector3.UP,theta))
		_beacon_part("box","lens",base+out*(radius+.11)+Vector3.UP*y,Vector3(.28,.96,.07),Basis(Vector3.UP,theta))
	var h:=tower_height+1.4
	_beacon_part("drum","salt",base+Vector3.UP*h,Vector3(2.96,.60,2.96))
	_beacon_part("drum","rust",base+Vector3.UP*(h+.40),Vector3(3.50,.30,3.50))
	_beacon_part("hoop","hull",base+Vector3.UP*(h+1.25),Vector3(3.30,1.3,3.30))
	for i in range(14):
		var theta:=i*TAU/14.
		var r:=Vector3(cos(theta),0,sin(theta))
		_beacon_part("drum","hull",base+Vector3.UP*(h+.88)+r*3.30,Vector3(.055,.90,.055))
		if i%2==0:
			_beacon_part("drum","rust",base+Vector3.UP*(h+2.46)+r*1.92,Vector3(.11,3.81,.11))
	for i in range(7):
		_beacon_part("drum","lens",base+Vector3.UP*(h+2.10+i*.23),Vector3(.77-absf(3-i)*.085,.15,.77-absf(3-i)*.085))
	_beacon_part("cone","hull",base+Vector3.UP*(h+5.14),Vector3(2.8,2.24,2.8))
	_beacon_part("drum","rust",base+Vector3.UP*(h+6.57),Vector3(.09,1.65,.09))
	_rotor=Node3D.new()
	add_child(_rotor)
	_rotor.position=base+Vector3.UP*(h+2.77)
	var lamp:=SpotLight3D.new()
	lamp.light_color=Color("ffd182")
	lamp.light_energy=7.5
	lamp.spot_range=32.0
	lamp.shadow_enabled=true
	lamp.position.z=-1.85
	lamp.set_meta("steady_power",7.5)
	lamp.add_to_group("scene_lights")
	lamp.spot_angle=12.8
	lamp.spot_attenuation=1.20
	lamp.light_volumetric_fog_energy=2.0
	_rotor.add_child(lamp)
	var shaft:=_cylinder(.09,3.14,36)
	shaft.height=18.2
	shaft.cap_top=false
	shaft.cap_bottom=false
	var beam:=_individual(_rotor,shaft,_beam_mat,Vector3(0,0,-9.15),Vector3.ONE,Basis(Vector3.RIGHT,PI/2))
	beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _observatory() -> void:
	# Empty sky between the hanging districts reveals the underside of each roofline.
	for side in [-1.0,1.0]:
		for front in [-1.0,1.0]:
			var x:float=side*_random.randf_range(19.0,22.2)
			var z:float=front*_random.randf_range(12.3,15.3)
			var h:=_random.randf_range(19.4,25.0)
			var anchor:=Vector3(x,h,z)
			_piece("oct","night",anchor+Vector3.UP*1.66,Vector3(8.8,3.8,7.9))
			_piece("oct","ivory",anchor,Vector3(9.1,.55,8.25))
			_piece("oct","copper",anchor-Vector3.UP*.51,Vector3(7.86,.41,7.07))
			for i in range(8):
				var angle:=i*TAU/8.
				var radius:=_random.randf_range(3.6,5.8)
				var top:=anchor+Vector3(cos(angle)*radius,-.64,sin(angle)*radius)
				var drop:=_random.randf_range(5.8,13.9)
				var w:=_random.randf_range(1.48,2.54)
				var d:=_random.randf_range(1.5,2.62)
				_house(top,drop,w,d,angle)
			_house(anchor-Vector3.UP*.68,_random.randf_range(12.5,17.0),2.9,3.25,.2)
	if _motif in [0,3]:
		_planetarium()
	else:
		_lunar_probe()
	var mount:=Vector3(0,24.8,0)
	_piece("drum","ivory",mount,Vector3(5.7,1.08,5.7))
	_piece("drum","night",mount-Vector3.UP*1.21,Vector3(4.75,1.41,4.75))
	_piece("drum","copper",mount-Vector3.UP*2.09,Vector3(4.22,.36,4.22))
	_piece("sphere","night",mount-Vector3.UP*2.12,Vector3(3.84,3.51,3.84))
	for i in range(16):
		var a:=TAU*i/16.
		var radial:=Vector3(sin(a),0,cos(a))
		_piece("box","window",mount+radial*4.73-Vector3.UP*1.04,Vector3(.49,.70,.08),Basis(Vector3.UP,a))
	_piece("hoop","ivory",mount-Vector3.UP*3.18,Vector3(3.77,1.4,3.77))
	_piece("cone","copper",mount-Vector3.UP*6.34,Vector3(1.13,4.38,1.13),Basis(Vector3.RIGHT,PI))
	# Tension stays suspend the two great rising walkways from the districts.
	for side in [-1.0,1.0]:
		for front in [-1.0,1.0]:
			var foot:=Vector3(side*14.9,5.4,front*1.65)
			var roof:=Vector3(side*18.3,21.,front*12.4)
			_bar(foot,roof,.095,.13,"copper")
			_piece("sphere","glass",foot,Vector3(.14,.18,.14))
	# Parallax star groups below and beside the path survive the approach from
	# another sky. They are pinned to space, never flashing or following the eye.
	for i in range(71):
		var x:=_random.randf_range(-31.2,31.2)
		var z:=_random.randf_range(-23.5,23.5)
		var y:=_random.randf_range(-31.,-12.)
		var r:=_random.randf_range(.022,.072)
		_piece("oct","glass",Vector3(x,y,z),Vector3(r,r*.93,r))

func _planetarium() -> void:
	# A planet hangs below the raised split; both paths look down onto its rings.
	var center:=Vector3(_random.randf_range(-1.4,1.4),-3.0,_random.randf_range(-1.1,1.1))
	var planet_radius:=_random.randf_range(3.45,4.32)
	_orbit_tilt=Basis(Vector3.BACK,_random.randf_range(.18,.44))*Basis(Vector3.RIGHT,.34)
	_piece("sphere","planet",center,Vector3.ONE*planet_radius,Basis(Vector3.BACK,-.39))
	for r in [1.40,1.52,1.83]:
		_piece("hoop","copper" if r<1.8 else "ivory",center,Vector3(planet_radius*r,planet_radius*.72,planet_radius*r),_orbit_tilt)
	# A high blue body is visible above the split even from a neighboring threshold.
	var hand:=1.0 if _random.randi()%2 else -1.0
	var sky_body:=Vector3(hand*6.8,12.15,-9.1)
	var body_radius:=_random.randf_range(3.05,3.80)
	var tilted:=Basis(Vector3.BACK,-hand*.56)*Basis(Vector3.RIGHT,.41)
	_piece("sphere","cobalt",sky_body,Vector3.ONE*body_radius,Basis(Vector3.BACK,.42))
	for factor in [1.45,1.54,1.62]:
		_piece("hoop","ivory" if factor<1.6 else "copper",sky_body,
			Vector3(body_radius*factor,body_radius*.66,body_radius*factor),tilted)
	_orbiter=Node3D.new()
	add_child(_orbiter)
	_orbiter.position=center
	var radius:=planet_radius*1.83
	var moon:=_individual(_orbiter,_mesh.sphere,_mat.moon,Vector3(radius,.18,0),Vector3.ONE*.79)
	moon.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _house(top:Vector3,drop:float,width:float,depth:float,angle:float) -> void:
	var axes:=Basis(Vector3.UP,angle)
	var half:=Vector3(width*.5,0,depth*.5)
	var mid:=top-Vector3.UP*(drop*.5)
	_piece("box","night",mid,Vector3(width,drop,depth),axes)
	_piece("box","ivory",top-Vector3.UP*(drop-.12),Vector3(width+.38,.40,depth+.38),axes)
	_piece("cone","night",top-Vector3.UP*(drop+.96),Vector3(width*.59,2.07,depth*.59),axes*Basis(Vector3.RIGHT,PI))
	_piece("drum","copper",top-Vector3.UP*(drop+2.14),Vector3(.053,.74,.053))
	var levels:=floori((drop-1.0)/1.52)
	for k in levels:
		var y:float=-1.02-k*1.52
		_piece("box","ivory",top+Vector3.UP*(y-.44),Vector3(width+.11,.13,depth+.11),axes)
		for side in [-1.0,1.0]:
			if _random.randf()>.30:
				var f:Vector3=axes*Vector3(0,y,side*(half.z+.025))
				_piece("box","window" if k%3 else "glass",top+f,Vector3(width*.44,.44,.05),axes)
			if _random.randf()>.50:
				var f:Vector3=axes*Vector3(side*(half.x+.025),y,0)
				_piece("box","window",top+f,Vector3(.05,.48,depth*.48),axes)

func _process(delta:float) -> void:
	_clock+=delta
	if _rotor:
		_rotor.rotation=Vector3(-.10,_phase+_clock*.27,0)
	if _orbiter:
		_orbiter.basis=_orbit_tilt*Basis(Vector3.UP,_phase+_clock*.105)

static func _hull_face(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,outward:Vector3) -> void:
	var norm:=(b-a).cross(c-a).normalized()
	var vertices:=[a,c,b,a,d,c]
	if norm.dot(outward)<0:
		norm=-norm
		vertices=[a,b,c,a,c,d]
	for pt in vertices:
		surface.set_normal(norm)
		surface.add_vertex(pt)

static func _barge_hull() -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stations:=[Vector2(-1,.06),Vector2(-.75,.85),Vector2(-.45,1),Vector2(.58,1),Vector2(.88,.49),Vector2(1,.04)]
	for j in stations.size()-1:
		var a:Vector2=stations[j]
		var b:Vector2=stations[j+1]
		for side in [-1.,1.]:
			var p:=Vector3(a.x,1.,a.y*side)
			var q:=Vector3(b.x,1.,b.y*side)
			var r:=Vector3(b.x,-.9,b.y*side*.69)
			var t:=Vector3(a.x,-.9,a.y*side*.69)
			_hull_face(st,p,q,r,t,Vector3(0,0,side))
		_hull_face(st,Vector3(a.x,1.,a.y),Vector3(b.x,1.,b.y),Vector3(b.x,1.,-b.y),Vector3(a.x,1.,-a.y),Vector3.UP)
	return st.commit()

func _wreck(base:Vector3) -> void:
	var tilt:=Basis(Vector3.BACK,-.125)*Basis(Vector3.RIGHT,.14)
	var origin:=base-Vector3.UP*.28
	_beacon_part("barge","rust",origin,Vector3(6.30,.89,2.08),tilt)
	_beacon_part("barge","hull",origin+tilt*Vector3.UP*.83,Vector3(6.36,.12,2.11),tilt)
	var cabin:=origin+tilt*Vector3(-1.55,1.89,0)
	_beacon_part("box","salt",cabin,Vector3(3.24,2.14,2.95),tilt)
	_beacon_part("box","hull",cabin+tilt*Vector3.UP*1.23,Vector3(3.67,.25,3.34),tilt)
	for i in [-1,0,1]:
		for side in [-1.,1.]:
			_beacon_part("box","hull",cabin+tilt*Vector3(i*.91,.37,side*1.49),Vector3(.78,.73,.09),tilt)
			_beacon_part("box","lens",cabin+tilt*Vector3(i*.91,.38,side*1.55),Vector3(.59,.52,.05),tilt)
	var mast:=origin+tilt*Vector3(1.68,4.4,0)
	_beacon_part("drum","rust",mast,Vector3(.16,7.6,.16),tilt)
	_beacon_part("box","hull",mast+tilt*Vector3.UP*2.94,Vector3(.23,.14,3.37),tilt)
	for side in [-1.,1.]:
		_bar(mast+tilt*Vector3(0,3,side*1.51),origin+tilt*Vector3(4.16,1.,side*1.65),.046,.046,"rope")
	for i in [0,1]:
		_beacon_part("drum","hull",origin+tilt*Vector3(-4.18+i*.75,1.32,.67),Vector3(.28,2.05,.28),tilt)
	_light(cabin+Vector3.UP,Color("edb079"),1.8,8.5)

func _diving_bell(base:Vector3) -> void:
	var top:=base+Vector3.UP*10.6
	for i in 3:
		var a:=TAU*(i+.15)/3.
		var foot:=base+Vector3(cos(a)*3.65,-1.42,sin(a)*3.65)
		_bar(foot,top,.33,.40,"rust")
		_beacon_part("drum","salt",foot+Vector3.UP*.44,Vector3(.57,1.3,.57))
	_beacon_part("drum","hull",top,Vector3(.64,.65,.64))
	_beacon_part("drum","rust",top-Vector3.UP*1.82,Vector3(.070,3.55,.070))
	var body:=base+Vector3.UP*3.55
	_beacon_part("sphere","rust",body+Vector3.UP*1.17,Vector3(2.16,1.89,2.16))
	_beacon_part("drum","rust",body,Vector3(2.16,2.3,2.16))
	_beacon_part("stem","hull",body-Vector3.UP*1.34,Vector3(2.73,.81,2.73))
	for i in range(8):
		var a:=TAU*i/8.
		var v:=Vector3(sin(a),0,cos(a))
		var face:=Basis(Vector3.UP,a)*Basis(Vector3.RIGHT,PI/2)
		_beacon_part("drum","hull",body+v*2.16,Vector3(.44,.14,.44),face)
		_beacon_part("drum","lens",body+v*2.25,Vector3(.30,.10,.30),face)
	_light(body+Vector3.UP*.2,Color("e9bd7a"),1.9,7.)

func _tidewheel(base:Vector3) -> void:
	var hub:=base+Vector3.UP*2.35
	var face:=Basis(Vector3.RIGHT,PI/2)
	for side in [-1.,1.]:
		var rim:Vector3=hub+Vector3.BACK*side*1.06
		_beacon_part("hoop","rust",rim,Vector3(4.2,4.6,4.2),face)
		for i in range(12):
			var a:=TAU*(i+.20)/12.
			var v:=Vector3(cos(a),sin(a),0)
			_bar(rim,rim+v*4.02,.14,.15,"hull")
			if side>0:
				_beacon_part("box","wood",hub+v*4.03,Vector3(.29,.96,2.4),Basis(Vector3.BACK,a))
		var pier:Vector3=hub+Vector3.BACK*side*1.87
		_beacon_part("box","salt",pier-Vector3.UP*2.1,Vector3(1.65,4.65,1.05))
		_beacon_part("drum","rust",pier,Vector3(.46,1.22,.46),face)

func _lunar_probe() -> void:
	var center:=Vector3(_random.randf_range(-1.3,1.3),6.6,_random.randf_range(-1.2,1.2))
	var orientation:=Basis(Vector3.UP,_random.randf_range(-.31,.31))*Basis(Vector3.BACK,.18)
	_piece("oct","copper",center,Vector3(1.92,2.6,1.92),orientation)
	_piece("oct","ivory",center+orientation*Vector3.UP*1.48,Vector3(1.56,.64,1.56),orientation)
	_piece("sphere","night",center+orientation*Vector3.UP*2.07,Vector3(1.33,1.06,1.33),orientation)
	for side in [-1.,1.]:
		var wing:=center+orientation*Vector3(side*4.4,.21,0)
		_piece("box","copper",wing,Vector3(5.12,.15,2.81),orientation)
		for i in range(6):
			for j in [-1.,1.]:
				var offset:=Vector3((i-2.5)*.79,-.092,j*.67)
				_piece("box","night",wing+orientation*offset,Vector3(.72,.03,1.17),orientation)
		for front in [-1.,1.]:
			var root:=center+orientation*Vector3(side*1.02,-.68,front*.91)
			var foot:=center+orientation*Vector3(side*2.9,-3.95,front*2.36)
			_bar(root,foot,.15,.15,"ivory")
			_bar(center+orientation*Vector3(side*1.04,.38,front*.63),foot,.075,.075,"copper")
			_piece("oct","copper",foot,Vector3(.49,.19,.49),orientation)
	# Parabolic receiver faces the path; concentric rims and spokes reveal the dish.
	var pivot:=center+orientation*Vector3(-.65,3.42,.50)
	var tilt:=Basis(Vector3.RIGHT,.78)*Basis(Vector3.BACK,-.30)
	for r in [1.2,2.1,2.85]:
		_piece("hoop","ivory",pivot+tilt*Vector3.UP*(r*r*.085),Vector3(r,2.2,r),tilt)
	for i in range(16):
		var a:=TAU*(i+.15)/16.
		var lip:=pivot+tilt*Vector3(cos(a)*2.85,.69,sin(a)*2.85)
		_bar(pivot,lip,.075,.085,"ivory")
		if i%4==0: _bar(lip,pivot+tilt*Vector3.UP*2.24,.055,.065,"copper")
	_piece("sphere","glass",pivot+tilt*Vector3.UP*2.24,Vector3.ONE*.23)
	_orbiter=Node3D.new()
	add_child(_orbiter)
	_orbiter.position=Vector3(0,11.,-7.)
	_orbit_tilt=Basis(Vector3.BACK,.24)
	_individual(_orbiter,_mesh.oct,_mat.copper,Vector3(4.,0,0),Vector3(.67,.68,.67))
	_individual(_orbiter,_mesh.box,_mat.night,Vector3(4.,0,0),Vector3(4.04,.11,.88))
