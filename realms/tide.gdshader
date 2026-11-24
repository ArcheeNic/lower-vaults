shader_type spatial;
render_mode cull_disabled;
varying vec2 water_xz;
uniform sampler2D wave : repeat_enable, filter_linear_mipmap_anisotropic;
void vertex() {
	water_xz=(MODEL_MATRIX*vec4(VERTEX,1.)).xz;
}
void fragment(){
	// Integer cycles per tile keep wave phase continuous through world rebases.
	vec2 p=water_xz*vec2(1./64.,1./48.);
	float a=texture(wave,p*vec2(6.,9.)+vec2(TIME*.010, TIME*.006)).r;
	float b=texture(wave,p*vec2(12.,15.)+vec2(-TIME*.009, TIME*.005)).g;
	float c=texture(wave,p*vec2(25.,18.)+vec2(TIME*.017,-TIME*.009)).r;
	float flicker=smoothstep(.64,.86,.65*b+.35*c);
	NORMAL_MAP=vec3(.50+(a-.5)*.24,.5+(b-.5)*.20,1.);
	ALBEDO=mix(vec3(.007,.065,.072),vec3(.11,.236,.206),flicker*.65);
	METALLIC=.30;
	ROUGHNESS=.15+.12*a;
	SPECULAR=.88;
	float fres=pow(1.-max(dot(normalize(NORMAL),normalize(VIEW)),0.),2.3);
	ALPHA=.49+.26*fres+.06*b;
}
