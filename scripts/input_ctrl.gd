class_name InputCtrl
extends Node2D
## マウス操作を解釈して Game に要求する。
##  - 詩の言葉をクリック → その言葉の演出
##  - 詩の言葉をドラッグして主人公 (吹き出し) へ落とす → 渡す
##  - 吹き出しの言葉をクリック / 外へドラッグ → 詩へ戻す
##  - 道具の言葉 (逆さ・ずれる) を詩の言葉に重ねる → 意味が変わる (どの詩の言葉にも重ねられる)
##  - それ以外の場所をクリック → 主人公がそこへ歩く

const DRAG_SLOP := 3.0
const TOUCH_DRAG_SLOP := 6.0          # 指は少しぶれるので、タップとドラッグの境を広めに
const TOUCH_LIFT := Vector2(0, -16)   # 指で運ぶ言葉は指より上に出す
const HOLD_TIME := 0.25

var game: Game
var view: PoemView
var player: Player

var _touch := false
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
			# スマホのタッチは Godot がマウス操作に置き換えて届ける (device がエミュレーション)
			_touch = e.device == InputEvent.DEVICE_ID_EMULATION
			_press(get_global_mouse_position())
		else:
			_release(get_global_mouse_position() + _lift())
	elif e is InputEventMouseMotion and _pressed_uid >= 0:
		var p := get_global_mouse_position()
		if not _dragging and p.distance_to(_press_pos) > (TOUCH_DRAG_SLOP if _touch else DRAG_SLOP):
			_begin_drag()
		if _dragging:
			# 指で運ぶときは言葉を指の少し上に出す (指で隠れないように)。落とす先もそこで決める
			view.drag_to(p + _lift())
			if _is_tool(_pressed_uid) and not _from_bubble:
				view.hover_tool_target(_pressed_uid, p + _lift())
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
	elif not _from_bubble and _is_tool(uid):
		var target := view.uid_at(p, uid)
		if target >= 0:
			game.apply_tool(uid, target)


## タッチで運んでいる間だけ、言葉を指の上へずらす量
func _lift() -> Vector2:
	return TOUCH_LIFT if _touch and _dragging else Vector2.ZERO


func _is_tool(uid: int) -> bool:
	return str(game.state.word_by_uid(uid).get("tool", "")) != ""
