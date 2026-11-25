extends RefCounted

const PAPER_RAY := preload("res://tableaux/wild_assets/paper_ray.glb")
const FACE := Vector3(PI*.5,0,0)
static var growth: CurveTexture


static func build(life:Node3D,id:int) -> void:
	match id:
		18: _tuning_forks(life)
		19,31: _swarm(life,id)
		20,24: _eclipse(life,id)
		21,30: _shoal(life,id)
		22,26: _plankton(life,id)
		23,25,27,29: _plumes(life,id)
		28: _satellites(life)


static func _tuning_forks(life:Node3D) -> void:
	var socket:Node3D=life.pieces(Vector3.ZERO)
	for i in 5:
		var x:float=(i-2)*1.46
		var h:float=6.0+.36*sin(i*1.3)
		socket.column(Vector3(x,(9.89-life.position.y+h)*.5,0),Vector3(.13,9.89-life.position.y-h,.13),"wood")
		socket.box(Vector3(x,h,0),Vector3(.82,.18,.28),"brass")
		for side:float in [-1.,1.]:
			var prong:Node3D=life.pieces(Vector3(x+side*.32,h-.05,0))
			prong.box(Vector3(0,-1.24,0),Vector3(.16,2.52,.21),"brass")
			prong.box(Vector3(0,-2.29,0),Vector3(.20,.29,.23),"pearl")
			life.oscillate(prong,1.30+i*.07,i*.55,Vector3.ZERO,Vector3(0,0,side*.12))
	life.sound(&"fork",3.9)


static func _swarm(life:Node3D,id:int) -> void:
	var hive := id==31
	for i in (9 if hive else 5):
		var pivot:Node3D=life.pieces(Vector3((i%5-2)*1.24,4.07+sin(i*2.6)*.64,.66*cos(i)),life.wing if i>3 else life)
		pivot.rotation.y=sin(i)*.78
		pivot.scale=Vector3.ONE*(.68 if hive else 1.0)
		pivot.ball(Vector3.ZERO,Vector3(.9,.42,.47),"brass" if hive else "moss")
		pivot.ball(Vector3(-.41,.10,0),Vector3(.43,.39,.39),"basalt")
		for flank:float in [-1.,1.]:
			var wing:Node3D=life.pieces(Vector3(0,.1,.15*flank),pivot)
			wing.ball(Vector3(.09,.08,.33*flank),Vector3(.55,.075,.82),"pearl" if hive else "bone")
			life.oscillate(wing,.27+i*.011,i*.9,Vector3.ZERO,Vector3(flank*.63,0,0))
		life.swim(pivot,4.7+i*.63,i*.96,Vector3(2.14,.44,0),Vector3(0,.21,1.03))


static func _eclipse(life:Node3D,id:int) -> void:
	var stars:Node3D=life.pieces(Vector3(0,4.85,-.65))
	if id==24:
		stars.ball(Vector3.ZERO,Vector3(2.78,2.78,.37),"ember")
		stars.ring(Vector3.ZERO,1.63,.065,"brass",FACE)
		var moon:Node3D=life.pieces(Vector3(0,4.85,-.30))
		moon.ball(Vector3.ZERO,Vector3(2.41,2.41,.43),"basalt")
		life.oscillate(moon,10.1,.3,Vector3(2.50,.35,0))
	else:
		stars.ball(Vector3.ZERO,Vector3.ONE*1.39,"glass")
		for i in 3:
			var band:Node3D=life.pieces(Vector3(0,4.85,-.65))
			var radius:=1.48+i*.36
			band.rotation.z=.28+i*.53
			band.ring(Vector3.ZERO,radius,.050,"brass")
			band.ball(Vector3(radius,0,0),Vector3.ONE*(.33+i*.07),"pearl")
			life.turn(band,6.2+i*2.2,Vector3.UP)


