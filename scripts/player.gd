class_name Player
extends Node2D
## 主人公。クリックした場所へ、部屋の床と階段 (RoomNav) をたどって歩く。
## 本棚・窓・ベッドなどの場所 (spots) に着いたら Game.arrive で知らせる。
## 場面 (GameState) からアニメを決め、伝えた反応 (首をかしげる・喜ぶ等) は一度だけ再生する。
## 見た目は子の AnimatedSprite2D (art/player/player_frames.tres) を差し替えればよい。
## 座標は部屋の絵のピクセル座標 (親の World が画面上の位置へずらしている)。

const WALK_SPEED := 42.0
const ARRIVE_DIST := 5.0
const KEY_COLOR := Color("ffd47e")

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var bubble: Bubble = $Bubble

var game: Game
var nav: RoomNav

var _path := PackedVector2Array()
var _base := "idle"
var _once := ""
var _once_t := 0.0
var _question_t := 0.0
var _has_key := false
var _ended := false
var _inside: Dictionary = {}  # いま居る spot -> true (着いた瞬間だけ知らせる)


func setup(g: Game) -> void:
	game = g
	nav = RoomNav.new(g.poem["nav"])
	bubble.setup(g)
	var st: Array = g.poem.get("start", [150, 177])
	position = Vector2(st[0], st[1])
	g.state_changed.connect(_apply)
	g.fx_requested.connect(_on_fx)
	_apply()


func can_move() -> bool:
	return not _ended and _once_t <= 0.0 and bool(game.stage_def().get("can_move", true))


## 画面座標 p の近くの歩ける場所へ向かう
func walk_to_screen(p: Vector2) -> void:
	if not can_move():
		return
	var local := (get_parent() as Node2D).get_global_transform_with_canvas().affine_inverse() * p
	# 窓などクリックできる範囲 (area) を押したら、そこに一番近い立ち位置へ
	for spot in game.poem["spots"]:
		var sp: Dictionary = game.poem["spots"][spot]
		if sp.has("area"):
			var a: Array = sp["area"]
			if Rect2(a[0], a[1], a[2], a[3]).has_point(local):
				local = _nearest_point(sp["points"])
	_path = nav.find_path(position, local)


## points のうち、主人公から一番近い点
func _nearest_point(points: Array) -> Vector2:
	var best := Vector2(points[0][0], points[0][1])
	for p in points:
		var v := Vector2(p[0], p[1])
		if v.distance_to(position) < best.distance_to(position):
			best = v
	return best


## 部屋の絵の座標 → 画面座標
func room_to_screen(p: Vector2) -> Vector2:
	return (get_parent() as Node2D).get_global_transform_with_canvas() * p


## 主人公の見た目上の矩形 (画面座標)。言葉を落とす先の判定に使う
func body_screen_rect() -> Rect2:
	var o := get_global_transform_with_canvas().origin
	return Rect2(o + Vector2(-5, -14), Vector2(10, 14))


func accepts_drop(screen_p: Vector2) -> bool:
	if _ended or game.capacity() <= 0:
		return false
	return body_screen_rect().grow(10.0).has_point(screen_p) \
		or bubble.screen_rect().grow(6.0).has_point(screen_p)


func _apply() -> void:
	var st := game.stage_def()
	_ended = game.state.d["ended"]
	_base = str(st.get("player_anim", "idle"))
	_has_key = bool(st.get("has_key", false))
	if _ended:
		_base = "happy"
		_walk_to_spot(str(game.poem.get("exit", "door")))
	else:
		modulate.a = 1.0
	if not bool(st.get("can_move", true)):
		_path.clear()
	bubble.visible = game.capacity() > 0


func _walk_to_spot(spot: String) -> void:
	var pts: Array = game.poem["spots"][spot]["points"]
	_path = nav.find_path(position, Vector2(pts[0][0], pts[0][1]))


func _on_fx(ev: Dictionary) -> void:
	match ev["kind"]:
		"told_ng":
			_play_once("tilt", 1.0)
			_question_t = 1.2
		"told_ok":
			for st in game.poem["stages"]:
				if st["id"] == ev["stage"] and st.has("reaction"):
					var r: Dictionary = st["reaction"]
					_play_once(str(r.get("anim", "happy")), float(r.get("time", 1.0)))


func _play_once(anim: String, time: float) -> void:
	_once = anim
	_once_t = time
	_path.clear()


func _process(delta: float) -> void:
	var anim := _base
	if _once_t > 0.0:
		_once_t -= delta
		anim = _once
	elif not _path.is_empty():
		var to := _path[0]
		var step := WALK_SPEED * delta
		if position.distance_to(to) <= step:
			position = to
			_path.remove_at(0)
		else:
			var dir := (to - position).normalized()
			position += dir * step
			if absf(dir.x) > 0.1:
				sprite.flip_h = dir.x < 0.0
		anim = "walk"
	elif _ended and modulate.a > 0.0:
		# 扉の中へ消えていく
		modulate.a = maxf(0.0, modulate.a - delta * 0.8)
	if sprite.animation != anim and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
	_check_spots()
	_question_t = maxf(0.0, _question_t - delta)
	queue_redraw()


func _check_spots() -> void:
	for spot in game.poem["spots"]:
		var near := false
		for p in game.poem["spots"][spot]["points"]:
			if position.distance_to(Vector2(p[0], p[1])) <= ARRIVE_DIST:
				near = true
		if near and not _inside.has(spot):
			_inside[spot] = true
			game.arrive(spot)
		elif not near:
			_inside.erase(spot)


func _draw() -> void:
	if _question_t > 0.0:
		draw_string(UIConst.FONT, Vector2(3, -16), "？", HORIZONTAL_ALIGNMENT_LEFT, -1,
			UIConst.FONT_SIZE, UIConst.TEXT_COLOR)
	if _has_key or _ended:
		# 手に持った鍵
		var side := -1.0 if sprite.flip_h else 1.0
		for p in [Vector2(6, -6), Vector2(7, -6), Vector2(8, -6), Vector2(8, -5), Vector2(5, -7), Vector2(5, -5), Vector2(4, -6)]:
			draw_rect(Rect2(Vector2(p.x * side, p.y), Vector2.ONE), KEY_COLOR)
