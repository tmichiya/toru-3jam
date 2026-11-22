class_name SaturationPost
extends ColorRect
## 画面全体の彩度を場面の進みに合わせて上げる (はじめはグレイスケール)。

const FADE_TIME := 2.5

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


func _target() -> float:
	if game.state.d["ended"]:
		return 1.0
	return float(game.stage_def().get("saturation", 0.0))


func _apply() -> void:
	var to := _target()
	if is_equal_approx(to, _value):
		return
	var from := _value
	_value = to
	create_tween().tween_method(func(v: float): _mat.set_shader_parameter("saturation", v), from, to, FADE_TIME)
