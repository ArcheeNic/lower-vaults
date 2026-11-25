extends Node3D


static func _metal(color: Color, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = .65
	material.roughness = .33
	if glow > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material


func _piece(parent: Node3D, at: Vector3, size3: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size3
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = material
	piece.position = at
	parent.add_child(piece)


func make_exit() -> void:
	var wood := _metal(Color("574a3d"))
	var frame := _metal(Color("a47e53"))
	var daylight := _metal(Color("fff3d4"), 5.)
	for hand: float in [-1.,1.]:
		_piece(self, Vector3(hand*.98,1.43,0), Vector3(.15,2.86,.32), frame)
		_piece(self, Vector3(hand*.47,1.39,0), Vector3(.90,2.52,.17), wood)
	_piece(self, Vector3(0,2.79,0), Vector3(2.12,.18,.32), frame)
	_piece(self, Vector3(0,1.39,0), Vector3(.04,2.54,.14), daylight)
	_piece(self, Vector3(0,.065,0), Vector3(1.89,.10,.15), daylight)
	var light := OmniLight3D.new()
	light.position.y = .28
	light.light_color = Color("ffe9bc")
	light.light_energy = 4.
	light.omni_range = 6.
	add_child(light)
