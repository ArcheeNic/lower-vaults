// Projections for masonry courses, timber grain and plate seams are measured
// in the architectural frame of the room that owns each instanced batch.
instance uniform vec3 room_right = vec3(1.,0.,0.);
instance uniform vec3 room_up = vec3(0.,1.,0.);
vec3 room_axes(vec3 v) {
	return vec3(dot(v,room_right),dot(v,room_up),dot(v,cross(room_right,room_up)));
}
