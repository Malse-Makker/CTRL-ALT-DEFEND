extends Control

# QTE "Connect the Projector" — herbruikbare mini-game (vergaderzaal-hazard).
#
# Zelfstandige view + interactie: bouwt beide fases, handelt het slepen af en meldt het
# resultaat via signalen. De AANROEPER bepaalt wanneer de QTE verschijnt/sluit en regelt
# een eventuele aftel-timer; deze node is puur de mini-game. Zo draaien level.gd (echte
# hazard) en de Art Room (los testen) op exact dezelfde code.
#
# Deze node IS de volledige overlay: full-rect Control met gui_input voor het slepen.

signal solved                        # speler koos de juiste optie (verbind → sluiten + afhandelen)
signal message(text: String)         # hint-tekst voor de aanroeper (bv. bij een foute keuze)

const SCREEN_W := 960.0
const SCREEN_H := 540.0
const SCREEN_INNER := Vector2(364.0, 252.0)   # het zichtbare monitor-scherm (achtergrond + taakbalk)

var play_cb: Callable = Callable()   # optioneel: aanroeper geeft _play(key) mee voor geluid

var _stage: String = "cables"        # "cables" → "sliding" → "screen"
var _stage1: Control
var _stage2: Control
var _cables: Array = []              # [{rect, cord, home, target, anchor, plugged}]
var _dragging: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _timer_label: Label
var _popup: Control

