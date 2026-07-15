shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D mask_tex : repeat_disable, filter_nearest;
uniform sampler2D frame_tex : repeat_disable, filter_nearest;
uniform float fill_ratio : hint_range(0.0, 1.0, 0.001);
uniform vec4 juice_color : source_color;
uniform float cavity_top : hint_range(0.0, 1.0) = 0.0;
uniform float cavity_bottom : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 mask = texture(mask_tex, UV);
	vec4 rim = texture(frame_tex, UV);
	float surface = mix(cavity_bottom, cavity_top, fill_ratio);
	bool inside = mask.a >= 0.05 && rim.a < 0.15 && UV.y >= surface;
	if (inside) {
		COLOR = vec4(juice_color.rgb, juice_color.a);
	} else {
		COLOR = vec4(0.0);
	}
}
