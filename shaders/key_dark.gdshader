shader_type canvas_item;
// 暗い地の色を透明にして、白い線と星だけを残す (背景の色が透けて見えるように)。

uniform float threshold = 0.12;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float v = max(c.r, max(c.g, c.b));
	COLOR = vec4(c.rgb, c.a * step(threshold, v));
}
