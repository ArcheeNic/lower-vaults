extends RefCounted

const FACE := Vector3(PI*.5,0,0)


static func build(life: Node3D, id: int) -> void:
	match id:
		0,4,5: _hanging(life,id)
		1,8,9: _wheel(life,id)
		2: _orrery(life)
		3,11,15: _press(life,id)
		6,12: _writing(life,id)
		7,10,13: _stagework(life,id)
		14,17: _rail(life,id)
		16,32: _measure(life,id)


static func _hanger(life: Node3D, width: float, y: float) -> Node3D:
	var rig: Node3D = life.pieces(Vector3.ZERO)
	for x: float in [-width*.46,width*.46]:
		if life.floor_mounted:
			var base: float = -9.72-life.position.y
			rig.column(Vector3(x,(y+base)*.5,-.84),Vector3(.24,y-base,.24),"iron")
			rig.box(Vector3(x,y,-.42),Vector3(.32,.24,1.13),"brass")
			rig.box(Vector3(x,base+.22,-.84),Vector3(.96,.44,1.04),"basalt")
		else:
			rig.column(Vector3(x, (.5*y+4.95),0), Vector3(.10,9.90-y,.10),"iron")
			rig.box(Vector3(x,9.73,0),Vector3(.52,.20,.48),"brass")
	rig.box(Vector3(0,y,0),Vector3(width,.21,.32),"wood")
	return rig


static func _hanging(life: Node3D, id: int) -> void:
	_hanger(life,6.9,6.3)
	for i in 3:
		var p:Node3D = life.pieces(Vector3((i-1)*2.4,6.26,0))
		var chain := 1.25 + .35*(i%2)
		p.column(Vector3(0,-chain*.5,0),Vector3(.062,chain,.062),"brass")
		if id == 5:
			p.cone(Vector3(0,-chain-.56,0),Vector3(1.46,1.35,1.46),"brass")
			p.ring(Vector3(0,-chain-1.13,0),.72,.07,"iron")
			p.ball(Vector3(0,-chain-1.25,0),Vector3.ONE*.32,"ember")
		elif id == 4:
			p.ball(Vector3(0,-chain-.42,0),Vector3(1.15,.80,1.15),"brass")
			p.ring(Vector3(0,-chain-.34,0),.58,.05,"ember")
			for j in 4:
				var end := Vector3(.47*cos(j*PI*.5),-chain-.25,.47*sin(j*PI*.5))
				p.beam(Vector3(0,-chain+.28,0),end,.045,.045,"iron")
		else:
			p.column(Vector3(0,-chain-.49,0),Vector3(.63,.87,.63),"ember")
			for h in [0.,-.95]:
				p.column(Vector3(0,-chain+h,0),Vector3(.92,.13,.92),"iron")
			for j in 4:
				var offset := Vector3(.38*cos(j*PI*.5),-chain,.38*sin(j*PI*.5))
				p.beam(offset,offset-Vector3.UP*.94,.055,.055,"iron")
		life.oscillate(p,4.3+i*.32,i*1.3,Vector3.ZERO,Vector3(.07,0,.30 if id==5 else .19))
	if id==5: life.sound(&"bell",4.3)


static func _wheel(life: Node3D, id: int) -> void:
	var rail := _hanger(life,4.9,7.25)
	rail.beam(Vector3(0,7.25,-.51),Vector3(0,4.8,-.51),.30,.31,"iron")
	var rotor:Node3D = life.pieces(Vector3(0,4.8,0))
	rotor.column(Vector3.ZERO,Vector3(.57,1.2,.57),"brass",FACE)
	rotor.ring(Vector3.ZERO,1.86,.085,"brass" if id != 1 else "rust",FACE)
	for i in 8:
		var dir := Vector3(cos(i*TAU/8.),sin(i*TAU/8.),0)
		rotor.beam(dir*.25,dir*1.86,.13,.12,"wood" if id==1 else "iron")
		var at := dir*1.52
		if id==1:
			rotor.box(at,Vector3(.9,.22,.80),"wood",Vector3(0,0,dir.signed_angle_to(Vector3.RIGHT,Vector3.BACK)*-1.+PI*.5))
		elif id==8:
			rotor.box(at*.83,Vector3(1.27,.44,.12),"salt",Vector3(.35,0,i*TAU/8.+.3))
		else:
			rotor.ring(at,.26,.06,"wood",FACE)
	life.turn(rotor,6.7 if id==8 else 10.,Vector3.BACK)
	if id==9:
		var weight:Node3D=life.pieces(Vector3(1.86,3.6,0))
		weight.column(Vector3(0,1.,0),Vector3(.075,2.1,.075),"wood")
		weight.ball(Vector3.ZERO,Vector3(.75,.63,.75),"iron")
		life.oscillate(weight,5.8,0.,Vector3.UP*.68)


