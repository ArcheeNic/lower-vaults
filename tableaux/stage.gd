extends Node3D

# The graph comes from the scene's floor plan. Four level thresholds line up
# with the surrounding worlds. Slopes and landings share a triangle surface.
const FoldWell := preload("res://world/fold_well.gd")
const HALF_WIDTH := 1.74
const STONE := preload("res://architecture/limestone.png")
const MATTER := preload("res://tableaux/matter.gdshader")
const SURFACES := {
	"stone":["999483",.03,.91,0.,1], "chalk":["c0bca5",0.,.94,0.,0],
	"basalt":["525865",.12,.82,0.,0], "iron":["656b71",.62,.54,0.,3],
	"brass":["ab8e60",.62,.43,0.,0], "rust":["98664e",.42,.78,0.,3],
	"wood":["8a7564",.02,.9,0.,2], "glass":["7c9aa6",.27,.20,.035,0],
	"salt":["c3cbca",.07,.48,0.,0], "moss":["626e58",.02,.97,0.,0],
	"cloth":["765b64",0.,.94,0.,2], "bone":["baaa91",.04,.71,0.,0],
	"ember":["ed9d63",.25,.5,.77,0], "pearl":["a2b6bd",.22,.4,.12,0]
}
static var materials := {}
static var meshes := {}
var _parts := {}
var _walk := PackedVector3Array()
var _body := StaticBody3D.new()
var has_well := false
var _floor := "stone"
var _handrail := "iron"
var _climate := 0
var landings: Array[Vector3] = []

