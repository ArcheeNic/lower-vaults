extends RefCounted

const TITLES := [
	"Лес камертонов", "Кладка великанов", "Море меридианов", "Останки левиафана",
	"Раковина глубин", "Стеклянный фьорд", "Чёрное солнце", "Жерло",
	"Сад медуз", "Архипелаг спор", "Дождь из спутников", "Долина гейзеров",
	"Бумажная гроза", "Лунная пасека",
]
const CLIMATES := [0,0,1,0,1,2,2,3,1,0,2,1,3,2]
const FLOORS := ["wood","bone","brass","bone","pearl","salt","basalt","basalt","glass","moss","iron","chalk","wood","pearl"]
const RAILS := ["brass","wood","glass","iron","brass","glass","brass","rust","pearl","wood","pearl","salt","iron","brass"]
const RISES := [.78,.60,.78,.68,.73,.82,.85,.72,.72,.61,.8,.66,.78,.66]
const ROUTES := [
	["....0....", "..121....", "..12233..", "001...210", "..12233..", "....1....", "....0...."],
	["....0....", ".3321233.", ".2.....2.", "01.....10", ".2.....2.", ".3321233.", "....0...."],
	["....0....", "....1.33.", ".2210122.", "01.....10", ".233.332.", "...212...", "....0...."],
	["....0....", "....1....", "..332....", "012.22210", "..332.32.", "....1....", "....0...."],
	["....0....", ".3321....", ".2.3221..", "01.4..100", ".2.32.1..", ".332121..", "....0...."],
	["....0....", "...21....", "..3323...", "012222210", "...11111.", "....12...", "....0...."],
	["....0....", "....1....", ".2332332.", "01..3..10", ".2332332.", "....1....", "....0...."],
	["....0....", "..32123..", ".23...32.", "01.....10", ".23...32.", "..32123..", "....0...."],
	["....0....", "..321123.", "..33.1.2.", "012321.10", ".....122.", "....11...", "....0...."],
	["....0....", ".0000....", ".1..1.11.", "01..22210", ".2332.3..", "..32123..", "....0...."],
	["....0....", ".2101....", ".2.0123..", "01....210", ".2.0123..", ".2101....", "....0...."],
	["....0....", ".332121..", ".233..1..", "01.4..110", "...32212.", "...21....", "....0...."],
	["....0....", "..22122..", "..1.1.1..", "000.0.000", "..1.1.1..", "..22122..", "....0...."],
	["....0....", "...21.43.", ".2332332.", "01....210", ".222222..", "...11....", "....0...."],
]
const FOSSIL := preload("res://tableaux/wild_assets/baleen_skull.glb")
const AMMONITE := preload("res://tableaux/wild_assets/ammonite.glb")
const EGG := preload("res://tableaux/wild_assets/hatched.glb")
const RAY := preload("res://tableaux/wild_assets/paper_ray.glb")

static func build(s: Node3D, id: int) -> void:
	s.plan(ROUTES[id], FLOORS[id], RAILS[id], RISES[id])
	var rng := RandomNumberGenerator.new()
	rng.seed = 19_811 + 701*id
	match id:
		0: _tuning_forest(s,rng)
		1: _clutch(s,rng)
		2: _longitude(s,rng)
		3: _leviathan(s)
		4: _chambered_shell(s,rng)
		5: _fjord(s,rng)
		6: _eclipse(s)
		7: _caldera(s,rng)
		8: _jellies(s,rng)
		9: _spores(s,rng)
		10: _falling_moons(s,rng)
		11: _geysers(s,rng)
		12: _paper_storm(s,rng)
		13: _lunar_hive(s,rng)

