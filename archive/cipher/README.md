# 未知の言語 (暗号) 化の仕組み — 保管中

`archive/.gdignore` があるので、このフォルダは Godot から無視されます (読み込み・コンパイルされない)。

## 中身
- `cipher.gd` — かな → ヘボン式ローマ字 → ローマ字の文字数ぶん a〜z をずらす (`Cipher.encode("とり") == "xsvm"`)
- `glyphs.gd` — `glyphs.txt` の記号を 1px 単位で描く (`Glyphs.draw_text`, `Glyphs.text_width`)
- `glyphs.txt` — a〜z の 5x7 ドット記号。テキストで描き換え可

`data/poem.json` の各単語にある `"yomi"` は、この暗号化のために残してあります (今のゲームでは未使用)。

## 戻すとき
1. `cipher.gd` / `glyphs.gd` を `scripts/` へ、`glyphs.txt` を `data/` へ移す (`glyphs.gd` の `PATH` は `res://data/glyphs.txt`)
2. `GameState.make_word` で `"code": Cipher.encode(src.get("yomi", t))` を単語に持たせる (穴 `make_gap` にもコピー)
3. `WordNode` の描画を記号にする:
   - 幅: `Glyphs.text_width(code, spread)`
   - 描画: `Glyphs.draw_text(self, code, off + Vector2(0, roundf((UIConst.text_height() - Glyphs.H) / 2.0)), c, spread, count)`
4. エンディングで日本語に戻すなら、状態に `decoded` を持たせ、WordNode をディザで溶かして記号 → 日本語に切り替える
