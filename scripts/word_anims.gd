class_name WordAnims
extends RefCounted
## 言葉の意味をあらわす演出。anim id -> Callable(node, fx, r)
## node: 単語ノード (anim_offset / spread / ghost / dim を tween できる)
## fx: 粒やフラッシュの道具、 r: 単語の矩形 (画面座標)

const ASH := Color("5a5a60")
const WARM := Color("ffe2b0")
const SKY := Color("bfe4ff")
const WATER := Color("7fc8ff")
const PINK := Color("ffc6e6")
const SUN := Color("ffb45c")

var _table: Dictionary = {}


func _init() -> void:
	_table = {
		"ash": _ash, "town": _town, "paint": _paint, "wind": _wind, "blow": _blow,
		"hands": _hands, "spread": _spread, "speak": _speak, "wait": _wait,
		"move": _move, "cloud": _cloud, "beyond": _beyond, "further": _further, "dream": _dream,
		"sparkle": _sparkle, "star": _star, "river": _river, "fall": _fall,
		"light": _light, "pour": _pour, "bird": _bird, "sing": _sing,
		"bright": _bright, "morning": _morning, "hush": _hush, "future": _future, "sleep": _sleep,
	}


func play(id: String, node: WordNode, fx: FxLayer, r: Rect2) -> void:
	if _table.has(id):
		_table[id].call(node, fx, r)
	else:
		fx.burst(r, UIConst.TEXT_COLOR, 12)


# --- 1行目 -----------------------------------------------------------------

