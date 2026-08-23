shader_type canvas_item;

instance uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.35, 0.35, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex;
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, hit_flash * tex.a);
	COLOR.rgb += flash_color.rgb * hit_flash * 0.25 * tex.a;
}
