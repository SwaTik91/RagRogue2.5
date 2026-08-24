shader_type canvas_item;

uniform float fog_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 fog_color : source_color = vec4(0.62, 0.78, 0.9, 0.55);

void fragment() {
	vec2 uv = UV;
	float edge = max(abs(uv.x - 0.5) * 2.0, abs(uv.y - 0.5) * 2.0);
	float fog = smoothstep(0.35, 1.0, edge);
	float pulse = sin(TIME * 0.25) * 0.03;
	COLOR = fog_color;
	COLOR.a = (fog + pulse) * fog_strength * fog_color.a;
}
