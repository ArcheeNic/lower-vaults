extends RefCounted

const TITLES := [
	"Ярусы колумбария", "Собор над провалом", "Архив прибоя", "Сцена после звонка",
	"Двор карантина", "Канатная кладовая", "Каменные слушатели", "Шлюзовая палата",
	"Мансарды переписчиков", "Дом ткацких станков", "Пересыльная станция",
	"Зал литейных форм", "Палата немых часов", "Обратный вокзал"
]
const CLIMATES := [0,0,1,0,0,1,0,1,0,0,2,3,0,2]
const FLOORS := ["stone","chalk","wood","wood","stone","wood","chalk","iron","wood","wood","iron","basalt","stone","iron"]
const GUARDS := ["bone","iron","brass","brass","iron","wood","stone","rust","wood","brass","brass","iron","brass","iron"]
const RISES := [.56,.83,.52,.63,.50,.65,.76,.60,.62,.55,.64,.84,.72,.68]
const PLANS := [
	["....0....",".222122..",".2....2..","01....210",".222...2.","...21222.","....0...."],
	["....0....","..32123..","..3.2.3..","012.3.210","..3.2.3..","..32123..","....0...."],
	["....0....",".3321233.",".2.3.3.2.","01.3.3.10",".2.3.3.2.",".3321233.","....0...."],
	["....0....","..321233.",".2332332.","01.....10",".233.332.","...212...","....0...."],
	["....0....","..111....","..1.111..","011...110","..111111.","....1111.","....0...."],
	["....0....",".3321233.",".2.....2.","012333210",".2.....2.",".3321233.","....0...."],
	["....0....","..32123..",".2332332.","01.....10",".2332332.","..32123..","....0...."],
	["....0....","....1.22.","..222222.","012....10","..2..222.","..2212...","....0...."],
	["....0....","...2123..","...32332.","0123..210","...3..3..","...2123..","....0...."],
	["....0....","....1....",".2222222.","012....10",".2222222.",".2221....","....0...."],
	["....0....","..32123..","..3...32.","012333.10","..3..3.2.","..321233.","....0...."],
	["....0....","....1....","..33233..","0123..210","...3233..","....1....","....0...."],
	["....0....","..32123..",".23...3..","01.443210",".2.3.33..",".332123..","....0...."],
	["....0....","..32123..","..3...3..","012...210","..33233..","..32123..","....0...."],
]

static var _flood_mesh: PlaneMesh
static var _flood_material: ShaderMaterial

static func build(s:Node3D,id:int) -> void:
	s.plan(PLANS[id], FLOORS[id], GUARDS[id], RISES[id])
	match id:
		0: _columbarium(s)
		1: _cathedral(s)
		2: _library(s)
		3: _theatre(s)
		4: _quarantine(s)
		5: _rigging_loft(s)
		6: _amphitheatre(s)
		7: _sluice(s)
		8: _scriptorium(s)
		9: _weaving(s)
		10: _sorting(s)
		11: _casting(s)
		12: _clock_house(s)
		13: _terminus(s)

static func _at(col:int,row:int) -> Vector3:
	return Vector3((col-4)*7.0,0,(row-3)*6.0)

static func _voids(id:int) -> Array[Vector3]:
	var result:Array[Vector3]=[]
	for row in range(1,6):
		for col in range(1,8):
			if PLANS[id][row][col]==".":
				result.append(_at(col,row))
	return result

static func _flood(s: Node3D, y:float) -> void:
	if not _flood_mesh:
		_flood_mesh=PlaneMesh.new()
		_flood_mesh.size=Vector2(64,48)
		_flood_material=ShaderMaterial.new()
		_flood_material.shader=preload("res://tableaux/stone_assets/flood.gdshader")
	var water:=MeshInstance3D.new()
	water.mesh=_flood_mesh
	water.material_override=_flood_material
	water.position.y=y
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.add_child(water)

# An arch is laid in its own vertical plane; its two faces stay open.
static func _arch(s:Node3D,center:Vector3,axis:Vector3,radius:float,rise:float,thickness:float,depth:float,mat:String,pointed:=false) -> void:
	var prior:=center-axis*radius
	for i in range(1,15):
		var t:=i*PI/14.0
		var profile:=sin(t)
		if pointed:
			profile*=.77+.23*(1.-absf(cos(t)))
		var p:=center-axis*(cos(t)*radius)+Vector3.UP*(rise*profile)
		s.beam(prior,p,thickness,depth,mat)
		prior=p

