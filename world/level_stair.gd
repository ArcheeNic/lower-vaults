extends "res://tableaux/stage.gd"

const Stone := preload("res://tableaux/stone_stairs.gd")
const Wild := preload("res://tableaux/wild_stairs.gd")
const Original := preload("res://world/original_stairs.gd")
const DOOR_X := 2.60
const DOOR_Z := 9.40
const WIDTH := 2.80
const RUN := 8.
const SIDE_DECK := 1.9
var rise: float
var side: int
var destination: Vector2i
var profile := PackedVector2Array()

func assemble(scene_id: int, hand: int, other_cell: Vector2i, sealed := false) -> void:
	side = hand
	destination = other_cell
	transform = Transform3D(Basis(Vector3.UP,0. if hand>0 else PI),
		Vector3((32.+SIDE_DECK*.5)*hand,0,1.9*hand))
	var style: Script = Original
	var index := scene_id
	if scene_id>=4 and scene_id<18:
		style = Stone
		index -= 4
	elif scene_id>=18 and scene_id<32:
		style = Wild
		index -= 18
	var palette: Array = style.palette(index)
	_prepare()
	add_child(_body)
	_floor = palette[0]
	_handrail = palette[2]
	_floor_strip(Vector3(0,0,-3.8),Vector3.ZERO,SIDE_DECK*.5,SIDE_DECK*.5)
	_guard(Vector3(-SIDE_DECK*.5,0,-3.8),Vector3(SIDE_DECK*.5,0,-3.8))
	_build_flights(style.flights(index),palette)
	style.dress(self,index)
	_vestibule()
	if sealed:
		_wall(Vector3(DOOR_X,rise+1.8,DOOR_Z),Vector3(.3,3.6,3.))
	_finish_geometry()

func _build_flights(flights: Array, palette: Array) -> void:
	var steps := 0
	for count: int in flights:
		steps += count
	var depth := (RUN-(flights.size()-1)*1.08)/steps
	rise = .18*steps*side
	profile.append(Vector2.ZERO)
	for count: int in flights:
		var start := profile[-1]
		var end := start+Vector2(depth,.18*side)*count
		profile.append(end)
		_incline(start,end)
		for i in count:
			var mid := start.lerp(end,(i+.5)/count)
			box(Vector3(0,mid.y-.13,mid.x),Vector3(WIDTH,.26,depth),palette[1])
			box(Vector3(0,mid.y-.036,mid.x),Vector3(WIDTH+.04,.072,depth+.024),palette[0])
			for edge: float in [-1.,1.]:
				box(Vector3(edge*(WIDTH*.5-.09),mid.y+.006,mid.x),Vector3(.07,.018,depth-.045),palette[2])
		if end.x<RUN-.001:
			var rest := end+Vector2(1.08,0)
			profile.append(rest)
			_floor_strip(Vector3(0,end.y,end.x),Vector3(0,rest.y,rest.x),WIDTH*.5,WIDTH*.5)
			for edge: float in [-1.,1.]:
				_guard(Vector3(edge*WIDTH*.5,end.y,end.x),Vector3(edge*WIDTH*.5,rest.y,rest.x))

func _incline(start: Vector2,end: Vector2) -> void:
	var half := WIDTH*.5
	var a := Vector3(-half,start.y,start.x)
	var b := Vector3(half,start.y,start.x)
	var c := Vector3(half,end.y,end.x)
	var d := Vector3(-half,end.y,end.x)
	_walk.append_array(PackedVector3Array([a,b,c,a,c,d]))
	_guard(a,d)
	_guard(b,c)

func height_at(z: float) -> float:
	for i in range(1,profile.size()):
		if z<=profile[i].x:
			var t := clampf(inverse_lerp(profile[i-1].x,profile[i].x,z),0.,1.)
			return lerpf(profile[i-1].y,profile[i].y,t)
	return rise

func lamp(at: Vector3,color: Color,power: float,reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = power
	light.omni_range = reach
	light.set_meta("steady_power",power)
	light.add_to_group("scene_lights")
	add_child(light)

func _wall(at: Vector3,size: Vector3) -> void:
	box(at,size,"basalt")
	var shape := BoxShape3D.new()
	shape.size = size
	_add_collider(shape,Transform3D(Basis.IDENTITY,at))

func _vestibule() -> void:
	_floor = "basalt"
	_handrail = "iron"
	var far_x := 2.*DOOR_X
	_floor_strip(Vector3(-1.4,rise,DOOR_Z),Vector3(far_x+1.4,rise,DOOR_Z),1.4,1.4)
	# Two elbows meet at a blind landing. Both ends have the same recess
	# and cornice, so either view survives a change of gravity at its centre.
	for sign_x: float in [-1.,1.]:
		var end_x := DOOR_X+sign_x*(DOOR_X+1.53)
		_wall(Vector3(end_x,rise+1.8,DOOR_Z),Vector3(.25,3.6,3.1))
		var wall_z := DOOR_Z+sign_x*1.50
		_wall(Vector3(DOOR_X-sign_x*1.40,rise+1.8,wall_z),Vector3(far_x,3.6,.20))
		# Close the outer corner past the opening on the opposite side.
		_wall(Vector3(DOOR_X+sign_x*(DOOR_X+1.46),rise+1.8,wall_z),Vector3(.18,3.6,.20))
		box(Vector3(DOOR_X+sign_x*.6,rise+1.06,wall_z-sign_x*.13),Vector3(2.8,.085,.09),"brass")
		box(Vector3(DOOR_X+sign_x*.8,rise+2.55,wall_z-sign_x*.13),Vector3(.64,.16,.05),"pearl")
		lamp(Vector3(DOOR_X+sign_x*.8,rise+2.48,wall_z-sign_x*.42),Color("edd7b7"),2.1,5.)
	_wall(Vector3(DOOR_X,rise+3.65,DOOR_Z),Vector3(far_x+3.1,.24,3.25))
	# Back of the far recess. Only the first half of the chamber is traversed.
	_wall(Vector3(far_x,rise+1.8,DOOR_Z+2.45),Vector3(2.82,3.6,.18))

func threshold() -> Vector3:
	return to_global(Vector3(DOOR_X,rise,DOOR_Z))

func has_crossed(point: Vector3) -> bool:
	var p := to_local(point)
	return p.x>=DOOR_X and p.x<DOOR_X+.65 and absf(p.y-rise)<.65 and absf(p.z-DOOR_Z)<1.40

func passage_to(other: Node3D) -> Transform3D:
	var turn := other.global_basis*Basis(Vector3.UP,PI)*global_basis.inverse()
	return Transform3D(turn,other.threshold()-turn*threshold())
