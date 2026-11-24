extends RefCounted

const SIDES := [-1., 1.]
const AXLE_X := Vector3(0, 0, PI/2)
const PALETTES := [
	["basalt","stone","bone"], ["chalk","stone","iron"], ["wood","salt","brass"],
	["wood","basalt","brass"], ["stone","chalk","iron"], ["wood","rust","wood"],
	["chalk","basalt","stone"], ["iron","moss","rust"], ["wood","chalk","wood"],
	["wood","cloth","brass"], ["iron","wood","brass"], ["basalt","rust","iron"],
	["stone","wood","brass"], ["iron","basalt","iron"],
]

# Flight lengths follow the room order in stone_atlas.gd.
const FLIGHTS := [
	[6,6,6],   # Columbarium niches mark three funerary terraces.
	[9,9],     # Twin processional flights under the cathedral ribs.
	[7,11],    # Tide staff landing, followed by the longer archive flight.
	[5,7,5],   # Short backstage calls between fly galleries.
	[10,6],    # Long approach to the inspection hatch.
	[19],      # Single companionway beside the hauling tackle.
	[6,7,6],   # A landing for each bank of seats.
	[12,6],    # Sluice service deck above the valve wheels.
	[16],      # Narrow attic stair to the scribes' windows.
	[8,5,8],   # Short centre flight between the two looms.
	[8,8],     # Paired loading galleries of the sorting station.
	[7,5,7],   # Maintenance landings between the casting bays.
	[10,10],   # Even rise through the clock cases.
	[22],      # Straight station flight beneath the inverted track.
]

static func flights(index: int) -> Array:
	return FLIGHTS[index]

static func palette(index: int) -> Array:
	return PALETTES[index]

static func dress(s: Node3D, index: int) -> void:
	match index:
		0: _columbarium(s)
		1: _cathedral(s)
		2: _tide_archive(s)
		3: _backstage(s)
		4: _quarantine(s)
		5: _rigging(s)
		6: _listeners(s)
		7: _sluice(s)
		8: _scriptorium(s)
		9: _loom(s)
		10: _sorting(s)
		11: _foundry(s)
		12: _clock_house(s)
		13: _terminus(s)

static func _at(s: Node3D, x: float, z: float, height: float) -> Vector3:
	return Vector3(x, s.height_at(z) + height, z)

static func _columbarium(s: Node3D) -> void:
	for side: float in SIDES:
		for bay in 4:
			var p := _at(s, side*2.20, 1.15+bay*1.9, 1.20)
			s.box(p,Vector3(.73,2.75,1.77),"basalt")
			for shelf in 3:
				var level := p+Vector3(0,(shelf-1)*.86,0)
				s.box(level+Vector3.UP*.40,Vector3(.9,.12,1.81),"chalk")
				s.box(level+Vector3(-side*.39,0,0),Vector3(.08,.63,1.48),"stone")
				s.box(level+Vector3(-side*.45,.08,0),Vector3(.05,.15,.63),"bone")
				for bolt: float in SIDES:
					s.ball(level+Vector3(-side*.46,-.12,bolt*.56),Vector3.ONE*.075,"brass")

static func _cathedral(s: Node3D) -> void:
	for z: float in [1.15,4.,6.85]:
		for side: float in SIDES:
			var foot := _at(s,side*2.12,z,0)
			for dz: float in [-.21,.0,.21]:
				s.column(foot+Vector3(0,1.83,dz),Vector3(.27,3.76,.27),"chalk")
			s.box(foot+Vector3.UP*3.67,Vector3(.74,.25,.83),"stone")
			var knee := foot+Vector3(-side*.53,4.45,0)
			var apex := foot+Vector3(-side*2.12,5.47,0)
			s.beam(foot+Vector3.UP*3.79,knee,.24,.29,"chalk")
			s.beam(knee,apex,.21,.26,"chalk")
		s.ball(_at(s,0,z,5.45),Vector3(.36,.38,.34),"brass")

static func _tide_archive(s: Node3D) -> void:
	for bay in 3:
		var p := _at(s,-2.17,1.35+bay*2.6,1.54)
		s.box(p,Vector3(.65,2.95,2.06),"wood")
		for row in 3:
			for i in 5:
				var h := .45+posmod(bay*3+row+i,4)*.084
				var spine := p+Vector3(.37,(row-1)*.79+h*.5-.22,(i-2)*.34)
				s.box(spine,Vector3(.19,h,.28),["moss","bone","rust"][(row+i)%3])
				s.box(spine+Vector3(.11,-.08,0),Vector3(.025,.056,.19),"brass")
			s.box(p+Vector3(.11,(row-1)*.79-.27,0),Vector3(.71,.095,2.08),"salt")
		var staff := _at(s,1.96,1.35+bay*2.6,1.28)
		s.box(staff,Vector3(.19,2.66,.36),"chalk")
		for tick in 10:
			s.box(staff+Vector3(-.11,tick*.23-1.04,0),Vector3(.033,.045,.3 if tick%3==0 else .14),"basalt")

