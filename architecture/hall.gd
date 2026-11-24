extends Node3D

# Each bay owns one physics body and a few instanced geometry batches.
const MASONRY := preload("res://architecture/masonry.gdshader")
const MINERAL := preload("res://architecture/limestone.png")
const ARCH_COUNT := 17
const RING := 0.175
const DECK_HALF := 2.4
const STAIR_X := 10.0
const WELL_Z := -20.0
const STOREY := 5.6

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}

var _pieces: Dictionary = {}
var _body := StaticBody3D.new()
var _bay: int
var _rng := RandomNumberGenerator.new()

func side_height(side: int) -> float:
	var upper := -1 if posmod(_bay, 3) != 1 else 1
	return (4.2 + 0.4 * posmod(_bay, 4)) if side == upper else (-3.2 - 0.3 * posmod(_bay, 3))

func build(index: int) -> void:
	_bay = index
	_rng.seed = hash(index) + 923
	_prepare_resources()
	add_child(_body)
	_main_bridge()
	_folded_stair()
	for sign_x in [-1, 1]:
		_stair_court(sign_x)
		_side_arcades(sign_x)
	_gallery()
	_clerestory()
	_vault()
	_flush()

static func _stone(color: String, coursed: bool, iron: bool = false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = MASONRY
	mat.set_shader_parameter("stone_color", Color(color))
	mat.set_shader_parameter("blocks", coursed)
	mat.set_shader_parameter("metal", iron)
	mat.set_shader_parameter("mineral", MINERAL)
	return mat

static func _prepare_resources() -> void:
	if not _meshes.is_empty():
		return
	_materials["stone"] = _stone("a79b85", true)
	_materials["slab"] = _stone("a39b8b", true)
	_materials["trim"] = _stone("bcb19a", false)
	_materials["shade"] = _stone("796f60", true)
	_materials["iron"] = _stone("403b35", false, true)
	_materials["oxide"] = _stone("805239", false, true)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	_meshes["cube"] = box
	_meshes["wedge"] = _wedge()
	_meshes["shoulder"] = _shoulders()

static func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	var norm := (b - a).cross(c - a).normalized()
	var points := [a,b,c,a,c,d]
	if norm.dot(outward) > 0.0:
		points = [a,c,b,a,d,c]
	else:
		norm = -norm
	for pt in points:
		st.set_normal(norm)
		st.add_vertex(pt)

static func _wedge() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var angle := PI / ARCH_COUNT * 0.480
	var a := Vector3(cos(-angle), sin(-angle), 0)
	var b := Vector3(cos(angle), sin(angle), 0)
	var c := b * (1.0 + RING)
	var d := a * (1.0 + RING)
	var front := Vector3.BACK * 0.5
	_face(st, a+front,b+front,c+front,d+front,Vector3.BACK)
	_face(st, a-front,b-front,c-front,d-front,Vector3.FORWARD)
	_face(st, a+front,b+front,b-front,a-front,Vector3.LEFT)
	_face(st, d+front,c+front,c-front,d-front,Vector3.RIGHT)
	_face(st, d+front,a+front,a-front,d-front,Vector3.DOWN)
	_face(st, c+front,b+front,b-front,c-front,Vector3.UP)
	return st.commit()

static func _shoulders() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var f := Vector3.BACK * 0.5
	for i in range(ARCH_COUNT):
		var a := Vector3(cos(i * PI / ARCH_COUNT), sin(i * PI / ARCH_COUNT), 0) * (1.0 + RING)
		var b := Vector3(cos((i+1) * PI / ARCH_COUNT), sin((i+1) * PI / ARCH_COUNT), 0) * (1.0 + RING)
		var c := Vector3(b.x, 1.24, 0)
		var d := Vector3(a.x, 1.24, 0)
		_face(st, a+f,b+f,c+f,d+f,Vector3.BACK)
		_face(st, a-f,b-f,c-f,d-f,Vector3.FORWARD)
	return st.commit()

func _put(mesh: String, material: String, basis: Basis, center: Vector3, tone := 1.0) -> void:
	var key := mesh + "/" + material
	if not _pieces.has(key):
		_pieces[key] = []
	_pieces[key].append([Transform3D(basis, center), Color(tone,tone,tone,1.0)])

func _flush() -> void:
	for key: String in _pieces:
		var part := key.split("/")
		var entries: Array = _pieces[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = _meshes[part[0]]
		mm.instance_count = entries.size()
		for i in entries.size():
			mm.set_instance_transform(i,entries[i][0])
			mm.set_instance_color(i,entries[i][1])
			var local_center: Vector3 = entries[i][0].origin
			mm.set_instance_custom_data(i, Color(local_center.x, local_center.y, local_center.z, 1))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = _materials[part[1]]
		add_child(instance)
	_pieces.clear()

func _solid(center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var slot := _body.create_shape_owner(_body)
	_body.shape_owner_set_transform(slot, Transform3D(basis, center))
	_body.shape_owner_add_shape(slot, shape)

func _box(center: Vector3, size: Vector3, material := "stone", basis := Basis.IDENTITY, solid := false, tone := 1.0) -> void:
	_put("cube", material, basis.scaled_local(size), center, tone)
	if solid:
		_solid(center, size, basis)

func _span_frame(a: Vector3, b: Vector3) -> Basis:
	var z := (b-a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	return Basis(x,z.cross(x),z)

func _beam(a: Vector3, b: Vector3, width: float, thick: float, material: String, solid := false) -> void:
	_box((a+b)*0.5, Vector3(width, thick, a.distance_to(b)), material, _span_frame(a,b), solid)

func _post(at: Vector3) -> void:
	_box(at + Vector3.UP*0.12, Vector3(0.25,0.24,0.25), "trim")
	_box(at + Vector3.UP*0.58, Vector3(0.115,0.85,0.115), "iron")
	_box(at + Vector3.UP*0.99, Vector3(0.17,0.11,0.17), "oxide")

func _rail(a: Vector3, b: Vector3, solid := true) -> void:
	var intervals := maxi(1, roundi(a.distance_to(b) / 2.5))
	for i in range(intervals+1):
		_post(a.lerp(b, float(i)/intervals))
	_beam(a+Vector3.UP*1.02, b+Vector3.UP*1.02, 0.11,0.105,"iron")
	_beam(a+Vector3.UP*0.47, b+Vector3.UP*0.47, 0.055,0.055,"oxide")
	if solid:
		_solid((a+b)*0.5+Vector3.UP*0.54, Vector3(0.12,1.08,a.distance_to(b)), _span_frame(a,b))

func _deck(center: Vector3, width: float, depth: float, thick := 0.68, playable := true) -> void:
	_box(center-Vector3.UP*(thick*0.5), Vector3(width,thick,depth), "slab", Basis.IDENTITY, playable)
	_box(center-Vector3.UP*(thick+0.12), Vector3(width+0.14,0.24,depth), "trim")

func _arch(at: Vector3, radius: float, depth: float, turn := 0.0, filled := true) -> void:
	var yaw := Basis(Vector3.UP,turn)
	for i in range(ARCH_COUNT):
		var angle := (i+0.5)*PI/ARCH_COUNT
		var scale3 := Vector3(radius,radius,depth*(1.18 if i == ARCH_COUNT/2 else 1.0))
		var frame := yaw * Basis(Vector3.BACK,angle)
		_put("wedge", "trim", frame.scaled_local(scale3), at, _rng.randf_range(.63,1.0))
	if filled:
		_put("shoulder", "stone", yaw.scaled_local(Vector3(radius,radius,depth*0.92)), at)

func _pier(x: float, z: float, base: float, cap: float, width: float, depth: float, playable := false) -> void:
	_box(Vector3(x,(base+cap)*0.5,z),Vector3(width,cap-base,depth),"stone",Basis.IDENTITY,playable)
	for k in range(3):
		var ext := (k+1)*0.15
		_box(Vector3(x,cap-0.40+k*0.17,z),Vector3(width+ext,0.18,depth+ext),"trim")
	_box(Vector3(x,base+0.40,z),Vector3(width+0.46,0.8,depth+0.46),"shade")
	# Paired pilaster strips break the broad face of each pier into recessed panels.
	for face in [-1.0,1.0]:
		for edge in [-1.0,1.0]:
			_box(Vector3(x+edge*width*.37,(base+cap)*.5,z+face*depth*.5),
				Vector3(width*.13,cap-base-.50,0.28),"stone")

func _main_bridge() -> void:
	_deck(Vector3.ZERO,DECK_HALF*2.0,48.0,1.0)
	for side in [-1.0,1.0]:
		var x: float = side*(DECK_HALF-0.11)
		for ends in [[-23.86,-16.7],[-13.3,13.3],[16.7,23.86]]:
			if side > 0 and ends[0] < WELL_Z:
				_rail(Vector3(x,0,ends[0]),Vector3(x,0,WELL_Z-1.25))
				_rail(Vector3(x,0,WELL_Z+1.25),Vector3(x,0,ends[1]))
			else:
				_rail(Vector3(x,0,ends[0]),Vector3(x,0,ends[1]))
	# The causeway itself stands on two tiers; both are visible from the side stairs.
	for z in [-18.0,-6.0,6.0,18.0]:
		_arch(Vector3(0,-8.5,z),5.05,4.2,PI/2)
	for z in [-22.8,-12.0,0.0,12.0,22.8]:
		_pier(0,z,-27.0,-8.5,4.1,1.65)
		_box(Vector3(0,-4.85,z),Vector3(4.14,7.3,1.1),"shade")

# Two ramps leave the same door, one up and one down. At their blind turn
# the north half of the landing is identified with the floor one storey below.
# The extra flights are physical sightlines through the stairwell's iron grille.
func _folded_stair() -> void:
	var near_x := 4.8
	var far_x := 11.8
	var top := STOREY * .5
	for level in [-1,0,1]:
		var y: float = level * STOREY
		_deck(Vector3(3.6,y,WELL_Z),2.4,5.4,.36,level==0)
		for side in [-1,1]:
			var z: float = WELL_Z + side*1.38
			_stair(Vector3(near_x,y,z),Vector3(far_x,y+side*top,z),2.66,level==0,false)
			_beam(Vector3(near_x,y+.93,z+side*1.17),Vector3(far_x,y+side*top+.93,z+side*1.17),.075,.075,"oxide")
		# A deeply recessed exterior, with a single open door on the bridge.
		for side in [-1,1]:
			var outer_z: float = WELL_Z+side*2.83
			_box(Vector3(8.53,y+.44,outer_z),Vector3(12.3,1.25,.27),"stone")
			_box(Vector3(8.53,y+3.94,outer_z),Vector3(12.3,2.95,.27),"shade")
			for i in 18:
				_box(Vector3(2.67+i*.68,y+1.77,outer_z),Vector3(.07,1.42,.12),"iron")
			_box(Vector3(8.53,y+2.47,outer_z),Vector3(12.35,.15,.39),"trim")
		for side in [-1,1]:
			_box(Vector3(2.54,y+1.96,WELL_Z+side*2.05),Vector3(.28,4.26,1.45),"stone",Basis.IDENTITY,true)
		_box(Vector3(2.54,y+4.6,WELL_Z),Vector3(.31,2.05,5.48),"shade",Basis.IDENTITY,true)
		_box(Vector3(2.5,y+3.56,WELL_Z),Vector3(.42,.18,2.88),"trim")
		if level != 0:
			_box(Vector3(2.54,y+1.75,WELL_Z),Vector3(.24,3.52,2.68),"iron",Basis.IDENTITY,true)
	# The central newel hides the exchange of floors. The turn has the same
	# ashlar, inspection lamp and lintel on both copies of the landing.
	_box(Vector3(8.28,1.2,WELL_Z),Vector3(7.04,18,.30),"stone",Basis.IDENTITY,true)
	for side in [-1,1]:
		_box(Vector3(8.53,1.5,WELL_Z+side*2.92),Vector3(12.3,19,.10),"iron",Basis.IDENTITY,true)
		var y: float = side*top
		_deck(Vector3(13.17,y,WELL_Z),2.74,5.52,.4)
		_box(Vector3(13.17,y+3.68,WELL_Z),Vector3(2.79,.34,5.6),"shade",Basis.IDENTITY,true)
		_inspection_lamp(Vector3(14.19,y+2.44,WELL_Z),2.0)
	_box(Vector3(14.66,1.2,WELL_Z),Vector3(.3,18,5.82),"stone",Basis.IDENTITY,true)
	_inspection_lamp(Vector3(2.14,2.72,WELL_Z-1.63),3.6)
	# Number III is a fixed landmark at the shared door.
	for i in range(-1,2):
		_box(Vector3(2.31,2.23,WELL_Z+1.9+i*.16),Vector3(.09,.52,.065),"oxide")
	var fold := NavigationLink3D.new()
	fold.start_position = Vector3(13.12,top+.12,WELL_Z+.04)
	fold.end_position = Vector3(13.12,-top+.12,WELL_Z-.04)
	add_child(fold)


func _inspection_lamp(at: Vector3, power: float) -> void:
	var bulb := MeshInstance3D.new()
	bulb.mesh = _meshes["cube"]
	var enamel := StandardMaterial3D.new()
	enamel.albedo_color = Color("ffe8ad")
	enamel.emission_enabled = true
	enamel.emission = Color("ffbd69")
	enamel.emission_energy_multiplier = 2.3
	bulb.material_override = enamel
	bulb.position = at
	bulb.scale = Vector3(.16,.42,.26)
	add_child(bulb)
	for y in [-.24,0.,.24]:
		_box(at+Vector3.UP*y,Vector3(.22,.054,.34),"iron")
	var lamp := OmniLight3D.new()
	lamp.position = at + Vector3.LEFT*.24
	lamp.light_color = Color("ffd49a")
	lamp.omni_range = 7.
	lamp.light_energy = power
	lamp.set_meta("steady_power",power)
	lamp.add_to_group("scene_lights")
	add_child(lamp)


func fold_offset(at: Vector3) -> float:
	if at.x < 11.8 or at.x > 14.52 or absf(at.z-WELL_Z) > 2.8:
		return 0.
	if absf(at.y-STOREY*.5) < .6 and at.z < WELL_Z:
		return -STOREY
	if absf(at.y+STOREY*.5) < .6 and at.z >= WELL_Z:
		return STOREY
	return 0.


func _stair(a: Vector3, b: Vector3, width: float, playable := true, rails := true) -> void:
	var flat := Vector3(b.x-a.x,0,b.z-a.z)
	var dir := flat.normalized()
	var across := Vector3.UP.cross(dir)
	var plan := Basis(across,Vector3.UP,dir)
	var count := maxi(2,ceili(absf(b.y-a.y)/.19))
	var thickness := 0.47
	for i in range(count):
		var mid := a.lerp(b, (i+0.5)/count)
		_box(mid-Vector3.UP*.16, Vector3(width, 0.32, flat.length()/count+.018), "slab", plan)
		var high_edge := mid+dir*signf(a.y-b.y)*(flat.length()/count*.5-.055)
		_box(high_edge-Vector3.UP*.038, Vector3(width+.07,.079,.13), "trim", plan)
	var slope := _span_frame(a,b)
	var center := (a+b)*.5 - slope.y*thickness*.5
	_box(center-slope.y*.14,Vector3(width-.12,thickness,a.distance_to(b)),"shade",slope)
	if playable:
		_solid(center,Vector3(width,thickness,a.distance_to(b)),slope)
	if rails:
		for sign_x in [-1.0,1.0]:
			var margin: Vector3 = across*(width*.5-.1)*sign_x
			_rail(a+margin,b+margin,playable)

func _stair_court(side: int) -> void:
	var x := STAIR_X * side
	var y := side_height(side)
	var width := 3.4
	for end in [-1.0,1.0]:
		var z: float = end*15.0
		_deck(Vector3(side*(DECK_HALF+STAIR_X+width*.5)*.5,0,z),STAIR_X+width*.5-DECK_HALF,width)
		_rail(Vector3(side*DECK_HALF,0,z+end*1.58),Vector3(x+side*1.59,0,z+end*1.58))
		_rail(Vector3(side*DECK_HALF,0,z-end*1.58),Vector3(x-side*1.59,0,z-end*1.58))
		_rail(Vector3(x+side*1.59,0,z-1.62),Vector3(x+side*1.59,0,z+1.62))
		_stair(Vector3(x,0,z-end*1.7),Vector3(x,y,end*2.3),width)
		_pier(x,z,-22,-.92,2.2,2.8)
	_deck(Vector3(x,y,0),width,4.6)
	_rail(Vector3(x-side*1.59,y,-2.30),Vector3(x-side*1.59,y,2.30))
	_lateral_bridge(side,y)

func _lateral_bridge(side: int, y: float) -> void:
	var s := float(side)
	var width := 4.6
	var start := 11.7
	var foot := 26.6
	var ramp := 13.6
	_deck(Vector3(s*(start+ramp)*.5,y,0),ramp-start,width,.65)
	for z in [-2.18,2.18]:
		_rail(Vector3(s*start,y,z),Vector3(s*ramp,y,z))
	_stair(Vector3(s*ramp,y,0),Vector3(s*foot,0,0),width)
	# The cornice ends flush at the shared seam, so either adjacent tile can own it.
	var edge := Vector3(s*(foot+32.0)*.5,0,0)
	_box(edge-Vector3.UP*.37,Vector3(32.0-foot,.74,width),"slab",Basis.IDENTITY,true)
	_box(edge-Vector3.UP*.83,Vector3(32.0-foot,.18,width+.15),"trim")
	for z in [-2.18,2.18]:
		_rail(Vector3(s*foot,0,z),Vector3(s*31.86,0,z))
	# Recessed double ribs carry the flight above the open well.
	var spring := minf(y,0.0)-5.2
	for x in [16.5,23.5,29.3]:
		var radius := 2.15 if x > 27.0 else 2.85
		for z in [-1.56,1.56]:
			_arch(Vector3(s*x,spring,z),radius,.55,0.0,false)
	for x in [13.0,20.0,27.0]:
		_pier(s*x,0,-22.0,spring,1.2,3.72)
		var deck_y := lerpf(y,0.0,clampf((x-ramp)/(foot-ramp),0.0,1.0))
		_box(Vector3(s*x,(spring+deck_y-.6)*.5,0),Vector3(.90,deck_y-.6-spring,3.21),"shade")

func _side_arcades(side: int) -> void:
	var s := float(side)
	var x := s*(18.8 + posmod(_bay+side,3)*.8)
	var spring := 7.7 + posmod(_bay+side,4)*1.15
	# The middle bay is a full-height breach. Both flanks remain layered, giving
	# the next landscape a frame from the stairs and a wide view from the bridge.
	for zsign in [-1.0,1.0]:
		var z: float = zsign*15.6
		for pier_z in [8.0,16.0,22.7]:
			_pier(x,zsign*pier_z,-26.0,spring,2.62,1.77)
		_arch(Vector3(x,-6.4,z),5.8,2.98,PI/2)
		_box(Vector3(x,1.15,z),Vector3(3.02,.58,15.3),"trim")
		for arch_z in [12.0,19.45]:
			_arch(Vector3(x,spring,zsign*arch_z),3.14,2.56,PI/2)
		var crown := spring+4.0
		_box(Vector3(x,crown+.10,z),Vector3(3.20,.42,15.6),"trim")
		_rail(Vector3(x-s*1.23,crown+.31,zsign*8),Vector3(x-s*1.23,crown+.31,zsign*23.36),false)
		# The outer abutments leave the centre of each doorway clear to the horizon.
		var far_x := s*(27.5+posmod(_bay-side,3)*.56)
		var high := 17.5+posmod(_bay+side,4)*2.05
		_pier(far_x,zsign*16.0,-23.0,high,3.4,4.16)
		_pier(far_x,zsign*22.2,-21.0,high+2.3,3.05,2.5)
		_arch(Vector3(far_x,high-1.0,zsign*19.0),2.32,2.83,PI/2)
		_deck(Vector3(far_x,high+2.1,zsign*19.25),3.82,8.56,.7,false)
		_beam(Vector3(x-s*2.9,spring-.6,zsign*8.0),Vector3(x-s*.8,spring-2.8,zsign*8.0),.16,.18,"oxide")
	# A single unfilled arch hangs high enough to see the neighbouring tile
	# even from the highest landing. Its keystone silhouettes against the sky.
	_arch(Vector3(x,spring+.20,0),7.1,1.6,PI/2,false)

func _gallery() -> void:
	var v := posmod(_bay,4)
	var z := -10.5 + (v % 3)*3.0
	var radius := 5.85 + .65*(v%2)
	var spring := 3.86 + (v%3)*1.12
	var depth := 2.12
	_arch(Vector3(0,spring,z),radius,depth)
	for s in [-1.0,1.0]:
		var x: float = s*(radius+.77)
		_pier(x,z,-21,spring,1.75,depth,true)
		_box(Vector3(x,spring+radius*.606,z),Vector3(1.4,radius*1.22,depth*.94),"stone")
		# Massive side spans leave an unobstructed view through to the flanking galleries.
		var side_r := 3.65
		_arch(Vector3(s*(radius+1.58+side_r),spring+1.15,z),side_r,depth*.94)
		_pier(s*(radius+2*side_r+2.30),z,-20,spring+1.15,1.65,depth*1.12)
	var cornice := spring+1.24*radius+.15
	_box(Vector3(0,cornice,z),Vector3(2*(radius+1.52),.42,2.6),"trim")
	for s in [-1.0,1.0]:
		_rail(Vector3(-radius-1.21,cornice+.21,z+s),Vector3(radius+1.21,cornice+.21,z+s),false)
	# Skewed flights, seen in profile against the open well.
	var hand := -1.0 if posmod(_bay,3)==1 else 1.0
	if v != 2:
		var a := Vector3(-hand*17.0,4.9+v,-19)
		var b := Vector3(hand*15.8,15.7+v,-5.5)
		_stair(a,b,2.25,false)
		_deck(Vector3(hand*17.7,b.y,b.z),5.7,3.8,.68,false)
		_pier(hand*18.9,b.z,-20,b.y-.90,2.1,2.3)
		for t in [.12,.84]:
			var p := a.lerp(b,t)
			_pier(p.x,p.z,-18,p.y-.5,1.28,1.38)
	else:
		for s in [-1.,1.]:
			_stair(Vector3(s*17,5.3,-17),Vector3(s*4.3,13.3,6),2.4,false)
		_deck(Vector3(0,13.3,6.1),10.7,3.0,.7,false)

func _clerestory() -> void:
	# A screen at the far end breaks the axial view. Its height and number of
	# openings give each court a different silhouette above the repeating bays.
	var v := posmod(_bay,4)
	var hand := -1.0 if v in [0,3] else 1.0
	var z := -21.1
	var x := hand * (11.4 if v != 2 else 8.8)
	var radius := 3.5 if v in [0,2] else 2.65
	var floor_y := 12.4+v*.8
	var top_y := floor_y + 4.65 + radius*1.24
	for s in [-1.,1.]:
		var px: float = x + s*(radius+.94)
		_pier(px,z,-26.0,floor_y,2.55,3.8)
		_pier(px,z,floor_y,floor_y+4.65,2.33,3.70)
		_box(Vector3(px,top_y-radius*.60,z),Vector3(1.92,radius*1.25,3.52),"stone")
	_arch(Vector3(x,floor_y+4.65,z),radius,3.72)
	_deck(Vector3(x,floor_y,z),radius*2+4.20,4.32,.74,false)
	_box(Vector3(x,top_y+.24,z),Vector3(radius*2+4.3,.48,4.14),"trim")
	_box(Vector3(x,top_y+.77,z),Vector3(radius*2+3.5,.62,3.77),"stone")
	var crown := top_y + 1.08
	if v in [0,3]:
		# Three narrow apertures of a bell tower taper into the mist.
		for i in [-1,0,1]:
			var xx:float = x+i*2.32
			_arch(Vector3(xx,crown+2.75,z),.97,2.65)
			_box(Vector3(xx-1.15,crown+1.38,z),Vector3(.45,2.76,2.61),"stone")
		_box(Vector3(x+3.46,crown+1.38,z),Vector3(.45,2.76,2.61),"stone")
		_box(Vector3(x,crown+4.08,z),Vector3(7.32,.27,2.95),"trim")
	else:
		var rim := Vector3(x,crown+2.26,z)
		for i in range(ARCH_COUNT*2):
			var angle := (i+.5)*PI/ARCH_COUNT
			_put("wedge","trim",Basis(Vector3.BACK,angle).scaled_local(Vector3(2.12,2.12,1.25)),
				rim,_rng.randf_range(.68,.99))

func _vault() -> void:
	var spring := 14.0 + posmod(_bay, 3)*.55
	var rise := 12.7 + posmod(_bay+1, 3)*.65
	# The roof consists of three structural bays. A missing patch of webbing
	# between the ribs admits light from a different side in every court.
	for run in range(3):
		var z := -16.0 + run*16
		var hole := 4 + posmod(_bay*3 + run*5,10)
		for sector in range(ARCH_COUNT):
			if absi(sector-hole) <= 1:
				continue
			var angle := (sector+.5)*PI/ARCH_COUNT
			var frame := Basis.from_scale(Vector3(19.8,rise,15.7)) * Basis(Vector3.BACK,angle)
			_put("wedge","shade",frame,Vector3(0,spring,z),_rng.randf_range(.73,.96))
		var rib_z := z-6.6
		for sector in range(ARCH_COUNT):
			var angle := (sector+.5)*PI/ARCH_COUNT
			var frame := Basis.from_scale(Vector3(19.17,rise-.55,1.21))*Basis(Vector3.BACK,angle)
			_put("wedge","trim",frame,Vector3(0,spring,rib_z),_rng.randf_range(.65,.90))
		for s in [-1.0,1.0]:
			_pier(s*19.56,rib_z,-20.0,spring,2.12,2.02)
			_box(Vector3(s*20.1,spring-.88,z),Vector3(1.12,1.72,16),"stone")
	# Iron ties span the high drum underneath the chain hoists.
	for z in [-5.0,6.0,10.9]:
		var y := spring+rise*.54
		_box(Vector3(0,y,z),Vector3(37,.26,.42),"iron")
		_box(Vector3(0,y+.17,z),Vector3(37,.11,.58),"oxide")
		for s in [-1.0,1.0]:
			_beam(Vector3(s*14.9,y+.16,z),Vector3(s*8.2,spring+rise-.4,z),.11,.13,"iron")
