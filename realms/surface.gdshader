shader_type spatial;
#include "res://architecture/relief.gdshaderinc"
uniform vec4 tint : source_color;
uniform int kind = 0;
uniform float metalness = 0.0;
uniform float glow = 0.0;
uniform sampler2D grain : repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 p;
varying vec3 n;
void vertex(){
	p=mat3(MODEL_MATRIX)*VERTEX+INSTANCE_CUSTOM.xyz;
	n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment(){
	vec3 normal_axis=abs(normalize(n));
	vec2 uv=normal_axis.y>max(normal_axis.x,normal_axis.z) ? p.xz : (normal_axis.x>normal_axis.z ? p.zy : p.xy);
	vec3 fleck=texture(grain,uv*.34).rgb;
	float stain=texture(grain,uv*.099).r;
	vec3 c=tint.rgb * COLOR.rgb;
	float gloss=.84;
	if(kind==0){
		// Coursed tidal concrete darkens below the salt and growth lines.
		float band=smoothstep(.33,.65,sin(p.y*4.27+stain*.30)*.5+.5);
		float salt=1.-smoothstep(.12,.68,abs(p.y-.35-fleck.r*.34));
		float moss=(1.-smoothstep(-.15,1.6,p.y+stain*1.4-1.2))*smoothstep(.28,.64,stain);
		c*=.68+.39*fleck.r+.23*stain+.11*band;
		c=mix(c,c*.35+vec3(.012,.057,.035),moss*.88);
		c+=vec3(.12,.16,.13)*salt*.79;
		gloss=mix(.82,.35,moss);
	}else if(kind==1){
		// Tightly grained wet timber in short slats.
		float fibers=texture(grain,uv*vec2(.7,4.3)).g;
		c*=.61+fibers*.35+.57*fleck.r;
		gloss=.46;
	}else if(kind==2){
		float oxide=smoothstep(.47,.72,stain+fleck.r*.1);
		c=mix(c,vec3(.15,.068,.032),oxide*.56);
		c*=.71+.60*fleck.r;
		gloss=.50;
	}else if(kind==3){
		float seam_x=abs(fract(uv.x/2.)-.5);
		float seam_y=abs(fract(uv.y/2.)-.5);
		float join=smoothstep(.475,.500,max(seam_x,seam_y));
		c*= (.80+.30*stain)*(1.-join*.36);
		gloss=.42;
	}else if(kind==4){
		float band=sin(p.y*4.7+stain*4.+sin(p.x*.75)*1.3)*.5+.5;
		c*=.50+.48*fleck.r+.64*band;
		gloss=.83;
	}else{
		gloss=.49;
	}
	vec3 cuts = texture(grain,uv*1.8).rgb;
	float pits = smoothstep(.42,.83,cuts.b);
	NORMAL = relief_normal(VERTEX,normalize(NORMAL),.024*fleck.r + .008*cuts.g - .021*pits);
	ALBEDO=c*(1.-.36*pits);
	METALLIC=metalness;
	ROUGHNESS=gloss;
	EMISSION=c*glow;
}
