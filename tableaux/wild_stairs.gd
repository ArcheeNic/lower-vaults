extends RefCounted

const Atlas := preload("res://tableaux/wild_atlas.gd")
const RISERS := ["iron","moss","iron","basalt","salt","glass","iron","rust",
	"cloth","bone","basalt","salt","cloth","bone"]

# Uninterrupted runs carry the vertebral arch and the meteor net. The clutch,
# the tide instruments and the hive use distinct shelves between short runs.
const FLIGHTS := [
	[5,7,9], [6,5,6], [8,4,8], [22],
	[9,6,4], [7,11], [8,8], [10,5,4],
	[6,10], [4,7,6], [20], [5,6,7],
	[11,7], [6,6,6]
]

static func flights(index: int) -> Array:
	return FLIGHTS[index]

static func palette(index: int) -> Array:
	return [Atlas.FLOORS[index],RISERS[index],Atlas.RAILS[index]]

static func dress(s: Node3D, index: int) -> void:
	match index:
		0: _tuning_forks(s)
		1: _nest(s)
		2: _transit_instruments(s)
		3: _rib_vault(s)
		4: _shell_sections(s)
		5: _ice_plates(s)
		6: _eclipse_sight(s)
		7: _fissure(s)
		8: _jelly_lanterns(s)
		9: _spore_shelves(s)
		10: _meteor_net(s)
		11: _sinter(s)
		12: _folded_vanes(s)
		13: _honeycomb(s)

static func _foot(s: Node3D, x: float, z: float) -> Vector3:
	return Vector3(x,s.height_at(z),z)

