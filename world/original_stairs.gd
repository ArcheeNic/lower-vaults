extends RefCounted

const PALETTES := {
	0:["stone","basalt","brass"],
	1:["wood","rust","iron"],
	2:["chalk","basalt","brass"],
	3:["iron","rust","brass"],
	32:["basalt","stone","brass"]
}
const FLIGHTS := {
	0:[10,10],   # Processional landing beneath the middle arch.
	1:[9,8],     # Pause by the tide gauge before the shorter dock flight.
	2:[22],      # An uninterrupted sightline between the transit sights.
	3:[5,9,5],   # Service landings beside the two sheaves.
	32:[6,6,6]   # Three equal measures on the plumb line.
}

static func palette(index: int) -> Array:
	return PALETTES[index]

static func flights(index: int) -> Array:
	return FLIGHTS[index]

static func dress(s: Node3D, index: int) -> void:
	match index:
		0: _vault(s)
		1: _lock(s)
		2: _transit_instrument(s)
		3: _winding_engine(s)
		32: _sounding_well(s)

static func _vault(s: Node3D) -> void:
	# The arch stones are individually bedded into the two rib mouldings.
	for z: float in [.85,4.,7.15]:
		var spring: float = s.height_at(z)+3.70
		for side: float in [-1.,1.]:
			var post := Vector3(side*1.99,spring-2.15,z)
			s.box(post,Vector3(.50,4.3,.55),"stone")
			s.column(post+Vector3(-side*.16,0,0),Vector3(.18,4.3,.28),"chalk")
			s.box(post+Vector3.UP*2.02,Vector3(.66,.26,.69),"basalt")
		var center := Vector3(0,spring,z)
		for i in 13:
			var a := PI*(i+.025)/13.
			var b := PI*(i+.975)/13.
			var p := Vector3(1.99*cos(a),1.38*sin(a),0)
			var q := Vector3(1.99*cos(b),1.38*sin(b),0)
			s.beam(center+p,center+q,.48,.31,"chalk" if i==6 else "stone")
			s.beam(center+p+Vector3.BACK*.21,center+q+Vector3.BACK*.21,.12,.18,"basalt")
	var niche := Vector3(1.96,s.height_at(4.)+2.12,4.)
	s.box(niche,Vector3(.33,.55,.39),"brass")
	s.box(niche-Vector3.RIGHT*.174,Vector3(.04,.36,.23),"ember")
	s.lamp(niche-Vector3.RIGHT*.27,Color("ffd394"),2.9,7.)

static func _lock(s: Node3D) -> void:
	# A lock keeper reads the staff gauge against a float in a stilling tube.
	for side: float in [-1.,1.]:
		for z: float in [1.25,4.0,6.75]:
			var pile := Vector3(side*2.12,s.height_at(z)+.74,z)
			s.column(pile,Vector3(.43,3.34,.43),"wood")
			for dy: float in [-1.,.6,1.36]:
				s.column(pile+Vector3.UP*dy,Vector3(.49,.12,.49),"rust")
		var a := Vector3(side*2.12,s.height_at(1.25)+1.74,1.25)
		var b := Vector3(side*2.12,s.height_at(6.75)+1.74,6.75)
		s.beam(a,b,.23,.28,"wood")
	var base := Vector3(-1.99,s.height_at(4.)-.81,4.78)
	s.box(base+Vector3.UP*1.77,Vector3(.14,3.52,.40),"salt")
	for i in 19:
		var tick := base+Vector3(.079,.17+i*.177,-.07 if i%5 else 0.)
		s.box(tick,Vector3(.025,.036,.15 if i%5 else .32),"basalt")
	var float_guide := base+Vector3(0,0,.47)
	s.column(float_guide+Vector3.UP*1.7,Vector3(.08,3.4,.08),"brass")
	s.ball(float_guide+Vector3.UP*1.35,Vector3(.32,.40,.32),"brass")
	var lantern := Vector3(2.12,s.height_at(6.75)+2.53,6.75)
	s.column(lantern,Vector3(.30,.42,.30),"glass")
	s.cone(lantern+Vector3.UP*.28,Vector3(.53,.18,.53),"rust")
	s.lamp(lantern,Color("aee7dc"),3.0,7.)

