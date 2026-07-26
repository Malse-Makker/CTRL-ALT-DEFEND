extends Control

# Twee lichte events (GDD §8):
#   "phone" — je telefoon schuift trillend in beeld: rood is ophangen, groen is opnemen (en
#             dan mag je alsnog ophangen, want dat is de grap).
#   "form"  — een document van vijf pagina's dat je op elke handtekeningregel moet tekenen.
#
# Beide waren eerst één grijs vakje met één knop. Een tester wilde iets dat er ook echt uitziet
# als een telefoon en als een document, dus alles wordt hier getekend in plaats van met Labels
# opgebouwd. Zelfde interface naar buiten: setup / show_event / hide_event / set_timer_text /
# finished, zodat het level en de Art Room niets hoeven te weten van de binnenkant.

signal finished

const SCREEN_W := 960.0
const SCREEN_H := 540.0

const PAGES := [
	["DATA PROCESSING NOTICE (GDPR)",
		"You acknowledge that your keystrokes, coffee intake and idle time are processed on the basis of legitimate interest.",
		"Data is retained for 7 years, or until the next reorganisation, whichever comes first."],
	["ACCEPTABLE USE POLICY",
		"The corporate network may not be used for personal matters, including but not limited to: your bank, your doctor, and lunch.",
		"Exceptions require written approval from a manager who no longer works here."],
	["INFORMATION SECURITY",
		"Passwords must contain a capital, a number, a symbol and a memory you would rather forget.",
		"Never write your password down. Never forget your password."],
	["HEALTH & SAFETY",
		"Your chair has been adjusted to a height determined by someone who has never met you.",
		"In case of fire, please complete this form first."],
	["TONE OF VOICE GUIDELINES",
		"All internal communication shall be positive, concise, and free of the word 'no'.",
		"This document is itself an example of our tone of voice."],
]

var _kind: String = "phone"
var _timer_label: Label

# telefoon
var _answered: bool = false
var _shake: float = 0.0
var _slide: float = 0.0                  # 0 = uit beeld, 1 = volledig in beeld
var _phone_rect := Rect2()
var _btn_red := Rect2()
var _btn_green := Rect2()

# formulier
var _page: int = 0
var _signed: Array = []                  # per pagina een array bools, één per handtekeningregel
var _sign_rects: Array = []              # rects van de regels op de huidige pagina
var _doc := Rect2(280, 60, 400, 400)


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(SCREEN_W, SCREEN_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_timer_label = Label.new()
	_timer_label.position = Vector2(150, SCREEN_H - 30)
	_timer_label.size = Vector2(660, 20)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 11)
	_timer_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_label)


func setup(kind: String) -> void:
	_kind = kind
	_answered = false
	_page = 0
	_slide = 0.0
	_signed = []
	for p in PAGES:
		_signed.append([false, false])
	queue_redraw()


func show_event() -> void:
	visible = true
	_slide = 0.0
	queue_redraw()


func hide_event() -> void:
	visible = false


func set_timer_text(txt: String) -> void:
	if _timer_label != null:
		_timer_label.text = txt


func _process(delta: float) -> void:
	if not visible:
		return
	var rt: float = delta / maxf(Engine.time_scale, 0.001)
	# Inschuiven en trillen: een telefoon die stil in beeld staat leest niet als "je wordt gebeld".
	_slide = minf(1.0, _slide + rt * 3.0)
	if _kind == "phone" and not _answered:
		_shake += rt
	queue_redraw()


# ---------- invoer ----------

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = event.position
	accept_event()
	if _kind == "phone":
		if _btn_red.has_point(p):
			finished.emit()
		elif _btn_green.has_point(p) and not _answered:
			_answered = true        # opnemen helpt niet, je moet alsnog ophangen
			_shake = 0.0
		return
	# formulier: klik op een nog niet getekende regel
	for i in _sign_rects.size():
		if (_sign_rects[i] as Rect2).has_point(p) and not bool(_signed[_page][i]):
			_signed[_page][i] = true
			if _page_done():
				if _page >= PAGES.size() - 1:
					finished.emit()
				else:
					_page += 1
					_slide = 0.0    # volgende pagina schuift in
			return


func _page_done() -> bool:
	for v in _signed[_page]:
		if not bool(v):
			return false
	return true


# ---------- tekenen ----------

func _draw() -> void:
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color(0.04, 0.05, 0.08, 0.65))
	if _kind == "phone":
		_draw_phone()
	else:
		_draw_form()


