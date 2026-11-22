class_name InputCtrl
extends Node2D
## マウス操作を解釈して Game に要求する。
##  - 詩の言葉をクリック → その言葉の演出
##  - 詩の言葉をドラッグして主人公 (吹き出し) へ落とす → 渡す
##  - 吹き出しの言葉をクリック / 外へドラッグ → 詩へ戻す
##  - それ以外の場所をクリック → 主人公がそこへ歩く

const DRAG_SLOP := 3.0
const HOLD_TIME := 0.25

var game: Game
var view: PoemView
var player: Player

var _pressed_uid := -1
var _from_bubble := false
var _press_pos := Vector2.ZERO
var _press_time := 0.0
var _dragging := false


func setup(g: Game, v: PoemView, p: Player) -> void:
	game = g
	view = v
	player = p


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press(get_global_mouse_position())
		else:
			_release(get_global_mouse_position())
	elif e is InputEventMouseMotion and _pressed_uid >= 0:
		var p := get_global_mouse_position()
		if not _dragging and p.distance_to(_press_pos) > DRAG_SLOP:
			_begin_drag()
		if _dragging:
			view.drag_to(p)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_Z, KEY_BACKSPACE:
				game.undo()
			KEY_R:
				game.reset()
			KEY_ENTER, KEY_SPACE:
				game.tell()


func _process(delta: float) -> void:
	if _pressed_uid >= 0 and not _dragging:
		_press_time += delta
		if _press_time >= HOLD_TIME:
			_begin_drag()


func _press(p: Vector2) -> void:
	_from_bubble = false
	_pressed_uid = view.uid_at(p)
	if _pressed_uid < 0:
		_pressed_uid = player.bubble.uid_at(p)
		_from_bubble = _pressed_uid >= 0
	if _pressed_uid < 0:
		# 言葉でなければ、そこへ歩いていく
		player.walk_to_screen(p)
		return
	_press_pos = p
	_press_time = 0.0
	_dragging = false


func _begin_drag() -> void:
	if game.state.d["ended"]:
		return
	_dragging = true
	view.begin_drag(_pressed_uid, _press_pos, _from_bubble)
	view.drag_to(get_global_mouse_position())


func _release(p: Vector2) -> void:
	if _pressed_uid < 0:
		return
	var uid := _pressed_uid
	_pressed_uid = -1
	if not _dragging:
		if _from_bubble:
			game.take_back(uid)
		else:
			game.click(uid)
		return
	_dragging = false
	view.end_drag()
	var on_player := player.accepts_drop(p)
	if _from_bubble and not on_player:
		game.take_back(uid)
	elif not _from_bubble and on_player:
		game.give(uid)
