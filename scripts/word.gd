class_name WordNode
extends Node2D
## 1単語の見た目。ゲーム状態は持たず、PoemView / WordAnims に言われた見た目を演じるだけ。

const DISSOLVE := preload("res://shaders/dissolve.gdshader")
const FOLLOW_SPEED := 14.0
const HIDDEN_PROGRESS := 0.93  # 隠れている言葉: ほんの少しだけ画素がゆらいで見える
const LENT_PROGRESS := 0.75    # 吹き出しに貸し出し中: うすく残る

var uid := -1
var text := ""
var status := ""

## 演出用 (WordAnims から tween される)
var anim_offset := Vector2.ZERO
var spread := 0.0      # 文字間を広げる量 (px)
var ghost := 0.0       # 残像の強さ 0..1
var ghost_dir := 1.0   # 残像の向き
var dim := 0.0         # 暗くする量 0..1
var flip := 0.0        # 上下の回転 0 = ふつう, 1 = 逆さま (縦に裏返る)

var _pending_text := ""  # 状態では変わったが、まだ見た目に反映していない言葉

var _target := Vector2.ZERO
var _pos := Vector2.ZERO
var _dragging := false
var _highlight := false
var _shake := 0.0
var _t := 0.0
var _progress := 1.0
var _reveal := -1.0    # タイプライタで見えている文字数 (<0 で全部)
var _tween: Tween
var _mat: ShaderMaterial


func setup(p_uid: int, p_text: String, p: Vector2) -> void:
	uid = p_uid
	text = p_text
	_mat = ShaderMaterial.new()
	_mat.shader = DISSOLVE
	material = _mat
	_set_progress(1.0)
	_pos = p
	_target = p
	position = p.round()


## 文字の縦の中心 (翼や手をくっつける高さの基準)
static func mid_y() -> float:
	return roundf(UIConst.text_height() / 2.0)


func width() -> float:
	return UIConst.text_width(text) + spread * maxi(0, text.length() - 1)


## 一文字ずつ現れる
func typewrite(delay: float) -> void:
	_reveal = 0.0
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "_reveal", float(text.length()), 0.07 * text.length())
	tw.tween_callback(func(): _reveal = -1.0)


func set_status(st: String, delay: float = 0.0) -> void:
	if st == status:
		return
	status = st
	var dur := 0.8 if st == "hidden" else 0.35
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if delay > 0.0:
		_tween.tween_interval(delay)
	_tween.tween_method(_set_progress, _progress, _progress_for(st), dur)


## 言葉が変わった。直後に morph() が呼ばれればそれで演出し、呼ばれなければ (Undo など) すぐ差し替える
func queue_text(t: String) -> void:
	_pending_text = t
	_flush_pending.call_deferred()


func _flush_pending() -> void:
	if _pending_text != "":
		text = _pending_text
		_pending_text = ""


## 逆さ (reverse): くるっと裏返って新しい言葉に / ずれる (shift): 横にずれて新しい言葉に
func morph(style: String) -> void:
	if _pending_text == "":
		return
	var to := _pending_text
	_pending_text = ""
	var tw := create_tween()
	if style == "reverse":
		flip = 0.0
		tw.tween_property(self, "flip", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): text = to)
		tw.tween_property(self, "flip", 2.0, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): flip = 0.0)
	else:
		ghost_dir = -1.0
		tw.tween_property(self, "anim_offset", Vector2(14, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(self, "ghost", 1.0, 0.2)
		tw.tween_callback(_swap_from_left.bind(to))
		tw.tween_property(self, "anim_offset", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "ghost", 0.0, 0.3)
	flash()


func _swap_from_left(to: String) -> void:
	text = to
	anim_offset = Vector2(-14, 0)


func move_to(p: Vector2) -> void:
	_target = p


func set_highlight(v: bool) -> void:
	_highlight = v


## ドラッグ中は (貸し出し中でも) くっきり見せ、離したら状態の見た目に戻す
func set_dragging(v: bool) -> void:
	_dragging = v
	z_index = 10 if v else 0
	if _tween:
		_tween.kill()
	if v:
		_set_progress(0.0)
	else:
		_tween = create_tween()
		_tween.tween_method(_set_progress, _progress, _progress_for(status), 0.3)


func drag_to(p: Vector2) -> void:
	_pos = p


func shake() -> void:
	_shake = 1.0


func flash() -> void:
	modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.4)


func _process(delta: float) -> void:
	_t += delta
	if not _dragging:
		_pos = _pos.lerp(_target, 1.0 - exp(-delta * FOLLOW_SPEED))
	var off := anim_offset
	if _shake > 0.0:
		off.x += round(sin(_t * 70.0) * 2.0 * _shake)
		_shake = maxf(0.0, _shake - delta * 3.0)
	position = (_pos + off).round()
	queue_redraw()


func _draw() -> void:
	var c := UIConst.HILITE_COLOR if _highlight or _dragging else UIConst.TEXT_COLOR
	c = c.lerp(Color(0.3, 0.3, 0.35), dim)
	# 縦に裏返す (flip = 1 で逆さま)。文字の高さの真ん中を軸にする
	var s := cos(PI * flip)
	draw_set_transform(Vector2(0, UIConst.text_height() * (1.0 - s) / 2.0), 0.0, Vector2(1, s))
	if ghost > 0.0:
		for i in 3:
			var a := ghost * (0.55 - i * 0.17)
			_draw_text(Vector2(ghost_dir * (i + 1) * ghost * 9.0, 0).round(), Color(c, a))
	_draw_text(Vector2.ZERO, c)
	draw_set_transform(Vector2.ZERO)
	if _highlight:
		var y := UIConst.text_height()
		for x in range(0, int(width()), 2):
			draw_rect(Rect2(x, y, 1, 1), c)


## 1文字ずつ描く (spread で文字間を広げられるように)
func _draw_text(off: Vector2, c: Color) -> void:
	var n := text.length() if _reveal < 0.0 else mini(int(_reveal), text.length())
	var x := 0.0
	var base_y := UIConst.FONT.get_ascent(UIConst.FONT_SIZE)
	for i in n:
		var ch := text[i]
		draw_string(UIConst.FONT, off + Vector2(roundf(x), base_y), ch,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UIConst.FONT_SIZE, c)
		x += UIConst.text_width(ch) + spread


func _progress_for(st: String) -> float:
	match st:
		"visible":
			return 0.0
		"hidden":
			return HIDDEN_PROGRESS
		"lent":
			return LENT_PROGRESS
	return 1.0


func _set_progress(v: float) -> void:
	_progress = v
	_mat.set_shader_parameter("progress", v)
