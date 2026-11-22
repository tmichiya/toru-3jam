extends SceneTree
## main.tscn を実行し、主人公を歩かせながら途中経過を PNG に保存する (見た目確認用)。
## godot --path . -s res://tests/screenshot.gd -- <出力フォルダ>

var out_dir := "user://"
var game: Game
var player: Player
var intro: Node


func _init() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out_dir = OS.get_cmdline_user_args()[0]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game = main.get_node("Game")
	player = main.get_node("World/Player")
	intro = main.get_node("IntroLayer/Intro")
	await _wait(0.5)
	for i in 3:
		intro._advance()
		await _wait(1.6)
	_save("0_intro")
	while is_instance_valid(intro) and not intro._done:
		intro._advance()
		await _wait(0.2)
	await _wait(2.0)
	_save("0_start")
	game.click(_uid("赤い"))
	await _wait(1.5)
	_save("1_red")
	game.apply_tool(_uid("逆さ"), _uid("涙"))
	await _wait(0.35)
	_save("1_flipping")
	await _wait(1.0)
	game.give(_uid("笑顔"))
	game.tell()
	await _wait(1.2)
	_save("1_room_appearing")
	await _wait(2.0)
	await _walk_to("bed")
	await _wait(2.5)
	game.click(_uid("青い"))
	game.apply_tool(_uid("ずれる"), _uid("夜"))
	await _wait(0.25)
	_save("2_shift")
	await _wait(1.5)
	game.give(_uid("朝"))
	game.give(_uid("笑顔"))
	game.tell()
	await _wait(2.0)
	await _walk_to("shelf_right")
	await _wait(1.5)
	game.click(_uid("紫の"))
	await _wait(1.8)
	_save("3_purple")
	game.click(_uid("赤い"))
	game.apply_tool(_uid("逆さ"), _uid("なくした"))
	game.click(_uid("金色"))
	await _wait(1.8)
	_save("3_gold")
	game.give(_uid("鍵"))
	game.give(_uid("みつけた"))
	game.tell()
	await _wait(2.5)
	_save("4_window_marked")
	# 窓そのものをクリックすると、近い階段の上へ歩く
	player.walk_to_screen(player.room_to_screen(Vector2(161, 90)))
	for i in 1500:
		await process_frame
		if player._path.is_empty():
			break
	await _wait(2.0)
	game.click(_uid("白い"))
	await _wait(1.8)
	_save("4_white")
	# 白の間に 明るい を渡し、青で ずれる を出して 過去 → 今 → 未来
	game.give(_uid("きらきらした"))
	game.give(_uid("明るい"))
	game.click(_uid("青い"))
	game.apply_tool(_uid("ずれる"), _uid("過去"))
	game.apply_tool(_uid("ずれる"), _uid("今"))
	game.give(_uid("未来"))
	await _wait(0.5)
	_save("4_give")
	game.tell()
	await _wait(9.0)
	_save("5_end")
	quit(0)


## spot まで実際にクリックと同じ経路で歩かせ、着くまで待つ
func _walk_to(spot: String) -> void:
	var p: Array = game.poem["spots"][spot]["points"][-1]
	player.walk_to_screen(player.room_to_screen(Vector2(p[0], p[1])))
	for i in 1500:
		await process_frame
		if player._path.is_empty():
			break


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	var path := out_dir + "/shot_" + name + ".png"
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _uid(t: String) -> int:
	for pid in game.state.d["poems"]:
		for line in game.state.poem_lines(pid):
			for w in line["words"]:
				if w["t"] == t:
					return w["uid"]
	return -1