## 灰色: 灰がはらはら落ちる
func _ash(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 40:
		var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		fx.add(p, Vector2(randf_range(-6, 6), randf_range(6, 16)), randf_range(1.4, 2.4), ASH,
			{"drag": 0.0, "delay": randf() * 0.4})


## 町: 小さな家が並んで建つ
func _town(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	var n := maxi(3, int(r.size.x / 7.0) + 1)
	for i in n:
		var x := r.position.x - 6.0 + i * (r.size.x + 12.0) / n
		fx.sprite("house", Vector2(x, r.end.y + 3), Vector2(0, -6), 1.8, WARM, {"delay": i * 0.08, "drag": 3.0})


## 色: 波紋 (背景の色替えは background が受け持つ)
func _paint(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	fx.ring(r.get_center(), Color.WHITE, 24, 40.0)


## 風: 画面を横切る筋、言葉もなびく
func _wind(n: WordNode, fx: FxLayer, _r: Rect2) -> void:
	for i in 28:
		var p := Vector2(-20 - randf() * 160, randf() * UIConst.SCREEN.y)
		fx.add(p, Vector2(randf_range(240, 340), 0), 2.0, Color(1, 1, 1, 0.55),
			{"size": Vector2(randi_range(6, 16), 1), "drag": 0.0, "delay": randf() * 0.4})
	var tw := n.create_tween()
	tw.tween_property(n, "anim_offset", Vector2(4, 0), 0.2)
	tw.tween_property(n, "anim_offset", Vector2(-1, 0), 0.3)
	tw.tween_property(n, "anim_offset", Vector2.ZERO, 0.3)


## ふく: 右へ息が吹き出す
func _blow(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 7:
		var p := Vector2(r.end.x + 1, r.get_center().y - 1)
		fx.sprite("puff", p, Vector2(randf_range(40, 70), randf_range(-10, 10)), 0.9, Color(1, 1, 1, 0.8),
			{"delay": i * 0.06})


# --- 2行目 -----------------------------------------------------------------

## 両手: 言葉の両側から手がひらく
func _hands(n: WordNode, _fx: FxLayer, r: Rect2) -> void:
	var y := WordNode.mid_y() - 3.0
	for side in [-1, 1]:
		var h := PixelSpriteNode.make(["hand"], WARM, side < 0)
		var x0 := -8.0 if side < 0 else r.size.x + 2.0
		h.position = Vector2(x0, y)
		n.add_child(h)
		var tw := h.create_tween()
		tw.tween_property(h, "position:x", x0 + side * 5.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.7)
		tw.tween_property(h, "modulate:a", 0.0, 0.3)
		tw.tween_callback(h.queue_free)


## ひろげて: 文字の間がひろがる
func _spread(n: WordNode, _fx: FxLayer, _r: Rect2) -> void:
	var tw := n.create_tween()
	tw.tween_property(n, "spread", 4.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.4)
	tw.tween_property(n, "spread", 0.0, 0.4)


## 言葉: ひらがながふわふわ口からこぼれる
const KANA := "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもらりるれろ"

func _speak(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 7:
		var ch := KANA[randi() % KANA.length()]
		fx.add(r.get_center() - Vector2(6, 6), Vector2(randf_range(-30, 30), randf_range(-40, -20)), 1.4, SKY,
			{"text": ch, "delay": i * 0.1})


## まつ: 「…」が順に灯る
func _wait(n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 3:
		var p := Vector2(r.get_center().x - 7 + i * 6, r.position.y - 6)
		fx.sprite("dot", p, Vector2.ZERO, 1.6 - i * 0.35, UIConst.TEXT_COLOR, {"delay": i * 0.35})
	var tw := n.create_tween()
	tw.tween_property(n, "dim", 0.6, 0.3)
	tw.tween_interval(1.0)
	tw.tween_property(n, "dim", 0.0, 0.4)


# --- 3行目 -----------------------------------------------------------------

## 動く: ぴょこぴょこ跳ねまわる
func _move(n: WordNode, _fx: FxLayer, _r: Rect2) -> void:
	var tw := n.create_tween()
	for o in [Vector2(6, -5), Vector2(-5, -7), Vector2(4, -3), Vector2(-2, -4), Vector2.ZERO]:
		tw.tween_property(n, "anim_offset", o, 0.12).set_trans(Tween.TRANS_SINE)


## 雲: 雲がわいて流れる
func _cloud(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	fx.sprite("cloud", r.position + Vector2(-6, -9), Vector2(10, 0), 2.6, Color.WHITE, {"drag": 0.0})
	fx.sprite("cloud", r.position + Vector2(r.size.x - 2, -13), Vector2(7, 0), 2.2, Color(1, 1, 1, 0.7),
		{"drag": 0.0, "delay": 0.3})


## むこう: 向こうへ去って、反対側から戻ってくる
func _beyond(n: WordNode, _fx: FxLayer, _r: Rect2) -> void:
	var tw := n.create_tween()
	tw.tween_property(n, "anim_offset", Vector2(90, 0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): n.anim_offset = Vector2(-90, 0))
	tw.tween_property(n, "anim_offset", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## さらなる: 残像が先へ先へと重なる
func _further(n: WordNode, _fx: FxLayer, _r: Rect2) -> void:
	n.ghost_dir = 1.0
	var tw := n.create_tween()
	tw.tween_property(n, "ghost", 1.0, 0.35)
	tw.tween_interval(0.4)
	tw.tween_property(n, "ghost", 0.0, 0.5)


## 夢: 泡がゆらゆら昇る
func _dream(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 8:
		var p := Vector2(r.position.x + randf() * r.size.x, r.position.y)
		fx.sprite("bubble", p, Vector2(randf_range(-4, 4), -16), 2.0, PINK,
			{"drag": 0.0, "wave": 1.5, "delay": i * 0.15})


# --- 4行目 -----------------------------------------------------------------

## きらきら: まわりに星粒がまたたく
func _sparkle(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	fx.stars(r.grow(26.0), UIConst.HILITE_COLOR, 26)


## 星: 星が夜空へ昇ってまたたく
func _star(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	var p := r.get_center() - Vector2(2, 2)
	fx.sprite("star", p, Vector2(0, -70), 1.0, UIConst.HILITE_COLOR, {"drag": 2.5})
	fx.stars(Rect2(p + Vector2(-6, -34), Vector2(16, 10)), UIConst.HILITE_COLOR, 6, 0.6)


## 川: 足もとをさざ波が流れる
func _river(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 90:
		var p := Vector2(r.position.x - 30 + randf() * (r.size.x + 40), r.end.y + 3)
		fx.add(p, Vector2(30, 0), 1.5, WATER, {"wave": 2.0, "drag": 0.0, "delay": randf() * 0.6})


## おちる: すとんと落ちて、ぽよんと戻る
func _fall(n: WordNode, _fx: FxLayer, _r: Rect2) -> void:
	var tw := n.create_tween()
	tw.tween_property(n, "anim_offset", Vector2(0, 50), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.15)
	tw.tween_property(n, "anim_offset", Vector2.ZERO, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- 5行目 -----------------------------------------------------------------

## 光: 光線が放射状にのびる
func _light(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for k in 4:
		fx.ring(r.get_center(), Color("fff6c8"), 16, 40.0 + k * 22.0)


## そそぐ: しずくが降りそそぐ
func _pour(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 18:
		var p := Vector2(r.position.x + randf() * r.size.x, r.end.y)
		fx.sprite("drop", p, Vector2(0, 10), 1.0, WATER, {"g": 160.0, "drag": 0.0, "delay": randf() * 0.7})


## 鳥: 両側から翼が生えて、ぱたぱた飛んでいき、また戻ってくる
func _bird(n: WordNode, _fx: FxLayer, r: Rect2) -> void:
	var y := WordNode.mid_y() - 4.0
	var wings: Array = []
	for side in [-1, 1]:
		var wing := PixelSpriteNode.make(["wing_up", "wing_down"], Color.WHITE, side < 0, 10.0)
		wing.position = Vector2(-7.0 if side < 0 else r.size.x + 1.0, y)
		wing.scale = Vector2(1, 0)
		n.add_child(wing)
		wings.append(wing)
		wing.create_tween().tween_property(wing, "scale:y", 1.0, 0.2)
	var tw := n.create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(n, "anim_offset", Vector2(20, -24), 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "anim_offset", Vector2(160, -110), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): n.anim_offset = Vector2(-200, -60))
	tw.tween_property(n, "anim_offset", Vector2.ZERO, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_fold_wings.bind(wings))


func _fold_wings(wings: Array) -> void:
	for wing in wings:
		var wt := (wing as Node2D).create_tween()
		wt.tween_property(wing, "scale:y", 0.0, 0.2)
		wt.tween_callback(wing.queue_free)


## うたう: 音符がゆれて昇る
func _sing(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 5:
		var c := Color.from_hsv(randf(), 0.35, 1.0)
		fx.sprite("note", Vector2(r.end.x - 2, r.position.y), Vector2(12, -22), 1.6, c,
			{"wave": 2.0, "drag": 0.0, "delay": i * 0.25})


# --- 6行目 -----------------------------------------------------------------

## 明るい: 画面がぱっと明るくなる
func _bright(_n: WordNode, fx: FxLayer, r: Rect2) -> void:
	fx.flash(Color(1, 1, 0.92), 0.9, 0.2)
	fx.ring(r.get_center(), Color.WHITE, 40, 110.0)


## 朝: 言葉のうしろから日がのぼる
func _morning(n: WordNode, _fx: FxLayer, r: Rect2) -> void:
	var sun := PixelSpriteNode.make(["sun"], SUN)
	sun.z_index = -1
	sun.position = Vector2(roundf(r.size.x / 2.0 - 5.0), 10)
	n.add_child(sun)
	var tw := sun.create_tween()
	tw.tween_property(sun, "position:y", -6.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(sun, "modulate:a", 0.0, 0.5)
	tw.tween_callback(sun.queue_free)


## しずか: まわりがすっと暗く静まる
func _hush(n: WordNode, fx: FxLayer, _r: Rect2) -> void:
	fx.flash(Color(0.05, 0.05, 0.1), 1.4, 0.55)
	var tw := n.create_tween()
	tw.tween_property(n, "dim", 0.5, 0.4)
	tw.tween_property(n, "dim", 0.0, 0.8)


## 未来: 前へ進み、うしろに残像を引く
func _future(n: WordNode, _fx: FxLayer, _r: Rect2) -> void:
	n.ghost_dir = -1.0
	var tw := n.create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "anim_offset", Vector2(26, 0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "ghost", 1.0, 0.4)
	tw.chain().tween_interval(0.3)
	tw.chain().tween_property(n, "anim_offset", Vector2.ZERO, 0.5)
	tw.tween_property(n, "ghost", 0.0, 0.5)


## ねむる: Zzz がのぼり、言葉がうとうと
func _sleep(n: WordNode, fx: FxLayer, r: Rect2) -> void:
	for i in 3:
		fx.sprite("z", Vector2(r.end.x, r.position.y - 2), Vector2(10, -14), 1.5, SKY,
			{"drag": 0.0, "delay": i * 0.4})
	var tw := n.create_tween()
	tw.tween_property(n, "anim_offset", Vector2(0, 2), 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(n, "dim", 0.4, 0.5)
	tw.tween_interval(0.6)
	tw.tween_property(n, "anim_offset", Vector2.ZERO, 0.4)
	tw.parallel().tween_property(n, "dim", 0.0, 0.4)
