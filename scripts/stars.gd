extends Control
# Getekende sterrenrij. Het standaardfont heeft geen glyph voor ★/☆ — op Windows viel dat
# nog mee, maar via Proton werden het lege blokjes (tester-melding v0.70). Zelf tekenen is
# de enige manier die overal hetzelfde oplevert.

var filled: int = 0
var total: int = 3
var star_size: float = 9.0
var gap: float = 4.0


func setup(f: int, t: int = 3, s: float = 9.0) -> void:
	filled = f
	total = t
	star_size = s
	custom_minimum_size = Vector2(float(t) * (s * 2.0 + gap), s * 2.0)
	size = custom_minimum_size
	queue_redraw()


func _star_points(c: Vector2, r: float) -> PackedVector2Array:
	# Vijfpuntige ster: afwisselend een punt op de buitenste en de binnenste cirkel.
	var pts := PackedVector2Array()
	for i in 10:
		var rad: float = r if i % 2 == 0 else r * 0.45
		var a: float = -PI / 2.0 + TAU * float(i) / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	return pts


func _draw() -> void:
	var step: float = star_size * 2.0 + gap
	for i in total:
		var c := Vector2(star_size + float(i) * step, star_size)
		var pts := _star_points(c, star_size)
		if i < filled:
			draw_colored_polygon(pts, Color(1.0, 0.82, 0.3))
		else:
			# Leeg: alleen een omtrek, zodat je ziet hoeveel er nog te halen zijn.
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.48, 0.56), 1.0)
