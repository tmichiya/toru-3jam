class_name Cipher
extends RefCounted
## 日本語の読み (かな) → ローマ字 (ヘボン式) → ローマ字の文字数ぶん後ろへずらす

const KANA := {
	"あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
	"か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
	"さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
	"た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
	"な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
	"は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
	"ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
	"や": "ya", "ゆ": "yu", "よ": "yo",
	"ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
	"わ": "wa", "を": "wo", "ん": "n",
	"が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
	"ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
	"だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
	"ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
	"ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
	"ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
}
const YOUON := {"ゃ": "ya", "ゅ": "yu", "ょ": "yo"}


static func encode(yomi: String) -> String:
	var r := to_romaji(yomi)
	return shift(r, r.length())


static func to_romaji(kana: String) -> String:
	var s := _to_hiragana(kana)
	var out := ""
	var double_next := false
	var i := 0
	while i < s.length():
		var ch := s[i]
		if ch == "っ":
			double_next = true
			i += 1
			continue
		if ch == "ー":
			if out.length() > 0:
				out += out[out.length() - 1]
			i += 1
			continue
		var r := ""
		if i + 1 < s.length() and YOUON.has(s[i + 1]) and KANA.has(ch):
			var base: String = KANA[ch]
			var y: String = YOUON[s[i + 1]]
			var stem := base.substr(0, base.length() - 1)
			# し・ち・じ + ゃ は sha / cha / ja、それ以外は kya のように y を残す
			r = stem + (y.substr(1) if base in ["shi", "chi", "ji"] else y)
			i += 2
		else:
			r = KANA.get(ch, "")
			i += 1
		if double_next and r != "":
			r = ("t" if r.begins_with("ch") else r[0]) + r
			double_next = false
		out += r
	return out


static func shift(romaji: String, n: int) -> String:
	var out := ""
	for i in romaji.length():
		var c := romaji.unicode_at(i)
		if c >= 97 and c <= 122:
			out += char((c - 97 + n) % 26 + 97)
		else:
			out += char(c)
	return out


static func _to_hiragana(s: String) -> String:
	var out := ""
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x30A1 and c <= 0x30F6:
			c -= 0x60
		out += char(c)
	return out