# Small floor-level objects sit in an unoccupied grid square. The narrowest
# space between its centre and an adjacent balustrade is 4.26 metres.
static func _clearings(id: int, rng: RandomNumberGenerator, limit: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for row in 7:
		for col in 9:
			if ROUTES[id][row][col]==".":
				points.append(Vector3((col-4)*7,0,(row-3)*6))
	for i in range(points.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var tmp := points[i]
		points[i] = points[j]
		points[j] = tmp
	points.resize(mini(points.size(),limit))
	return points

static func _model(s: Node3D, asset: PackedScene, p: Vector3, size3: Vector3, angles := Vector3.ZERO) -> Node3D:
	var node := asset.instantiate() as Node3D
	node.transform = Transform3D(Basis.from_euler(angles).scaled_local(size3),p)
	s.add_child(node)
	return node

static func _rad(a: float) -> Vector3:
	return Vector3(cos(a),0,sin(a))

static func _tuning_forest(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-9,0),Vector3(63.8,.5,47.8),"moss")
	for p in _clearings(0,rng,28):
		var height := rng.randf_range(6.2,18.5)
		var yaw := rng.randf_range(-PI,PI)
		var arm := _rad(yaw)*rng.randf_range(.53,1.20)
		var neck := p+Vector3.UP*height*.50
		s.cone(p+Vector3.DOWN*2,Vector3(2.40,13,2.3),"wood")
		s.beam(p+Vector3.DOWN,neck,.47,.52,"brass")
		for sign_ in [-1.,1.]:
			var shoulder: Vector3 = neck+arm*sign_+Vector3.UP*.68
			s.beam(neck,shoulder,.36,.44,"brass")
			s.beam(shoulder,p+arm*sign_+Vector3.UP*height,.34,.44,"brass")
		s.column(p+Vector3.UP*(height*.35),Vector3(.82,.26,.82),"iron")
		s.ball(p+Vector3.UP*.16,Vector3(2.7,1.2,2.3),"moss")

static func _clutch(s: Node3D,rng: RandomNumberGenerator) -> void:
	# The open, descending walkway goes all the way around a single breeding ledge.
	s.ball(Vector3(0,-4,0),Vector3(30,8,18),"moss")
	for course in 4:
		var r := 8.0+course*.65
		for i in 17:
			var a := TAU*i/17.0+rng.randf_range(-.07,.07)
			var b := a+rng.randf_range(.65,1.)
			var u := Vector3(cos(a)*r,-.5+course*.45,sin(a)*r*.62)
			var v := Vector3(cos(b)*r,.08+course*.48,sin(b)*r*.62)
			s.beam(u,v,.24,.31,"wood")
	_model(s,EGG,Vector3(-4.0,3.55,-.7),Vector3(2.55,2.8,2.55),Vector3(0,.3,-.22))
	var eggs := [Vector3(1.45,4.0,-2.1),Vector3(4.50,2.85,1.2),Vector3(-.8,2.55,2.5)]
	for i in eggs.size():
		var k := 1.-.14*i
		var p: Vector3 = eggs[i]
		s.ball(p,Vector3(4.2,7.9,4.65)*k,"bone" if i<2 else "pearl")
		for j in 9:
			var ang := j*2.4+.47
			var y := rng.randf_range(-.57,.53)
			var r := sqrt(1-y*y)
			s.ball(p+Vector3(cos(ang)*2.10*r,y*3.89,sin(ang)*2.30*r)*k,Vector3(.23,.32,.20)*k,"moss")
	for p in _clearings(1,rng,16):
		if Vector2(p.x,p.z).length()>12:
			s.cone(p-Vector3.UP*6,Vector3(4.8,rng.randf_range(8,15),4.25),"stone")

static func _longitude(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-2.2,0),Vector3(63.8,.6,47.8),"glass")
	# A mostly submerged armillary sphere; its crown emerges between the piers.
	var pole := Vector3(.35,-5.55,2.05)
	s.ball(pole,Vector3(14.2,14.2,14.2),"basalt")
	for i in 9:
		s.ring(pole,8.4,.15,"brass",Vector3(PI/2,PI*i/9.0,.15))
	for y in [-5.,-2.5,0.,2.5,5.]:
		s.ring(pole+Vector3.UP*y,sqrt(8.4*8.4-y*y),.12,"brass")
	for p in _clearings(2,rng,15):
		if absf(p.x)<9 and absf(p.z)<10: continue
		var h := rng.randf_range(1.1,5.4)
		s.cone(p+Vector3.UP*(h*.5-1.25),Vector3(.64,h,.64),"iron")
		s.ball(p+Vector3.UP*(h-1.4),Vector3(.85,.85,.85),"brass")
		s.ring(p-Vector3.UP*1.80,2.1,.055,"pearl")
		s.ring(p-Vector3.UP*1.78,1.35,.05,"pearl")