static func _orrery(life: Node3D) -> void:
	_hanger(life,5.5,7.8)
	var fixed:Node3D=life.pieces(Vector3.ZERO)
	fixed.column(Vector3(0,6.4,0),Vector3(.12,2.7,.12),"brass")
	fixed.ball(Vector3(0,5.3,0),Vector3.ONE*1.25,"ember")
	for i in 3:
		var orbit:Node3D=life.pieces(Vector3(0,5.3,0))
		orbit.rotation.z = (i-1)*.48
		var radius := 1.25 + i*.52
		orbit.ring(Vector3.ZERO,radius,.055,"brass")
		var satellite:Node3D=life.pieces(Vector3.ZERO,orbit)
		satellite.ball(Vector3(radius,0,0),Vector3.ONE*(.38+i*.11),"pearl" if i!=1 else "rust")
		life.turn(satellite,4.+i*2.3,Vector3.UP)


static func _press(life: Node3D, id: int) -> void:
	var rack := _hanger(life,5.6,7.25)
	for x: float in [-1.85,1.85]:
		rack.column(Vector3(x,5.46,0),Vector3(.22,3.52,.22),"iron")
	rack.box(Vector3(0,3.66,0),Vector3(4.24,.28,1.18),"basalt")
	if id==15:
		var pot:Node3D=life.pieces(Vector3(0,5.43,0))
		pot.ball(Vector3.ZERO,Vector3(2.06,1.42,1.54),"rust")
		pot.ring(Vector3(0,.39,0),.77,.12,"ember")
		pot.cone(Vector3(1.08,.13,0),Vector3(.56,.9,.56),"ember",Vector3(0,0,-.95))
		life.oscillate(pot,5.,0.,Vector3.ZERO,Vector3(0,0,.57))
	else:
		for i in (2 if id==3 else 1):
			var piston:Node3D=life.pieces(Vector3((i-.5)*1.7 if id==3 else 0.,5.7,0))
			piston.column(Vector3(0,.48,0),Vector3(.26,2.4,.26),"brass")
			if id==3:
				piston.box(Vector3(0,-.72,0),Vector3(1.26,.63,.84),"iron")
			else:
				for j in 4:
					piston.box(Vector3(0,-.44+j*.26,0),Vector3(3.45,.19,.36),"rust")
			life.oscillate(piston,2.1 if id==3 else 5.3,i*PI,Vector3.UP*.74)
	if id==3: life.sound(&"press",1.05)


static func _writing(life: Node3D, id: int) -> void:
	_hanger(life,6.1,5.72)
	for i in 5:
		var sheet:Node3D=life.pieces(Vector3((i-2)*1.06,5.63,-.1*sin(i)))
		sheet.box(Vector3(0,-.69,0),Vector3(.93,1.36,.05),"chalk")
		for j in 4:
			sheet.box(Vector3(-.03,-.34-j*.19,.033),Vector3(.62-j*.065,.038,.018),"iron")
		sheet.rotation.y=(i-2)*.17
		life.oscillate(sheet,3.8+i*.13,i*.91,Vector3.ZERO,Vector3(.35,.30,.08))
	life.sound(&"rustle",3.8)
	if id==12:
		var quill:Node3D=life.pieces(Vector3(0,4.2,.43))
		quill.beam(Vector3.ZERO,Vector3(.54,1.09,0),.069,.065,"brass")
		for i in 7:
			var end := Vector3(.22+.05*i,.37+i*.089,0)
			quill.beam(end,end+Vector3(-.29,.20,0),.10,.045,"bone")
		life.oscillate(quill,4.2,.3,Vector3(1.49,.17,0),Vector3(0,0,.12))


