shader_type canvas_item;
// 上下グラデーション + 円形ワイプ + Bayer ディザで減色した背景。
// a = 古い色, b = 新しい色。wipe_center から wipe_radius の内側が b になる。

uniform vec4 top_a : source_color = vec4(0.55, 0.55, 0.56, 1.0);
uniform vec4 bottom_a : source_color = vec4(0.3, 0.3, 0.32, 1.0);
uniform vec4 top_b : source_color = vec4(0.55, 0.55, 0.56, 1.0);
uniform vec4 bottom_b : source_color = vec4(0.3, 0.3, 0.32, 1.0);
uniform vec2 wipe_center = vec2(240.0, 135.0);
uniform float wipe_radius = 600.0;
uniform float brightness = 0.0;
uniform float rainbow = 0.0;
uniform float levels = 7.0;
uniform vec2 screen_size = vec2(480.0, 270.0);

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	return (BAYER[x + y * 4] + 0.5) / 16.0;
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 px = floor(UV * screen_size);
	float th = bayer4(px);
	// ゆっくり揺れる水平の波でグラデーションに表情をつける
	float t = clamp(px.y / screen_size.y + sin(px.x * 0.02 + TIME * 0.4) * 0.03, 0.0, 1.0);

	vec3 ca = mix(top_a.rgb, bottom_a.rgb, t);
	vec3 cb = mix(top_b.rgb, bottom_b.rgb, t);
	float edge = clamp((wipe_radius - distance(px, wipe_center)) / 32.0 + 0.5, 0.0, 1.0);
	vec3 col = edge > th ? cb : ca;

	col += brightness;
	if (rainbow > 0.0) {
		float h = fract(t * 0.7 + px.x / screen_size.x * 0.25 - TIME * 0.04);
		col = mix(col, hsv2rgb(vec3(h, 0.4, 0.97)), rainbow * 0.75);
	}
	col = floor(clamp(col, 0.0, 1.0) * levels + th) / levels;
	COLOR = vec4(col, 1.0);
}