static func _leviathan(s: Node3D) -> void:
	s.box(Vector3(0,-11.2,0),Vector3(63.8,.8,47.8),"basalt")
	_model(s,FOSSIL,Vector3(1.2,9.8,-11.8),Vector3(2.4,2.4,2.4),Vector3(-.15,PI+.18,-.13))
	# The central crossing threads the hollow thorax under the long vertebral arch.
	for i in 20:
		var z := -8.45+i*1.48
		var p := Vector3(1.08+1.7*sin(i*.22),9.56-i*.084,z)
		var k := 1.-i*.033
		s.ball(p,Vector3(1.7,.91,.87)*k,"bone")
		s.cone(p+Vector3.UP*.65*k,Vector3(.50,1.55,.58)*k,"chalk")
		if i<15:
			for side in [-1.,1.]:
				var shoulder := p+Vector3(side*1.3*k,-.18,.1)
				var elbow := p+Vector3(side*(5.35+.75*sin(i*.37))*k,-2.15,1.20)
				var tip := p+Vector3(side*3.62*k,-4.42*k,2.15)
				s.beam(p,shoulder,.34*k,.43*k,"bone")
				s.beam(shoulder,elbow,.38*k,.45*k,"bone")
				s.beam(elbow,tip,.27*k,.32*k,"chalk")
	for side in [-1.,1.]:
		for i in 9:
			var p := Vector3(side*(15.+4.*sin(i*.60)),-6.7+i*.12,-16.+i*4.0)
			s.ball(p,Vector3(4.7,3.0,3.3),"stone")

static func _chambered_shell(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-5,0),Vector3(63.8,.5,47.8),"moss")
	_model(s,AMMONITE,Vector3(1.5,11.6,1.0),Vector3.ONE*2.1,Vector3(0,-.31,-.48))
	for p in _clearings(4,rng,18):
		var r := rng.randf_range(.60,1.30)
		s.cone(p-Vector3.UP*2.6,Vector3(2.6,7.5,2.2),"chalk")
		s.ring(p+Vector3.UP*.82,r,.19,"bone",Vector3(1.25,.72,.22))
		s.ball(p+Vector3.UP*.71,Vector3(r*.65,r*.65,r*.65),"pearl")
	# Dissolution terraces run below the broad lip.
	for i in 4:
		s.ball(Vector3(-3.5+i*.9,-7.1+i*.9,1),Vector3(31.-3.*i,3.0,19.-i*2.4),"salt")

static func _fjord(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-6.8,0),Vector3(63.9,.5,47.8),"glass")
	for p in _clearings(5,rng,30):
		var h := rng.randf_range(6.,18.)
		var axis := rng.randf_range(-PI,PI)
		s.box(p-Vector3.UP*.9,Vector3(3.4,h,3.25),"glass",Vector3(.075,axis,-.08))
		s.box(p+Vector3.UP*(h*.5-1.0),Vector3(3.45,.72,3.31),"salt",Vector3(.075,axis,-.08))
		s.cone(p+Vector3.UP*(h*.52),Vector3(2.5,rng.randf_range(3.1,6.4),2.65),"salt",Vector3(.09,axis,.14))
		if rng.randf()<.55:
			s.beam(p+Vector3(.8,h*.32,0),p+Vector3(2.35,1.0,.72),.52,.67,"pearl")
	# Floating ice fragments interrupt the dark river at different angles.
	for i in 22:
		var p := Vector3(rng.randf_range(-28.,28.),-6.4,rng.randf_range(-20.,20.))
		s.box(p,Vector3(rng.randf_range(.9,4.7),.42,rng.randf_range(1.2,3.4)),"salt",Vector3(0,rng.randf_range(0,PI),.075))