func build(atlas: Script, index: int, climate: int) -> void:
	_prepare()
	_climate = climate
	add_child(_body)
	has_well = atlas == preload("res://tableaux/stone_atlas.gd") and index == 1
	atlas.build(self,index)
	var collision := ConcavePolygonShape3D.new()
	collision.backface_collision = true
	collision.set_faces(_walk)
	_add_collider(collision,Transform3D.IDENTITY)
	_walk.clear()
	for key: String in _parts:
		var pair := key.split("/")
		var batch: Array = _parts[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[pair[0]]
		mm.instance_count = batch.size()
		for i in batch.size():
			mm.set_instance_transform(i,batch[i])
		var renderer := MultiMeshInstance3D.new()
		renderer.material_override = materials[pair[1]]
		renderer.multimesh = mm
		add_child(renderer)
	_parts.clear()

static func _prepare() -> void:
	if not meshes.is_empty():
		return
	for key: String in SURFACES:
		var spec: Array = SURFACES[key]
		var mat := ShaderMaterial.new()
		mat.shader = MATTER
		mat.set_shader_parameter("mineral",STONE)
		mat.set_shader_parameter("pigment",Color(spec[0]))
		mat.set_shader_parameter("metallic",spec[1])
		mat.set_shader_parameter("roughness",spec[2])
		mat.set_shader_parameter("emission",spec[3])
		mat.set_shader_parameter("surface",spec[4])
		materials[key] = mat
	meshes["box"] = BoxMesh.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 20
	sphere.rings = 9
	meshes["ball"] = sphere
	meshes["outcrop"] = _outcrop()
	for key in ["column","cone"]:
		var cyl := CylinderMesh.new()
		cyl.height = 1
		cyl.radial_segments = 20
		cyl.rings = 0
		cyl.top_radius = .5 if key=="column" else 0.
		cyl.bottom_radius = .5
		meshes[key] = cyl

# Bedded rock has fractured flanks and a broken crown. Keep the regular
# sphere for glass, eggs, lenses and the astronomical instruments.
static func _outcrop() -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for layer in 5:
		var points := PackedVector3Array()
		var breadth: float = [.31,.47,.50,.40,.19][layer]
		for i in 13:
			var angle := TAU*(i+.19*sin(layer*1.9+i*.7))/13.
			var r := breadth*(.89+.11*cos(i*4.1+layer*.72))
			points.append(Vector3(cos(angle)*r,-.44+layer*.215+.027*sin(i*2.2+layer),sin(angle)*r))
		rings.append(points)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in 13:
		var j := (i+1)%13
		for layer in 4:
			var a := rings[layer][i]
			var b := rings[layer][j]
			var c := rings[layer+1][i]
			var d := rings[layer+1][j]
			for point in [a,b,c,b,d,c]:
				st.add_vertex(point)
		for point in [rings[4][i],rings[4][j],Vector3(0,.50,0),rings[0][j],rings[0][i],Vector3(0,-.50,0)]:
			st.add_vertex(point)
	st.generate_normals()
	return st.commit()

func _part(key:String,mat:String,at:Vector3,scale3:Vector3,basis:Basis) -> void:
	var batch := key+"/"+mat
	if not _parts.has(batch):
		_parts[batch] = []
	_parts[batch].append(Transform3D(basis.scaled_local(scale3),at))

func box(at:Vector3,size3:Vector3,mat:String,rotation3:=Vector3.ZERO) -> void:
	_part("box",mat,at,size3,Basis.from_euler(rotation3))

func column(at:Vector3,size3:Vector3,mat:String,rotation3:=Vector3.ZERO) -> void:
	_part("column",mat,at,size3,Basis.from_euler(rotation3))

func cone(at:Vector3,size3:Vector3,mat:String,rotation3:=Vector3.ZERO) -> void:
	_part("cone",mat,at,size3,Basis.from_euler(rotation3))

func ball(at:Vector3,size3:Vector3,mat:String) -> void:
	if mat in ["stone","chalk","salt","moss","basalt"] and size3.length_squared() > 2.:
		_part("outcrop",mat,at,size3,Basis(Vector3.UP, fposmod(at.x*.92+at.z*.47,TAU)))
	else:
		_part("ball",mat,at,size3,Basis.IDENTITY)

func ring(at:Vector3,radius:float,tube:float,mat:String,rotation3:=Vector3.ZERO) -> void:
	if radius<=0 or tube<=0:
		return
	var ratio := clampi(roundi(256.*tube/radius),2,249)
	var key := "torus_%d"%ratio
	if not meshes.has(key):
		var torus := TorusMesh.new()
		torus.inner_radius = 1.-ratio/256.
		torus.outer_radius = 1.+ratio/256.
		torus.rings = 48
		torus.ring_segments = 8
		meshes[key] = torus
	_part(key,mat,at,Vector3.ONE*radius,Basis.from_euler(rotation3))

func _frame(a:Vector3,b:Vector3) -> Basis:
	var z := a.direction_to(b)
	var ref_axis := Vector3.UP if absf(z.y)<.999 else Vector3.RIGHT
	var x := ref_axis.cross(z).normalized()
	return Basis(x,z.cross(x),z)

func beam(a:Vector3,b:Vector3,width:float,depth:float,mat:String) -> void:
	if a.distance_squared_to(b)>.000001:
		_part("box",mat,(a+b)*.5,Vector3(width,depth,a.distance_to(b)),_frame(a,b))

func plan(rows:Array,floor_material:String,rail_material:String,rise:float=.65) -> void:
	_floor = floor_material
	_handrail = rail_material
	var grid := {}
	for row in rows.size():
		for col in rows[row].length():
			var glyph: String = rows[row][col]
			if glyph.is_valid_int():
				var at := Vector3((col-4)*7.,glyph.to_int()*rise,(row-3)*6.)
				grid[Vector2i(col,row)] = at
				landings.append(at)
	for key: Vector2i in grid:
		var p:Vector3 = grid[key]
		_floor_strip(p-Vector3.BACK*HALF_WIDTH,p+Vector3.BACK*HALF_WIDTH)
		if _climate in [0,1]:
			column(p-Vector3.UP*4.83,Vector3(.67,9.,.67),_handrail)
		else:
			box(p-Vector3.UP*.76,Vector3(3.08,.46,3.08),_handrail)
		for dir:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var d := Vector3(dir.x,0,dir.y)
			var outward := p+d*HALF_WIDTH
			var next := key+dir
			if grid.has(next):
				if dir.x+dir.y>0:
					_bridge(outward,grid[next]-d*HALF_WIDTH)
			elif (key==Vector2i(4,0) and dir==Vector2i.UP) or (key==Vector2i(4,6) and dir==Vector2i.DOWN) or (key==Vector2i(0,3) and dir==Vector2i.LEFT) or (key==Vector2i(8,3) and dir==Vector2i.RIGHT):
				_bridge(outward,p+d*(4. if dir.x else 6.),2.26)
			elif has_well and key == Vector2i(4,3) and dir == Vector2i.RIGHT:
				_well_balcony(outward)
			else:
				var v := Vector3.UP.cross(d)*HALF_WIDTH
				_guard(outward-v,outward+v)

func _well_balcony(threshold: Vector3) -> void:
	var center := threshold + Vector3.RIGHT*2.56
	var hole := FoldWell.HALF_OPENING
	var width := 2.56
	for side: float in [-1.,1.]:
		for axis: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
			var rim := center + axis*side*((width+hole)*.5)
			var sizes := Vector3(width-hole,.46,2.*width) if axis == Vector3.RIGHT else Vector3(2.*hole,.46,width-hole)
			var slab := BoxShape3D.new()
			slab.size = sizes
			box(rim-Vector3.UP*.23,sizes,"basalt")
			_add_collider(slab,Transform3D(Basis.IDENTITY,rim-Vector3.UP*.23))
			var lip := center + axis*side*(hole+.06)
			var tangent := Vector3.UP.cross(axis)
			beam(lip-tangent*hole,lip+tangent*hole,.12,.055,"brass")
			var liner := BoxShape3D.new()
			liner.size = Vector3(.14,2.8,2.*hole) if axis == Vector3.RIGHT else Vector3(2.*hole,2.8,.14)
			var wall := center + axis*side*(hole+.07)-Vector3.UP*1.45
			box(wall,liner.size,"iron")
			_add_collider(liner, Transform3D(Basis.IDENTITY,wall))
		_guard(center+Vector3(-width,0,side*width),center+Vector3(width,0,side*width))
	_guard(center+Vector3(width,0,-width),center+Vector3(width,0,width))
	var well := FoldWell.new()
	well.position = center-Vector3.UP*.12
	add_child(well)

func _floor_strip(a:Vector3,b:Vector3,wa:float=HALF_WIDTH,wb:float=HALF_WIDTH) -> void:
	var frame := _frame(a,b)
	var left := frame.x
	var quad := PackedVector3Array([a-left*wa,a+left*wa,b+left*wb,a-left*wa,b+left*wb,b-left*wb])
	_walk.append_array(quad)
	# The top stays flush with the collider. A tapered threshold uses a narrow
	# flat centre and two matching side wedges for the wider external landing.
	if is_equal_approx(wa,wb):
		_part("box",_floor,(a+b)*.5-frame.y*.18,Vector3(wa*2.,.36,a.distance_to(b)),frame)
	else:
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in quad:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
		var border:=MeshInstance3D.new()
		border.mesh=st.commit()
		border.material_override=materials[_floor]
		add_child(border)
		_part("box",_handrail,(a+b)*.5-Vector3.UP*.23,Vector3(minf(wa,wb)*2,.42,a.distance_to(b)),frame)
	beam(a-frame.y*.39,b-frame.y*.39,minf(wa,wb)*1.66,.20,_handrail)

func _bridge(a:Vector3,b:Vector3,end_width:float=HALF_WIDTH) -> void:
	_floor_strip(a,b,HALF_WIDTH,end_width)
	var across := _frame(a,b).x
	for s in [-1.,1.]:
		_guard(a+across*HALF_WIDTH*s,b+across*end_width*s)

func _guard(a:Vector3,b:Vector3) -> void:
	var f:=_frame(a,b)
	var length:=a.distance_to(b)
	var barrier:=BoxShape3D.new()
	barrier.size=Vector3(.095,.99,length)
	_add_collider(barrier,Transform3D(f,(a+b)*.5+Vector3.UP*.50))
	var wall := _handrail in ["stone","basalt","chalk","salt"]
	var rope := _handrail in ["wood","cloth","moss","bone"]
	if wall:
		beam(a+Vector3.UP*.38,b+Vector3.UP*.38,.19,.76,_handrail)
		beam(a+Vector3.UP*.81,b+Vector3.UP*.81,.26,.11,_floor)
	elif not rope:
		beam(a+Vector3.UP*.93,b+Vector3.UP*.93,.075,.076,_handrail)
		beam(a+Vector3.UP*.38,b+Vector3.UP*.38,.05,.05,_handrail)
	var count := maxi(1,ceili(length/2.9))
	for i in range(count+1):
		var foot:=a.lerp(b,float(i)/count)
		if rope:
			column(foot+Vector3.UP*.47,Vector3(.15,.94,.15),_handrail)
			if i<count:
				var end:=a.lerp(b,float(i+1)/count)
				var sag:=(foot+end)*.5+Vector3.UP*.80
				beam(foot+Vector3.UP*.94,sag,.058,.058,"wood")
				beam(sag,end+Vector3.UP*.94,.058,.058,"wood")
		else:
			box(foot+Vector3.UP*.47,Vector3(.11,.94,.11),_handrail)
			if _handrail in ["pearl","glass"]:
				cone(foot+Vector3.UP*.51,Vector3(.25,.85,.25),_handrail)

func _add_collider(shape:Shape3D,local:Transform3D) -> void:
	var owner_id:=_body.create_shape_owner(_body)
	_body.shape_owner_set_transform(owner_id,local)
	_body.shape_owner_add_shape(owner_id,shape)