static func _transit_instrument(s: Node3D) -> void:
	# The slits in the two sights line up with the suspended meridian.
	for z: float in [1.25,6.75]:
		for side: float in [-1.,1.]:
			var base := Vector3(side*1.98,s.height_at(z),z)
			s.column(base+Vector3.UP*1.56,Vector3(.35,3.42,.35),"chalk")
			s.column(base+Vector3.UP*3.16,Vector3(.47,.19,.47),"brass")
			s.beam(base+Vector3.UP*3.14,base+Vector3(-side*.89,4.47,0),.15,.17,"iron")
			s.box(base+Vector3(-side*.90,4.55,0),Vector3(.27,.43,.18),"brass")
		var axis := Vector3(0,s.height_at(z)+4.52,z)
		s.beam(axis+Vector3.LEFT*1.14,axis+Vector3.RIGHT*1.14,.13,.11,"iron")
	var center := Vector3(0,s.height_at(4.)+4.94,4.)
	s.ring(center,1.05,.048,"brass",Vector3(PI*.5,0,0))
	s.ring(center,.83,.037,"iron",Vector3(1.21,.76,.38))
	s.ring(center,.66,.033,"brass",Vector3(.24,.29,.97))
	s.ball(center,Vector3.ONE*.31,"pearl")
	for i in 24:
		var a := TAU*i/24.
		var ray := Vector3(cos(a),sin(a),0)
		s.beam(center+ray*.98,center+ray*(1.14 if i%3==0 else 1.07),.028,.04,"chalk")
	s.lamp(center,Color("b9cfff"),3.6,8.)

static func _winding_engine(s: Node3D) -> void:
	# Drivers see two spoked sheaves and the two parallel runs of their belt.
	var hubs: Array[Vector3] = []
	for z: float in [1.8,6.2]:
		var hub := Vector3(2.02,s.height_at(z)+1.12,z)
		hubs.append(hub)
		s.box(hub-Vector3.UP*.82,Vector3(.50,1.72,.62),"basalt")
		s.column(hub,Vector3(.42,.68,.42),"brass",Vector3(0,0,PI*.5))
		s.ring(hub,.77,.12,"iron",Vector3(0,0,PI*.5))
		for i in 8:
			var angle := TAU*i/8.
			s.beam(hub,hub+Vector3(0,.73*cos(angle),.73*sin(angle)),.12,.10,"rust")
	var axle_line := hubs[0].direction_to(hubs[1])
	var radial := axle_line.cross(Vector3.RIGHT).normalized()*.79
	for side: float in [-1.,1.]:
		s.beam(hubs[0]+radial*side,hubs[1]+radial*side,.14,.072,"cloth")
	for z: float in [1.,4.,7.]:
		var foot := Vector3(-2.03,s.height_at(z),z)
		s.box(foot+Vector3.UP*1.14,Vector3(.31,2.77,.41),"iron")
		for dy: float in [.18,1.83]:
			s.box(foot+Vector3.UP*dy,Vector3(.61,.31,.60),"rust")
			s.column(foot+Vector3(.22,dy+.16,.19),Vector3(.10,.10,.10),"brass")
	var lamp := Vector3(-2.03,s.height_at(4.)+2.64,4.)
	s.box(lamp,Vector3(.48,.29,.66),"ember")
	s.lamp(lamp,Color("ff9b57"),3.3,7.)

static func _sounding_well(s: Node3D) -> void:
	# Brass plumb bobs hang beside enamel gauge staffs. Each set has a
	# different length but all three tips read at the handrail.
	for i in 3:
		var z := 1.35+i*2.65
		var side := -1. if i==1 else 1.
		var y: float = s.height_at(z)
		var top := Vector3(side*2.11,y+3.30+i*.27,z)
		var datum := Vector3(top.x,y+1.11,top.z)
		s.box(Vector3(top.x,y+1.07,z+.34),Vector3(.13,3.08,.32),"chalk")
		for tick in 13:
			var mark := Vector3(top.x-side*.078,y-.28+tick*.225,z+.34)
			s.box(mark,Vector3(.025,.035,.24 if tick%4==0 else .10),"basalt")
		s.box(top,Vector3(.26,.15,1.12),"wood")
		s.beam(top,datum+Vector3.UP*.48,.037,.037,"brass")
		s.column(datum+Vector3.UP*.49,Vector3(.29,.30,.29),"brass")
		s.cone(datum+Vector3.UP*.16,Vector3(.29,.36,.29),"brass",Vector3(PI,0,0))
	var lens := Vector3(-2.11,s.height_at(4.)+2.75,4.34)
	s.ball(lens,Vector3(.24,.38,.24),"pearl")
	s.lamp(lens,Color("edd5ae"),3.,7.)
