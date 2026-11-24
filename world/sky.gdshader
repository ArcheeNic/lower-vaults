shader_type sky;

uniform vec3 moon_dir = vec3(-.69,.42,-.58);
uniform float night = 0.0;
uniform vec4 horizon : source_color = vec4(.62, .56, .46, 1.);
uniform vec4 zenith : source_color = vec4(.27, .33, .35, 1.);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}
float clouds(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),
		mix(hash(i+vec2(0.,1.)),hash(i+vec2(1.)),f.x),f.y);
}
void sky(){
	float elev = max(EYEDIR.y, 0.0);
	vec3 col = mix(horizon.rgb, zenith.rgb, pow(elev,.56));
	vec2 p = EYEDIR.xz / (.29 + abs(EYEDIR.y)) * vec2(3.5,8.);
	float gauze = clouds(p)*.52 + clouds(p*2.8)*.30 + clouds(p*7.1)*.18;
	col *= .77 + gauze*.46;
	float disc = distance(EYEDIR, normalize(moon_dir));
	float halo = exp(-disc*16.) * (.11+.16*gauze);
	float maria = clouds(EYEDIR.xz*1300.)*.14 + clouds(EYEDIR.xy*360.)*.21;
	vec3 silver = mix(vec3(.51,.65,.79),vec3(.59,.62,.78),night);
	col += silver*(halo+(1.-smoothstep(.029,.031,disc))*(1.-maria));
	vec2 chart = SKY_COORDS*vec2(660.,330.);
	vec2 id = floor(chart);
	vec2 centre = .22+.56*vec2(hash(id+17.),hash(id+31.));
	float star = (1.-smoothstep(.035,.19,distance(fract(chart),centre)))*smoothstep(.961,.995,hash(id));
	vec3 dome = mix(col, horizon.rgb*.17, smoothstep(.0,.66,-EYEDIR.y));
	COLOR = dome + star*(.20+night*.64)*vec3(1.2,1.38,1.75);
}