static func _columbarium(s:Node3D) -> void:
	# Freestanding tomb walls split the zigzag aisles into small rooms.
	for p:Vector3 in _voids(0):
		s.box(p+Vector3.UP*2.9,Vector3(4.6,9.2,3.7),"basalt")
		for level in 4:
			var y:float=-.5+level*1.94
			s.box(p+Vector3.UP*(y+.92),Vector3(5.0,.24,4.04),"stone")
			for flank in [-1.,1.]:
				var front:=p+Vector3(0,y,flank*1.91)
				s.box(front,Vector3(3.65,1.19,.23),"stone")
				s.box(front+Vector3(0,.24,flank*.14),Vector3(2.28,.18,.095),"chalk")
				for j in [-1.,1.]:
					s.ball(front+Vector3(j*1.33,-.12,flank*.18),Vector3(.18,.18,.13),"brass")
		s.box(p+Vector3.UP*7.63,Vector3(5.07,.31,4.18),"chalk")
	for x in [-27.8,27.8]:
		for z in [-12.,12.]:
			s.box(Vector3(x,4.0,z),Vector3(3.4,12.0,15.5),"stone")
			for y in [2.,5.,8.]:
				for dz in [-4.8,0.,4.8]:
					s.box(Vector3(x-signf(x)*1.72,y,z+dz),Vector3(.24,1.4,3.3),"basalt")
	for z in [-14.8,-2.2,10.2]:
		s.box(Vector3(0,9.8,z),Vector3(54,.95,1.15),"stone")
		for x in [-18.,-6.,6.,18.]:
			_arch(s,Vector3(x,7.3,z),Vector3.RIGHT,5.8,2.2,.42,.8,"bone")

	for side in [-1.,1.]:
		for z in [-16.,-3.,10.]:
			# Buried ceiling slabs leave narrow daylight cracks above the niches.
			s.box(Vector3(side*11.0,10.57,z),Vector3(20.3,1.14,12.38),"basalt")
			s.box(Vector3(side*1.13,10.07,z),Vector3(.69,.47,12.42),"stone")

static func _cathedral(s:Node3D) -> void:
	# Clustered shafts resolve into a pointed nave and two lower aisles.
	for x in [-8.5,8.5]:
		for z in [-18.,-6.,6.,18.]:
			for k in 5:
				var t:=k*TAU/5.
				var p:=Vector3(x+cos(t)*.62,6.9,z+sin(t)*.62)
				s.column(p,Vector3(.83,24,.83),"stone")
				s.column(p+Vector3.UP*11.63,Vector3(1.17,.45,1.17),"chalk")
	for z in [-18.,-6.,6.,18.]:
		_arch(s,Vector3(0,18.5,z),Vector3.RIGHT,8.5,10.,1.03,.83,"chalk",true)
		for side in [-1.,1.]:
			_arch(s,Vector3(side*17.9,12.5,z),Vector3.RIGHT,8.55,7.3,.75,.84,"stone",true)
			s.box(Vector3(side*27.1,7.3,z),Vector3(1.65,21.,1.85),"chalk")
	for z in [-12.,0.,12.]:
		for x in [-8.5,8.5]:
			_arch(s,Vector3(x,17.25,z),Vector3.BACK,6.,6.3,.68,.71,"stone",true)
		for side in [-1.,1.]:
			s.beam(Vector3(side*8.5,18.6,z-6),Vector3(0,28.2,z),.48,.72,"chalk")
			s.beam(Vector3(side*8.5,18.6,z+6),Vector3(0,28.2,z),.48,.72,"chalk")
		s.ball(Vector3(0,28.35,z),Vector3(1.6,1.45,1.6),"brass")
	for z in [-20.7,20.7]:
		s.ring(Vector3(0,17.25,z),4.5,.34,"chalk",Vector3(PI/2,0,0))
		for k in 8:
			var t:=TAU*k/8.
			s.ring(Vector3(cos(t)*2.6,17.25+sin(t)*2.6,z),1.25,.12,"stone",Vector3(PI/2,0,0))

