extends SceneTree
## 主人公の仮ドット絵 (スプライトシート) と SpriteFrames を生成する。
## godot --headless --path . -s res://tools/gen_player_placeholder.gd
##
## 生成物:
##   art/player/player_sheet.png   1コマ 10x14、行 = アニメ、列 = コマ (ANIMS の順)
##   art/player/player_frames.tres 上の PNG を切り出した SpriteFrames
## 差し替えるときは player_sheet.png を同じ並びで描き直せばそのまま反映される。
## (コマ数やサイズを変えたいときはエディタで player_frames.tres を直接編集してもOK。
##  足元が下端中央になるように scenes/player.tscn の Sprite の位置も合わせる)

const W := 10
const H := 14
const COLS := 4
const OUT_DIR := "res://art/player/"

## [アニメ名, コマ数, fps, ループ]
const ANIMS := [
	["idle", 2, 3.0, true],
	["cry", 2, 4.0, true],
	["happy", 2, 6.0, true],
	["sleep", 2, 1.5, true],
	["wake", 2, 4.0, true],
	["walk", 4, 8.0, true],
	["search", 2, 4.0, true],
	["think", 2, 2.0, true],
	["tilt", 1, 1.0, true],
]

## 部屋の絵 (白い線画) に合わせて、白い輪郭 + 暗い塗り
const LINE := Color("f4f1ea")
const FILL := Color("1a1a1e")
const CLOTH := Color("6f86b8")
const TEAR := Color("6fb6ff")
const CHEEK := Color("f0a0a8")


