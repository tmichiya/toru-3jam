class_name RoomNav
extends RefCounted
## 部屋の床・階段をつないだ線のグラフ (poem.json の nav)。
## クリックした点から一番近い歩ける点を求め、そこまでの経路 (点の列) を返す。

var nodes: Dictionary = {}  # id -> Vector2
var edges: Array = []       # [Vector2 a, Vector2 b, id_a, id_b]


func _init(def: Dictionary) -> void:
	for id in def.get("nodes", {}):
		var p: Array = def["nodes"][id]
		nodes[id] = Vector2(p[0], p[1])
	for e in def.get("edges", []):
		edges.append([nodes[e[0]], nodes[e[1]], e[0], e[1]])


## p に一番近い歩ける点。{ "edge": 番号, "point": Vector2 }
func project(p: Vector2) -> Dictionary:
	var best := {"edge": -1, "point": p}
	var best_d := INF
	for i in edges.size():
		var q := Geometry2D.get_closest_point_to_segment(p, edges[i][0], edges[i][1])
		var d := q.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"edge": i, "point": q}
	return best


## from から to まで歩く経路。to は歩ける点へ寄せる。最初の点 (from) は含まない
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var s := project(from)
	var g := project(to)
	if s["edge"] < 0 or g["edge"] < 0:
		return PackedVector2Array()
	if s["edge"] == g["edge"]:
		return PackedVector2Array([g["point"]])

	# スタートとゴールを仮の点としてグラフに足し、ダイクストラ法で最短経路
	var pos := nodes.duplicate()
	pos["_S"] = s["point"]
	pos["_G"] = g["point"]
	var adj := {}
	for id in pos:
		adj[id] = []
	for i in edges.size():
		var e: Array = edges[i]
		if i == s["edge"] or i == g["edge"]:
			continue
		adj[e[2]].append(e[3])
		adj[e[3]].append(e[2])
	for pair in [["_S", s["edge"]], ["_G", g["edge"]]]:
		var e: Array = edges[pair[1]]
		for end in [e[2], e[3]]:
			adj[pair[0]].append(end)
			adj[end].append(pair[0])

	var dist := {"_S": 0.0}
	var prev := {}
	var open := ["_S"]
	while not open.is_empty():
		var cur: String = open[0]
		for id in open:
			if dist[id] < dist[cur]:
				cur = id
		open.erase(cur)
		if cur == "_G":
			break
		for nb in adj[cur]:
			var nd: float = dist[cur] + (pos[cur] as Vector2).distance_to(pos[nb])
			if nd < dist.get(nb, INF):
				dist[nb] = nd
				prev[nb] = cur
				if not nb in open:
					open.append(nb)

	if not prev.has("_G"):
		return PackedVector2Array()
	var path := PackedVector2Array()
	var at := "_G"
	while at != "_S":
		path.insert(0, pos[at])
		at = prev[at]
	return path