func _draw_phone() -> void:
	var font := ThemeDB.fallback_font
	var w := 190.0
	var h := 340.0
	# Van onderen inschuiven, met een trilling die je in je ooghoek ziet.
	var rest_y: float = SCREEN_H / 2.0 - h / 2.0
	var y: float = lerpf(SCREEN_H + 20.0, rest_y, _slide)
	var dx: float = 0.0
	if not _answered and _slide >= 1.0:
		dx = sin(_shake * 42.0) * 3.0
	var x: float = SCREEN_W / 2.0 - w / 2.0 + dx
	_phone_rect = Rect2(x, y, w, h)

	# behuizing + scherm
	draw_rect(_phone_rect.grow(4.0), Color(0.06, 0.07, 0.09))
	draw_rect(_phone_rect, Color(0.13, 0.14, 0.18))
	draw_rect(_phone_rect, Color(0.45, 0.48, 0.56), false, 2.0)
	draw_rect(Rect2(x + w / 2.0 - 22.0, y + 8.0, 44.0, 5.0), Color(0.06, 0.07, 0.09))  # speaker

	draw_string(font, Vector2(x, y + 58.0), "Incoming call", HORIZONTAL_ALIGNMENT_CENTER, w, 13,
		Color(0.65, 0.7, 0.8))
	draw_string(font, Vector2(x, y + 88.0), "UNKNOWN NUMBER", HORIZONTAL_ALIGNMENT_CENTER, w, 17,
		Color(0.95, 0.96, 1.0))
	draw_string(font, Vector2(x, y + 110.0), "mobile", HORIZONTAL_ALIGNMENT_CENTER, w, 11,
		Color(0.5, 0.54, 0.62))

	# "profielfoto": een grijze silhouet-cirkel
	var pc := Vector2(x + w / 2.0, y + 168.0)
	draw_circle(pc, 34.0, Color(0.22, 0.24, 0.3))
	draw_circle(pc + Vector2(0, -10.0), 12.0, Color(0.4, 0.43, 0.5))
	draw_rect(Rect2(pc.x - 18.0, pc.y + 4.0, 36.0, 20.0), Color(0.4, 0.43, 0.5))

	if _answered:
		draw_string(font, Vector2(x, y + 224.0), "\"Hi, do you have a minute?\"",
			HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color(1.0, 0.8, 0.45))

	# knoppen: rood = ophangen, groen = opnemen
	var by: float = y + h - 76.0
	_btn_red = Rect2(x + 22.0, by, 60.0, 60.0)
	_btn_green = Rect2(x + w - 82.0, by, 60.0, 60.0)
	draw_circle(_btn_red.get_center(), 30.0, Color(0.85, 0.25, 0.25))
	draw_string(font, Vector2(_btn_red.position.x, by + 78.0), "Hang up",
		HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color(0.9, 0.6, 0.6))
	# Hoorn omlaag = ophangen, omhoog = opnemen. Klein maar genoeg om ze uit elkaar te houden.
	_draw_handset(_btn_red.get_center(), true)
	if not _answered:
		draw_circle(_btn_green.get_center(), 30.0, Color(0.25, 0.75, 0.4))
		_draw_handset(_btn_green.get_center(), false)
		draw_string(font, Vector2(_btn_green.position.x, by + 78.0), "Answer",
			HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color(0.6, 0.9, 0.7))
	else:
		draw_circle(_btn_green.get_center(), 30.0, Color(0.2, 0.24, 0.28))
		draw_string(font, Vector2(_btn_green.position.x, by + 78.0), "On call",
			HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color(0.45, 0.48, 0.56))


func _draw_handset(c: Vector2, down: bool) -> void:
	# Simpele hoorn: twee uiteinden met een beugel ertussen, gedraaid als je ophangt.
	var col := Color(1, 1, 1, 0.9)
	var a: float = 2.4 if down else -0.7
	var d := Vector2(cos(a), sin(a))
	var n := Vector2(-d.y, d.x)
	draw_line(c - d * 9.0, c + d * 9.0, col, 5.0)
	draw_line(c - d * 9.0 - n * 5.0, c - d * 9.0 + n * 5.0, col, 5.0)
	draw_line(c + d * 9.0 - n * 5.0, c + d * 9.0 + n * 5.0, col, 5.0)