static func _library(s:Node3D) -> void:
	_flood(s,-.84)
	var papers:=["wood","basalt","rust","moss","bone"]
	for p:Vector3 in _voids(2):
		var offset:=roundi(p.x+p.z)
		s.box(p+Vector3.UP*3.25,Vector3(4.22,9.7,1.8),"basalt")
		for x in [-2.18,2.18]:
			s.box(p+Vector3(x,3.28,0),Vector3(.24,9.9,2.32),"wood")
		for tier in 6:
			var y:float=-1.06+tier*1.59
			s.box(p+Vector3.UP*y,Vector3(4.61,.21,2.35),"wood")
			for side in [-1.,1.]:
				for i in 6:
					var height:=.72+posmod(i*13+tier*9+offset,7)*.09
					var spine:=p+Vector3((i-2.5)*.65,y+.14+height*.5,side*.99)
					s.box(spine,Vector3(.47,height,.36),papers[posmod(offset+i*7+tier,5)],Vector3(0,0,(i%3-1)*.055))
					if i%3==1:
						s.box(spine+Vector3(0,height*.21,side*.19),Vector3(.29,.044,.026),"brass")
		if posmod(offset,3)==0:
			for x in [1.15,1.94]:
				s.beam(p+Vector3(x,-.75,2.18),p+Vector3(x,6.99,1.24),.075,.10,"brass")
			for j in 12:
				s.box(p+Vector3(1.54,-.38+j*.61,2.14-j*.076),Vector3(.79,.06,.10),"wood")
	for z in [-17.,17.]:
		s.box(Vector3(0,10.22,z),Vector3(51,.66,2.72),"wood")
		for x in range(-24,25,4):
			s.box(Vector3(x,11.,z),Vector3(.13,1.34,.13),"brass")
		s.box(Vector3(0,11.72,z),Vector3(50.2,.13,.14),"brass")

	for side in [-1.,1.]:
		for end in [-1.,1.]:
			var outer:=Vector3(side*26.35,6.10,end*12.8)
			s.box(outer,Vector3(2.08,15.7,15.61),"stone")
			s.box(outer+Vector3.UP*8.04,Vector3(2.61,.5,16.14),"wood")
			for k in 4:
				var panel:=outer+Vector3(-side*1.11,2.97,(k-1.5)*3.41)
				s.box(panel,Vector3(.22,7.38,2.65),"basalt")
				s.box(panel+Vector3(-side*.18,0,0),Vector3(.13,7.38,.20),"brass")

static func _theatre(s:Node3D) -> void:
	s.box(Vector3(0,-.48,.35),Vector3(32,.9,5.65),"wood")
	for side in [-1.,1.]:
		var x:float=side*16.3
		s.box(Vector3(x,6.0,0),Vector3(2.72,14.,2.50),"basalt")
		for dx in [-.98,.98]:
			s.column(Vector3(x+dx,6.0,1.28),Vector3(.56,13.5,.56),"brass")
		for pleat in 14:
			var px:float=side*(5.04+pleat*.775)
			var drop:=8.55+pleat*.24
			s.column(Vector3(px,13.8-drop*.5,.55+cos(pleat*PI)*.28),Vector3(1.06,drop,.73),"cloth")
			s.ball(Vector3(px,13.8-drop,.57),Vector3(1.04,.52,.74),"cloth")
		s.box(Vector3(side*23.45,9.0,-4.),Vector3(3.65,.51,13),"wood")
	for z in [-5.7,-3.3,-.8,2.]:
		s.beam(Vector3(-17,14.4,z),Vector3(17,14.4,z),.20,.20,"iron")
		for x in [-14.,-9.,9.,14.]:
			s.box(Vector3(x,17.72,z),Vector3(.052,6.55,.052),"iron")
	s.box(Vector3(0,14.46,1.0),Vector3(36,1.3,3.2),"wood")
	for i in range(11):
		s.ball(Vector3((i-5)*3.14,13.59,1.57),Vector3(4.0,2.32,1.4),"cloth")
	for side in [-1.,1.]:
		for z in [-14.,13.]:
			s.box(Vector3(side*25,6.15,z),Vector3(4.63,1.32,6.24),"wood")
			s.box(Vector3(side*23.15,7.04,z),Vector3(.33,1.48,6.43),"cloth")

	s.box(Vector3(0,18.4,-3.8),Vector3(38.9,.82,13.1),"wood")
	s.box(Vector3(0,10.85,-6.99),Vector3(33.5,10.10,.40),"basalt")
	for i in range(7):
		s.box(Vector3((i-3)*4.34,9.82,-6.69),Vector3(4.02,7.4,.22),"cloth")
	for side in [-1.,1.]:
		var prior:=Vector3(side*5.2,12.9,1.43)
		for j in range(1,11):
			var t:=j/10.
			var next:=Vector3(side*(5.2+10.*t),12.9-2.15*sin(t*PI)+.13*t,1.43)
			s.beam(prior,next,.11,.13,"brass")
			prior=next
		for end in [-1.,1.]:
			s.box(Vector3(side*27.9,6.1,end*12.8),Vector3(3.2,16.1,14.9),"basalt")
			s.box(Vector3(side*25.81,7.03,end*12.8),Vector3(1.24,1.55,15.2),"wood")

