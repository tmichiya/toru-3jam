extends SceneTree
## 主人公の元絵 (art/player/player_base.png) から、全部のアニメのコマを作る。
## godot --headless --path . -s res://tools/gen_player_sprites.gd
##
## 元絵 1枚を「頭」と「体」に分け、ずらしたり、目・涙・腕・寝息を描き足してコマにする。
## 元絵を描き直したらこのスクリプトを実行し直せば全部のコマに反映される。
## 生成物:
##   art/player/player_sheet.png   1コマ = 元絵と同じ大きさ。行 = アニメ、列 = コマ (ANIMS の順)
##   art/player/player_frames.tres 上の PNG を切り出した SpriteFrames
## (1コマずつ手で描きたくなったら player_sheet.png を直接描き直してもよい。その場合はこのスクリプトを実行しないこと)

const BASE := "res://art/player/player_base.png"
const OUT_DIR := "res://art/player/"
const COLS := 4

## 元絵の中の場所 (元絵が変わったらここを合わせる)
const HEAD_ROWS := Vector2i(7, 13)     # 頭の行 (上端, 下端)
const BODY_ROWS := Vector2i(14, 18)    # 体の行
const EYES := [Vector2i(6, 9), Vector2i(6, 10), Vector2i(8, 9), Vector2i(8, 10)]  # 目の画素
const ARM_L := Vector2i(4, 15)         # 腕の付け根 (体の左右のふくらみ)
const ARM_R := Vector2i(10, 15)

const LINE := Color("ffffff")
const FILL := Color("1b1b1b")
const TEAR := Color("6fb6ff")
const CHEEK := Color("f0a0a8")

## [アニメ名, コマ数, fps, ループ]
const ANIMS := [
	["idle", 2, 2.5, true],
	["cry", 2, 4.0, true],
	["happy", 2, 6.0, true],
	["sleep", 2, 1.5, true],
	["wake", 2, 4.0, true],
	["walk", 4, 8.0, true],
	["search", 2, 4.0, true],
	["think", 2, 2.0, true],
	["tilt", 1, 1.0, true],
]

var base: Image
var W := 0
var H := 0


func _init() -> void:
	base = Image.load_from_file(ProjectSettings.globalize_path(BASE))
	base.convert(Image.FORMAT_RGBA8)
	W = base.get_width()
	H = base.get_height()
	var sheet := Image.create(W * COLS, H * ANIMS.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row in ANIMS.size():
		for f in int(ANIMS[row][1]):
			var fr := _frame(ANIMS[row][0], f)
			sheet.blit_rect(fr, Rect2i(0, 0, W, H), Vector2i(f * W, row * H))
	sheet.save_png(OUT_DIR + "player_sheet.png")
	_write_frames()
	print("generated ", OUT_DIR, " frame ", W, "x", H)
	quit()


## アニメとコマ番号から、頭と体のずらし方・目などの描き足しを決める
func _frame(anim: String, f: int) -> Image:
	var p := {
		"head": Vector2i.ZERO, "body": Vector2i.ZERO, "eyes": "open",
		"tears": -1, "arms": "", "z": false, "cheek": false,
	}
	match anim:
		"idle":
			p["head"] = Vector2i(0, f)          # 息をするように頭が上下
		"cry":
			p["eyes"] = "down"
			p["head"] = Vector2i(0, 1)
			p["tears"] = f
		"happy":
			p["eyes"] = "happy"
			p["cheek"] = true
			p["head"] = Vector2i(0, -f)
			p["body"] = Vector2i(0, -f)         # ぴょんと跳ねる
			p["arms"] = "up" if f == 1 else ""
		"sleep":
			p["eyes"] = "closed"
			p["head"] = Vector2i(1, 1)          # 首がかくん
			p["z"] = f == 1
		"wake":
			p["eyes"] = "wide" if f == 0 else "closed"
			p["arms"] = "up"
		"walk":
			var bob: int = [0, -1, 0, -1][f]
			var lean: int = [0, 1, 0, -1][f]
			p["head"] = Vector2i(lean, bob)
			p["body"] = Vector2i(0, bob)
		"search":
			p["eyes"] = "down"
			p["head"] = Vector2i(-1 if f == 0 else 1, 1)
		"think":
			p["eyes"] = "up"
			p["arms"] = "chin"
			p["head"] = Vector2i(0, -f)
		"tilt":
			p["head"] = Vector2i(1, 0)
			p["eyes"] = "up"
	return _compose(p)


func _compose(p: Dictionary) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hd: Vector2i = p["head"]
	var bd: Vector2i = p["body"]
	# 体 → 頭 の順に重ねる (頭が上に乗る)
	_copy_rows(img, BODY_ROWS, bd)
	_copy_rows(img, HEAD_ROWS, hd)
	# 目を描き直す
	for e in EYES:
		_px(img, e + hd, FILL)
	var eyes := _eye_pixels(str(p["eyes"]))
	for e in eyes:
		_px(img, e + hd, LINE)
	if p["cheek"]:
		_px(img, Vector2i(5, 11) + hd, CHEEK)
		_px(img, Vector2i(9, 11) + hd, CHEEK)
	if p["tears"] >= 0:
		for x in [6, 8]:
			_px(img, Vector2i(x, 11 + p["tears"]) + hd, TEAR)
			_px(img, Vector2i(x, 12 + p["tears"]) + hd, TEAR)
	match p["arms"]:
		"up":
			for i in 3:
				_px(img, ARM_L + bd + Vector2i(-1, -1 - i), LINE)
				_px(img, ARM_R + bd + Vector2i(1, -1 - i), LINE)
		"chin":
			_px(img, ARM_R + bd + Vector2i(1, -1), LINE)
			_px(img, ARM_R + bd + Vector2i(1, -2), LINE)
			_px(img, ARM_R + bd + Vector2i(0, -3), LINE)
	if p["z"]:
		for q in [Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3), Vector2i(12, 4), Vector2i(11, 5), Vector2i(12, 5), Vector2i(13, 5)]:
			_px(img, q, LINE)
	return img


## 目の形 (元の目は縦2画素)
func _eye_pixels(kind: String) -> Array:
	match kind:
		"closed":
			return [Vector2i(6, 10), Vector2i(8, 10)]
		"happy":
			return [Vector2i(6, 9), Vector2i(8, 9)]
		"up":
			# 頭のふちに付かないよう、上向きは目を短くして上だけ残す
			return [Vector2i(5, 9), Vector2i(7, 9)]
		"down":
			return [Vector2i(6, 10), Vector2i(6, 11), Vector2i(8, 10), Vector2i(8, 11)]
		"wide":
			return [Vector2i(6, 9), Vector2i(6, 10), Vector2i(6, 11), Vector2i(8, 9), Vector2i(8, 10), Vector2i(8, 11)]
	return EYES


func _copy_rows(dst: Image, rows: Vector2i, offset: Vector2i) -> void:
	for y in range(rows.x, rows.y + 1):
		for x in W:
			var c := base.get_pixel(x, y)
			if c.a > 0.0:
				_px(dst, Vector2i(x, y) + offset, c)


func _px(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.x < W and p.y >= 0 and p.y < H:
		img.set_pixelv(p, c)


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
