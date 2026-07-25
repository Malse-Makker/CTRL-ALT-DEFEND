extends Node2D

# ART ROOM — showroom en testbank, geen gameplay. Toont alle tower-sprites en laat alle
# vijanden rondjes lopen, met knoppen om elk geluid en elk effect los af te spelen.
# Bedoeld om te zien of nieuwe art en effecten in de stijl passen zonder een level te spelen.
#
# Twee dingen worden hier bewust omzeild, zonder de gameplay-code aan te passen:
#  - Towers tekenen normaal een range-cirkel; 18 daarvan over elkaar is onleesbaar.
#    range_radius op 0 zetten na configure() laat de cirkel weg maar houdt sprite en
#    level-stipjes intact.
#  - Vijanden doen queue_free() zodra ze het eind van hun pad halen. Ze lopen hier op een
#    gesloten ring, en bij reached_end zetten we er meteen een verse neer.

signal closed

const SCREEN_W := 960.0
const SCREEN_H := 540.0
const TowerScript = preload("res://scripts/tower.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const FxLayer = preload("res://scripts/fx_layer.gd")
const Sfx = preload("res://scripts/sfx.gd")
const QteProjector = preload("res://scripts/qte_projector.gd")
const QtePizza = preload("res://scripts/qte_pizza.gd")
const QteDino = preload("res://scripts/qte_dino.gd")
const QteClick = preload("res://scripts/qte_click.gd")

# Alle 14 torens, in dezelfde volgorde als de shop (vrijspeelvolgorde). Stond hier eerder op
# 11 -- Pomodoro, Reply All en Ctrl+Alt+Del ontbraken dus in de showroom.
const TOWER_ORDER := ["coffee", "auto", "phones", "ceo", "filter", "scrum", "trap",
	"chain", "machinegun", "multishot", "pomodoro", "splash", "keyboard", "ctrlaltdel"]
const RING_STEPS := 32          # punten per rondje; hoger = ronder maar meer padpunten

var _rings: Dictionary = {}     # type_id -> pad
var _players: Dictionary = {}
var fx: Node2D
var flash_rect: ColorRect
var _flash_time: float = 0.0
var _flash_col: Color = Color(1, 0, 0)
var _smoke_time: float = 0.0
var big_label: Label
var _big_timer: float = 0.0
var _demo_enemies: Array = []   # de vijanden waarop we statuseffecten demonstreren
var qte: Control                # de projector-mini-game (gedeelde component)
var _qte_time: float = 0.0      # auto-skip-aftelling zodat je altijd terug kunt
var pizza_qte: Control
var dino_qte: Control
var click_qte: Control

# Alles wat inhoud is hangt onder content; scrollen = die laag verschuiven. De vaste kop en
# de overlays blijven in hun eigen CanvasLayer staan. Node2D-scrollen in plaats van een
# ScrollContainer, omdat towers en enemies Node2D's zijn en die scrollen daar niet in mee.
var content: Node2D
var _scroll: float = 0.0
var _content_h: float = SCREEN_H
const HEADER_H := 34.0
const SCROLL_STEP := 60.0

func _ready() -> void:
	# Een level kan time_scale op 0 hebben laten staan (pauze/plan-fase); hier moet
	# alles gewoon lopen.
	Engine.time_scale = 1.0
	_build_background()
	content = Node2D.new()
	content.position = Vector2(0, HEADER_H)
	add_child(content)
	fx = FxLayer.new()
	fx.z_index = 5
	content.add_child(fx)
	_build_audio()
	var y: float = 10.0
	y = _build_towers(y)
	y = _build_enemies(y)
	y = _build_demo_buttons(y)
	_content_h = y + 20.0
	_build_ui()
	_build_qte()

func _build_qte() -> void:
	# Dezelfde mini-game-component als in het level, hier los te testen. Eigen CanvasLayer
	# zodat de overlay boven de showroom-UI valt.
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	qte = QteProjector.new()
	qte.play_cb = Callable(self, "_play")
	qte.solved.connect(func():
		qte.hide_qte()
		_big_msg("PROJECTOR CONNECTED", Color(0.6, 1.0, 0.7)))
	qte.message.connect(func(text: String): _big_msg(text, Color(1.0, 0.85, 0.45)))
	layer.add_child(qte)
	# De overige vier mini-games stonden hier helemaal niet in, terwijl ze net zo goed
	# getest moeten kunnen worden. Zelfde componenten als in het level.
	pizza_qte = QtePizza.new()
	pizza_qte.finished.connect(func():
		pizza_qte.hide_event()
		_big_msg("PIZZA GONE", Color(0.6, 1.0, 0.7)))
	layer.add_child(pizza_qte)
	dino_qte = QteDino.new()
	dino_qte.dodged.connect(func(): _big_msg("DODGED", Color(0.6, 1.0, 0.7)))
	layer.add_child(dino_qte)
	click_qte = QteClick.new()
	click_qte.finished.connect(func():
		click_qte.hide_event()
		_big_msg("HANDLED", Color(0.6, 1.0, 0.7)))
	layer.add_child(click_qte)

func _demo_mini(which: String) -> void:
	match which:
		"pizza":
			pizza_qte.start_event()
			_qte_time = 14.0
		"dino":
			dino_qte.start_event()
			_qte_time = 14.0
		"phone", "form":
			click_qte.setup(which)
			click_qte.show_event()
			_qte_time = 14.0

func _demo_qte() -> void:
	if qte.visible:
		return
	qte.show_qte()
	_qte_time = 12.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

# ---------- geluid ----------

func _build_audio() -> void:
	# Zelfde geluiden als in het level (scripts/level.gd), zodat je hier hoort wat je
	# straks in het spel hoort.
	var made := {
		"auto": Sfx.noise(0.09, 0.30, 0.30, 2.5),
		"ceo": Sfx.thump(190.0, 0.26, 0.50),
		"phones": Sfx.sweep(900.0, 300.0, 0.18, 0.22),
		"kill": Sfx.noise(0.13, 0.26, 0.5, 2.0),
		"buy": Sfx.sweep(420.0, 720.0, 0.12, 0.35),
		"upgrade": Sfx.sweep(520.0, 1040.0, 0.22, 0.35),
		"sell": Sfx.chime(880.0, 0.34, 0.32),
		"leak": Sfx.tone(150.0, 0.30, 0.45, 1.4),
		"alarm": Sfx.siren(2.6, 0.30),
		"lunch": Sfx.alarm_clock(0.28),
		"crowd": Sfx.crowd(2.2, 0.22),
		"coffee": Sfx.bubble(0.5, 0.30),
		"ambient": Sfx.typing(12.0, 0.30),
	}
	for key in made.keys():
		var p := AudioStreamPlayer.new()
		p.stream = made[key]
		if key == "ambient":
			p.bus = "Music"
		elif key in ["buy", "upgrade", "sell"]:
			p.bus = "BuySFX"
		elif key == "coffee":
			p.bus = "CoffeeSFX"
		elif key in ["leak", "alarm", "lunch", "crowd"]:
			p.bus = "EventSFX"
		else:
			p.bus = "ShootSFX"
		add_child(p)
		_players[key] = p

func _play(key: String) -> void:
	var p: AudioStreamPlayer = _players.get(key)
	if p != null:
		if p.playing:
			p.stop()
		p.play()

# ---------- achtergrond ----------

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.10, 0.11, 0.14)
	bg.z_index = -10
	add_child(bg)
	# Alleen de bovenste scheidingslijn: een tweede op 386 liep dwars door de namen
	# van de onderste vijandenrij. De sectiekopjes geven daar genoeg structuur.
	for y in [196.0]:
		var d := ColorRect.new()
		d.position = Vector2(24, y)
		d.size = Vector2(SCREEN_W - 48, 1)
		d.color = Color(1, 1, 1, 0.08)
		d.z_index = -9
		add_child(d)