static func _quarantine(s:Node3D) -> void:
	for side in [-1.,1.]:
		for end in [-1.,1.]:
			var p:=Vector3(side*25.4,4.22,end*12.)
			s.box(p,Vector3(5.42,11.9,14.8),"chalk")
			s.box(p+Vector3.UP*6.21,Vector3(6.02,.57,15.6),"basalt")
			for level in [0.,3.55,7.1]:
				for room in [-1.,0.,1.]:
					var w:=Vector3(side*22.62,level+1.57,end*12.+room*4.3)
					s.box(w,Vector3(.15,2.42,1.70),"basalt")
					for bar in [-.49,.0,.49]:
						s.box(w+Vector3(-side*.13,0,bar),Vector3(.10,2.42,.057),"iron")
				s.box(Vector3(side*21.91,level+.10,end*12.),Vector3(1.68,.33,14.7),"stone")
				s.box(Vector3(side*21.1,level+1.17,end*12.),Vector3(.11,.11,14.7),"iron")
	for row in 4:
		var z:float=-7.8+row*4.77
		var left:=Vector3(-23.,10.4,z)
		var sag:=Vector3(0,7.8+row*.21,z+.5)
		var right:=Vector3(23.,10.4,z)
		s.beam(left,sag,.05,.05,"iron")
		s.beam(sag,right,.05,.05,"iron")
		for i in range(7):
			var x:float=(i-3)*4.67+(row%2)*.77
			var y:=lerpf(sag.y,10.4,absf(x)/23.)
			var h:=1.20+posmod(i*3+row*7,6)*.19
			s.box(Vector3(x,y-h*.50,z+.46),Vector3(1.81,h,.084),"cloth" if (i+row)%4==0 else "bone",Vector3(.03*i,.015*i,(i%3-1)*.035))
	for z in [-18.6,18.6]:
		for side in [-1.,1.]:
			s.box(Vector3(side*9.05,2.42,z),Vector3(6.1,6.83,4.2),"stone")
			s.box(Vector3(side*8.15,3.75,z-signf(z)*2.15),Vector3(2.61,1.14,.19),"basalt")

	s.box(Vector3(0,-1.22,0),Vector3(55.2,.77,37.45),"stone")
	for x in [-9.25,9.25]:
		s.box(Vector3(x,-.823,0),Vector3(1.15,.045,32.5),"basalt")
		for z in range(-16,17,2):
			s.box(Vector3(x,-.790,z),Vector3(1.11,.035,.14),"iron")

static func _rigging_loft(s:Node3D) -> void:
	_flood(s,-2.32)
	for p:Vector3 in _voids(5):
		var width:=2.81
		var axle:=p+Vector3.UP*2.92
		var face:=Vector3(0,0,PI/2)
		s.column(axle,Vector3(3.42,width,3.42),"wood",face)
		for i in range(8):
			s.ring(axle+Vector3.RIGHT*(i-3.5)*.335,1.76,.149,"bone",face)
		for end in [-1.,1.]:
			s.column(axle+Vector3.RIGHT*end*1.67,Vector3(4.59,.27,4.59),"wood",face)
			s.column(axle+Vector3.RIGHT*end*1.86,Vector3(1.22,.28,1.22),"brass",face)
			s.box(p+Vector3(end*2.14,.53,0),Vector3(.32,4.70,1.52),"wood")
		for z in [-1.04,1.04]:
			s.box(p+Vector3(0,-1.35,z),Vector3(5.01,.41,.37),"rust")
	for z in [-13.,0.,13.]:
		s.box(Vector3(0,11.5,z),Vector3(55.,.74,.60),"wood")
		for x in [-20.,-7.,8.,20.]:
			s.ring(Vector3(x,10.75,z),.86,.14,"brass",Vector3(PI/2,0,0))
			s.box(Vector3(x+.68,8.77,z),Vector3(.068,3.84,.068),"bone")
			s.box(Vector3(x-.68,8.48,z),Vector3(.068,4.34,.068),"bone")
			s.column(Vector3(x,6.45,z),Vector3(1.33,.42,1.33),"wood",Vector3(PI/2,0,0))
	for x in [-27.,27.]:
		for z in [-13.,13.]:
			s.box(Vector3(x,5.05,z),Vector3(.65,14.1,.67),"wood")
			s.beam(Vector3(x,8.61,z),Vector3(x-signf(x)*3.4,11.35,z),.28,.31,"wood")

