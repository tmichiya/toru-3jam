shader_type canvas_item;
// 画面全体の彩度。0 でグレイスケール、1 で元の色。

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(l), c, saturation), 1.0);
}