static func _shoal(life:Node3D,id:int) -> void:
	if id==30: life.sound(&"rustle",4.65)
	for i in 7:
		var fish:Node3D=life.pieces(Vector3((i-3)*1.14,4.21 + .60*cos(i*2.),.87*sin(i*1.81)),life.wing if i>3 else life)
		if id==30:
			var paper := PAPER_RAY.instantiate() as Node3D
			paper.scale=Vector3.ONE*(.34+.05*(i%3))
			paper.rotation.y=PI*.5
			fish.add_child(paper)
		else:
			fish.ball(Vector3.ZERO,Vector3(1.12,.44,.35),"pearl")
			fish.ball(Vector3(-.29,.08,.17),Vector3.ONE*.11,"basalt")
			fish.beam(Vector3(.12,.13,0),Vector3(.28,.43,0),.16,.07,"bone")
			fish.scale = Vector3.ONE * (1.12 + .09*(i%3))
			var tail:Node3D=life.pieces(Vector3(.47,0,0),fish)
			for h:float in [-1.,1.]:
				tail.beam(Vector3.ZERO,Vector3(.41,h*.30,0),.20,.068,"bone")
			life.oscillate(tail,.66+i*.034,i*.77,Vector3.ZERO,Vector3(0,.54,0))
		life.swim(fish,6.1+i*.31,i*.40, Vector3(2.05,.49,0),Vector3(0,.19,1.12))


static func _plankton(life:Node3D,id:int) -> void:
	for i in 5:
		var jelly:Node3D=life.pieces(Vector3((i-2)*1.77,4.62+.55*sin(i*1.12),.70*sin(i)),life.wing if i>2 else life)
		if id==26:
			jelly.ball(Vector3.ZERO,Vector3(1.29,.8,1.20),"glass")
			jelly.ring(Vector3(0,-.18,0),.55,.086,"pearl")
			for j in 5:
				var thread:Node3D=life.pieces(Vector3(.37*cos(j*TAU/5.),-.23,.37*sin(j*TAU/5.)),jelly)
				thread.beam(Vector3.ZERO,Vector3(.18,-1.01,0),.058,.053,"pearl")
				life.oscillate(thread,2.25+i*.18,i+j*.2,Vector3.ZERO,Vector3(.17,0,.27))
		else:
			for j in 3:
				jelly.ring(Vector3(.12*j,.07*j,0),.44-j*.10,.07,"bone",FACE)
			jelly.ball(Vector3(.29,-.09,0),Vector3(.49,.32,.37),"glass")
		life.oscillate(jelly,3.5+i*.48,i*1.4,Vector3(.56,.55,0),Vector3(.13,0,.20),Vector3(0,.04,.36))


static func _satellites(life:Node3D) -> void:
	for i in 6:
		var orbit:Node3D=life.pieces(Vector3((i-2.5)*1.48,4.95+.58*sin(i),.6*cos(i*1.7)),life.wing if i>2 else life)
		var relic:Node3D=life.pieces(Vector3.ZERO,orbit)
		relic.ball(Vector3.ZERO,Vector3(.69,.65,.73),"iron")
		for s:float in [-1.,1.]:
			relic.box(Vector3(s*.68,0,0),Vector3(.74,.070,.49),"glass")
			relic.beam(Vector3(s*.28,0,0),Vector3(s*.92,0,0),.073,.073,"brass")
		life.turn(relic,3.8+i*.71,Vector3(.26,.83,.58))
		life.oscillate(orbit,6.8+i*.23,i*.82,Vector3(.48,.73,0),Vector3.ZERO,Vector3(0,0,.58))


