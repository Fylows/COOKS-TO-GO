shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D frame_tex : repeat_disable, filter_nearest;
uniform vec4 tap_uv_rect = vec4(0.72, 0.58, 1.0, 0.8);
uniform int layer_mode = 0;

void fragment() {
	vec4 c = texture(frame_tex, UV);
	bool in_tap = UV.x >= tap_uv_rect.x && UV.x <= tap_uv_rect.z
		&& UV.y >= tap_uv_rect.y && UV.y <= tap_uv_rect.w;
	if (layer_mode == 1 && in_tap) {
		c = vec4(0.0);
	} else if (layer_mode == 2 && !in_tap) {
		c = vec4(0.0);
	}
	COLOR = c;
}