func _draw_form() -> void:
	var font := ThemeDB.fallback_font
	var page: Array = PAGES[_page]
	var slide_x: float = (1.0 - _slide) * 40.0
	var d := Rect2(_doc.position + Vector2(slide_x, 0), _doc.size)

	# Papier met een schaduw eronder, zodat het als document leest en niet als dialoogvenster.
	draw_rect(Rect2(d.position + Vector2(6, 6), d.size), Color(0, 0, 0, 0.35))
	draw_rect(d, Color(0.93, 0.92, 0.88))
	draw_rect(d, Color(0.6, 0.6, 0.58), false, 1.0)

	var ink := Color(0.15, 0.16, 0.2)
	var faint := Color(0.45, 0.46, 0.5)
	draw_string(font, d.position + Vector2(20, 34), "CORPORATE COMPLIANCE PACK",
		HORIZONTAL_ALIGNMENT_LEFT, d.size.x - 40, 11, faint)
	draw_line(d.position + Vector2(20, 44), d.position + Vector2(d.size.x - 20, 44), faint, 1.0)
	draw_string(font, d.position + Vector2(20, 72), String(page[0]),
		HORIZONTAL_ALIGNMENT_LEFT, d.size.x - 40, 15, ink)

	var y: float = 104.0
	for i in range(1, page.size()):
		y += _draw_wrapped(font, String(page[i]), d.position + Vector2(20, y), d.size.x - 40, ink)
		y += 14.0

	# Handtekeningregels
	_sign_rects = []
	var labels := ["Signature", "Initials"]
	for i in 2:
		var ry: float = d.position.y + d.size.y - 118.0 + float(i) * 52.0
		var r := Rect2(d.position.x + 20.0, ry, d.size.x - 40.0, 40.0)
		_sign_rects.append(r)
		draw_string(font, Vector2(r.position.x, r.position.y - 2.0), labels[i],
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 10, faint)
		draw_line(Vector2(r.position.x, r.position.y + 30.0),
			Vector2(r.position.x + r.size.x, r.position.y + 30.0), Color(0.3, 0.32, 0.38), 1.0)
		if bool(_signed[_page][i]):
			_draw_squiggle(r)
		else:
			# Alleen de nog-te-tekenen regel licht op; anders zoek je waar je moet klikken.
			draw_rect(r, Color(0.95, 0.85, 0.35, 0.18))
			draw_rect(r, Color(0.85, 0.7, 0.25), false, 1.0)
			draw_string(font, Vector2(r.position.x, r.position.y + 22.0), "click to sign",
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color(0.5, 0.45, 0.2))

	draw_string(font, Vector2(d.position.x, d.position.y + d.size.y - 16.0),
		"Page %d of %d" % [_page + 1, PAGES.size()], HORIZONTAL_ALIGNMENT_CENTER, d.size.x, 11, faint)

	# Voortgang naast het document
	for i in PAGES.size():
		var col: Color = Color(0.4, 0.85, 0.55) if i < _page else (
			Color(0.95, 0.85, 0.45) if i == _page else Color(0.3, 0.32, 0.38))
		draw_rect(Rect2(d.position.x + d.size.x + 16.0, d.position.y + 8.0 + float(i) * 22.0, 12.0, 12.0), col)


func _draw_wrapped(font: Font, text: String, pos: Vector2, width: float, col: Color) -> float:
	# Miniatuur-woordafbreker: draw_string wrapt niet, en de policy-teksten zijn te lang
	# voor één regel.
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var y: float = 0.0
	for w in words:
		var test: String = line + (" " if line != "" else "") + w
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > width and line != "":
			draw_string(font, pos + Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, 12, col)
			y += 16.0
			line = w
		else:
			line = test
	if line != "":
		draw_string(font, pos + Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, 12, col)
		y += 16.0
	return y


func _draw_squiggle(r: Rect2) -> void:
	# Een gekrabbelde handtekening: vaste vorm, ziet er handgeschreven genoeg uit.
	var col := Color(0.15, 0.2, 0.55)
	var pts := PackedVector2Array()
	var n: int = 26
	for i in n:
		var t: float = float(i) / float(n - 1)
		var x: float = r.position.x + 24.0 + t * (r.size.x * 0.55)
		var y: float = r.position.y + 22.0 - sin(t * TAU * 1.6) * 9.0 - t * 4.0
		pts.append(Vector2(x, y))
	draw_polyline(pts, col, 2.0)
