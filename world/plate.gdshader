shader_type canvas_item;
render_mode unshaded;
uniform float pressure = 0.0;
uniform float lamplight_lost = 0.0;
uniform float ink_stain = 0.0;
uniform vec2 visor_water = vec2(0.0);
uniform sampler2D plate : hint_screen_texture, repeat_disable, filter_linear;

float mark(float t) {
	return 1.0-smoothstep(.10,.38,abs(fract(t)-.5));
}
void fragment() {
	vec2 uv = SCREEN_UV;
	if (visor_water.x > 0.0) {
		uv.x += visor_water.x * 0.003 * sin(uv.y * 42.0 + visor_water.y * 2.8);
	}
	vec3 c = texture(plate, uv).rgb;
	float value = dot(c, vec3(.2126,.7152,.0722));
	vec2 pix = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float weave = sin(pix.y * .029 + .54*sin(pix.x*.019));
	float stroke = mark(pix.x * .163 + pix.y * .117 + weave * .33);
	float crosshatch = mark(pix.x * -.091 + pix.y * .151 + weave*.25);
	float ink = stroke*(1.-smoothstep(.13,.43,value))*.047;
	ink += crosshatch*(1.-smoothstep(.09,.25,value))*.042;
	c = max(vec3(0.),(c-.26)*1.09+.26);
	c *= vec3(.88,.96,1.04) + smoothstep(.30,.69,value)*vec3(.14,.045,-.075);
	c = c*(1.-ink);
	float grain = fract(52.9829189 * fract(dot(floor(pix), vec2(.06711056,.00583715))))-.5;
	c += grain*(.013 - .006*value);
	float vignette = smoothstep(.24,.73,length((SCREEN_UV-.5)*vec2(.96,1.0)));
	c = mix(c, vec3(dot(c,vec3(.25,.6,.15)))*vec3(.88,.96,1.03), pressure*.20);
	// The remaining highlights let a walker find their way through the dark.
	c *= 1.0 - lamplight_lost * (.84 - .38 * smoothstep(.5, 1.0, value));
	c = mix(c, c * vec3(.46,.82,.85) + vec3(.012,.045,.055), visor_water.x);
	if (ink_stain > 0.0) {
		vec2 p = (SCREEN_UV - .5) * vec2(1.45, 1.);
		float edge = length(p) + .04 * sin(p.x * 31.) + .024 * cos(p.y * 47. + p.x * 14.);
		c = mix(c, vec3(.042,.030,.035), ink_stain * smoothstep(.36, .52, edge) * .94);
	}
	COLOR = vec4(c*(1.-(.24+.30*pressure)*vignette),1.);
}
