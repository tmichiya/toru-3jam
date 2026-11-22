class_name PoemBackground
extends ColorRect
## ディザのかかったグラデーション背景。色の言葉をとると、その位置から新しい色が広がる。

const WIPE_TIME := 1.6
const WIPE_MAX := 560.0

var game: Game
var view: PoemView

var _mat: ShaderMaterial
var _top := Color()
var _bottom := Color()
var _wipe_pending := false
var _floats: Dictionary = {}


func setup(g: Game, v: PoemView) -> void:
	game = g
	view = v
	_mat = material as ShaderMaterial
	g.state_changed.connect(_on_state)
	g.fx_requested.connect(_on_fx)
	_target_colors()
	_snap()


func _target_colors() -> void:
	var s := game.state
	var cur: String = s.d["color"]
	var prev: String = s.d["prev_color"]
	_top = game.palette_color(cur, 0)
	_bottom = game.palette_color(prev if prev != "" else cur, 1)


func _on_state() -> void:
	var old_top := _top
	var old_bottom := _bottom
	_target_colors()
	_tween_param("rainbow", 1.0 if game.state.d["ended"] else 0.0, 3.0)
	if old_top != _top or old_bottom != _bottom:
		# 直後に color fx が来ればワイプ、来なければ (Undo など) 即切り替え
		_wipe_pending = true
		_snap_if_no_wipe.call_deferred()


func _on_fx(ev: Dictionary) -> void:
	if ev["kind"] != "color":
		return
	_wipe_pending = false
	var center := UIConst.SCREEN / 2.0
	if not ev["uids"].is_empty():
		center = view.get_rect(ev["uids"][0]).get_center()
	_mat.set_shader_parameter("top_a", _mat.get_shader_parameter("top_b"))
	_mat.set_shader_parameter("bottom_a", _mat.get_shader_parameter("bottom_b"))
	_mat.set_shader_parameter("top_b", _top)
	_mat.set_shader_parameter("bottom_b", _bottom)
	_mat.set_shader_parameter("wipe_center", center)
	_mat.set_shader_parameter("wipe_radius", 0.0)
	var tw := create_tween()
	tw.tween_method(func(r: float): _mat.set_shader_parameter("wipe_radius", r), 0.0, WIPE_MAX, WIPE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _snap_if_no_wipe() -> void:
	if _wipe_pending:
		_wipe_pending = false
		_snap()


func _snap() -> void:
	for k in ["top_a", "top_b"]:
		_mat.set_shader_parameter(k, _top)
	for k in ["bottom_a", "bottom_b"]:
		_mat.set_shader_parameter(k, _bottom)
	_mat.set_shader_parameter("wipe_radius", WIPE_MAX)


## 未設定の uniform は get_shader_parameter が null を返すので、目標値は自前で覚える
func _tween_param(param: String, to: float, dur: float) -> void:
	var from: float = _floats.get(param, 0.0)
	if is_equal_approx(from, to):
		return
	_floats[param] = to
	create_tween().tween_method(func(v: float): _mat.set_shader_parameter(param, v), from, to, dur)