static func _eclipse(s: Node3D) -> void:
	s.box(Vector3(0,-7,0),Vector3(63.8,.72,47.8),"basalt")
	var sun := Vector3(-7,13.8,-7.4)
	s.ball(sun,Vector3(13.2,13.2,13.2),"basalt")
	s.ring(sun,7.1,.22,"ember",Vector3(PI/2,.38,.0))
	s.ring(sun,7.64,.065,"brass",Vector3(PI/2,.38,.0))
	for side in [-1.,1.]:
		for z in [-16.5,-3.,3.,16.5]:
			var p := Vector3(side*(11.2 if absf(z)<6 else 18.1),0,z)
			var h := 9.5+absf(z)*.42
			s.cone(p+Vector3.UP*(h*.46),Vector3(2.28,h,1.61),"basalt")
			s.box(p+Vector3.UP*1.3,Vector3(2.0,.16,1.45),"brass")
			s.box(p-Vector3.UP*.7,Vector3(3.12,1.46,2.58),"stone")
	for i in 21:
		var ang := i*TAU/21.
		var v := Vector3(cos(ang),sin(ang),0).rotated(Vector3.UP,.38)
		s.beam(sun+v*7.55,sun+v*(7.9+.73*absf(sin(i*3.2))),.07,.07,"brass")

static func _caldera(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-12.2,0),Vector3(63.8,.50,47.8),"basalt")
	s.ball(Vector3(0,-4.1,0),Vector3(15.5,2.1,9.3),"ember")
	for i in 22:
		var a := TAU*i/22.
		var p := Vector3(cos(a)*8.1,-1.9,sin(a)*5.0)
		var h := rng.randf_range(3.4,7.3)
		s.column(p,Vector3(2.65,h,2.51),"basalt",Vector3(.20*cos(a),a,.23*sin(a)))
		s.box(p+Vector3.UP*(h*.5-.36),Vector3(2.44,.65,2.20),"rust",Vector3(.2*cos(a),a,.23*sin(a)))
	for i in 24:
		var p := _rad(rng.randf_range(0,TAU))*rng.randf_range(.3,4.)
		var y := rng.randf_range(1,12)
		s.ball(p*(1.+.06*y)+Vector3.UP*y,Vector3.ONE*rng.randf_range(.17,.54),"ember" if i%3 else "basalt")
	for p in _clearings(7,rng,15):
		if absf(p.x)<12 and absf(p.z)<7: continue
		s.cone(p-Vector3.UP*3.6,Vector3(4.2,rng.randf_range(8.,19.),3.55),"basalt")

static func _jellies(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-8.6,0),Vector3(63.8,.6,47.8),"glass")
	var cells := _clearings(8,rng,15)
	for i in cells.size():
		var r := rng.randf_range(1.4,3.4)
		var p := cells[i]+Vector3.UP*rng.randf_range(6.6,15.5)
		p.x = clampf(p.x,-27.8,27.8)
		s.ball(p+Vector3.UP*r*.40,Vector3(2*r,1.33*r,2*r),"glass")
		s.ring(p,r*.94,.11,"pearl")
		s.ball(p-Vector3.UP*.2,Vector3(r*.91,r*.61,r*.91),"cloth")
		# Split tentacles make a recognisable silhouette when viewed from below.
		for k in 7:
			var a := TAU*k/7.+i*.71
			var base := p+_rad(a)*r*.80
			var joint := base+Vector3(sin(a+i)*.50,-r*.84,cos(a+i)*.44)
			var tail := joint+Vector3(sin(a+1.7)*.42,-r*.86,cos(a+1.7)*.48)
			s.beam(base,joint,.15,.13,"pearl")
			s.beam(joint,tail,.11,.095,"pearl" if k%3 else "cloth")
			s.ball(base,Vector3(.26,.24,.26),"pearl")

