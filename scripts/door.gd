class_name Door
extends Node2D
## 扉。show_door の場面から現れ、エンディングで開いて光がこぼれる。

const W := 18
const H := 30
const FRAME := Color("2b2b33")
const PANEL := Color("8a5a3c")
const LIGHT := Color("fff1b0")

var game: Game
var _shown := false
var _open := 0.0
var _t := 0.0


func setup(g: Game) -> void:
	game = g
	position = Vector2(float(g.poem.get("door_x", 660)), UIConst.GROUND_Y)
	modulate.a = 0.0
	g.state_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var should_show: bool = bool(game.stage_def().get("show_door", false)) or bool(game.state.d["ended"])
	if should_show != _shown:
		_shown = should_show
		create_tween().tween_property(self, "modulate:a", 1.0 if should_show else 0.0, 1.2)
	var target := 1.0 if game.state.d["ended"] else 0.0
	if not is_equal_approx(target, _open):
		create_tween().tween_property(self, "_open", target, 1.5).set_delay(0.8 if target > 0.0 else 0.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var x0 := -W / 2
	var y0 := -H
	# 開いた奥の光
	if _open > 0.0:
		draw_rect(Rect2(x0 + 1, y0 + 1, W - 2, H - 1), Color(LIGHT, _open))
		for i in 12:
			var a := TAU * i / 12.0 + _t * 0.3
			var r := 14.0 + _open * 30.0 + sin(_t * 3.0 + i) * 3.0
			draw_rect(Rect2((Vector2(0, -H / 2.0) + Vector2.from_angle(a) * r).round(), Vector2.ONE),
				Color(LIGHT, _open))
	# 扉板 (開くと横幅が縮む)
	var pw := roundf((W - 2) * (1.0 - _open * 0.85))
	draw_rect(Rect2(x0 + 1, y0 + 1, pw, H - 1), PANEL)
	if _open < 0.5:
		draw_rect(Rect2(x0 + W - 6, y0 + 15, 2, 2), Color("ffd47e"))
		draw_rect(Rect2(x0 + W - 5, y0 + 18, 1, 2), FRAME)
	# 枠
	draw_rect(Rect2(x0, y0, W, H), FRAME, false, 1.0)
