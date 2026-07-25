extends Control
# Kleine getekende HUD-iconen: een bliksemschicht bij Focus en een kopje bij Coffee.
#
# Getekend en niet als tekst, want het standaardfont rendert geen emoji (zie HANDOFF) -- een
# "⚡" wordt daar een leeg blokje. Getekend is meteen scherp op elke resolutie en kleurt mee
# met de meter.

var kind := "bolt"           # "bolt" of "cup"
var tint := Color(1, 1, 1)


func setup(k: String, col: Color, s: Vector2 = Vector2(14, 16)) -> void:
	kind = k
	tint = col
	custom_minimum_size = s
	size = s


func set_tint(col: Color) -> void:
	if col != tint:
		tint = col
		queue_redraw()


func _draw() -> void:
	if kind == "bolt":
		_draw_bolt()
	else:
		_draw_cup()


func _draw_bolt() -> void:
	# Klassieke schicht: breed bovenaan, punt onderaan.
	var w := size.x
	var h := size.y
	var pts := PackedVector2Array([
		Vector2(w * 0.58, 0.0),
		Vector2(w * 0.16, h * 0.55),
		Vector2(w * 0.45, h * 0.55),
		Vector2(w * 0.34, h),
		Vector2(w * 0.86, h * 0.40),
		Vector2(w * 0.53, h * 0.40),
	])
	draw_colored_polygon(pts, tint)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.5), 1.0)


func _draw_cup() -> void:
	var w := size.x
	var h := size.y
	var body := Rect2(w * 0.10, h * 0.30, w * 0.62, h * 0.55)
	# Oor eerst, zodat de beker er overheen valt en het oor er niet doorheen steekt.
	draw_arc(Vector2(w * 0.74, h * 0.52), w * 0.20, -PI * 0.5, PI * 0.5, 10, tint, 2.0)
	draw_rect(body, tint)
	draw_rect(body, Color(0, 0, 0, 0.45), false, 1.0)
	# Schoteltje
	draw_rect(Rect2(w * 0.02, h * 0.86, w * 0.78, h * 0.12), tint)
	# Damp: twee streepjes boven de beker, zodat het als koffie leest en niet als emmer.
	var steam := Color(tint.r, tint.g, tint.b, 0.55)
	draw_line(Vector2(w * 0.28, h * 0.20), Vector2(w * 0.34, h * 0.04), steam, 1.0)
	draw_line(Vector2(w * 0.50, h * 0.20), Vector2(w * 0.56, h * 0.04), steam, 1.0)
