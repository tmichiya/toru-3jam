class_name PixelSprites
extends RefCounted
## 演出用の小さなドット絵。'#' が点。自由に描き換えてOK

const SPR := {
	"house": ["..#..", ".###.", "#####", "#.#.#", "#.#.#", "#####"],
	"hand": [".#.#..", ".#.#.#", ".#####", "######", ".####.", "..###."],
	"wing_up": ["....##", "...##.", "..###.", ".####.", "####.."],
	"wing_down": ["......", "####..", ".####.", "..###.", "...##."],
	"cloud": ["..##....", ".####.#.", "########", ".######."],
	"bubble": [".##.", "#..#", "#..#", ".##."],
	"puff": [".#.", "###", ".#."],
	"note": ["..##", "..#.", "..#.", "###.", "##.."],
	"z": ["####", "..#.", ".#..", "####"],
	"sun": ["...#####...", "..#######..", ".#########.", "###########"],
	"drop": [".#.", "###", ".#."],
	"dot": ["##", "##"],
	"star": ["..#..", "..#..", "#####", "..#..", "..#.."],
}


static func get_rows(name: String) -> PackedStringArray:
	return PackedStringArray(SPR.get(name, []))


static func draw_rows(ci: CanvasItem, rows: PackedStringArray, pos: Vector2, color: Color,
		flip: bool = false) -> void:
	for y in rows.size():
		var row: String = rows[y]
		var w := row.length()
		for x in w:
			if row[x] == "#":
				var xx := (w - 1 - x) if flip else x
				ci.draw_rect(Rect2(pos + Vector2(xx, y), Vector2.ONE), color)
