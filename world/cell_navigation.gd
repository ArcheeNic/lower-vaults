extends NavigationRegion3D

var room_map: RID

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
	room_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(room_map, mesh.cell_size)
	NavigationServer3D.map_set_cell_height(room_map, mesh.cell_height)
	NavigationServer3D.map_set_up(room_map, tile.global_basis.y)
	NavigationServer3D.map_set_active(room_map,true)
	set_navigation_map(room_map)
	for link: NavigationLink3D in tile.find_children("*","NavigationLink3D",true,false):
		link.set_navigation_map(room_map)

func route(start: Vector3, goal: Vector3) -> PackedVector3Array:
	if NavigationServer3D.map_get_iteration_id(room_map) == 0:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(room_map,start,goal,true)

func _exit_tree() -> void:
	if room_map.is_valid():
		NavigationServer3D.free_rid(room_map)
		room_map = RID()
