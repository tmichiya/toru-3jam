class_name Player
extends Node2D
## 主人公。場面 (GameState) から「どこに立って、どのアニメか」を決めて演じる。
## 伝えたときの反応 (首をかしげる・喜ぶ等) は fx event を受けて一度だけ再生する。
## 見た目は子の AnimatedSprite2D (art/player/player_frames.tres) を差し替えればよい。

const WALK_SPEED := 50.0
const KEY_COLOR := Color("ffd47e")

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var bubble: Bubble = $Bubble

var game: Game

var _target_x := 0.0
var _base := "idle"
var _once := ""
var _once_t := 0.0
var _question_t := 0.0
var _has_key := false
var _ended := false


func setup(g: Game) -> void:
	game = g
	bubble.setup(g)
	g.state_changed.connect(_apply)
	g.fx_requested.connect(_on_fx)
	_apply()
	position = Vector2(_target_x, UIConst.GROUND_Y)


## 主人公の見た目上の矩形 (画面座標)。言葉を落とす先の判定に使う
func body_screen_rect() -> Rect2:
	var o := get_global_transform_with_canvas().origin
	return Rect2(o + Vector2(-8, -24), Vector2(16, 24))


func accepts_drop(screen_p: Vector2) -> bool:
	if _ended:
		return false
	return body_screen_rect().grow(8.0).has_point(screen_p) \
		or bubble.screen_rect().grow(6.0).has_point(screen_p)


func _apply() -> void:
	var st := game.stage_def()
	_ended = game.state.d["ended"]
	_target_x = float(st.get("player_x", 150))
	_base = str(st.get("player_anim", "idle"))
	_has_key = bool(st.get("has_key", false))
	if _ended:
		_target_x = float(game.poem.get("door_x", _target_x))
		_base = "happy"
	else:
		modulate.a = 1.0
	bubble.visible = not _ended


func _on_fx(ev: Dictionary) -> void:
	match ev["kind"]:
		"told_ng":
			_play_once("tilt", 1.0)
			_question_t = 1.2
		"told_ok":
			for st in game.poem["stages"]:
				if st["id"] == ev["stage"]:
					var r: Dictionary = st.get("reaction", {})
					_play_once(str(r.get("anim", "happy")), float(r.get("time", 1.0)))


func _play_once(anim: String, time: float) -> void:
	_once = anim
	_once_t = time


func _process(delta: float) -> void:
	var anim := _base
	var dx := _target_x - position.x
	if _once_t > 0.0:
		_once_t -= delta
		anim = _once
	elif absf(dx) > 0.5:
		position.x += signf(dx) * minf(absf(dx), WALK_SPEED * delta)
		anim = "walk"
		sprite.flip_h = dx < 0.0
	elif _ended and modulate.a > 0.0:
		# 扉の中へ消えていく
		modulate.a = maxf(0.0, modulate.a - delta * 0.8)
	if not _ended and absf(dx) <= 0.5:
		sprite.flip_h = false
	if sprite.animation != anim and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
	_question_t = maxf(0.0, _question_t - delta)
	queue_redraw()


func _draw() -> void:
	if _question_t > 0.0:
		draw_string(UIConst.FONT, Vector2(6, -22), "？", HORIZONTAL_ALIGNMENT_LEFT, -1,
			UIConst.FONT_SIZE, UIConst.TEXT_COLOR)
	if _has_key or _ended:
		# 手に持った鍵
		for p in [Vector2(9, -10), Vector2(10, -10), Vector2(11, -10), Vector2(12, -10),
				Vector2(12, -9), Vector2(10, -9), Vector2(8, -11), Vector2(8, -9), Vector2(7, -10)]:
			draw_rect(Rect2(p, Vector2.ONE), KEY_COLOR)