func _label(text: String, pos: Vector2, size: int, col: Color, width: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if width > 0.0:
		# Afkappen met een ellipsis, niet afbreken: een Label dat niet in een container zit
		# maakt zichzelf net zo breed als zijn tekst, dus autowrap doet hier niets en lange
		# namen liepen het scherm uit en over de buren heen.
		l.size.x = width
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(l)
	return l

# ---------- towers ----------

func _section(y: float, title: String, hint: String = "") -> float:
	# Kopregel met een lijn eronder: de secties liepen zonder scheiding in elkaar over.
	_label(title, Vector2(24, y), 13, Color(0.95, 0.85, 0.45))
	if hint != "":
		_label(hint, Vector2(24, y + 17.0), 10, Color(0.55, 0.6, 0.7))
	var d := ColorRect.new()
	d.position = Vector2(24, y + (32.0 if hint != "" else 20.0))
	d.size = Vector2(SCREEN_W - 48, 1)
	d.color = Color(1, 1, 1, 0.10)
	content.add_child(d)
	return y + (42.0 if hint != "" else 30.0)

func _build_towers(y0: float) -> float:
	var y := _section(y0, "TOWERS (%d)" % TOWER_ORDER.size(),
		"Each column is one tower, level 1 to 3 from top to bottom.")
	var defs: Dictionary = TowerScript.defs()
	# 5 kolommen in plaats van alles op één rij: met 14 torens werd een kolom 60px breed en
	# vielen de namen over elkaar heen.
	var cols: int = 5
	var col_w: float = (SCREEN_W - 60.0) / float(cols)
	var row_h: float = 152.0
	for i in TOWER_ORDER.size():
		var id: String = String(TOWER_ORDER[i])
		if not defs.has(id):
			continue
		var d: Dictionary = defs[id]
		var cx: float = 40.0 + col_w * (float(i % cols) + 0.5)
		var ry: float = y + float(i / cols) * row_h
		_label(String(d["name"]), Vector2(cx - col_w * 0.5 + 6.0, ry), 11,
			Color(0.85, 0.87, 0.92), col_w - 12.0)
		var levels: int = int(d["levels"].size())
		for lvl in range(1, levels + 1):
			var t = TowerScript.new()
			t.configure(id, lvl)
			t.range_radius = 0.0        # geen range-cirkel in de showroom
			t.position = Vector2(cx, ry + 40.0 + float(lvl - 1) * 36.0)
			content.add_child(t)
			_label("L%d" % lvl, Vector2(cx - col_w * 0.5 + 6.0, ry + 32.0 + float(lvl - 1) * 36.0),
				9, Color(0.45, 0.48, 0.56))
	var rows: int = int(ceil(float(TOWER_ORDER.size()) / float(cols)))
	return y + float(rows) * row_h + 10.0

# ---------- vijanden ----------

func _build_enemies(y0: float) -> float:
	var ids: Array = EnemyScript.defs().keys()
	var y := _section(y0, "ENEMIES (%d)" % ids.size(),
		"Each one walks its own loop — that is the walk animation.")
	# 6 kolommen: bij 15 was een cel 64px breed en overlapten de namen elkaar; 6 geeft 160px,
	# genoeg voor vrijwel elke naam zonder afkappen.
	var cols: int = 6
	var cell_w: float = SCREEN_W / float(cols)
	var cell_h: float = 116.0   # ruimte voor de grootste boss plus zijn naam eronder
	for i in ids.size():
		var id: String = String(ids[i])
		var d: Dictionary = EnemyScript.defs()[id]
		var cx: float = cell_w * (float(i % cols) + 0.5)
		var cy: float = y + 32.0 + float(i / cols) * cell_h
		var ring: float = 26.0
		var path := PackedVector2Array()
		for s2 in RING_STEPS + 1:          # +1 sluit de ring
			var a: float = TAU * float(s2) / float(RING_STEPS)
			path.append(Vector2(cx + cos(a) * ring, cy + sin(a) * ring * 0.5))
		_rings[id] = path
		_spawn_enemy(id, path)
		# 44 en niet 28: bosses zijn ~48px en liepen op hun rondje over hun eigen naam heen.
		_label(String(d["name"]), Vector2(cx - cell_w * 0.5 + 4.0, cy + 44.0), 9,
			Color(0.75, 0.78, 0.85), cell_w - 8.0)
	var rows: int = int(ceil(float(ids.size()) / float(cols)))
	return y + 32.0 + float(rows) * cell_h + 10.0

func _spawn_enemy(id: String, path: PackedVector2Array) -> void:
	var e = EnemyScript.new()
	e.configure(id)
	# De silence-aura van de Kletskous is 95px breed en zou over de buurcellen vallen.
	e.disrupt_radius = 0.0
	e.setup(path)
	e.reached_end.connect(_on_lap_done.bind(id))
	content.add_child(e)
	_demo_enemies.append(e)

func _on_lap_done(enemy, id: String) -> void:
	_demo_enemies.erase(enemy)
	if not _rings.has(id):
		return
	call_deferred("_spawn_enemy", id, _rings[id])

func _living() -> Array:
	var out: Array = []
	for e in _demo_enemies:
		if is_instance_valid(e):
			out.append(e)
	return out

# ---------- effecten ----------

func _big_msg(text: String, col: Color) -> void:
	big_label.text = text
	big_label.add_theme_color_override("font_color", col)
	_big_timer = 2.0

func _screen_flash(col: Color, dur: float) -> void:
	_flash_col = col
	_flash_time = dur

func _process(delta: float) -> void:
	# Auto-skip geldt voor élke mini-game: je moet er altijd uit kunnen zonder 'm te halen.
	if qte != null and qte.visible:
		_qte_time -= delta
		qte.set_timer_text("Auto-skips in %ds" % int(ceil(maxf(_qte_time, 0.0))))
		if _qte_time <= 0.0:
			qte.hide_qte()
	elif pizza_qte != null and pizza_qte.visible:
		_qte_time -= delta
		if _qte_time <= 0.0:
			pizza_qte.hide_event()
	elif dino_qte != null and dino_qte.visible:
		_qte_time -= delta
		if _qte_time <= 0.0:
			dino_qte.hide_event()
	elif click_qte != null and click_qte.visible:
		_qte_time -= delta
		click_qte.set_timer_text("Auto-skips in %ds" % int(ceil(maxf(_qte_time, 0.0))))
		if _qte_time <= 0.0:
			click_qte.hide_event()
	if _big_timer > 0.0:
		_big_timer -= delta
		big_label.modulate = Color(1, 1, 1, clampf(_big_timer / 0.8, 0.0, 1.0))
		if _big_timer <= 0.0:
			big_label.text = ""
	if _flash_time > 0.0:
		_flash_time -= delta
		var pulse: float = 0.20 + 0.10 * sin(Time.get_ticks_msec() * 0.012)
		flash_rect.color = Color(_flash_col.r, _flash_col.g, _flash_col.b,
			pulse * clampf(_flash_time, 0.0, 1.0))
		_smoke_time -= delta
		if _smoke_time <= 0.0 and _flash_col.r > 0.9 and _flash_col.g < 0.5:
			_smoke_time = 0.18
			fx.smoke(Vector2(randf_range(60.0, SCREEN_W - 60.0), randf_range(230.0, 380.0)),
				randf_range(14.0, 26.0), randf_range(-12.0, 12.0))
	elif flash_rect.color.a > 0.0:
		flash_rect.color = Color(_flash_col.r, _flash_col.g, _flash_col.b, 0.0)

# --- demo-acties voor de knoppen ---

func _demo_shot(id: String) -> void:
	var from := Vector2(120, 440)
	var to := Vector2(820, 440)
	fx.shot(from, to, id, "damage")
	_play(id)

func _demo_kill() -> void:
	for e in _living():
		fx.puff(e.position, e.color, clampf(e.radius * 0.9, 8.0, 34.0))
		if e.coffee_reward >= 1.0:
			fx.floater(e.position + Vector2(0, -e.radius), "+%d" % int(round(e.coffee_reward)),
				Color(0.95, 0.8, 0.45))
	_play("kill")

func _demo_coffee() -> void:
	for t in get_children():
		if t is Node2D and t.get("role") == "economy":
			fx.floater(t.position + Vector2(0, -16), "+2", Color(0.92, 0.80, 0.55))
	_play("coffee")

func _demo_status(what: String) -> void:
	# Zet het effect op alle vijanden tegelijk, zodat je in één blik ziet hoe het eruitziet.
	for e in _living():
		match what:
			"stun":
				e.cc_immune_below = 0     # in de showroom mag iedereen gestunt worden
				e.apply_stun(2.5, 3)
			"slow":
				e.apply_slow(0.4, 3.0)
			"shield":
				e.max_shield = maxf(e.max_shield, 20.0)
				e.shield = e.max_shield
			"hurt":
				e.hp = maxf(1.0, e.max_hp * 0.25)   # laat HP-balken en rage zien
				e.queue_redraw()
			"reset":
				e.hp = e.max_hp
				e.shield = e.max_shield
				e.stun_time = 0.0
				e.slow_time = 0.0
				e.queue_redraw()

func _demo_alarm() -> void:
	_big_msg("FIRE ALARM", Color(1.0, 0.45, 0.4))
	_screen_flash(Color(1.0, 0.25, 0.2), 4.0)
	_play("alarm")

func _demo_lunch() -> void:
	_big_msg("LUNCH BREAK", Color(1.0, 0.85, 0.45))
	_screen_flash(Color(1.0, 0.8, 0.35), 4.0)
	_play("lunch")
	_play("crowd")

func _demo_boss_phase() -> void:
	_big_msg("PHASE 3\nIMPROVEMENT PLAN", Color(1.0, 0.45, 0.4))
	_screen_flash(Color(1.0, 0.3, 0.3), 1.2)

# ---------- ui ----------

func _btn(text: String, cb: Callable, pos: Vector2, w: float = 86.0) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = Vector2(w, 22)
	b.size = Vector2(w, 22)
	b.add_theme_font_size_override("font_size", 10)
	b.pressed.connect(cb)
	content.add_child(b)
	return b

func _row(items: Array, y: float, w: float) -> float:
	# Legt knoppen naast elkaar en breekt af zodra de rij vol is, zodat er nooit iets
	# buiten beeld of over de volgende sectie heen valt.
	var x: float = 24.0
	var yy: float = y
	for it in items:
		if x + w > SCREEN_W - 24.0:
			x = 24.0
			yy += 28.0
		_btn(String(it[0]), it[1], Vector2(x, yy), w)
		x += w + 6.0
	return yy + 34.0

func _build_demo_buttons(y0: float) -> float:
	var y := _section(y0, "SOUNDS", "Every sound in the game, on its own.")
	var sounds: Array = []
	for pair in [["Auto-Reply", "auto"], ["Artillery", "ceo"], ["Headphones", "phones"],
			["Coffee", "coffee"], ["Kill", "kill"], ["Buy", "buy"], ["Upgrade", "upgrade"],
			["Sell", "sell"], ["Focus lost", "leak"], ["Lunch bell", "lunch"], ["Crowd", "crowd"],
			["Fire alarm", "alarm"]]:
		var key: String = String(pair[1])
		if key in ["auto", "ceo", "phones"]:
			sounds.append([String(pair[0]), func(): _demo_shot(key)])
		else:
			sounds.append([String(pair[0]), func(): _play(key)])
	sounds.append(["Ambient on", func(): _play("ambient")])
	sounds.append(["Ambient off", func():
		var pl: AudioStreamPlayer = _players.get("ambient")
		if pl != null:
			pl.stop()])
	y = _row(sounds, y, 104.0)

	y = _section(y, "STATUS EFFECTS", "Applied to every enemy at once.")
	y = _row([["Stun (zzz)", func(): _demo_status("stun")],
		["Slow (coffee ring)", func(): _demo_status("slow")],
		["Shield", func(): _demo_status("shield")],
		["Damage them", func(): _demo_status("hurt")],
		["Reset", func(): _demo_status("reset")]], y, 130.0)

	y = _section(y, "EFFECTS & EVENTS")
	y = _row([["Kill puff + coins", _demo_kill], ["Coffee made", _demo_coffee],
		["FIRE ALARM", _demo_alarm], ["LUNCH BREAK", _demo_lunch],
		["Boss phase", _demo_boss_phase], ["Clear effects", func(): fx.clear()]], y, 130.0)

	y = _section(y, "MINI-GAMES", "All five, exactly as they appear in a level. Escape closes one.")
	y = _row([["Projector QTE", _demo_qte],
		["Eat the Pizza", func(): _demo_mini("pizza")],
		["No Internet (dino)", func(): _demo_mini("dino")],
		["Phone: hang up", func(): _demo_mini("phone")],
		["Form: sign here", func(): _demo_mini("form")]], y, 150.0)
	return y

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(SCREEN_W, SCREEN_H)
	flash_rect.color = Color(1, 0, 0, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(flash_rect)

	big_label = Label.new()
	big_label.position = Vector2(0, 150)
	big_label.size = Vector2(SCREEN_W, 60)
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.add_theme_font_size_override("font_size", 28)
	big_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_label.modulate = Color(1, 1, 1, 0)
	canvas.add_child(big_label)

	# Vaste kop: blijft staan terwijl de inhoud eronder doorscrolt.
	var hdr := ColorRect.new()
	hdr.size = Vector2(SCREEN_W, HEADER_H)
	hdr.color = Color(0.08, 0.09, 0.12)
	canvas.add_child(hdr)
	var title := Label.new()
	title.text = "ART ROOM"
	title.position = Vector2(24, 5)
	title.add_theme_font_size_override("font_size", 18)
	canvas.add_child(title)
	var hint := Label.new()
	hint.text = "scroll with the mouse wheel"
	hint.position = Vector2(140, 12)
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.54, 0.62))
	canvas.add_child(hint)

	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(SCREEN_W - 90, 4)
	back.custom_minimum_size = Vector2(70, 24)
	back.pressed.connect(func(): closed.emit())
	canvas.add_child(back)

