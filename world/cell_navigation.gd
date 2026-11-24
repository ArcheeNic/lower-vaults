extends NavigationRegion3D

# Bake the same static colliders the walker uses, including sloped decks and rails.
func build(tile: Node3D) -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.cell_size = .20
	mesh.cell_height = .10
	mesh.agent_radius = .4
	mesh.agent_height = 2.0
	mesh.agent_max_climb = .3
	mesh.agent_max_slope = 49
	mesh.region_min_size = 1
	mesh.filter_ledge_spans = false
	mesh.edge_max_error = .6
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh, source, tile)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	navigation_mesh = mesh
	# Erosion leaves a narrow gap where each streamed tile ends.
	for seam in [Vector3(32,0,0), Vector3(0,0,-24)]:
		var link := NavigationLink3D.new()
		link.start_position = seam - seam.normalized() * 1.25
		link.end_position = seam + seam.normalized() * 1.25
		add_child(link)
