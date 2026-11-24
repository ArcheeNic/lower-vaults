shader_type spatial;
#include "res://architecture/relief.gdshaderinc"
#include "res://architecture/room_axes.gdshaderinc"
uniform sampler2D patina : repeat_enable, filter_linear_mipmap;
uniform vec4 paint : source_color;
uniform bool decking = false;
varying vec3 pos;
varying vec3 face;
void vertex() {
	pos = room_axes((MODEL_MATRIX * vec4(VERTEX, 1.)).xyz);
	face = room_axes(normalize(MODEL_NORMAL_MATRIX * NORMAL));
}
void fragment() {
	vec3 n = abs(face);
	vec2 uv = n.y > max(n.x,n.z) ? pos.xz : (n.x > n.z ? pos.zy : pos.xy);
	float stain = texture(patina,uv*.09).r;
	float pores = texture(patina,uv*.72).g;
	float wear = smoothstep(.48,.78,stain*.73+pores*.27);
	vec3 c = paint.rgb * (0.62+pores*.50+stain*.20);
	c = mix(c, vec3(.24,.123,.047), wear*.39);
	if (decking && n.y > .75) {
		vec2 bars = abs(fract(uv*vec2(4.,2.)+.5)-.5);
		vec2 aa = max(fwidth(uv)*vec2(4.,2.),vec2(.012));
		vec2 slot = smoothstep(vec2(.12,.065)-aa,vec2(.12,.065)+aa,bars);
		c *= 1.-.78*slot.x*slot.y;
	}
	vec2 panel = abs(fract(uv/vec2(1.8,2.5))-.5) * vec2(1.8,2.5);
	vec2 rim = vec2(.9,1.25)-panel;
	float joint = smoothstep(.004,.024,min(rim.x,rim.y));
	float bolt = 1.-smoothstep(.032,.048,length(rim-.085));
	c *= (.65+.35*joint)*(1.+.33*bolt);
	NORMAL = relief_normal(VERTEX,normalize(NORMAL),.022*joint+.019*bolt+.014*wear+.013*pores);
	ALBEDO = c;
	ROUGHNESS = mix(.49,.85,wear);
	METALLIC = .64;
}