func _init() -> void:
	var img := Image.create(W * COLS, H * ANIMS.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for row in ANIMS.size():
		for f in int(ANIMS[row][1]):
			_draw_frame(img, Vector2i(f * W, row * H), ANIMS[row][0], f)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	img.save_png(OUT_DIR + "player_sheet.png")
	_write_frames()
	print("generated ", OUT_DIR)
	quit()


## アニメとコマ番号から見た目のパラメータを決めて描く
func _draw_frame(img: Image, o: Vector2i, anim: String, f: int) -> void:
	var p := {
		"head": Vector2i.ZERO, "body_dy": 0, "eyes": "open",
		"tears": -1, "legs": 0, "arms": "down", "z": false, "smile": false,
	}
	match anim:
		"idle":
			p["head"] = Vector2i(0, f)
		"cry":
			p["eyes"] = "cry"
			p["tears"] = f
			p["head"] = Vector2i(0, 1)
		"happy":
			p["eyes"] = "happy"
			p["smile"] = true
			p["body_dy"] = -f
			p["arms"] = "up" if f == 1 else "down"
		"sleep":
			p["eyes"] = "closed"
			p["head"] = Vector2i(1, 1)
			p["z"] = f == 1
		"wake":
			p["eyes"] = "open" if f == 0 else "closed"
			p["arms"] = "up"
		"walk":
			p["legs"] = f + 1
			p["head"] = Vector2i(0, f % 2)
		"search":
			p["eyes"] = "down"
			p["head"] = Vector2i(f, 1)
		"think":
			p["eyes"] = "up"
			p["arms"] = "chin"
		"tilt":
			p["head"] = Vector2i(1, 0)
	_figure(img, o, p)


func _figure(img: Image, o: Vector2i, p: Dictionary) -> void:
	var by: int = p["body_dy"]
	# 脚
	var legs: Array = [[3, 6], [2, 7], [3, 6], [4, 5], [3, 6]][p["legs"]]
	for x in legs:
		for y in range(11, 14):
			_px(img, o, x, y + (by if y < 13 else 0), LINE)
	# 胴
	for y in range(6, 11):
		for x in range(2, 8):
			var edge := x == 2 or x == 7 or y == 10
			_px(img, o, x, y + by, LINE if edge else CLOTH)
	# 腕
	match p["arms"]:
		"down":
			for y in range(7, 10):
				_px(img, o, 1, y + by, LINE)
				_px(img, o, 8, y + by, LINE)
		"up":
			for y in range(3, 7):
				_px(img, o, 0, y + by, LINE)
				_px(img, o, 9, y + by, LINE)
		"chin":
			for y in range(7, 10):
				_px(img, o, 1, y + by, LINE)
			_px(img, o, 8, 6 + by, LINE)
			_px(img, o, 7, 5 + by, LINE)
	# 頭 (6x5)
	var h: Vector2i = Vector2i(2, 0) + p["head"] + Vector2i(0, by)
	for x in range(1, 5):
		_px(img, o, h.x + x, h.y, LINE)
		_px(img, o, h.x + x, h.y + 5, LINE)
	for y in range(1, 5):
		_px(img, o, h.x, h.y + y, LINE)
		_px(img, o, h.x + 5, h.y + y, LINE)
		for x in range(1, 5):
			_px(img, o, h.x + x, h.y + y, FILL)
	# 目
	var el: Vector2i = h + Vector2i(1, 2)
	var er: Vector2i = h + Vector2i(4, 2)
	match p["eyes"]:
		"open":
			_px(img, o, el.x, el.y, LINE)
			_px(img, o, er.x, er.y, LINE)
		"up":
			_px(img, o, el.x, el.y - 1, LINE)
			_px(img, o, er.x, er.y - 1, LINE)
		"down", "cry":
			_px(img, o, el.x, el.y + 1, LINE)
			_px(img, o, er.x, er.y + 1, LINE)
		"closed", "happy":
			_px(img, o, el.x, el.y + 1, LINE)
			_px(img, o, er.x, er.y + 1, LINE)
			_px(img, o, el.x + 1, el.y + (0 if p["eyes"] == "happy" else 1), LINE)
			_px(img, o, er.x - 1, er.y + (0 if p["eyes"] == "happy" else 1), LINE)
	if p["eyes"] == "happy":
		_px(img, o, el.x, el.y + 2, CHEEK)
		_px(img, o, er.x, er.y + 2, CHEEK)
	if p["smile"]:
		_px(img, o, h.x + 2, h.y + 4, LINE)
		_px(img, o, h.x + 3, h.y + 4, LINE)
	# 涙
	if p["tears"] >= 0:
		for e in [el, er]:
			_px(img, o, e.x, e.y + 2 + p["tears"], TEAR)
	# 寝息
	if p["z"]:
		for q in [Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(8, 1), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2)]:
			_px(img, o, q.x, q.y, LINE)


func _px(img: Image, o: Vector2i, x: int, y: int, c: Color) -> void:
	if x < 0 or x >= W or y < 0 or y >= H:
		return
	img.set_pixel(o.x + x, o.y + y, c)


func _write_frames() -> void:
	var subs := ""
	var anims := []
	for row in ANIMS.size():
		var a: Array = ANIMS[row]
		var frames := []
		for f in int(a[1]):
			var id := "at_%s_%d" % [a[0], f]
			subs += "[sub_resource type=\"AtlasTexture\" id=\"%s\"]\natlas = ExtResource(\"1_sheet\")\nregion = Rect2(%d, %d, %d, %d)\n\n" % [id, f * W, row * H, W, H]
			frames.append("{\n\"duration\": 1.0,\n\"texture\": SubResource(\"%s\")\n}" % id)
		anims.append("{\n\"frames\": [%s],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}" % [
			", ".join(frames), "true" if a[3] else "false", a[0], a[2]])
	var txt := "[gd_resource type=\"SpriteFrames\" format=3]\n\n"
	txt += "[ext_resource type=\"Texture2D\" path=\"%splayer_sheet.png\" id=\"1_sheet\"]\n\n" % OUT_DIR
	txt += subs
	txt += "[resource]\nanimations = [%s]\n" % ", ".join(anims)
	var f := FileAccess.open(OUT_DIR + "player_frames.tres", FileAccess.WRITE)
	f.store_string(txt)
	f.close()
