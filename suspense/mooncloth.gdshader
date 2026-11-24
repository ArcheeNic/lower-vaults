shader_type spatial;
render_mode cull_disabled;
uniform vec4 pigment : source_color = vec4(.32,.31,.28,1.0);
uniform float metal = .0;
uniform float grain = .8;

#include "res://architecture/relief.gdshaderinc"
uniform sampler2D weathering : repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec3 axis = abs(local_normal);
	vec2 uv = axis.y > max(axis.x,axis.z) ? local_pos.xz : (axis.x > axis.z ? local_pos.zy : local_pos.xy);
	vec3 wear = texture(weathering,uv*2.7).rgb;
	float thread = sin(uv.x*980.)*sin(uv.y*830.)*(1.-smoothstep(.001,.006,length(fwidth(uv))));
	float scratch = smoothstep(.42,.73,texture(weathering,uv*vec2(7.5,1.1)).b);
	float patina = smoothstep(.38,.65,wear.r)*scratch;
	ALBEDO = pigment.rgb * (.70+.60*wear.r+.09*thread);
	ALBEDO = mix(ALBEDO,vec3(.115,.061,.032),metal*patina);
	METALLIC = metal*(1.-patina*.65);
	ROUGHNESS = clamp(grain+.24*(wear.r-.5)-.21*metal*(1.-patina),.19,.96);
	NORMAL = relief_normal(VERTEX,normalize(NORMAL),.003*wear.g+.00035*thread-.002*scratch);
}
