shader_type spatial;
render_mode cull_disabled;
varying vec2 p;
void vertex() {
	p = VERTEX.xz;
}
void fragment(){
	float a = sin(p.x*.81 + sin(p.y*.37 + TIME*.31) + TIME*.41);
	float b = sin(p.y*3.3 + p.x*.54 + a*1.5 - TIME*.77);
	float c = sin(p.y*6.9 - p.x*.34 + TIME*.81 + b*.45);
	NORMAL = normalize(NORMAL + (MODELVIEW_MATRIX * vec4(a*.042, 0., b*.065+c*.021, 0.)).xyz);
	ALBEDO = vec3(.022,.047,.046);
	ROUGHNESS = .18 + .07*a;
	METALLIC = .65;
	SPECULAR = .83;
}
