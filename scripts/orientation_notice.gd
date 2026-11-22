class_name OrientationNotice
extends Control
## スマホを縦にして遊んでいるとき (画面が縦長のとき)、横向きにしてもらう案内を出す。
## 画面が横長になれば自動で消える。表示中は後ろの操作を止める。

const TEXT := "スマホを よこむきに して あそんでね"


func _ready() -> void:
	size = UIConst.SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("121212")
	bg.size = UIConst.SCREEN
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var l := Label.new()
	l.text = TEXT
	l.size = Vector2(UIConst.SCREEN.x, 16)
	l.position = Vector2(0, roundf(UIConst.SCREEN.y / 2.0 - 8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UIConst.FONT)
	l.add_theme_font_size_override("font_size", UIConst.FONT_SIZE)
	l.add_theme_color_override("font_color", UIConst.TEXT_COLOR)
	add_child(l)
	_update()


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	var s := DisplayServer.window_get_size()
	var portrait := s.y > s.x
	if visible != portrait:
		visible = portrait
