shader_type fog;

// Each pair of samples shares its endpoints with the neighbouring segments.
// Interpolate the floor and the growing upper surface along the actual walk.
uniform vec4 start;
uniform vec4 end_point;
uniform vec2 rise;

void fog() {
	vec2 axis = end_point.xz - start.xz;
	vec2 offset = WORLD_POSITION.xz - start.xz;
	float t = clamp(dot(offset, axis) / max(dot(axis, axis), .00001), 0., 1.);
	float radial = length(offset - t * axis) / mix(start.w, end_point.w, t);
	float y = WORLD_POSITION.y - mix(start.y, end_point.y, t);
	float height = mix(rise.x, rise.y, t) * sqrt(max(0., 1. - radial * radial));
	float curls = sin(WORLD_POSITION.x * 2.2 + WORLD_POSITION.z * 1.7 + TIME * .55)
		* sin(WORLD_POSITION.y * 2.4 - WORLD_POSITION.z * .9 - TIME * .32);
	float rim = smoothstep(0., .42 + .12 * curls, height - y);
	float weight = (1. - smoothstep(.82, 1., radial)) * rim * smoothstep(-.05, .04, y);
	DENSITY = weight * (1.15 + .25 * curls);
	ALBEDO = vec3(.016, .012, .027);
}
