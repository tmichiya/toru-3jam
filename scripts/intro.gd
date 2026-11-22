class_name Intro
extends Control
## ゲームの前に流れる文章 (poem.json の intro)。一行ずつ現れ、クリックで次へ。
## 最後の行のあとクリックすると、ゆっくり部屋が見えてくる。
## 表示中は画面全体でクリックとキーを受け止めるので、後ろのゲームは操作されない。

const LINE_H := 22.0
const CHAR_TIME := 0.07
const FADE_TIME := 1.5

var _lines: Array = []
var _labels: Array = []
var _index := -1
var _typing: Tween
var _next_label: Label
var _done := false
var _t := 0.0


func setup(lines: Array) -> void:
	_lines = lines
	if _lines.is_empty():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = UIConst.SCREEN
	var bg := ColorRect.new()
	bg.color = Color("121212")
	bg.size = UIConst.SCREEN
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var top := roundf((UIConst.SCREEN.y - LINE_H * _lines.size()) / 2.0)
	for i in _lines.size():
		var l := _make_label(_lines[i], Vector2(0, top + i * LINE_H))
		l.visible_ratio = 0.0
		_labels.append(l)
	_next_label = _make_label("クリックで つぎへ", Vector2(0, UIConst.SCREEN.y - 20))
	_next_label.modulate.a = 0.0
	_advance()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _input(e: InputEvent) -> void:
	if _done:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in [KEY_ENTER, KEY_SPACE]:
			_advance()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_t += delta
	if _next_label and not _done:
		var line_done := _typing == null or not _typing.is_running()
		_next_label.modulate.a = (0.35 + 0.25 * sin(_t * 4.0)) if line_done else 0.0


## 打っている途中なら最後まで出す。出し終わっていれば次の行へ。最後なら部屋へ
func _advance() -> void:
	if _done:
		return
	if _typing and _typing.is_running():
		_typing.kill()
		_labels[_index].visible_ratio = 1.0
		return
	_index += 1
	if _index >= _labels.size():
		_finish()
		return
	var l: Label = _labels[_index]
	_typing = create_tween()
	_typing.tween_property(l, "visible_ratio", 1.0, CHAR_TIME * l.text.length())


func _finish() -> void:
	_done = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tw.tween_callback(queue_free)


func _make_label(t: String, p: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.position = p
	l.size = Vector2(UIConst.SCREEN.x, LINE_H)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UIConst.FONT)
	l.add_theme_font_size_override("font_size", UIConst.FONT_SIZE)
	l.add_theme_color_override("font_color", UIConst.TEXT_COLOR)
	add_child(l)
	return l
