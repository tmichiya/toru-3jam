class_name RoomProps
extends Node2D
## 部屋の絵の上に重ねる小さな演出。
##  - 開いていて詩が残っている本棚・窓に、きらきらした目印
##  - エンディングで扉が開き、光がこぼれる
## 座標は部屋の絵のピクセル座標。

const MARK_COLOR := Color("fff1a0")
const LIGHT := Color("fff1b0")

var game: Game
var _t := 0.0
var _open := 0.0


func setup(g: Game) -> void:
	game = g
	g.state_changed.connect(_apply)


func _apply() -> void:
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
	if _open > 0.0:
		var r: Array = game.poem.get("door_light", [227, 88, 16, 17])
		var rect := Rect2(r[0], r[1], r[2], r[3])
		draw_rect(rect, Color(LIGHT, _open))
		for i in 14:
			var a := TAU * i / 14.0 + _t * 0.3
			var dist := 10.0 + _open * 22.0 + sin(_t * 3.0 + i) * 3.0
			draw_rect(Rect2((rect.get_center() + Vector2.from_angle(a) * dist).round(), Vector2.ONE), Color(LIGHT, _open))


## ふわふわ上下しながら瞬く星の目印
func _draw_mark(c: Vector2) -> void:
	var y := roundf(sin(_t * 3.0) * 1.5)
	var p := c + Vector2(0, y)
	var arm := 2 if int(_t * 4.0) % 2 == 0 else 1
	draw_rect(Rect2(p, Vector2.ONE), MARK_COLOR)
	for i in range(1, arm + 1):
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_rect(Rect2(p + dir * i, Vector2.ONE), Color(MARK_COLOR, 1.0 if i == 1 else 0.6))
