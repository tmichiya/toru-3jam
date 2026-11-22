class_name FxLayer
extends Node2D
## ドット粒・小さなドット絵の演出。fx event を受けて粒を出し、_draw で 1px 単位に描く。
## 言葉の意味の演出は WordAnims に任せ、ここは道具 (粒・フラッシュ) を提供する。

const MAX_PARTICLES := 2000
const DISSOLVE := preload("res://shaders/dissolve.gdshader")

var game: Game
var view: PoemView
var player: Player
var anims := WordAnims.new()

var _ps: Array = []
var _flash: ColorRect
var _flash_mat: ShaderMaterial


func setup(g: Game, v: PoemView, p: Player) -> void:
	game = g
	view = v
	player = p
	z_index = 20
	_flash = ColorRect.new()
	_flash.size = UIConst.SCREEN
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = DISSOLVE
	_flash_mat.set_shader_parameter("progress", 1.0)
	_flash.material = _flash_mat
	add_child(_flash)
	g.fx_requested.connect(_on_fx)


func _on_fx(ev: Dictionary) -> void:
	var uids: Array = ev["uids"]
	match ev["kind"]:
		"anim":
			for uid in uids:
				var node := view.get_word_node(uid)
				if node:
					anims.play(ev["anim"], node, self, view.get_rect(uid))
		"collect":
			# 本棚から詩が舞い上がって、その詩が並ぶ場所へ
			var m: Array = game.poem["spots"][ev["spot"]].get("mark", game.poem["spots"][ev["spot"]]["points"][0])
			var from := player.room_to_screen(Vector2(m[0], m[1]))
			var dest: Array = game.poem.get("poem_layout", {}).get(ev["poem"], [240, 20])
			for i in 24:
				var to := Vector2(dest[0], dest[1] + 20)
				add(from, (to - from) * randf_range(1.2, 1.8) + Vector2(randf_range(-30, 30), randf_range(-30, 30)),
					randf_range(0.6, 1.0), UIConst.HILITE_COLOR, {"star": i % 3 == 0, "drag": 2.0, "delay": i * 0.02})
			ring(from, Color.WHITE, 24, 50.0)
		"transform":
			# 色が混ざったら、できた色の波紋
			if ev.get("tool", "") == "mix":
				for uid in uids:
					var w := game.state.word_by_uid(uid)
					if not w.is_empty():
						ring(view.get_rect(uid).get_center(), game.palette_color(str(w["arg"]), 0), 36, 60.0)
		"give":
			stars(player.bubble.screen_rect().grow(4.0), UIConst.HILITE_COLOR, 6)
		"color":
			var c := game.palette_color(ev["color"], 0)
			for uid in uids:
				ring(view.get_rect(uid).get_center(), c, 48, 70.0)
		"told_ok":
			var r := player.body_screen_rect()
			stars(r.grow(16.0), UIConst.HILITE_COLOR, 20)
			ring(r.get_center(), Color.WHITE, 40, 80.0)
		"ending":
			var r := player.body_screen_rect()
			burst(r.grow(10.0), UIConst.HILITE_COLOR, 80)
			ring(r.get_center(), Color.WHITE, 80, 160.0)
			flash(Color.WHITE, 1.2, 0.3)


func _process(delta: float) -> void:
	if game.state.d["ended"] and randf() < 20.0 * delta:
		var p := Vector2(randf() * UIConst.SCREEN.x, randf() * UIConst.SCREEN.y)
		add(p, Vector2(0, -4), randf_range(0.6, 1.6), Color.from_hsv(randf(), 0.35, 1.0), {"star": true})
	for i in range(_ps.size() - 1, -1, -1):
		var pt: Dictionary = _ps[i]
		if pt["delay"] > 0.0:
			pt["delay"] -= delta
			continue
		pt["life"] -= delta
		if pt["life"] <= 0.0:
			_ps.remove_at(i)
			continue
		pt["age"] += delta
		var v: Vector2 = pt["v"]
		v.y += pt["g"] * delta
		pt["p"] += v * delta
		pt["v"] = v * maxf(0.0, 1.0 - pt["drag"] * delta)
	queue_redraw()


func _draw() -> void:
	for pt in _ps:
		if pt["delay"] > 0.0:
			continue
		var k: float = pt["life"] / pt["max"]
		# 消えかけはチラつかせる (ドット絵っぽい点滅)
		if k < 0.3 and int(pt["life"] * 30.0) % 2 == 0:
			continue
		var p: Vector2 = pt["p"]
		if pt["wave"] > 0.0:
			p.y += sin(p.x * 0.25 + pt["age"] * 3.0) * pt["wave"]
		p = p.round()
		var c: Color = pt["c"]
		if pt["text"] != "":
			draw_string(UIConst.FONT, p + Vector2(0, UIConst.FONT.get_ascent(UIConst.FONT_SIZE)), pt["text"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, UIConst.FONT_SIZE, c)
		elif pt["rows"] != null:
			PixelSprites.draw_rows(self, pt["rows"], p, c, pt["flip"])
		elif pt["star"]:
			var arm := 1 if k < 0.5 else 2
			draw_rect(Rect2(p, Vector2.ONE), c)
			for i in range(1, arm + 1):
				var cc := Color(c, 0.6 if i == arm else 1.0)
				for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
					draw_rect(Rect2(p + dir * i, Vector2.ONE), cc)
		else:
			draw_rect(Rect2(p, pt["size"]), c)


## 粒をひとつ足す。opts: size(Vector2) star rows(PackedStringArray) text g wave delay drag flip
func add(p: Vector2, v: Vector2, life: float, c: Color, opts: Dictionary = {}) -> void:
	if _ps.size() >= MAX_PARTICLES:
		return
	_ps.append({
		"p": p, "v": v, "life": life, "max": life, "c": c, "age": 0.0,
		"size": opts.get("size", Vector2.ONE),
		"star": opts.get("star", false),
		"rows": opts.get("rows", null),
		"text": opts.get("text", ""),
		"g": opts.get("g", 0.0),
		"wave": opts.get("wave", 0.0),
		"delay": opts.get("delay", 0.0),
		"drag": opts.get("drag", 1.8),
		"flip": opts.get("flip", false),
	})


func sprite(name: String, p: Vector2, v: Vector2, life: float, c: Color, opts: Dictionary = {}) -> void:
	var o := opts.duplicate()
	o["rows"] = PixelSprites.get_rows(name)
	add(p, v, life, c, o)


## 矩形の中の画素が散って舞い上がる
func burst(r: Rect2, c: Color, n: int) -> void:
	for i in n:
		var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		add(p, Vector2(randf_range(-20, 20), randf_range(-50, -10)), randf_range(0.5, 1.3), c)


func ring(center: Vector2, c: Color, n: int, speed: float, delay: float = 0.0) -> void:
	for i in n:
		add(center, Vector2.from_angle(TAU * i / n) * speed, randf_range(0.7, 1.1), c, {"delay": delay})


func stars(r: Rect2, c: Color, n: int, delay: float = 0.0) -> void:
	for i in n:
		var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		add(p, Vector2(0, randf_range(-6, 0)), randf_range(0.6, 1.6), c,
			{"star": true, "delay": delay + randf() * 0.3})


## 画面全体をディザで覆ってから晴らす。start = 最初に覆う割合 (0 で全面)
func flash(c: Color, dur: float, start: float = 0.4) -> void:
	_flash.color = c
	var tw := create_tween()
	tw.tween_method(func(v: float): _flash_mat.set_shader_parameter("progress", v), start, 1.0, dur)
