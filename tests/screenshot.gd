extends SceneTree
## main.tscn を実行し、主人公を歩かせながら途中経過を PNG に保存する (見た目確認用)。
## godot --path . -s res://tests/screenshot.gd -- <出力フォルダ>

var out_dir := "user://"
var game: Game
var player: Player


func _init() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out_dir = OS.get_cmdline_user_args()[0]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game = main.get_node("Game")
	player = main.get_node("World/Player")
	await _wait(1.0)
	_save("0_start")
	await _walk_to("shelf_bottom")
	await _wait(2.0)
	_save("1_got_p1")
	game.give(_uid("笑顔を"))
	await _wait(0.3)
	_save("1_give")
	game.tell()
	await _wait(2.0)
	await _walk_to("bed")
	await _wait(2.5)
	_save("2_sleep")
	game.give(_uid("やさしい"))
	game.give(_uid("笑顔を"))
	game.tell()
	await _wait(2.0)
	await _walk_to("shelf_right")
	await _wait(1.5)
	game.click(_uid("金色の"))
	await _wait(2.0)
	_save("3_gold")
	game.give(_uid("鍵"))
	game.give(_uid("さがして"))
	game.tell()
	await _wait(2.5)
	await _walk_to("window")
	await _wait(2.0)
	_save("4_window")
	for t in ["きらきらとした", "明るい", "未来"]:
		game.give(_uid(t))
	await _wait(0.3)
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
