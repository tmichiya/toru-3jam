class_name Bubble
extends Node2D
## 主人公の頭上の吹き出し。伝えられる語数ぶんの枠があり、渡された言葉が並ぶ。

const SLOT_MIN := 24.0
const SLOT_GAP := 4.0
const PAD := 4.0
const BG := Color("f4f1ea")
const INK := Color("2b2b33")

var game: Game


func setup(g: Game) -> void:
	game = g


## 枠の矩形 (ローカル座標)。吹き出しの下端が y = 0
func slot_rects() -> Array:
	var msg := game.state.message()
	var n := game.capacity()
	var widths: Array = []
	var total := SLOT_GAP * (n - 1)
	for i in n:
		var w := SLOT_MIN
		if i < msg.size():
			w = maxf(SLOT_MIN, UIConst.text_width(game.state.word_by_uid(msg[i])["t"]) + 4.0)
		widths.append(w)
		total += w
	var h := UIConst.text_height() + 2.0
	var x := roundf(-total / 2.0)
	var rects: Array = []
	for w in widths:
		rects.append(Rect2(x, -h - PAD, w, h))
		x += w + SLOT_GAP
	return rects


func frame_rect() -> Rect2:
	var rs := slot_rects()
	var r: Rect2 = rs[0]
	for s in rs:
		r = r.merge(s)
	return r.grow(PAD)


func screen_rect() -> Rect2:
	var r := frame_rect()
	return Rect2(get_global_transform_with_canvas() * r.position, r.size)


## 画面座標 p にある吹き出しの言葉の uid。なければ -1
func uid_at(screen_p: Vector2) -> int:
	if not visible:
		return -1
	var local := get_global_transform_with_canvas().affine_inverse() * screen_p
	var msg := game.state.message()
	var rs := slot_rects()
	for i in mini(rs.size(), msg.size()):
		if (rs[i] as Rect2).grow(2.0).has_point(local):
			return msg[i]
	return -1


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var f := frame_rect()
	f.position = f.position.round()
	draw_rect(f, BG)
	draw_rect(f, INK, false, 1.0)
	# しっぽ
	for i in 3:
		draw_rect(Rect2(-1 + i, f.end.y + i, 3 - i * 1, 1), BG if i < 2 else INK)
	var msg := game.state.message()
	var rs := slot_rects()
	for i in rs.size():
		var r: Rect2 = rs[i]
		if i < msg.size():
			var t: String = game.state.word_by_uid(msg[i])["t"]
			var x := r.position.x + roundf((r.size.x - UIConst.text_width(t)) / 2.0)
			draw_string(UIConst.FONT, Vector2(x, r.position.y + 1 + UIConst.FONT.get_ascent(UIConst.FONT_SIZE)),
				t, HORIZONTAL_ALIGNMENT_LEFT, -1, UIConst.FONT_SIZE, INK)
		else:
			# 空き枠は点線
			for x in range(int(r.position.x), int(r.end.x), 2):
				draw_rect(Rect2(x, r.end.y - 2, 1, 1), Color(INK, 0.5))
