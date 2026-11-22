class_name Glyphs
extends RefCounted
## 未知の記号 (data/glyphs.txt) を読み込んで 1px 単位で描く

const PATH := "res://data/glyphs.txt"
const W := 5
const H := 7
const SPACING := 1

static var _map: Dictionary = {}


static func rows(ch: String) -> PackedStringArray:
	_ensure_loaded()
	return _map.get(ch, PackedStringArray())


static func text_width(s: String, extra_spacing: float = 0.0) -> float:
	if s.is_empty():
		return 0.0
	return s.length() * (W + SPACING + extra_spacing) - SPACING - extra_spacing


## s の先頭 count 文字を描く (count < 0 なら全部)
static func draw_text(ci: CanvasItem, s: String, pos: Vector2, color: Color,
		extra_spacing: float = 0.0, count: int = -1) -> void:
	var n := s.length() if count < 0 else mini(count, s.length())
	for i in n:
		var x := roundf(i * (W + SPACING + extra_spacing))
		PixelSprites.draw_rows(ci, rows(s[i]), pos + Vector2(x, 0), color)


static func _ensure_loaded() -> void:
	if not _map.is_empty():
		return
	var cur := ""
	for raw in FileAccess.get_file_as_string(PATH).split("\n"):
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with(";"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			cur = line.substr(1, line.length() - 2)
			_map[cur] = PackedStringArray()
		elif cur != "":
			_map[cur].append(line)