static func _amphitheatre(s:Node3D) -> void:
	# Interrupted seating blocks preserve passages across the rake. Each bank
	# looks toward the same sunken orchestra, including the wedge-shaped boxes.
	s.column(Vector3(0,-3.1,0),Vector3(23,.75,12.),"basalt")
	for k in 3:
		s.ring(Vector3(0,-2.69,0),2.0+k*1.15,.075,"brass")
	for p:Vector3 in _voids(6):
		if absf(p.x)<.4 and absf(p.z)<.4: continue
		var facing:=atan2(p.x,p.z)
		for tier in 4:
			var r:float=(tier-1.5)*.54
			var v:=Vector3(sin(facing)*r,0,cos(facing)*r)
			var h:=.15+tier*.48+absf(p.z)*.055
			s.box(p+v+Vector3.UP*(h*.5-1.),Vector3(3.88,h+2.0,.66),"stone",Vector3(0,facing,0))
			s.box(p+v+Vector3.UP*h,Vector3(4.04,.19,.68),"chalk",Vector3(0,facing,0))
	for side in [-1.,1.]:
		for row in range(4):
			var radius:=26.65+row*1.02
			for j in range(9):
				var a:float=lerpf(-1.07,1.07,float(j)/8.)
				var p:=Vector3(side*cos(a)*radius,2.60+row*1.19,sin(a)*(18.30+row*1.12))
				# Leave the east and west entrance aisles open through the banking.
				if absf(p.z)<5.55: continue
				s.box(p,Vector3(2.11,1.45,3.75),"stone",Vector3(0,-side*a,0))
				s.box(p+Vector3.UP*.83,Vector3(2.19,.23,3.87),"chalk",Vector3(0,-side*a,0))
		for z in [-16.,16.]:
			s.column(Vector3(side*17.6,6.8,z),Vector3(1.18,14.5,1.18),"stone")
			s.column(Vector3(side*17.6,14.1,z),Vector3(2.12,.60,2.12),"chalk")
	for z in [-17.7,17.7]:
		s.box(Vector3(0,14.12,z),Vector3(35.8,.78,2.05),"chalk")
		for x in [-12.,-6.,0.,6.,12.]:
			s.ball(Vector3(x,14.98,z),Vector3(.71,1.02,.71),"bone")

	# A two-storey scaena frons closes the north end of the auditorium.
	for x in [-21.,-7.,7.,21.]:
		var p:=Vector3(x,4.07,-18.78)
		s.box(p,Vector3(3.15,16.65,2.86),"stone")
		for dx in [-1.03,1.03]:
			s.column(p+Vector3(dx,.55,1.51),Vector3(.67,15.0,.67),"chalk")
		s.box(p+Vector3.UP*8.54,Vector3(3.72,.66,3.14),"chalk")
	for x in [-14.,0.,14.]:
		_arch(s,Vector3(x,8.05,-18.78),Vector3.RIGHT,5.67,4.53,.92,.73,"chalk")
		s.box(Vector3(x,13.48,-18.78),Vector3(14.10,.65,3.),"stone")
		for dx in [-4.15,0.,4.15]:
			s.column(Vector3(x+dx,15.45,-18.78),Vector3(.71,4.11,.71),"chalk")
		s.box(Vector3(x,17.69,-18.78),Vector3(14.1,.44,2.11),"chalk")

static func _sluice(s:Node3D) -> void:
	_flood(s,-.63)
	for p:Vector3 in _voids(7):
		s.box(p+Vector3.UP*.65,Vector3(3.24,6.55,4.32),"moss")
		s.box(p+Vector3.UP*4.05,Vector3(3.75,.46,4.68),"salt")
		for j in 8:
			s.box(p+Vector3(-1.66,.14+j*.39,-.63),Vector3(.12,.085,.77 if j%2 else 1.30),"bone")
	for z in [-8.95,8.95]:
		for side in [-1.,1.]:
			var x:float=side*16.65
			s.box(Vector3(x,8.52,z),Vector3(1.0,20.0,1.26),"stone")
			s.box(Vector3(x,17.54,z),Vector3(2.57,1.41,2.82),"rust")
			s.column(Vector3(x,18.73,z),Vector3(2.56,1.15,2.56),"iron",Vector3(PI/2,0,0))
			s.box(Vector3(x-side*.81,14.09,z),Vector3(.12,8.14,.12),"brass")
		s.box(Vector3(0,18.47,z),Vector3(35.,.65,.88),"iron")
		s.box(Vector3(0,10.45,z),Vector3(31.9,4.3,.36),"rust")
		for x in range(-15,16,3):
			s.box(Vector3(x,10.45,z+.30),Vector3(.21,4.55,.38),"iron")
		for y in [8.45,10.45,12.45]:
			s.box(Vector3(0,y,z+.44),Vector3(32.2,.18,.28),"iron")
	for x in [-27.1,27.1]:
		for z in [-12.,12.]:
			s.box(Vector3(x,1.10,z),Vector3(4.34,8.1,13.5),"moss")
			s.box(Vector3(x,5.25,z),Vector3(4.81,.44,14.0),"salt")