static func _spores(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-6.9,0),Vector3(63.8,.6,47.8),"moss")
	for p in _clearings(9,rng,21):
		var h := rng.randf_range(5.2,13.0)
		var r := rng.randf_range(1.4,3.12)
		var skew := _rad(rng.randf_range(0.,TAU))*.53
		var cap := p+Vector3.UP*h+skew
		s.ball(p-Vector3.UP*4,Vector3(4.9,8.5,4.6),"moss")
		s.beam(p-Vector3.UP*.5,p+Vector3.UP*h*.40,.74,.81,"bone")
		s.beam(p+Vector3.UP*h*.40,cap,.60,.63,"bone")
		s.ball(cap+Vector3.UP*r*.30,Vector3(r*2,r*.89,r*2),"cloth")
		s.ring(cap,r*.91,.12,"bone")
		for i in 8:
			var a := i*TAU/8.
			s.beam(cap-Vector3.UP*.45,cap+_rad(a)*r*.92,.078,.12,"salt")
		if rng.randf()<.62:
			var sp := p-skew*2.5+Vector3.UP*h*.30
			s.ball(sp,Vector3(2.25,.84,2.1),"rust")
			s.column(Vector3(sp.x,sp.y*.5,sp.z),Vector3(.31,sp.y,.34),"bone")

static func _falling_moons(s: Node3D,rng: RandomNumberGenerator) -> void:
	# A diagonal chain of increasingly large satellites has stopped in mid-fall.
	var centers := [Vector3(-19,18,-12),Vector3(-10.3,14.6,-7.3),Vector3(-2,11.7,-3.4),Vector3(5,8.3,1.3),Vector3(11.5,5.8,4.4)]
	var radii := [4.75,3.6,2.65,1.72,1.05]
	for i in centers.size():
		var p: Vector3 = centers[i]
		var r: float = radii[i]
		s.ball(p,Vector3.ONE*r*2,"chalk" if i%2==0 else "iron")
		for j in 9:
			var a := j*2.399
			var y := -.77+1.54*j/8.
			var elev := Vector3(cos(a)*sqrt(1-y*y),y,sin(a)*sqrt(1-y*y))
			var center := p+elev*r*.965
			var pitch := acos(clampf(elev.y,-1,1))
			var rot := Vector3(pitch,atan2(elev.x,elev.z),0)
			s.ring(center,r*(.1+.025*(j%3)),.09,"basalt",rot)
		if i==1 or i==3:
			s.ring(p,r*1.6,.15,"glass",Vector3(.52,.37,-.44))
	for i in 40:
		var u := rng.randf()
		var p: Vector3 = centers.front().lerp(centers.back(),u)
		p += Vector3(rng.randf_range(-3.7,3.7),rng.randf_range(2.3,6.3),rng.randf_range(-4.,4.))
		var r := rng.randf_range(.15,.62)
		s.box(p,Vector3(r,r*.6,r*1.6),"iron" if i%4 else "pearl",Vector3(u*12.,u*11.,u*8.))
	s.ball(Vector3(17,-7,9),Vector3(17,3.6,12),"basalt")