static func _plumes(life:Node3D,id:int) -> void:
	var ceiling:Node3D=life.pieces(Vector3.ZERO)
	for i in 3:
		var x:float=(i-1)*2.50
		var vent:Node3D=life.pieces(Vector3(x,5.70+.5*sin(i),0))
		var velocity:float
		var material:String
		var gravity:float
		var direction:=Vector3.DOWN
		if life.floor_mounted:
			# At an unused court the terrain rises from the bottom of the pit;
			# the jets break just above its lip beside the walkway.
			var rim := Vector3(x,1.45+.31*sin(i*1.7),0)
			var deep: float = -9.72 - life.position.y
			var rock := "moss" if id==27 else "chalk" if id==29 else "basalt"
			ceiling.column(Vector3(x,(deep+rim.y)*.5,0),Vector3(1.9,rim.y-deep,1.76),rock)
			for j in 3:
				ceiling.ball(rim + Vector3(.34*cos(j*2.1),j*.21-.35,.34*sin(j*2.1)),
					Vector3(1.69-j*.19,.78,1.5-j*.12),rock)
			vent.position = rim+Vector3.UP*.23
			if id==27:
				vent.ball(Vector3(0,.53,0),Vector3(1.59,.68,1.28),"moss")
				vent.ring(Vector3(0,.45,0),.63,.065,"bone")
			else:
				vent.ring(Vector3.ZERO,.48,.11,"salt" if id==29 else "rust")
				vent.ball(Vector3.ZERO,Vector3(.84,.19,.72),"glass" if id==29 else "ember")
			material="ember" if id==25 else "pearl"
			velocity=6.7 if id==29 else 4. if id==25 else 1.82
			gravity=-3.6 if id!=27 else -.34
			life.oscillate(vent,2.6+i*.31,i*.73,Vector3.UP*.12)
			_jet(vent,material,Vector3.UP,velocity,gravity,1.9,i)
			continue
		match id:
			23:
				var height:float=3.1+.65*i
				ceiling.cone(Vector3(x,9.84-height*.5,0),Vector3(1.12,height,1.05),"salt",Vector3(PI,0,0))
				vent.position.y = 9.82-height
				vent.ball(Vector3.ZERO,Vector3(.24,.40,.24),"glass")
				velocity=.65
				material="glass"
				gravity=-3.3
			25:
				vent.position.y=8.9
				ceiling.ring(Vector3(x,9.55,0),.61,.25,"basalt")
				vent.ball(Vector3.ZERO,Vector3(.89,.40,.80),"ember")
				velocity=1.8
				material="ember"
				gravity=-2.3
			27:
				ceiling.column(Vector3(x,8.16,0),Vector3(.24,3.4,.28),"wood")
				vent.position.y=6.4
				vent.ball(Vector3.ZERO,Vector3(1.65,.83,1.47),"moss")
				vent.ring(Vector3(0,-.13,0),.70,.07,"bone")
				velocity=1.22
				material="pearl"
				gravity=-.33
			_:
				# A leaky pressure main under the ceiling jets across the upper air.
				ceiling.column(Vector3(x,8.48,0),Vector3(.41,2.85,.41),"iron")
				vent.position.y=7.10
				vent.ring(Vector3.ZERO,.26,.08,"brass")
				velocity=4.3
				material="pearl"
				gravity=-1.75
				direction=Vector3(.77,-.5,.04).normalized()
		var offset := Vector3(0,.22,0) if id in [25,27] else Vector3.ZERO
		life.oscillate(vent,2.2+i*.32,i*.93,offset,Vector3(0,0,.08))
		_jet(vent,material,direction,velocity,gravity,1.4 if id==29 else 2.15,i)
	if id==23: life.sound(&"drip",3.1)
	if id==29: life.sound(&"vent",4.6)


static func _jet(root:Node3D,material:String,dir:Vector3,speed:float,gravity:float,duration:float,index:int) -> void:
	var stage := preload("res://tableaux/stage.gd")
	if not growth:
		var curve := Curve.new()
		curve.add_point(Vector2(0,.26))
		curve.add_point(Vector2(.18,1.0))
		curve.add_point(Vector2(.85,.48))
		curve.add_point(Vector2(1.,0.))
		growth=CurveTexture.new()
		growth.curve=curve
	var process:=ParticleProcessMaterial.new()
	process.direction=dir
	process.spread=17. if material!="ember" else 32.
	process.gravity=Vector3.UP*gravity
	process.initial_velocity_min=speed*.63
	process.initial_velocity_max=speed
	process.scale_min=.13
	process.scale_max=.26
	process.scale_curve=growth
	var jet:=GPUParticles3D.new()
	jet.amount=21
	jet.lifetime=duration
	jet.preprocess=duration
	jet.explosiveness=.64 if material=="pearl" else .43
	jet.local_coords=true
	jet.use_fixed_seed=true
	jet.seed=17268+index*189
	jet.process_material=process
	jet.draw_pass_1=stage.meshes["ball"]
	jet.material_override=stage.materials[material]
	jet.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	jet.visibility_aabb=AABB(Vector3(-9,-10,-5),Vector3(18,13,10))
	root.add_child(jet)