func _lbl(text: String, pos: Vector2, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent != null:
		parent.add_child(l)
	return l

func _scroll_by(amount: float) -> void:
	# De inhoud is hoger dan het scherm; onderaan stopt hij zodat je nooit in het niets scrollt.
	var min_y: float = minf(0.0, SCREEN_H - HEADER_H - _content_h)
	_scroll = clampf(_scroll + amount, min_y, 0.0)
	content.position.y = HEADER_H + _scroll

func _mini_open() -> bool:
	for m in [qte, pizza_qte, dino_qte, click_qte]:
		if m != null and m.visible:
			return true
	return false

func _close_minis() -> void:
	if qte != null and qte.visible:
		qte.hide_qte()
	if pizza_qte != null and pizza_qte.visible:
		pizza_qte.hide_event()
	if dino_qte != null and dino_qte.visible:
		dino_qte.hide_event()
	if click_qte != null and click_qte.visible:
		click_qte.hide_event()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Escape sluit eerst een openstaande mini-game -- anders val je uit de Art Room
		# terwijl je alleen de demo wilde stoppen.
		if _mini_open():
			_close_minis()
		else:
			closed.emit()
		return
	if event is InputEventMouseButton and event.pressed and not _mini_open():
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_by(-SCROLL_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_by(SCROLL_STEP)
