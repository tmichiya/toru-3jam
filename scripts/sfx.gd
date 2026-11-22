class_name Sfx
extends Node
## コードで生成するピコ音。fx event の kind と同じ名前の音を鳴らす。

const RATE := 22050
const VOICES := 6

var _streams: Dictionary = {}
var _players: Array = []


func setup(g: Game) -> void:
	for i in VOICES:
		var pl := AudioStreamPlayer.new()
		pl.volume_db = -10.0
		add_child(pl)
		_players.append(pl)
	_streams = {
		"click": _seq([[880, 0.04], [1320, 0.07]], "tri"),
		"give": _seq([[660, 0.05], [990, 0.08]], "tri"),
		"transform": _seq([[1047, 0.05], [784, 0.05], [1319, 0.05], [1568, 0.14]], "square"),
		"anim_flip": _seq([[880, 0.05], [660, 0.05], [880, 0.08]], "tri"),
		"anim_slide": _seq([[660, 0.04], [698, 0.04], [740, 0.08]], "tri"),
		"collect": _seq([[784, 0.07], [988, 0.07], [1175, 0.07], [1568, 0.2]], "tri"),
		"take_back": _seq([[330, 0.05], [247, 0.09]], "tri"),
		"full": _seq([[196, 0.07], [165, 0.12]], "square"),
		"told_ng": _seq([[392, 0.08], [370, 0.08], [349, 0.16]], "tri"),
		"told_ok": _seq([[660, 0.05], [990, 0.05], [1320, 0.1]], "square"),
		"stage": _seq([[523, 0.1], [659, 0.1], [784, 0.1], [1047, 0.3]], "tri"),
		"anim_smile": _seq([[784, 0.06], [988, 0.06], [1175, 0.12]], "tri"),
		"anim_key": _seq([[1568, 0.04], [2093, 0.1]], "square"),
		"color": _seq([[523, 0.08], [659, 0.08], [784, 0.20]], "tri"),
		"anim_bird": _seq([[1200, 0.03], [900, 0.03], [1200, 0.03], [900, 0.03], [1400, 0.06]], "square"),
		"anim_sparkle": _seq([[1568, 0.05], [2093, 0.05], [2637, 0.10]], "tri"),
		"anim_star": _seq([[1047, 0.06], [1568, 0.06], [2093, 0.12]], "tri"),
		"anim_bright": _seq([[784, 0.06], [1047, 0.16]], "tri"),
		"anim_fall": _seq([[880, 0.06], [660, 0.06], [440, 0.06], [220, 0.1]], "square"),
		"anim_sing": _seq([[523, 0.1], [659, 0.1], [587, 0.1], [784, 0.2]], "tri"),
		"anim_sleep": _seq([[330, 0.2], [294, 0.3]], "tri"),
		"anim_move": _seq([[440, 0.04], [660, 0.04], [440, 0.04], [660, 0.04]], "square"),
		"undo": _seq([[600, 0.04], [420, 0.07]], "tri"),
		"ending": _seq([[523, 0.15], [659, 0.15], [784, 0.15], [1047, 0.15],
			[784, 0.15], [1047, 0.15], [1319, 0.6]], "tri"),
	}
	g.fx_requested.connect(_on_fx)


## 言葉の演出は anim_<id> の音があればそれ、なければ共通のクリック音
func _on_fx(ev: Dictionary) -> void:
	if ev["kind"] == "anim":
		var id: String = "anim_" + str(ev["anim"])
		play(id if _streams.has(id) else "click")
	else:
		play(ev["kind"])


func play(id: String) -> void:
	if not _streams.has(id):
		return
	for pl in _players:
		if not pl.playing:
			pl.stream = _streams[id]
			pl.play()
			return


func _seq(notes: Array, wave: String) -> AudioStreamWAV:
	var total := 0
	for n in notes:
		total += int(float(n[1]) * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var off := 0
	for n in notes:
		var f: float = n[0]
		var count := int(float(n[1]) * RATE)
		for i in count:
			var ph := fmod(float(i) * f / RATE, 1.0)
			var v := 0.0
			if wave == "square":
				v = 1.0 if ph < 0.5 else -1.0
			else:
				v = 4.0 * absf(ph - 0.5) - 1.0
			var env := minf(1.0, i / 60.0) * (1.0 - float(i) / count)
			data.encode_s16(off, int(clampf(v * env * 0.35, -1.0, 1.0) * 32767.0))
			off += 2
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