static func _backstage(s: Node3D) -> void:
	for z: float in [1.5,5.8]:
		for side: float in SIDES:
			var rail := _at(s,side*2.06,z,3.76)
			s.box(rail,Vector3(.18,.14,2.36),"brass")
			for fold in 8:
				var length := 2.9-.81*sin(PI*fold/7.)
				var p := rail+Vector3(side*.07*cos(fold*PI),-length*.5,(fold-3.5)*.28)
				s.column(p,Vector3(.30,length,.36),"cloth")
			var cord := rail+Vector3(-side*.19,-1.35,1.02)
			s.box(cord,Vector3(.047,2.65,.05),"brass")
			s.cone(cord-Vector3.UP*1.42,Vector3(.21,.32,.21),"brass")
		s.beam(_at(s,-2.06,z,3.88),_at(s,2.06,z,3.88),.17,.24,"wood")

static func _quarantine(s: Node3D) -> void:
	for side: float in SIDES:
		for z: float in [1.6,4.,6.4]:
			var shutter := _at(s,side*2.16,z,1.94)
			s.box(shutter,Vector3(.41,3.03,2.21),"chalk")
			var hatch := shutter+Vector3(-side*.23,0,0)
			s.box(hatch,Vector3(.09,1.32,1.63),"basalt")
			for i in 6:
				s.box(hatch+Vector3(-side*.08,.0,(i-2.5)*.25),Vector3(.079,1.37,.061),"iron")
			s.box(hatch+Vector3(-side*.12,-.7,0),Vector3(.25,.12,1.82),"salt")
	# Inspection sheets on a line above the barred hatch.
	for i in 6:
		var z := 1.3+i*.99
		s.box(_at(s,-1.82,z,3.85),Vector3(.045,.69,.66),"cloth" if i%3==1 else "bone")
	s.beam(_at(s,-1.82,.62,4.23),_at(s,-1.82,7.43,4.23),.052,.052,"iron")

static func _rigging(s: Node3D) -> void:
	for z: float in [1.7,5.9]:
		for side: float in SIDES:
			var wheel := _at(s,side*2.23,z,2.68)
			s.box(wheel+Vector3(side*.32,-1.17,0),Vector3(.23,3.2,.4),"wood")
			s.column(wheel,Vector3(.91,.47,.91),"wood",AXLE_X)
			for flange: float in SIDES:
				s.column(wheel+Vector3.RIGHT*flange*.24,Vector3(1.08,.08,1.08),"rust",AXLE_X)
			for dz: float in [-.46,.46]:
				var top := wheel+Vector3.BACK*dz
				var bottom := top-Vector3.UP*(1.64+dz*.44)
				s.beam(top,bottom,.072,.072,"bone")
				s.ring(bottom,.14,.044,"brass",AXLE_X)
		s.beam(_at(s,-2.32,z,3.93),_at(s,2.32,z,3.93),.33,.27,"wood")

static func _listeners(s: Node3D) -> void:
	# Empty limestone seats climb with the visitor, facing the central aisle.
	for side: float in SIDES:
		for seat in 5:
			var p := _at(s,side*2.31,1.+seat*1.48,.34)
			s.box(p,Vector3(.98,.97,1.28),"stone")
			s.box(p+Vector3.UP*.54,Vector3(1.2,.15,1.38),"chalk")
			s.box(p+Vector3(side*.49,1.04,0),Vector3(.2,1.12,1.28),"stone")
			s.ring(p+Vector3(side*.36,1.12,0),.26,.05,"bone",AXLE_X)

static func _sluice(s: Node3D) -> void:
	for side: float in SIDES:
		for z: float in [1.6,4.,6.4]:
			var gate := _at(s,side*2.27,z,1.06)
			s.box(gate,Vector3(.54,2.25,2.21),"moss")
			for dz: float in [-.91,0.,.91]:
				s.box(gate+Vector3(-side*.31,0,dz),Vector3(.14,2.27,.11),"iron")
			var hub := gate+Vector3(-side*.40,.57,0)
			s.ring(hub,.53,.064,"rust",AXLE_X)
			for i in 5:
				var a := TAU*i/5.
				s.beam(hub,hub+Vector3(0,.50*cos(a),.50*sin(a)),.061,.067,"brass")
			s.box(gate+Vector3.UP*1.62,Vector3(.12,1.56,.12),"iron")

static func _scriptorium(s: Node3D) -> void:
	for z: float in [1.25,3.9,6.55]:
		var desk := _at(s,-2.37,z,1.04)
		s.box(desk,Vector3(1.12,.14,1.96),"wood",Vector3(0,0,-.12))
		for dz: float in [-.72,.72]:
			s.box(desk+Vector3(0,-.66,dz),Vector3(.86,1.28,.16),"wood")
		var folio := desk+Vector3(.04,.102,-.24)
		s.box(folio,Vector3(.71,.045,.9),"bone",Vector3(0,0,-.12))
		for i in 5:
			s.box(folio+Vector3(i*.10-.2,.031-i*.012+.024,0),Vector3(.015,.014,.58),"basalt")
		s.column(desk+Vector3(-.20,.22,.62),Vector3.ONE*.24,"basalt")
		var window := _at(s,2.12,z,2.96)
		s.box(window,Vector3(.18,2.15,2.16),"glass")
		for dz: float in [-1.02,0.,1.02]:
			s.box(window+Vector3(-.12,0,dz),Vector3(.17,2.25,.11),"wood")
		s.box(window+Vector3(-.12,-.24,0),Vector3(.15,.10,2.18),"wood")