static func _stagework(life: Node3D, id: int) -> void:
	var bar := _hanger(life,7.5,6.9)
	if id==13:
		bar.box(Vector3(0,3.48,0),Vector3(7.5,.24,.60),"wood")
		for i in 24:
			var x := (i-11.5)*.29
			bar.beam(Vector3(x,3.48,0),Vector3(x,6.87,0),.047,.047,"cloth" if i%3 else "brass")
		var shuttle:Node3D=life.pieces(Vector3(0,4.38,.14))
		shuttle.ball(Vector3.ZERO,Vector3(1.48,.33,.28),"brass")
		shuttle.box(Vector3(0,0,.16),Vector3(.61,.15,.14),"cloth")
		life.oscillate(shuttle,2.8,0.,Vector3.RIGHT*2.85)
		life.sound(&"loom",1.4)
	elif id==7:
		for side: float in [-1.,1.]:
			var curtain:Node3D=life.pieces(Vector3(side*2.2,6.75,0))
			for i in 6:
				var at:=Vector3((i-2.5)*.29,-1.48,.13*cos(i*PI))
				curtain.column(at,Vector3(.49,2.93,.34),"cloth")
				curtain.ball(at-Vector3.UP*1.44,Vector3(.48,.30,.33),"brass")
			life.oscillate(curtain,7.9,.45,Vector3.RIGHT*side*.97,Vector3(0,0,.065*side))
	else:
		for i in 5:
			var mask:Node3D=life.pieces(Vector3((i-2)*1.5,4.94,0))
			bar.column(Vector3((i-2)*1.5,5.98,0),Vector3(.062,1.98,.062),"wood")
			mask.ball(Vector3.ZERO,Vector3(.88,1.36,.58),"chalk")
			for eye:float in [-1.,1.]:
				mask.ball(Vector3(eye*.18,.12,.25),Vector3(.21,.15,.10),"basalt")
			mask.ball(Vector3(0,-.30,.26),Vector3(.25,.26,.12),"basalt")
			life.oscillate(mask,5.1,i*.64,Vector3.ZERO,Vector3(.08,.96,.04))


static func _rail(life:Node3D,id:int) -> void:
	var track := _hanger(life,9.,6.20)
	track.box(Vector3(0,6.12,.25),Vector3(8.9,.12,.26),"brass")
	var carriage:Node3D=life.pieces(Vector3(0,5.90,.2))
	for hand:float in [-1.,1.]:
		carriage.column(Vector3(hand*.66,0,0),Vector3(.39,.30,.39),"iron",FACE)
		carriage.beam(Vector3(hand*.66,-.12,0),Vector3(hand*.66,-.89,0),.09,.09,"iron")
	carriage.box(Vector3(0,-1.22,0), Vector3(1.84,.81,1.07),"wood" if id==14 else "iron")
	if id==14:
		carriage.box(Vector3(.21,-1.17,.54),Vector3(.47,.24,.024),"chalk")
	else:
		for i in 3:
			carriage.box(Vector3((i-1)*.52,-1.16,.55),Vector3(.38,.32,.031),"ember")
	life.oscillate(carriage,6.8,0.,Vector3.RIGHT*3.18)


static func _measure(life:Node3D,id:int) -> void:
	var stand := _hanger(life,5.9,7.65)
	stand.column(Vector3(0,6.86,0),Vector3(.28,1.58,.28),"brass")
	var arm:Node3D=life.pieces(Vector3(0,6.03,0))
	if id==32:
		for side:float in [-1.,1.]:
			arm.beam(Vector3.ZERO,Vector3(side*2.5,-.16,0),.16,.16,"brass")
			arm.beam(Vector3(0,.38,0),Vector3(side*2.5,-.16,0),.082,.082,"brass")
			var pan:Node3D=life.pieces(Vector3(side*2.5,-.16,0),arm)
			for j in 3:
				var rim:=Vector3(.66*cos(TAU*j/3.),-1.4,.66*sin(TAU*j/3.))
				pan.beam(Vector3.ZERO,rim,.043,.043,"brass")
			pan.ball(Vector3(0,-1.45,0),Vector3(1.51,.30,1.51),"brass")
			pan.column(Vector3(0,-1.19,0),Vector3(.46 if side>0 else .65,.35,.46 if side>0 else .65),"iron")
			life.oscillate(pan,4.7,0.,Vector3.ZERO,Vector3(0,0,-.22))
		arm.ball(Vector3(0,.39,0),Vector3.ONE*.36,"ember")
		life.oscillate(arm,4.7,0.,Vector3.ZERO,Vector3(0,0,.22))
	else:
		stand.ring(Vector3(0,5.8,0),1.43,.14,"brass",FACE)
		for j in 12:
			var radial:=Vector3(sin(j*TAU/12.),cos(j*TAU/12.),0)
			stand.beam(radial*1.18+Vector3.UP*5.8,radial*1.36+Vector3.UP*5.8,.065,.065,"bone")
		arm.beam(Vector3.ZERO,Vector3.UP*1.13,.10,.10,"ember")
		life.turn(arm,12.,Vector3.FORWARD)
		var pend:Node3D=life.pieces(Vector3(0,4.75,.16))
		pend.beam(Vector3.ZERO,Vector3.DOWN*1.42,.08,.08,"brass")
		pend.ball(Vector3.DOWN*1.5,Vector3(.60,.75,.25),"brass")
		life.oscillate(pend,2.9,0.,Vector3.ZERO,Vector3(0,0,.44))
	life.sound(&"balance" if id==32 else &"clock",2.35 if id==32 else 1.45)
