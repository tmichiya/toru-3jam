class_name PixelSpriteNode
extends Node2D
## コマ送りのドット絵 (翼・手・太陽など、単語にくっつく演出用)

var frames: Array = []  # Array[PackedStringArray]
var fps := 8.0
var color := Color.WHITE
var flip := false
var _t := 0.0


static func make(frame_names: Array, p_color: Color, p_flip: bool = false, p_fps: float = 8.0) -> PixelSpriteNode:
	var n := PixelSpriteNode.new()
	for f in frame_names:
		n.frames.append(PixelSprites.get_rows(f))
	n.color = p_color
	n.flip = p_flip
	n.fps = p_fps
	return n


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if frames.is_empty():
		return
	var f: PackedStringArray = frames[int(_t * fps) % frames.size()]
	PixelSprites.draw_rows(self, f, Vector2.ZERO, color, flip)
