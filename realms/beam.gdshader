shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
varying float travel;
void vertex(){
	travel=clamp(.5 - VERTEX.y / 18.2, 0., 1.);
}
void fragment(){
	float outer=pow(abs(dot(normalize(NORMAL),normalize(VIEW))),.65);
	ALBEDO=vec3(1.,.69,.26);
	ALPHA=(.008+.08*outer)*(1.-smoothstep(.0,1.0,travel));
}
