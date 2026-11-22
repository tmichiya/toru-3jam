class_name WorldCamera
extends Camera2D
## 主人公を追う横スクロールのカメラ。主人公が画面の左寄りに来るようにする。

const LEAD := 90.0       # 主人公より右をどれだけ見せるか
const MIN_X := 240.0     # これより左へはスクロールしない
const FOLLOW_SPEED := 4.0

var player: Node2D


func setup(p: Node2D) -> void:
	player = p
	position = Vector2(_target_x(), UIConst.SCREEN.y / 2.0)
	make_current()


func _process(delta: float) -> void:
	if player == null:
		return
	var x := lerpf(position.x, _target_x(), 1.0 - exp(-delta * FOLLOW_SPEED))
	position = Vector2(roundf(x), UIConst.SCREEN.y / 2.0)


func _target_x() -> float:
	return maxf(MIN_X, player.position.x + LEAD)
