shader_type spatial;
render_mode unshaded, fog_disabled;
uniform sampler2D view_through : source_color, repeat_disable, filter_linear;
void fragment() {
	ALBEDO = texture(view_through, SCREEN_UV).rgb;
}
