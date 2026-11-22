class_name InputCtrl
extends Node2D
## マウス操作を解釈して Game に要求する。
##  - 単語をクリック → その言葉の演出
##  - 単語を長押し / ドラッグ → 運ぶ。つなげられる場所なら固定、だめなら元の場所へ

const DRAG_SLOP := 3.0
const HOLD_TIME := 0.25

var game: Game
var view: PoemView

var _pressed_uid := -1
var _press_pos := Vector2.ZERO
var _press_time := 0.0
var _dragging := false


func setup(g: Game, v: PoemView) -> void:
	game = g
	view = v


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(get_global_mouse_position())
		else:
			_release()
	elif e is InputEventMouseMotion and _pressed_uid >= 0:
		var p := get_global_mouse_position()
		if not _dragging and p.distance_to(_press_pos) > DRAG_SLOP:
			_begin_drag()
		if _dragging:
			view.drag_to(p)
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_Z or e.keycode == KEY_BACKSPACE:
			game.undo()
		elif e.keycode == KEY_R:
			game.reset()


func _process(delta: float) -> void:
	if _pressed_uid >= 0 and not _dragging:
		_press_time += delta
		if _press_time >= HOLD_TIME:
			_begin_drag()


func _press(p: Vector2) -> void:
	_pressed_uid = view.uid_at(p)
	_press_pos = p
	_press_time = 0.0
	_dragging = false


func _begin_drag() -> void:
	if game.state.d["ended"]:
		return
	_dragging = true
	view.begin_drag(_pressed_uid, _press_pos)
	view.drag_to(get_global_mouse_position())


func _release() -> void:
	if _pressed_uid < 0:
		return
	if _dragging:
		var t := view.end_drag()
		if t["line"] >= 0:
			game.drop(_pressed_uid, t["line"], t["after"])
		else:
			game.return_home(_pressed_uid)
	else:
		game.click(_pressed_uid)
	_pressed_uid = -1
	_dragging = false
