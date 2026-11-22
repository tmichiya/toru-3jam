class_name SaturationPost
extends ColorRect
## 画面全体の彩度を場面の進みに合わせて上げる (はじめはグレイスケール)。

const FADE_TIME := 1.6

var game: Game
var _mat: ShaderMaterial
var _value := 0.0


func setup(g: Game) -> void:
	game = g
	_mat = material as ShaderMaterial
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.state_changed.connect(_apply)
	_value = _target()
	_mat.set_shader_parameter("saturation", _value)


## 場面の彩度 + 色の言葉を選んでいる間は color_boost だけ色が濃くなる
func _target() -> float:
	if game.state.d["ended"]:
		return 1.0
	var v := float(game.stage_def().get("saturation", 0.0))
	if game.state.d["color"] != "gray":
		v += float(game.poem.get("color_boost", 0.0))
	return clampf(v, 0.0, 1.0)


func _apply() -> void:
	var to := _target()
	if is_equal_approx(to, _value):
		return
	var from := _value
	_value = to
	create_tween().tween_method(func(v: float): _mat.set_shader_parameter("saturation", v), from, to, FADE_TIME)