static func _loom(s: Node3D) -> void:
	for side: float in SIDES:
		for z: float in [1.97,5.91]:
			var p := _at(s,side*2.02,z,1.78)
			for dz: float in [-1.47,1.47]:
				s.box(p+Vector3(0,-.17,dz),Vector3(.19,3.55,.21),"wood")
			for y: float in [-1.12,1.46]:
				s.column(p+Vector3.UP*y,Vector3(.30,3.23,.30),"wood",Vector3(PI/2,0,0))
			for i in 14:
				var dz := (i-6.5)*.20
				s.beam(p+Vector3(0,1.42,dz),p+Vector3(side*(i%2)*.11,-.45,dz),.035,.044,"bone")
			s.box(p+Vector3(0,-.78,0),Vector3(.12,.69,2.76),"cloth")
			s.box(p+Vector3(-side*.10,.09,0),Vector3(.10,.12,3.15),"brass")

static func _sorting(s: Node3D) -> void:
	for side: float in SIDES:
		for z: float in [1.25,3.95,6.65]:
			var p := _at(s,side*2.14,z,1.42)
			s.box(p,Vector3(.64,2.76,1.89),"iron")
			for row in 3:
				for col in 2:
					var drawer := p+Vector3(-side*.35,(row-1)*.80,(col-.5)*.89)
					s.box(drawer,Vector3(.09,.72,.79),"wood")
					s.box(drawer+Vector3(-side*.067,.17,0),Vector3(.041,.115,.39),"bone")
					s.box(drawer+Vector3(-side*.09,-.10,0),Vector3(.095,.064,.30),"brass")
			s.column(p+Vector3.UP*1.94,Vector3(.25,1.08,.25),"brass")
			s.ring(p+Vector3.UP*2.34,.15,.035,"iron")
	s.beam(_at(s,-2.14,.2,3.94),_at(s,-2.14,7.8,3.94),.29,.27,"brass")

static func _foundry(s: Node3D) -> void:
	for z: float in [1.5,4.,6.5]:
		for side: float in SIDES:
			var p := _at(s,side*2.26,z,1.07)
			s.box(p,Vector3(.70,2.28,2.08),"basalt")
			var face := p+Vector3(-side*.38,.06,0)
			s.ring(face,.59,.125,"rust",AXLE_X)
			s.ring(face+Vector3.LEFT*side*.04,.36,.042,"ember",AXLE_X)
			for dz: float in [-.85,.85]:
				s.box(face+Vector3(0,0,dz),Vector3(.17,2.39,.105),"iron")
	var furnace := _at(s,2.08,4.,1.2)
	s.lamp(furnace-Vector3.RIGHT*.36,Color("ff9b58"),2.3,5.)

static func _clock_house(s: Node3D) -> void:
	for bay in 3:
		var side: float = SIDES[bay%2]
		var p := _at(s,side*2.18,1.45+bay*2.55,2.45)
		s.box(p-Vector3.UP*.63,Vector3(.49,3.51,1.83),"wood")
		var dial := p+Vector3(-side*.28,.06,0)
		s.column(dial,Vector3(1.58,.11,1.58),"basalt",AXLE_X)
		dial.x -= side*.08
		s.ring(dial,.75,.053,"brass",AXLE_X)
		for i in 12:
			var t := TAU*i/12.
			var tick := Vector3(0,cos(t),sin(t))
			s.beam(dial+tick*.56,dial+tick*.68,.055,.057,"bone")
		var theta := .7+bay*2.11
		for length: float in [.60,.41]:
			s.beam(dial,dial+Vector3(0,cos(theta),sin(theta))*length,.065,.069,"brass")
			theta += 1.78
		s.beam(dial-Vector3.UP*.8,dial-Vector3.UP*1.83,.06,.06,"brass")
		s.column(dial-Vector3.UP*1.9,Vector3(.40,.12,.40),"brass",AXLE_X)

static func _terminus(s: Node3D) -> void:
	# Twin running rails and their sleepers follow the ceiling in the station.
	for x: float in [-.75,.75]:
		s.beam(_at(s,x,.48,4.18),_at(s,x,7.52,4.18),.12,.18,"iron")
	for i in 9:
		var z := .65+i*.84
		s.box(_at(s,0,z,4.34),Vector3(2.64,.18,.23),"wood")
	for side: float in SIDES:
		var head := _at(s,side*2.09,3.85+side*1.64,2.3)
		s.column(head-Vector3.UP*1.35,Vector3(.19,2.77,.19),"iron")
		s.box(head,Vector3(.52,1.41,.55),"basalt")
		for y: float in [-.34,.34]:
			for face: float in SIDES:
				s.ball(head+Vector3(0,y,face*.29),Vector3(.31,.31,.13),"ember" if y<0. else "pearl")
