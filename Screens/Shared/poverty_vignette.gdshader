shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv / vec2(0.5, 0.5));
	float edge = smoothstep(0.42, 1.1, dist);
	float alpha = edge * intensity * 0.9;
	vec3 black = vec3(0.0);
	vec3 red_tint = vec3(0.42, 0.02, 0.02);
	vec3 color = mix(black, red_tint, edge * 0.35 + intensity * 0.08);
	COLOR = vec4(color, alpha);
}