static func _geysers(s: Node3D,rng: RandomNumberGenerator) -> void:
	s.box(Vector3(0,-3.4,0),Vector3(63.8,.65,47.8),"glass")
	var deposits := _clearings(11,rng,13)
	for i in deposits.size():
		var p := deposits[i]
		var r := rng.randf_range(1.6,2.65)
		var h := rng.randf_range(5.8,13.)
		for k in 4:
			var w := r*(2.31-.36*k)
			s.column(p+Vector3.UP*(-1.85+.51*k),Vector3(w,.64,w*.9),"bone" if k%2 else "salt")
		s.ring(p-Vector3.UP*.12,r*.55,.20,"chalk")
		s.ball(p-Vector3.UP*.25,Vector3(r,.4,r),"glass")
		if i%3==1: continue
		var dir := _rad(i*2.12)
		s.cone(p+Vector3.UP*(h*.44),Vector3(.88,h*.95,.91),"pearl")
		# Fine spray bends off the top of each jet with the common crosswind.
		for j in 11:
			var t := j/10.0
			var q := p+dir*(sin(t*PI)*.46)+Vector3(t*t*1.49,h*(.75+.48*sin(t*PI)-.39*t),0)
			var size3 := Vector3(.31,.65,.31)*(1.-t*.55)
			s.ball(q,size3,"pearl")
		for j in 3:
			var q := p+Vector3(.5+j*.7,h*.82+j*.62,.6*j)
			s.ball(q,Vector3(1.4+j*.22,.65+j*.14,.99),"salt")

static func _paper_storm(s: Node3D,rng: RandomNumberGenerator) -> void:
	# A flock turns through a twist; each silhouette changes with the observer.
	for i in 20:
		var a := TAU*i/20.
		var p := Vector3(cos(a)*21.4,11.2+4.6*sin(a*2+.4),sin(a)*13.9)
		var k := 1.68 if i%7==0 else rng.randf_range(.46,1.22)
		var model := _model(s,RAY,p,Vector3.ONE*k,Vector3(.17*sin(a),-a-.9,-.43*cos(a)))
		var duration := rng.randf_range(3.1,5.2)
		if model.is_inside_tree():
			_glide(model,p.y,duration)
		else:
			model.ready.connect(_glide.bind(model,p.y,duration),CONNECT_ONE_SHOT)
	for p in _clearings(12,rng,13):
		var h := rng.randf_range(3.0,8.6)
		s.beam(p-Vector3.UP*6,p+Vector3.UP*h,.17,.19,"iron")
		s.box(p+Vector3.UP*(h-.91)+Vector3(.45,0,0),Vector3(.96,1.22,.053),"cloth",Vector3(-.12,.14,.51))
	s.box(Vector3(0,-13,0),Vector3(63.8,.5,47.8),"basalt")

static func _glide(model: Node3D, y: float, duration: float) -> void:
	var motion := model.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	motion.tween_property(model,"position:y",y+.83,duration)
	motion.tween_property(model,"position:y",y,duration)

static func _lunar_hive(s: Node3D,rng: RandomNumberGenerator) -> void:
	# Suspended honeycomb sheets have proper open centres and share cell sides.
	for sheet in 3:
		var origin := [Vector3(-16,9.7,-9.6),Vector3(5.8,13.2,6.6),Vector3(18.5,8.8,-7.2)][sheet] as Vector3
		var axis := _rad(.30+sheet*.86)
		var normal := Vector3.UP.cross(axis)
		var r := 1.70 if sheet==1 else 1.14
		for row in 3:
			for col in 5:
				if (row==0 and col==4) or (row==2 and col==0): continue
				var p := origin+axis*((col-2+.5*(row%2))*sqrt(3.)*r)+Vector3.UP*(row-1)*1.5*r
				var previous := p+Vector3.UP*r
				for k in range(1,7):
					var a := k*TAU/6.
					var current := p+axis*sin(a)*r+Vector3.UP*cos(a)*r
					s.beam(previous,current,.15,.21,"brass")
					previous=current
				if (col+2*row+sheet)%3==0:
					s.ball(p+normal*.11,Vector3.ONE*r*1.24,"pearl")
		s.beam(origin+Vector3.UP*r*1.9,origin+Vector3.UP*(r*4.0),.10,.10,"brass")
	for p in _clearings(13,rng,14):
		var h := rng.randf_range(2.2,7.4)
		s.cone(p+Vector3.UP*(h*.5-2.0),Vector3(.97,h,1.08),"brass")
		s.ball(p+Vector3.UP*(h-2.0),Vector3(1.25,1.65,1.22),"bone")
	s.ball(Vector3(0,-8.8,0),Vector3(31,7.5,26),"pearl")