func _ready() -> void:
	# Grootte expliciet zetten: een FULL_RECT-anchorpreset levert géén grootte op onder een
	# CanvasLayer (anchors gelden alleen t.o.v. een parent-Control), waardoor GUI-picking een
	# 0x0-control vindt en het slepen via gui_input nooit binnenkomt.
	position = Vector2.ZERO
	size = Vector2(SCREEN_W, SCREEN_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	gui_input.connect(_on_gui_input)
	_build()

func _play(key: String) -> void:
	if play_cb.is_valid():
		play_cb.call(key)

# ---------- kleine opbouw-helpers ----------

func _rect(parent: Control, pos: Vector2, size: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _label(parent: Control, txt: String, pos: Vector2, size: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _btn(text: String, cb: Callable, w: float, h: float) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.pressed.connect(cb)
	return b

# ---------- opbouw ----------

func _build() -> void:
	# Fase 1: sleep de VGA- en power-kabel naar de juiste poort op de projector. Fase 2:
	# pixel-art Windows-XP-scherm met een display-pop-up — klik de 2e optie.
	_rect(self, Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H), Color(0.04, 0.05, 0.08, 0.72))
	_label(self, "CONNECT THE PROJECTOR", Vector2(150, 40), Vector2(660, 30), 22, Color(0.7, 0.85, 1.0))
	_timer_label = _label(self, "", Vector2(150, SCREEN_H - 40), Vector2(660, 20), 11, Color(0.6, 0.65, 0.75))

	# ---------- Fase 1: kabels slepen ----------
	_stage1 = Control.new()
	_stage1.position = Vector2.ZERO
	_stage1.size = Vector2(SCREEN_W, SCREEN_H)
	_stage1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage1)
	_label(_stage1, "Drag each cable up into its matching port.", Vector2(230, 78), Vector2(500, 20), 13, Color(0.8, 0.82, 0.88))
	# grote, gedetailleerde projector-sprite (96px, getoond op 2,6x voor scherpe pixels)
	var proj_pos := Vector2(355, 100)
	var proj_scale := 2.6
	var projector := TextureRect.new()
	projector.texture = load("res://art/ui/qte_projector.png")
	projector.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	projector.position = proj_pos
	projector.size = Vector2(96, 96) * proj_scale
	projector.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	projector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage1.add_child(projector)
	# poort-markeringen uitgelijnd op de poorten van de sprite (onderrand). De sprite toont de
	# blauwe VGA links en een blauwe HDMI-poort rechts; daar leggen we de sleepdoelen op.
	var vga_port := proj_pos + Vector2(25, 74) * proj_scale
	var pwr_port := proj_pos + Vector2(69, 74) * proj_scale
	_rect(_stage1, vga_port - Vector2(16, 11), Vector2(32, 22), Color(0.3, 0.55, 1.0, 0.35))
	_label(_stage1, "VGA", vga_port - Vector2(24, 30), Vector2(48, 16), 11, Color(0.7, 0.85, 1.0))
	_rect(_stage1, pwr_port - Vector2(16, 11), Vector2(32, 22), Color(1.0, 0.85, 0.3, 0.3))
	_label(_stage1, "PWR", pwr_port - Vector2(24, 30), Vector2(48, 16), 11, Color(1.0, 0.9, 0.6))
	# kabels onderaan (sleepbaar, echte sprites)
	_cables = []
	_add_cable("VGA", "res://art/ui/qte_vga.png", Vector2(360, 410), vga_port)
	_add_cable("PWR", "res://art/ui/qte_power.png", Vector2(520, 410), pwr_port)

	# ---------- Fase 2: XP-scherm + pop-up ----------
	_stage2 = Control.new()
	_stage2.position = Vector2.ZERO
	_stage2.size = Vector2(SCREEN_W, SCREEN_H)
	_stage2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage2.visible = false
	add_child(_stage2)
	# monitor-bezel
	_rect(_stage2, Vector2(283, 93), Vector2(394, 278), Color(0.14, 0.14, 0.16))
	# Het scherm zelf is een apart, GECLIPT vlak: alles wat erin zit (achtergrond, taakbalk,
	# pop-up) blijft binnen de monitor — de pop-up kan er dus nooit meer overheen vallen.
	var screen := Control.new()
	screen.position = Vector2(298, 106)
	screen.size = SCREEN_INNER
	screen.clip_contents = true
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage2.add_child(screen)
	# XP Bliss-achtergrond
	var wall := TextureRect.new()
	wall.texture = load("res://art/ui/qte_xp_wall.png")
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wall.position = Vector2.ZERO
	wall.size = Vector2(SCREEN_INNER.x, SCREEN_INNER.y - 16.0)
	wall.stretch_mode = TextureRect.STRETCH_SCALE
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(wall)
	# taakbalk onderaan het scherm + "start"-knop
	_rect(screen, Vector2(0, SCREEN_INNER.y - 16.0), Vector2(SCREEN_INNER.x, 16), Color(0.2, 0.4, 0.75))
	_rect(screen, Vector2(4, SCREEN_INNER.y - 14.0), Vector2(46, 12), Color(0.4, 0.7, 0.3))
	# de XP-pop-up (klein → groot geanimeerd, past binnen het scherm)
	_popup = _build_popup()
	screen.add_child(_popup)

func _build_popup() -> Control:
	# Een echte Windows-XP-dialoog nagebouwd met styled nodes: titelbalk (blauw met highlight),
	# rode sluitknop, lichte body, een bericht en twee keuzeknoppen. Kleiner dan het scherm.
	var w := 264.0
	var h := 150.0
	var p := Control.new()
	p.size = Vector2(w, h)
	p.position = Vector2((SCREEN_INNER.x - w) * 0.5, (SCREEN_INNER.y - h) * 0.5 - 4.0)
	p.pivot_offset = Vector2(w, h) * 0.5      # klein→groot schaalt rond het midden
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.visible = false
	# slagschaduw + body + rand
	_rect(p, Vector2(5, 5), Vector2(w, h), Color(0, 0, 0, 0.28))
	_rect(p, Vector2(-1, -1), Vector2(w + 2, h + 2), Color(0.55, 0.55, 0.6))   # rand
	_rect(p, Vector2.ZERO, Vector2(w, h), Color(0.925, 0.914, 0.847))          # XP-dialooggrijs
	# titelbalk (XP-blauw met een lichtere highlight bovenaan)
	_rect(p, Vector2(2, 2), Vector2(w - 4, 22), Color(0.10, 0.28, 0.80))
	_rect(p, Vector2(2, 2), Vector2(w - 4, 7), Color(0.26, 0.47, 0.93))
	var t := _label(p, "Display Settings", Vector2(9, 3), Vector2(w - 60, 18), 12, Color(1, 1, 1))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# rode sluitknop — klikbaar, maar sluit niks: een meeting ontsnap je niet zo makkelijk
	_rect(p, Vector2(w - 24, 5), Vector2(17, 15), Color(0.85, 0.22, 0.16))
	_rect(p, Vector2(w - 24, 5), Vector2(17, 4), Color(0.95, 0.45, 0.40))
	_label(p, "x", Vector2(w - 24, 2), Vector2(17, 18), 12, Color(1, 1, 1))
	var close_btn := _btn("", func(): message.emit("You can't escape a meeting like that."), 17, 15)
	close_btn.position = Vector2(w - 24, 5)
	close_btn.flat = true
	p.add_child(close_btn)
	# bericht
	var m := _label(p, "How should the display show up?", Vector2(14, 32), Vector2(w - 28, 18), 12, Color(0.1, 0.1, 0.12))
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# twee opties — de 2e is de juiste (naar de projector)
	var opt1 := _btn("Show desktop only on this laptop", func(): message.emit("That keeps it on your laptop — try the other one."), w - 36, 26)
	opt1.position = Vector2(18, 62)
	opt1.add_theme_font_size_override("font_size", 10)
	p.add_child(opt1)
	var opt2 := _btn("Duplicate desktop to the projector", func(): solved.emit(), w - 36, 26)
	opt2.position = Vector2(18, 96)
	opt2.add_theme_font_size_override("font_size", 10)
	p.add_child(opt2)
	return p

func _pop_in() -> void:
	# klein → groot, snel (binnen een seconde), met een lichte overshoot zodat het "ploept"
	_popup.visible = true
	_popup.scale = Vector2(0.15, 0.15)
	var tw := create_tween()
	tw.tween_property(_popup, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _add_cable(tag: String, tex_path: String, home: Vector2, target: Vector2) -> void:
	# cord (Node2D-lijn) van een vast ankerpunt onderaan naar de stekker
	var cord := Line2D.new()
	cord.width = 3.0
	cord.default_color = Color(0.25, 0.25, 0.28)
	_stage1.add_child(cord)
	var rect := TextureRect.new()
	rect.texture = load(tex_path)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.position = home
	rect.size = Vector2(64, 40)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage1.add_child(rect)
	_label(rect, tag, Vector2(0, 40), Vector2(64, 14), 10, Color(0.85, 0.88, 0.95))
	var anchor := Vector2(home.x + 32, SCREEN_H - 6)
	_cables.append({"rect": rect, "cord": cord, "home": home, "target": target,
		"anchor": anchor, "plugged": false})
	_update_cord(_cables.size() - 1)

func _update_cord(i: int) -> void:
	var c: Dictionary = _cables[i]
	var plug: Vector2 = Vector2(c["rect"].position) + Vector2(32, 15)
	c["cord"].points = PackedVector2Array([c["anchor"], plug])

# ---------- besturing door de aanroeper ----------

func show_qte() -> void:
	_stage = "cables"
	_dragging = -1
	_stage1.position = Vector2.ZERO
	_stage2.position = Vector2.ZERO
	for i in _cables.size():
		var c: Dictionary = _cables[i]
		c["plugged"] = false
		c["rect"].position = c["home"]
		c["rect"].modulate = Color(1, 1, 1)
		_update_cord(i)
	if _popup != null:
		_popup.visible = false
	_stage1.visible = true
	_stage2.visible = false
	visible = true

func hide_qte() -> void:
	visible = false
	_dragging = -1

func set_timer_text(txt: String) -> void:
	if _timer_label != null:
		_timer_label.text = txt

# ---------- slepen ----------

func _on_gui_input(event: InputEvent) -> void:
	if not visible or _stage != "cables":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in _cables.size():
				var c: Dictionary = _cables[i]
				if not c["plugged"] and Rect2(c["rect"].position, c["rect"].size).has_point(event.position):
					_dragging = i
					_drag_offset = Vector2(c["rect"].position) - event.position
					break
		elif _dragging >= 0:
			var c: Dictionary = _cables[_dragging]
			var center: Vector2 = Vector2(c["rect"].position) + c["rect"].size * 0.5
			if center.distance_to(c["target"]) <= 46.0:
				c["plugged"] = true
				c["rect"].position = Vector2(c["target"]) - c["rect"].size * 0.5
				c["rect"].modulate = Color(0.7, 1.0, 0.7)
				_play("buy")
			else:
				c["rect"].position = c["home"]
			_update_cord(_dragging)
			_dragging = -1
			_check_cables()
	elif event is InputEventMouseMotion and _dragging >= 0:
		var c: Dictionary = _cables[_dragging]
		c["rect"].position = event.position + _drag_offset
		_update_cord(_dragging)

func _check_cables() -> void:
	for c in _cables:
		if not c["plugged"]:
			return
	# beide erin → schuif-animatie van de projector naar het XP-scherm
	_stage = "sliding"
	_stage2.position = Vector2(SCREEN_W, 0)
	_stage2.visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_stage1, "position:x", -SCREEN_W, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_stage2, "position:x", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(false)
	tw.tween_callback(func():
		_stage = "screen"
		_stage1.visible = false
		_pop_in())