static func _scriptorium(s:Node3D) -> void:
	var n:=0
	for p:Vector3 in _voids(8):
		var yaw:=PI if n%2 else 0.0
		s.box(p+Vector3.UP*1.73,Vector3(3.91,.25,2.45),"wood",Vector3(-.13,0,0))
		s.box(p+Vector3.UP*1.89,Vector3(2.2,.09,1.33),"bone",Vector3(-.13,0,0))
		for x in [-1.43,1.43]:
			s.box(p+Vector3(x,-.23,0),Vector3(.23,3.77,1.71),"wood")
		s.box(p+Vector3(-.53,2.05,.10),Vector3(.058,.08,.72),"basalt",Vector3(-.13,yaw,.11))
		s.column(p+Vector3(1.29,2.0,-.32),Vector3(.36,.39,.36),"basalt")
		s.box(p+Vector3(0,.83,1.74),Vector3(2.43,.19,.75),"wood")
		if n%2==0:
			for j in 7:
				s.box(p+Vector3(-.94,2.02+j*.082,-.36),Vector3(1.01,.075,.72),"bone",Vector3(-.13,j*.025,0))
		n+=1
	for x in [-21.,-7.,7.,21.]:
		var a:=Vector3(x-6.45,10.22,0)
		var b:=Vector3(x+5.72,15.27,0)
		var center:=(a+b)*.5
		s.box(center,Vector3(a.distance_to(b),.29,39.),"wood",Vector3(0,0,.394))
		s.box(Vector3(x+5.92,12.71,0),Vector3(.21,4.92,39.),"glass")
		for z in range(-18,19,6):
			s.box(Vector3(x+5.60,12.71,z),Vector3(.42,5.03,.20),"wood")
			s.beam(Vector3(x-6.45,10.03,z),Vector3(x+5.72,15.07,z),.30,.36,"wood")

	for side in [-1.,1.]:
		for end in [-1.,1.]:
			s.box(Vector3(side*27.26,4.13,end*12.1),Vector3(.91,11.9,14.2),"wood")
			for k in 3:
				var z:float=end*12.1+(k-1)*4.5
				s.box(Vector3(side*26.73,5.51,z),Vector3(.23,6.52,3.11),"glass")
				s.box(Vector3(side*26.57,5.52,z),Vector3(.09,6.56,.17),"wood")

static func _weaving(s:Node3D) -> void:
	for p:Vector3 in _voids(9):
		# A double heddle separates the vertical warp; a width of finished cloth
		# runs over the breast beam and winds around the lower roller.
		for x in [-2.08,2.08]:
			s.box(p+Vector3(x,2.81,0),Vector3(.24,8.5,.37),"wood")
			s.beam(p+Vector3(x,-1.22,1.46),p+Vector3(x,3.11,.02),.19,.26,"wood")
		s.column(p+Vector3(0,6.73,0),Vector3(.62,4.58,.62),"wood",Vector3(0,0,PI/2))
		s.column(p+Vector3(0,.67,1.04),Vector3(.76,4.42,.76),"cloth",Vector3(0,0,PI/2))
		for i in range(17):
			var x:float=(i-8)*.229
			s.beam(p+Vector3(x,6.58,0),p+Vector3(x,2.94,.54+(i%2)*.16),.033,.046,"bone")
		s.box(p+Vector3(0,1.85,.86),Vector3(3.93,2.12,.097),"cloth",Vector3(-.19,0,0))
		for y in [2.91,3.67,4.25]:
			s.box(p+Vector3(0,y,.45),Vector3(4.32,.13,.21),"wood")
	for z in [-12.,0.,12.]:
		s.box(Vector3(0,10.04,z),Vector3(54,.62,.55),"wood")
		for x in range(-24,25,4):
			s.ring(Vector3(x,9.48,z),.44,.08,"brass",Vector3(PI/2,0,.28))
	for side in [-1.,1.]:
		for i in 5:
			var z:float=-14.+i*7.
			if absf(z)<3.0: continue
			var x:float=side*25.5
			s.column(Vector3(x,6.5,z),Vector3(1.0,12.7,1.0),"wood")
			s.box(Vector3(x,7.55,z),Vector3(.16,9.,4.42),"cloth")

