class_name RoomProps
extends Node2D
## 部屋の絵の上に重ねる小さな演出。
##  - 開いていて詩が残っている本棚・窓に、きらきらした目印
##  - エンディングで扉が開き、光がこぼれる
##  - 部屋の線を今の色 (色の言葉) に染める
##  - はじまり (hide_room の場面) は部屋ごと隠す
## 座標は部屋の絵のピクセル座標。

const MARK_COLOR := Color("fff1a0")
const LIGHT := Color("fff1b0")

const TINT := 0.45  # 部屋の線を今の色にどれだけ染めるか
const ROOM_FADE_TIME := 2.5

var game: Game
var _room_shown := true
var _tinted: Array = []  # 今の色に染める CanvasItem (部屋の絵)
var _t := 0.0
var _open := 0.0


func setup(g: Game, tinted: Array) -> void:
	game = g
	_tinted = tinted
	g.state_changed.connect(_apply)
	_room_shown = not bool(g.stage_def().get("hide_room", false))
	for item in _tinted:
		item.modulate.a = 1.0 if _room_shown else 0.0
	modulate.a = 1.0 if _room_shown else 0.0
	_apply()


func _apply() -> void:
	# はじまり (hide_room) は部屋を隠し、主人公だけが見える。泣きやむと部屋がゆっくり現れる
	var shown: bool = not bool(game.stage_def().get("hide_room", false)) or bool(game.state.d["ended"])
	var c := Color.WHITE.lerp(game.palette_color(game.state.d["color"], 0), TINT)
	c.a = 1.0 if shown else 0.0
	var dur := ROOM_FADE_TIME if shown != _room_shown else 1.0
	_room_shown = shown
	for item in _tinted:
		create_tween().tween_property(item, "modulate", c, dur)
	create_tween().tween_property(self, "modulate:a", c.a, dur)
	var target := 1.0 if game.state.d["ended"] else 0.0
	if not is_equal_approx(target, _open):
		var tw := create_tween()
		if target > 0.0:
			tw.tween_interval(1.0)
		tw.tween_property(self, "_open", target, 1.5)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for spot in game.poem["spots"]:
		if game.spot_has_poem(spot):
			var sp: Dictionary = game.poem["spots"][spot]
			var m: Array = sp.get("mark", sp["points"][0])
			_draw_mark(Vector2(m[0], m[1]))
			if sp.has("area"):
				# 窓など広い場所: 枠を点滅させ、立つ場所 (階段の上) に下向きの矢印
				var a: Array = sp["area"]
				_draw_dotted_rect(Rect2(a[0], a[1], a[2], a[3]))
				for p in sp["points"]:
					_draw_arrow(Vector2(p[0], p[1] - 22))
	if _open > 0.0:
		var r: Array = game.poem.get("door_light", [227, 88, 16, 17])
		var rect := Rect2(r[0], r[1], r[2], r[3])
		draw_rect(rect, Color(LIGHT, _open))
		for i in 14:
			var a := TAU * i / 14.0 + _t * 0.3
			var dist := 10.0 + _open * 22.0 + sin(_t * 3.0 + i) * 3.0
			draw_rect(Rect2((rect.get_center() + Vector2.from_angle(a) * dist).round(), Vector2.ONE), Color(LIGHT, _open))


## 点線の枠。点が流れるように動く
func _draw_dotted_rect(r: Rect2) -> void:
	var phase := int(_t * 8.0) % 3
	var c := MARK_COLOR
	for x in range(int(r.position.x), int(r.end.x)):
		if (x + phase) % 3 != 0:
			draw_rect(Rect2(x, r.position.y, 1, 1), c)
			draw_rect(Rect2(x, r.end.y, 1, 1), c)
	for y in range(int(r.position.y), int(r.end.y)):
		if (y + phase) % 3 != 0:
			draw_rect(Rect2(r.position.x, y, 1, 1), c)
			draw_rect(Rect2(r.end.x, y, 1, 1), c)


## 下向きの矢印 (ここに立つ)。ぴょこぴょこ跳ねる
func _draw_arrow(p: Vector2) -> void:
	var y := roundf(absf(sin(_t * 4.0)) * -3.0)
	var rows := ["#####", ".###.", "..#.."]
	for i in rows.size():
		for x in 5:
			if rows[i][x] == "#":
				draw_rect(Rect2(p + Vector2(x - 2, i + y), Vector2.ONE), MARK_COLOR)


## ふわふわ上下しながら瞬く星の目印
func _draw_mark(c: Vector2) -> void:
	var y := roundf(sin(_t * 3.0) * 1.5)
	var p := c + Vector2(0, y)
	var arm := 2 if int(_t * 4.0) % 2 == 0 else 1
	draw_rect(Rect2(p, Vector2.ONE), MARK_COLOR)
	for i in range(1, arm + 1):
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_rect(Rect2(p + dir * i, Vector2.ONE), Color(MARK_COLOR, 1.0 if i == 1 else 0.6))
