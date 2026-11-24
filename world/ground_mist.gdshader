shader_type fog;
uniform sampler2D strata : repeat_enable, filter_linear;
uniform float density = .042;
uniform vec4 mist_color : source_color = vec4(.55,.63,.69,1.);
void fog(){
	vec2 p=WORLD_POSITION.xz;
	float broad=textureLod(strata,p*.019+vec2(TIME*.0009,-TIME*.00051),0.).r;
	float ribbons=textureLod(strata,p*vec2(.032,.102)+vec2(-TIME*.0012,TIME*.00034),0.).g;
	float under=1.-smoothstep(.30,.86,UVW.y+(ribbons-.5)*.60);
	vec3 edge=min(UVW,1.-UVW);
	float rim=smoothstep(0.,.13,min(edge.x,edge.z))*smoothstep(0.,.19,UVW.y);
	DENSITY=density*smoothstep(.30,.68,broad*.65+ribbons*.35)*under*rim;
	ALBEDO=mist_color.rgb;
}
