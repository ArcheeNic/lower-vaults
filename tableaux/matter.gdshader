shader_type spatial;
#include "res://architecture/relief.gdshaderinc"
#include "res://architecture/room_axes.gdshaderinc"
uniform sampler2D mineral : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 pigment : source_color = vec4(.5,.5,.5,1.);
uniform float metallic = .0;
uniform float roughness = .85;
uniform float emission = .0;
uniform int surface = 0;
varying vec3 pos;
varying vec3 face;
void vertex(){
	pos = room_axes((MODEL_MATRIX * vec4(VERTEX,1.)).xyz);
	face = room_axes(normalize(MODEL_NORMAL_MATRIX*NORMAL));
}
void fragment(){
	vec3 n=abs(face);
	vec2 uv=n.y>max(n.x,n.z)?pos.xz:(n.x>n.z?pos.zy:pos.xy);
	vec3 dust=texture(mineral,uv*.21).rgb;
	float stain=texture(mineral,uv*.051).r;
	float tone=.69+.37*dust.r+.24*stain;
	vec3 chips = texture(mineral,uv*1.52).rgb;
	float pit = smoothstep(.48,.78,chips.b);
	float relief = .025*dust.r + .008*chips.g - .016*pit;
	tone *= 1.-.37*pit;
	if(surface==1){
		vec2 brick=uv/vec2(1.74,.81);
		brick.x+=.5*mod(floor(brick.y),2.);
		vec2 edge=min(fract(brick),1.-fract(brick));
		relief += .024*smoothstep(.003,.037,min(edge.x,edge.y));
		tone*=mix(.61,1.,smoothstep(.004,.028,min(edge.x,edge.y)));
	} else if(surface==2){
		vec2 board=uv/vec2(.34,2.8);
		board.y+=fract(sin(floor(board.x)*97.)*735.34);
		vec2 edge=min(fract(board),1.-fract(board));
		float joint=smoothstep(.003,.024,min(edge.x,edge.y));
		float fibres=sin(uv.x*29.+stain*14.+dust.r*2.);
		relief += .017*joint + .004*fibres;
		tone*=(.87+.13*fibres)*mix(.45,1.,joint);

	} else if(surface==5 && face.y>.85){
		// Broad dressed flags. Keep the joints legible across the whole court
		// and fade their contrast once they become smaller than a pixel.
		vec2 flag = uv / vec2(2.7, 1.45);
		flag.x += .5 * mod(floor(flag.y), 2.);
		vec2 edges = min(fract(flag), 1.-fract(flag)) * vec2(2.7, 1.45);
		float joint_distance = min(edges.x, edges.y);
		float pixel = max(max(fwidth(uv.x), fwidth(uv.y)), .002);
		float joint = 1. - smoothstep(.014, .045 + pixel, joint_distance);
		joint *= .045 / (.045 + pixel);
		float variation = fract(sin(dot(mod(floor(flag), 127.), vec2(43.1, 19.7))) * 157.3);
		tone *= (.84 + .19 * variation) * (1.-.48 * joint);
		relief -= .024 * joint;
	} else if(surface==3){
		vec2 plate = fract(uv / vec2(1.2,2.4)) * vec2(1.2,2.4);
		vec2 edge = min(plate,vec2(1.2,2.4)-plate);
		float seam = smoothstep(.003,.021,min(edge.x,edge.y));
		float bolt = 1.-smoothstep(.025,.044,length(edge-vec2(.085)));
		relief += .014*seam + .018*bolt;
		tone *= (.72+.28*seam) * (1.+.32*bolt);
		if(n.y>.85){
			vec2 checker=uv*vec2(6.,9.);
			vec2 d=abs(fract(checker+.5)-.5);
			float emboss=1.-smoothstep(.30,.46,d.x+d.y*1.85);
			tone*=.86+.29*emboss;
		}
	}
	NORMAL=relief_normal(VERTEX,normalize(NORMAL),relief);
	ALBEDO=pigment.rgb*tone;
	METALLIC=metallic;
	ROUGHNESS=clamp(roughness+.13*(dust.r-.5),.05,1.);
	EMISSION=pigment.rgb*emission*(.6+.4*dust.r);
}
