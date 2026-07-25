extends Node2D
# Visuele effecten: projectielen, poefjes, zwevende tekst en rook. Eén lijst met een
# "kind" per item, zodat alles op dezelfde manier verouderd en getekend wordt.
#
# Staat als aparte laag boven het speelveld, zodat projectielen over de towers en vijanden
# heen gaan in plaats van eronder. Wordt gebruikt door zowel het level als de Art Room —
# zo ziet de showroom precies wat het spel doet.
#
# Alles loopt op delta, dus bij time_scale 0 (plan-fase, pauze, game over) bevriest het mee.

var _fx: Array = []


func shot(from: Vector2, to: Vector2, id: String, _role: String) -> void:
	# Reistijd schaalt met de afstand maar blijft kort genoeg om responsief te voelen.
	var dist: float = from.distance_to(to)
	_fx.append({"kind": "shot", "t": 0.0, "life": clampf(dist / 900.0, 0.06, 0.28),
		"from": from, "to": to, "id": id})


func puff(pos: Vector2, col: Color, size: float) -> void:
	# Eigen hoek per poef, anders vliegen alle spetters van elke kill dezelfde kant op.
	_fx.append({"kind": "puff", "t": 0.0, "life": 0.35, "pos": pos, "col": col,
		"size": size, "seed": randf() * TAU})


func floater(pos: Vector2, text: String, col: Color) -> void:
	_fx.append({"kind": "float", "t": 0.0, "life": 0.9, "pos": pos, "text": text, "col": col})


func smoke(pos: Vector2, size: float, drift: float) -> void:
	_fx.append({"kind": "smoke", "t": 0.0, "life": 1.6, "pos": pos, "size": size, "drift": drift})


func toss(from: Vector2, to: Vector2) -> void:
	# Een punaise die naar een tegel op de baan wordt gegooid: klein puntje in een boog.
	_fx.append({"kind": "toss", "t": 0.0, "life": 0.35, "from": from, "to": to})


func letters(pos: Vector2, amount: int = 8) -> void:
	# Toetsen die wegvliegen bij een Keyboard Smash: losse tekens in willekeurige richtingen.
	var chars := "QWERTYUIOPASDFGHJKLZXCVBNM"
	for i in amount:
		var ang: float = randf() * TAU
		var spd: float = randf_range(50.0, 140.0)
		_fx.append({"kind": "letter", "t": 0.0, "life": randf_range(0.4, 0.7),
			"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd,
			"ch": chars[randi() % chars.length()]})


func clear() -> void:
	_fx.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _fx.is_empty():
		return
	var i: int = _fx.size() - 1
	while i >= 0:
		var f: Dictionary = _fx[i]
		f["t"] = float(f["t"]) + delta
		if float(f["t"]) >= float(f["life"]):
			_fx.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for f in _fx:
		var k: float = clampf(float(f["t"]) / float(f["life"]), 0.0, 1.0)
		match String(f["kind"]):
			"shot":
				var p: Vector2 = Vector2(f["from"]).lerp(Vector2(f["to"]), k)
				var dir: Vector2 = (Vector2(f["to"]) - Vector2(f["from"])).normalized()
				match String(f["id"]):
					"ceo":
						# zware klap: dikke rode punt met een korte sleep
						draw_line(p - dir * 9.0, p, Color(0.95, 0.45, 0.4, 0.9), 4.0)
						draw_circle(p, 3.5, Color(0.9, 0.3, 0.3))
					"phones":
						for w in 3:
							var o: float = float(w) * 5.0
							draw_arc(p - dir * o, 3.0 + o * 0.4, dir.angle() - 0.9,
								dir.angle() + 0.9, 8, Color(0.6, 0.9, 1.0, 0.8 - float(w) * 0.2), 1.5)
					_:
						# papieren vliegtuigje in de vliegrichting
						var n: Vector2 = dir.orthogonal()
						draw_colored_polygon(PackedVector2Array([
							p + dir * 5.0, p - dir * 3.0 + n * 3.0, p - dir * 3.0 - n * 3.0]),
							Color(0.85, 0.92, 1.0, 0.95))
			"puff":
				var r: float = float(f["size"]) * (0.4 + k * 1.3)
				var c: Color = f["col"]
				var pc: Vector2 = Vector2(f["pos"])
				draw_arc(pc, r, 0.0, TAU, 20, Color(c.r, c.g, c.b, (1.0 - k) * 0.8), 2.0)
				for s in 5:
					var ang: float = TAU * float(s) / 5.0 + float(f["seed"])
					var d: Vector2 = Vector2(cos(ang), sin(ang))
					draw_circle(pc + d * r * 0.95, 2.4 * (1.0 - k),
						Color(c.r, c.g, c.b, (1.0 - k) * 0.95))
			"smoke":
				var sp: Vector2 = Vector2(f["pos"]) + Vector2(float(f["drift"]) * k, -26.0 * k)
				var sr: float = float(f["size"]) * (0.5 + k * 0.9)
				draw_circle(sp, sr, Color(0.75, 0.75, 0.78, (1.0 - k) * 0.30))
				draw_circle(sp + Vector2(sr * 0.5, sr * 0.2), sr * 0.65,
					Color(0.68, 0.68, 0.72, (1.0 - k) * 0.24))
			"float":
				var pos: Vector2 = Vector2(f["pos"]) + Vector2(0, -18.0 * k)
				var c2: Color = f["col"]
				draw_string(font, pos, String(f["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 11,
					Color(c2.r, c2.g, c2.b, 1.0 - k * k))
			"toss":
				var tp: Vector2 = Vector2(f["from"]).lerp(Vector2(f["to"]), k)
				tp.y -= sin(k * PI) * 22.0        # boogje omhoog
				draw_circle(tp, 2.6, Color(0.85, 0.78, 0.4))
				draw_circle(tp, 1.2, Color(0.5, 0.45, 0.2))
			"letter":
				# wegvliegende toets: vertraagt en valt terug terwijl hij vervaagt
				var lp: Vector2 = Vector2(f["pos"]) + Vector2(f["vel"]) * float(f["t"]) * (1.0 - k * 0.6)
				lp.y += 40.0 * k * k
				draw_string(font, lp, String(f["ch"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 13,
					Color(0.9, 0.9, 0.95, 1.0 - k))
