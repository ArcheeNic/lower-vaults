extends StaticBody3D

# The walkable colliders omit scenery such as solid piers and vaults. Give
# substantial pieces of scenery their own ray-only layer for the gaze test.
const LAYER := 2
func build(tile: Node3D) -> void:
	collision_layer = LAYER
	collision_mask = 0
	var triangles := PackedVector3Array()
	var source_faces := {}
	for batch: MultiMeshInstance3D in tile.find_children("*","MultiMeshInstance3D",true,false):
		var mm := batch.multimesh
		var mesh := mm.mesh
		var size3 := mesh.get_aabb().size
		var base := tile.global_transform.affine_inverse() * batch.global_transform
		for i in mm.instance_count:
			var xf := base * mm.get_instance_transform(i)
			var dims := xf.basis.get_scale().abs() * size3
			var broad := int(dims.x >= .9) + int(dims.y >= .9) + int(dims.z >= .9)
			if broad < 2 or xf.origin.y-dims.length()*.5 > 14 or xf.origin.y+dims.length()*.5 < -8:
				continue
			if not source_faces.has(mesh):
				source_faces[mesh] = mesh.get_faces()
			var faces: PackedVector3Array = source_faces[mesh]
			triangles.append_array(xf*faces)
	if not triangles.is_empty():
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(triangles)
		shape_owner_add_shape(create_shape_owner(self),shape)
