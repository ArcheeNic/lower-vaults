extends StaticBody3D

# End frames belong to the two rooms. Their outward tangents define the
# centreline and their floor normals define how gravity turns through the bend.
var cells: Array[Vector2i] = []
var points := PackedVector3Array()
var normals := PackedVector3Array()
static var slab: Material
static var bronze: Material
static var glass: StandardMaterial3D

func build(a: Transform3D, b: Transform3D, across: bool) -> void:
	var axis := Vector3.RIGHT if across else Vector3.FORWARD
	var extent := 32. if across else 24.
	var t0 := a.basis * axis
	var t1 := b.basis * axis
	var start := a.origin + t0*extent
	var end := b.origin - t1*extent
	position = start
	var chord := end-start
	var handle := chord.length() / (3.*cos(t0.angle_to(t1)*.25)*cos(t0.angle_to(t1)*.25))
	var count := maxi(4,ceili(chord.length()/.65))
	for i in range(count+1):
		var t := float(i)/count
		points.append(Vector3.ZERO.bezier_interpolate(t0*handle,chord-t1*handle,chord,t))
		normals.append(a.basis.y.slerp(b.basis.y,t).normalized())
	set_meta("walk_surface",self)
	if not slab:
		slab = preload("res://architecture/hall.gd")._stone("918879",true)
		bronze = preload("res://architecture/hall.gd")._stone("956137",false,true)
		glass = StandardMaterial3D.new()
		glass.albedo_color = Color("e0c497")
		glass.emission_enabled = true
		glass.emission = Color("ffca85")
		glass.emission_energy_multiplier = 1.7
	var deck: Array[Transform3D] = []
	var rail: Array[Transform3D] = []
	var lenses: Array[Transform3D] = []
	for i in count:
		var mid := (points[i]+points[i+1])*.5
		var direction := points[i].direction_to(points[i+1])
		var side := normals[i].lerp(normals[i+1],.5).cross(direction).normalized()
		var frame := Basis(side,direction.cross(side),direction)
		var length := points[i].distance_to(points[i+1])
		var center := mid-frame.y*.19
		_piece(deck,center,frame,Vector3(3.8,.38,length+.024),true)
		for hand in [-1.,1.]:
			var edge: Vector3 = mid+side*hand*1.84
			_piece(rail,edge+frame.y*.99,frame,Vector3(.086,.09,length+.032))
			_piece(rail,edge+frame.y*.43,frame,Vector3(.05,.06,length+.016))
			_solid(edge+frame.y*.51,frame,Vector3(.10,1.02,length+.012))
			if i%3==0 or i==count-1:
				_piece(rail,edge+frame.y*.50,frame,Vector3(.085,1.,.085))
		if i%10==0 or i==count-1:
			for hand in [-1.,1.]:
				var fixture: Vector3 = mid+side*hand*1.84+frame.y*.73
				_piece(rail,fixture,frame,Vector3(.17,.28,.26))
				_piece(lenses,fixture-side*hand*.092,frame,Vector3(.03,.115,.19))
		if i==count/2:
			var lamp := OmniLight3D.new()
			lamp.position = mid+side*1.62+frame.y*.73
			lamp.light_color = Color("ffcf94")
			lamp.light_energy = 1.7
			lamp.omni_range = 6.8
			lamp.set_meta("steady_power",lamp.light_energy)
			lamp.add_to_group("scene_lights")
			add_child(lamp)
	_batch(lenses,glass)
	_batch(deck,slab)
	_batch(rail,bronze)

func _piece(batch: Array[Transform3D], at: Vector3, frame: Basis, size3: Vector3, solid := false) -> void:
	batch.append(Transform3D(frame.scaled_local(size3),at))
	if solid:
		_solid(at,frame,size3)

func _solid(at: Vector3, frame: Basis, size3: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size3
	var owner_id := create_shape_owner(self)
	shape_owner_set_transform(owner_id,Transform3D(frame,at))
	shape_owner_add_shape(owner_id,box)

func _batch(pieces: Array[Transform3D], material: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = pieces.size()
	for i in pieces.size():
		mm.set_instance_transform(i,pieces[i])
		var p := pieces[i].origin
		mm.set_instance_custom_data(i,Color(p.x,p.y,p.z,1.))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = mm
	instance.material_override = material
	add_child(instance)

func coordinate(at: Vector3) -> float:
	var local := to_local(at)
	var best := INF
	var result := 0.
	for i in points.size()-1:
		var delta := points[i+1]-points[i]
		var t := clampf((local-points[i]).dot(delta)/delta.length_squared(),0.,1.)
		var distance := local.distance_squared_to(points[i]+delta*t)
		if distance < best:
			best = distance
			result = i+t
	return result

func up_at(at: Vector3) -> Vector3:
	var u := coordinate(at)
	var i := mini(floori(u),normals.size()-2)
	return normals[i].slerp(normals[i+1],u-i).normalized()

func section(start: float, end: float) -> PackedVector3Array:
	var route := PackedVector3Array()
	var step := 1 if end >= start else -1
	var first := floori(start)+1 if step==1 else ceili(start)-1
	var stop := ceili(end) if step==1 else floori(end)
	for i in range(first,stop,step):
		route.append(to_global(points[i]))
	var i := mini(floori(end),points.size()-2)
	route.append(to_global(points[i].lerp(points[i+1],end-i)))
	return route