static func _sorting(s:Node3D) -> void:
	for p:Vector3 in _voids(10):
		s.box(p+Vector3.UP*2.24,Vector3(4.41,7.21,2.8),"iron")
		for tier in 5:
			for j in 3:
				var v:=p+Vector3((j-1)*1.38,-.47+tier*1.32,1.44)
				s.box(v,Vector3(1.18,1.05,.11),"wood")
				s.box(v+Vector3(0,.32,.071),Vector3(.48,.15,.049),"bone")
				s.box(v+Vector3(0,-.19,.091),Vector3(.40,.08,.11),"brass")
		s.box(p+Vector3.UP*5.98,Vector3(4.61,.28,3.11),"iron")
	# The brass tube network hangs well above the highest sorting bridge.
	for lane in 4:
		var z:float=-13.4+lane*3.17
		var y:float=11.38+lane*.51
		s.column(Vector3(-3,y,z),Vector3(.62,43.4,.62),"brass",Vector3(0,0,PI/2))
		for j in range(9):
			s.column(Vector3(-23+j*5.0,y,z),Vector3(.82,.19,.82),"iron",Vector3(0,0,PI/2))
		var x:float=18.69
		_arch(s,Vector3(x,y-.97,z),Vector3.RIGHT,1.05,1.0,.63,.63,"brass")
		s.column(Vector3(x+1.02,y-2.56,z),Vector3(.61,3.2,.61),"brass")
	for side in [-1.,1.]:
		var p:=Vector3(side*26.2,3.52,side*13.2)
		s.box(p,Vector3(5.10,9.44,5.17),"wood")
		for i in 3:
			var v:=p+Vector3((i-1)*1.45,.76,-side*2.62)
			s.ring(v,.54,.13,"brass",Vector3(PI/2,0,0))
			s.column(v+Vector3(0,0,-side*.10),Vector3(.79,.14,.79),"basalt",Vector3(PI/2,0,0))

static func _casting(s:Node3D) -> void:
	var index:=0
	for p:Vector3 in _voids(11):
		s.box(p-Vector3.UP*.35,Vector3(4.38,2.77,4.29),"basalt")
		var axis:=Vector3(0,0,PI/2) if index%2 else Vector3(PI/2,0,0)
		s.ring(p+Vector3.UP*2.19,1.53,.67,"rust",axis)
		s.ring(p+Vector3.UP*2.19,1.07,.18,"basalt",axis)
		for x in [-1.78,1.78]:
			s.box(p+Vector3(x,1.01,0),Vector3(.40,3.64,1.34),"iron")
		index+=1
	for z in [-15.,0.,15.]:
		for flank in [-1.,1.]:
			if is_zero_approx(z): continue
			var at:=Vector3(flank*24.3,4.31,z)
			s.column(at,Vector3(5.8,12.7,5.8),"basalt")
			for h in [-.62,2.14,5.2]:
				s.ring(at+Vector3.UP*h,2.98,.11,"iron")
			s.cone(at+Vector3.UP*7.42,Vector3(4.48,2.49,4.48),"rust")
			s.column(at+Vector3.UP*9.36,Vector3(1.00,4.66,1.00),"iron")
	for x in [-18.1,18.1]:
		s.box(Vector3(x,14.74,0),Vector3(.49,.96,40.6),"iron")
	for z in [-10.5,7.7]:
		s.box(Vector3(0,14.24,z),Vector3(37.,.85,1.04),"rust")
		for i in range(9):
			s.beam(Vector3(-18+i*4.,14.7,z),Vector3(-14+i*4.,15.8,z),.15,.16,"iron")
		s.box(Vector3(0,15.86,z),Vector3(37,.24,.48),"iron")
		for dx in [-.85,.85]:
			s.box(Vector3(dx,11.44,z),Vector3(.083,4.8,.083),"iron")
		s.ring(Vector3(0,8.98,z),.91,.21,"iron",Vector3(PI/2,0,0))
	for x in [-25.,25.]:
		s.box(Vector3(x,-1.85,-6.),Vector3(5.21,.22,2.77),"ember")

	for x in [-18.1,18.1]:
		for z in [-16.3,16.3]:
			s.box(Vector3(x,6.45,z),Vector3(.87,16.35,.91),"iron")
			s.beam(Vector3(x,11.51,z),Vector3(x,14.54,z-signf(z)*3.2),.29,.31,"rust")

