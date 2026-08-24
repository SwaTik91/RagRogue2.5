shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;
uniform float mist_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec4 mist_color : source_color = vec4(0.55, 0.72, 0.88, 1.0);
uniform float warmth : hint_range(-0.2, 0.2) = 0.06;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	c.r += warmth * 0.08;
	c.b -= warmth * 0.04;
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - 0.5;
	float dist = length(centered);
	float vignette = smoothstep(0.85, 0.25, dist);
	c *= mix(1.0, vignette, vignette_strength);
	float mist_wave = sin(uv.y * 8.0 + TIME * 0.35) * 0.04;
	float mist = smoothstep(0.15, 0.95, uv.y + mist_wave) * mist_strength;
	c = mix(c, mist_color.rgb, mist * 0.35);
	COLOR = vec4(c, 1.0);
}
