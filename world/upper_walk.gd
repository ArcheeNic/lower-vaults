extends Node3D

const LAMP := preload("res://models/vigil.glb")
const FIGURE := preload("res://models/surveyor.glb")
var walker: Node3D
var time := 0.0
var phase := 0.0
static var unit_box := BoxMesh.new()
var batches := {}
var stone := StandardMaterial3D.new()
var iron := StandardMaterial3D.new()

func build(hand: int, seed_value: int) -> void:
	# Everything on this crossing shares the other gravity, including lamps and the passer-by.
	position = Vector3(0, 12.6, 7.4)
	rotation = Vector3(0,hand * 0.24,PI)
	stone.albedo_color = Color("827969")
	stone.roughness = 0.94
	iron.albedo_color = Color("352e29")
	iron.metallic = 0.6
	iron.roughness = 0.72
	phase = float(posmod(hash(seed_value), 500)) * .11
	_beam(Vector3(0,-.39,0), Vector3(35,.78,2.42), stone)
	_beam(Vector3(0,-.78,0), Vector3(35,.18,2.55), stone)
	for side in [-1,1]:
		var z := float(side)*1.11
		_beam(Vector3(0,1.06,z),Vector3(35,.09,.08),iron)
		_beam(Vector3(0,.43,z),Vector3(35,.06,.06),iron)
		for i in range(-8,9):
			_beam(Vector3(2*i,.53,z), Vector3(.084,1.06,.084), iron)
	for material: Material in batches:
		var transforms: Array = batches[material]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = unit_box
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
		var geometry := MultiMeshInstance3D.new()
		geometry.multimesh = mm
		geometry.material_override = material
		add_child(geometry)
	batches.clear()
	for i in [0]:
		var lamp: Node3D = LAMP.instantiate()
		lamp.position = Vector3(i,0,1)
		add_child(lamp)
	walker = FIGURE.instantiate()
	walker.scale = Vector3.ONE*1.08
	add_child(walker)

func _beam(at: Vector3, size: Vector3, material: Material) -> void:
	if not batches.has(material):
		batches[material] = []
	batches[material].append(Transform3D(Basis.from_scale(size), at))

func _process(delta: float) -> void:
	time += delta
	var step := time*.073+phase
	walker.position = Vector3(sin(step) * 13.3, absf(sin(step*19.0))*.027, 0)
	walker.rotation.y = PI*.5 if cos(step)>0 else -PI*.5