static func _tuning_forks(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		for i in 4:
			var p := _foot(s,side*1.88,1.+1.95*i)
			var neck := p+Vector3.UP*.96
			var length := 1.1+.31*(i if side>0 else 3-i)
			s.column(p,Vector3(.37,1.35,.37),"wood")
			s.column(p+Vector3.UP*.47,Vector3(.31,.12,.31),"iron")
			s.beam(p,neck,.15,.16,"brass")
			for tine: float in [-1.,1.]:
				var elbow := neck+Vector3(0,.17,tine*.22)
				s.beam(neck,elbow,.13,.13,"brass")
				s.beam(elbow,elbow+Vector3.UP*length,.12,.15,"brass")

static func _nest(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		# Each egg sits behind two plaited courses; the weave changes hand
		# at the middle peg of each panel.
		for i in 3:
			var z := 1.65+i*2.34
			var mid := _foot(s,side*2.17,z)
			s.ball(mid+Vector3.UP*.46,Vector3(.83,1.25,.91),"bone" if i!=1 else "pearl")
			for j in 4:
				var a := j*1.61
				s.ball(mid+Vector3(-side*.36,.51+.22*sin(a),.21*cos(a)),Vector3(.065,.10,.08),"moss")
			for hand: float in [-1.,1.]:
				var left := _foot(s,side*1.76,z-.95)+Vector3.UP*.5
				var right := _foot(s,side*1.76,z+.95)+Vector3.UP*.5
				var knot := _foot(s,side*1.88,z)+Vector3.UP*(.50+hand*.22)
				s.beam(left,knot,.09,.12,"wood")
				s.beam(knot,right,.09,.12,"wood")

static func _transit_instruments(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		for z: float in [1.65,4.,6.35]:
			var base := _foot(s,side*1.94,z)
			var hub := base+Vector3.UP*1.58
			s.column(base+Vector3.UP*.55,Vector3(.27,1.18,.27),"iron")
			s.ring(hub,.67,.043,"brass",Vector3(0,0,PI/2))
			var arm := Vector3(0,sin(z*.63),cos(z*.63))
			s.beam(hub-arm*.65,hub+arm*.76,.09,.09,"glass")
			s.ball(hub,Vector3.ONE*.19,"brass")
			for tick in 9:
				var angle := PI*tick/8.
				var ray := Vector3(0,sin(angle),cos(angle))
				s.beam(hub+ray*.64,hub+ray*(.76 if tick%2==0 else .70),.045,.04,"iron")

static func _rib_vault(s: Node3D) -> void:
	var last := Vector3.ZERO
	for i in 5:
		var z := 1.+i*1.5
		var spine := _foot(s,0,z)+Vector3.UP*(4.74+.2*sin(i*.78))
		s.ball(spine,Vector3(.62,.48,.81),"bone")
		s.cone(spine+Vector3.UP*.33,Vector3(.25,.46,.42),"chalk")
		if i>0:
			s.beam(last,spine,.32,.34,"bone")
		last = spine
		for side: float in [-1.,1.]:
			var shoulder := spine+Vector3(side*1.79,-.47,.04)
			var elbow := spine+Vector3(side*2.18,-1.28,.16)
			var tip := _foot(s,side*1.88,z+.50)+Vector3.UP*.56
			s.beam(spine,shoulder,.19,.25,"bone")
			s.beam(shoulder,elbow,.20,.23,"bone")
			s.beam(elbow,tip,.15,.18,"chalk")

static func _shell_sections(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		for z: float in [2.0,5.95]:
			var nucleus := _foot(s,side*1.86,z)+Vector3.UP*1.42
			var previous := nucleus+Vector3.UP*.12
			for k in range(1,25):
				var phase := k*TAU/15.
				var radius := .12*exp(.22*phase)
				var radial := Vector3(0,cos(phase),sin(phase)*side)
				var edge := nucleus+radial*radius
				s.beam(previous,edge,.12,.12,"bone")
				if k>10 and k%2==0:
					s.beam(nucleus+radial*radius*.27,edge,.046,.045,"brass")
				previous = edge
			s.ball(nucleus,Vector3.ONE*.23,"pearl")

static func _ice_plates(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		for i in 7:
			var p := _foot(s,side*2.08,.82+i*1.05)
			var height := 1.06+1.98*absf(sin(i*1.63+side*.58))
			var slant := Vector3(.12*cos(i*.83),0,-side*.054)
			s.box(p+Vector3.UP*(height*.37),Vector3(.32,height,1.03),"glass",slant)
			var crest := p+Vector3.UP*(height*.84)+Vector3(side*.035,0,height*slant.x*.40)
			s.box(crest,Vector3(.34,.13,1.04),"salt",slant)
			s.beam(p+Vector3(-side*.19,.35,-.30),crest+Vector3(-side*.19,0,.27),.035,.036,"pearl")

static func _eclipse_sight(s: Node3D) -> void:
	for z: float in [1.55,6.45]:
		var axis := _foot(s,0,z)+Vector3.UP*5.0
		s.ring(axis,.84,.075,"brass",Vector3(PI/2,0,0))
		for side: float in [-1.,1.]:
			var base := _foot(s,side*2.08,z)
			var tip := base+Vector3.UP*4.20
			s.cone(base+Vector3.UP*1.95,Vector3(.60,4.4,.64),"basalt")
			s.beam(tip,axis+Vector3.RIGHT*side*.80,.11,.13,"brass")
			for band in 3:
				s.column(base+Vector3.UP*(.4+band*.24),Vector3(.61,.07,.61),"brass")
	# From the middle of the stairs the two sights frame the same black disc.
	var eclipse := _foot(s,0,4.)+Vector3.UP*5.
	s.ball(eclipse,Vector3.ONE*1.04,"iron")
	s.ring(eclipse,.59,.058,"ember",Vector3(PI/2,0,0))
	s.lamp(eclipse+Vector3.DOWN*.45,Color("efad68"),1.5,5.)

static func _fissure(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		var prior := Vector3.ZERO
		for i in 8:
			var z := .73+i*.92
			var p := _foot(s,side*2.13,z)
			var height := .75+.38*cos(i*1.92+side)
			s.column(p+Vector3.UP*(height-.85),Vector3(.83,1.70,.86),"basalt")
			var lip := p+Vector3(-side*.40,height-.25,0)
			s.beam(lip+Vector3(0,-.24,-.22),lip,.047,.065,"ember")
			var seam := lip+Vector3(0,.12,.38)
			s.beam(lip,seam,.05,.06,"ember")
			if i>0:
				s.beam(prior,lip+Vector3(0,-.24,-.22),.035,.047,"rust")
			prior = seam
	s.lamp(_foot(s,2.,3.9)+Vector3.UP*.5,Color("f29c68"),2.1,5.5)

static func _jelly_lanterns(s: Node3D) -> void:
	for i in 5:
		var side := -1. if i%2==0 else 1.
		var z := 1.10+i*1.46
		var bell := _foot(s,side*2.47,z)+Vector3.UP*(2.52+.49*sin(i*1.45))
		s.ball(bell+Vector3.UP*.16,Vector3(1.23,.80,1.23),"glass")
		s.ring(bell,.60,.055,"pearl")
		s.ball(bell-Vector3.UP*.14,Vector3(.5,.32,.50),"cloth")
		for k in 6:
			var a := TAU*k/6.
			var lip := bell+Vector3(cos(a)*.51,0,sin(a)*.51)
			var knot := lip+Vector3(side*.12,-.62,.14*cos(a))
			s.beam(lip,knot,.059,.064,"pearl")
			s.beam(knot,knot+Vector3(side*.10,-.62,.24*sin(a)),.035,.04,"cloth")
		if i==2:
			s.lamp(bell,Color("8dd2c5"),1.65,5.)

static func _spore_shelves(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		for i in 4:
			var z := 1.+i*1.9
			var root := _foot(s,side*2.39,z)
			var elbow := root+Vector3(side*.20,.76,0)
			var cap := root+Vector3(side*.12,1.37+.68*cos(i*1.22+side),.17)
			s.beam(root-Vector3.UP*.45,elbow,.24,.29,"bone")
			s.beam(elbow,cap,.19,.21,"bone")
			s.ball(cap+Vector3.UP*.07,Vector3(1.24,.45,1.29),"cloth")
			s.ball(elbow+Vector3(-side*.18,0,-.18),Vector3(.71,.22,.69),"rust")
			for gill in 7:
				var a := TAU*gill/7.
				s.beam(cap-Vector3.UP*.15,cap+Vector3(cos(a)*.57,0,sin(a)*.57),.035,.045,"salt")

static func _meteor_net(s: Node3D) -> void:
	var previous := Vector3.ZERO
	for i in 6:
		var z := .92+i*1.2
		var center := _foot(s,.52*sin(i*1.23),z)+Vector3.UP*(4.72+i*.093)
		var radius := .43-i*.044
		s.ball(center,Vector3.ONE*radius*2.,"pearl" if i%3==0 else "iron")
		s.ring(center+Vector3(0,.12,-radius*.84),radius*.27,.025,"basalt",Vector3(1.2,0,0))
		if i>0:
			s.beam(previous,center,.03,.035,"glass")
		previous = center
		for side: float in [-1.,1.]:
			var anchor := _foot(s,side*1.92,z)+Vector3.UP*4.22
			s.beam(_foot(s,side*1.92,z)-Vector3.UP*.33,anchor,.095,.11,"iron")
			s.beam(anchor,center-Vector3.UP*radius,.035,.045,"iron")

static func _sinter(s: Node3D) -> void:
	for side: float in [-1.,1.]:
		for i in 4:
			var spring := _foot(s,side*2.40,1.26+i*1.77)
			for terrace in 3:
				var diameter := 1.28-terrace*.22
				s.column(spring+Vector3.UP*(.17+terrace*.16),Vector3(diameter,.20,diameter*.92),"salt" if terrace%2==0 else "chalk")
			var vent := spring+Vector3.UP*.62
			s.ring(vent,.29,.07,"bone")
			s.ball(vent,Vector3(.51,.16,.51),"glass")
			if (i+int(side))%2==0:
				s.cone(vent+Vector3.UP*.64,Vector3(.22,1.35,.22),"pearl")
				for drop in 5:
					var t := drop*.21
					s.ball(vent+Vector3(side*t*.24,1.23+.51*sin(PI*t)-.13*t,t*.72),Vector3(.075,.11,.075),"pearl")

static func _folded_vanes(s: Node3D) -> void:
	for i in 7:
		var side := -1. if i%2==0 else 1.
		var z := .85+i*1.03
		var foot := _foot(s,side*1.87,z)
		var pivot := foot+Vector3.UP*(2.10+.31*sin(i*1.34))
		s.beam(foot-Vector3.UP*.55,pivot,.076,.082,"iron")
		s.ball(pivot,Vector3.ONE*.19,"brass")
		for fold: float in [-1.,1.]:
			var panel := pivot+Vector3(side*.17,.08,fold*.34)
			s.box(panel,Vector3(.042,.64,.76),"bone" if i%3==0 else "cloth",Vector3(-.36,fold*side*.45,.03))
			s.beam(pivot+Vector3.UP*.29,panel+Vector3(side*.16,-.08,fold*.34),.035,.035,"iron")

static func _honeycomb(s: Node3D) -> void:
	var radius := .56
	for side: float in [-1.,1.]:
		for col in 6:
			for row in 2:
				var z := 1.25+(col+row*.5)*sqrt(3.)*radius
				# Each column has a level sill, with its own attachment to
				# the stepped deck; alternate rows fit the same cell edges.
				var base_y: float = s.height_at(1.25+col*sqrt(3.)*radius)
				var center := Vector3(side*1.85,base_y+.64+row*1.5*radius,z)
				var a := center+Vector3.UP*radius
				for k in range(1,7):
					var angle := k*TAU/6.
					var b := center+Vector3(0,cos(angle),sin(angle))*radius
					s.beam(a,b,.07,.09,"brass")
					a = b
				if (col+row+int(side))%3==0:
					s.ball(center,Vector3(.25,.54,.54),"pearl")
