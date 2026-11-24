// Perturb a view-space normal from a height measured in metres. Screen
// derivatives keep the relief aligned to masonry courses on any projection.
vec3 relief_normal(vec3 position, vec3 normal, float height) {
	vec3 dx = dFdx(position);
	vec3 dy = dFdy(position);
	vec3 u = cross(dy, normal);
	vec3 v = cross(normal, dx);
	float determinant = dot(dx, u);
	vec3 gradient = dFdx(height)*u + dFdy(height)*v;
	return normalize(max(abs(determinant), 0.0000001)*normal - sign(determinant)*gradient);
}
