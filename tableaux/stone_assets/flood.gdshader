shader_type spatial;
render_mode cull_disabled;
varying vec2 p;
void vertex(){
	p=VERTEX.xz;
}
void fragment(){
	float tide = sin(p.x*.33+p.y*.17+.45*TIME);
	float ripple = sin(p.y*3.38+2.2*tide+sin(p.x*.87-TIME*.13));
	float scum=pow(max(0.,sin(p.y*.62+tide*2.)*.57+ripple*.43),11.);
	ALBEDO=mix(vec3(.016,.063,.062),vec3(.090,.151,.131),scum);
	NORMAL_MAP=vec3(.5+.025*tide,.5+.058*ripple,1.);
	ROUGHNESS=.115+.074*scum;
	METALLIC=.49;
}