static func _clock_house(s:Node3D) -> void:
	for side in [-1.,1.]:
		for end in [-1.,1.]:
			var origin:=Vector3(side*25.75,5.72,end*13.55)
			s.box(origin,Vector3(5.54,15.81,6.65),"stone")
			s.box(origin+Vector3.UP*8.23,Vector3(5.95,.65,7.09),"chalk")
			s.cone(origin+Vector3.UP*10.91,Vector3(6.76,5.35,7.77),"basalt")
			var face:=origin+Vector3(-side*2.81,3.23,0)
			s.column(face,Vector3(5.24,.29,5.24),"basalt",Vector3(0,0,PI/2))
			s.ring(face+Vector3.LEFT*side*.27,2.49,.14,"brass",Vector3(0,0,PI/2))
			for i in range(12):
				var t:=i*TAU/12.
				s.box(face+Vector3(-side*.33,cos(t)*2.09,sin(t)*2.09),Vector3(.11,.38,.14),"bone",Vector3(t,0,0))
			var hub:=face+Vector3(-side*.42,0,0)
			var t:float=side*end*.78
			s.beam(hub,hub+Vector3(0,cos(t)*1.87,sin(t)*1.87),.11,.14,"brass")
			s.beam(hub,hub+Vector3(0,cos(t+1.74)*1.39,sin(t+1.74)*1.39),.14,.15,"brass")
	for p:Vector3 in _voids(12):
		var y:=2.42+fposmod(p.x+p.z,4.0)*.4
		s.box(p+Vector3.UP*11.9,Vector3(2.8,.31,2.04),"wood")
		for x in [-.60,.60]:
			s.box(p+Vector3(x,(11.68+y)*.5,0),Vector3(.067,11.68-y,.067),"iron")
		s.column(p+Vector3.UP*(y-.88),Vector3(1.87,2.14,1.87),"basalt")
		s.cone(p+Vector3.UP*(y-2.23),Vector3(1.87,.68,1.87),"iron",Vector3(PI,0,0))
	for z in [-13.,0.,13.]:
		s.box(Vector3(0,13.88,z),Vector3(52,.88,.83),"wood")
		for x in [-17.,0.,17.]:
			s.ring(Vector3(x,12.93,z),1.16,.16,"iron",Vector3(PI/2,0,0))

static func _terminus(s:Node3D) -> void:
	# The running rails and wheelsets are above the carriages; the concourse
	# threads below their roofs on separate raised platforms.
	for x in [-11.,11.]:
		for offset in [-1.36,1.36]:
			s.box(Vector3(x+offset,15.65,0),Vector3(.17,.30,45.72),"iron")
		for z in range(-21,22,3):
			s.box(Vector3(x,15.98,z),Vector3(4.18,.23,.39),"wood")
		for end in [-1.,1.]:
			var p:=Vector3(x,11.66,end*9.43)
			s.box(p,Vector3(4.12,4.75,14.44),"moss" if end<0 else "basalt")
			s.box(p-Vector3.UP*2.59,Vector3(4.38,.72,14.74),"iron")
			for i in range(6):
				for side in [-1.,1.]:
					var win:=p+Vector3(side*2.10,-.46,(i-2.5)*2.08)
					s.box(win,Vector3(.085,1.33,1.47),"glass" if i%3==1 else "bone")
					s.box(win+Vector3(-side*.02,.0,0),Vector3(.15,.077,1.48),"iron")
			for dz in [-4.93,4.93]:
				for side in [-1.,1.]:
					s.column(p+Vector3(side*1.34,2.94,dz),Vector3(1.49,.36,1.49),"iron",Vector3(0,0,PI/2))
	for z in [-18.,-6.,6.,18.]:
		for x in [-24.8,24.8]:
			s.column(Vector3(x,6.88,z),Vector3(.81,18.4,.81),"iron")
			s.column(Vector3(x,15.98,z),Vector3(1.74,.51,1.74),"brass")
		_arch(s,Vector3(0,16.23,z),Vector3.RIGHT,24.8,6.8,.53,.54,"iron")
		s.box(Vector3(0,16.3,z),Vector3(50.,.26,.30),"iron")
	for x in [-25.3,25.3]:
		for z in [-12.,12.]:
			s.box(Vector3(x,1.25,z),Vector3(1.07,.22,6.64),"wood")
			s.box(Vector3(x+signf(x)*.48,1.66,z),Vector3(.13,.84,6.6),"wood")
