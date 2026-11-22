shader_type canvas_item;
// 文字を Bayer ディザの閾値で 1px ずつ消す / 浮かび上がらせる。
// 途中の状態では閾値パターンが時間でずれて、画素がゆらぐ。

uniform float progress : hint_range(0.0, 1.0) = 0.0;

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

void fragment() {
	float moving = step(0.001, progress) * step(progress, 0.999);
	vec2 p = floor(FRAGCOORD.xy) + vec2(floor(TIME * 7.0), floor(TIME * 3.0)) * moving;
	if (bayer4(p) < progress) {
		discard;
	}
}
