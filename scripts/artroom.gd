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

const TOWER_ORDER := ["auto", "coffee", "ceo", "phones", "filter", "scrum", "trap", "chain", "machinegun", "multishot", "keyboard"]
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

func _ready() -> void:
	# Een level kan time_scale op 0 hebben laten staan (pauze/plan-fase); hier moet
	# alles gewoon lopen.
	Engine.time_scale = 1.0
	_build_background()
	fx = FxLayer.new()
	fx.z_index = 5
	add_child(fx)
	_build_audio()
	_build_towers()
	_build_enemies()
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
		l.size.x = width
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(l)
	return l

# ---------- towers ----------

func _build_towers() -> void:
	_label("TOWERS — three upgrade levels each", Vector2(24, 30), 12, Color(0.6, 0.65, 0.75))
	var defs: Dictionary = TowerScript.defs()
	var col_w: float = (SCREEN_W - 80.0) / float(TOWER_ORDER.size())
	for i in TOWER_ORDER.size():
		var id: String = String(TOWER_ORDER[i])
		var d: Dictionary = defs[id]
		var cx: float = 60.0 + col_w * (float(i) + 0.5)
		_label(String(d["name"]), Vector2(cx - col_w * 0.5, 48.0), 10,
			Color(0.85, 0.87, 0.92), col_w)
		for lvl in range(1, 4):
			var t = TowerScript.new()
			t.configure(id, lvl)
			t.range_radius = 0.0        # geen range-cirkel in de showroom
			t.position = Vector2(cx, 86.0 + float(lvl - 1) * 38.0)
			add_child(t)
	for lvl in range(1, 4):
		_label("L%d" % lvl, Vector2(28, 78.0 + float(lvl - 1) * 38.0), 10,
			Color(0.55, 0.58, 0.66))

# ---------- vijanden ----------

func _build_enemies() -> void:
	var ids: Array = EnemyScript.defs().keys()
	_label("ENEMIES (%d) — each on its own loop" % ids.size(), Vector2(24, 204), 12,
		Color(0.6, 0.65, 0.75))
	# Genoeg kolommen om alles in 2 rijen te houden (anders loopt rij 3 over de knoppenbalk).
	# 29 vijanden (blok 2/3-bosses erbij) → 15 kolommen zodat alles in 2 rijen boven de UI blijft.
	var cols: int = 15
	var cell_w: float = SCREEN_W / float(cols)
	for i in ids.size():
		var id: String = String(ids[i])
		var d: Dictionary = EnemyScript.defs()[id]
		var cx: float = cell_w * (float(i % cols) + 0.5)
		var cy: float = 246.0 + float(i / cols) * 88.0
		var ring: float = 26.0
		var path := PackedVector2Array()
		for s in RING_STEPS + 1:          # +1 sluit de ring
			var a: float = TAU * float(s) / float(RING_STEPS)
			path.append(Vector2(cx + cos(a) * ring, cy + sin(a) * ring * 0.5))
		_rings[id] = path
		_spawn_enemy(id, path)
		_label(String(d["name"]), Vector2(cx - cell_w * 0.5, cy + 26.0), 9,
			Color(0.75, 0.78, 0.85), cell_w)

func _spawn_enemy(id: String, path: PackedVector2Array) -> void:
	var e = EnemyScript.new()
	e.configure(id)
	# De silence-aura van de Kletskous is 95px breed en zou over de buurcellen vallen.
	e.disrupt_radius = 0.0
	e.setup(path)
	e.reached_end.connect(_on_lap_done.bind(id))
	add_child(e)
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
	if qte != null and qte.visible:
		_qte_time -= delta
		qte.set_timer_text("Auto-skips in %ds" % int(ceil(maxf(_qte_time, 0.0))))
		if _qte_time <= 0.0:
			qte.hide_qte()
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
	return b

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

	var title := Label.new()
	title.text = "ART ROOM"
	title.position = Vector2(24, 4)
	title.add_theme_font_size_override("font_size", 20)
	canvas.add_child(title)

	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(SCREEN_W - 90, 6)
	back.custom_minimum_size = Vector2(70, 26)
	back.pressed.connect(func(): closed.emit())
	canvas.add_child(back)

	# --- knoppenbalk onderaan ---
	# Alle 11 geluiden op één rij: smallere knoppen met korte labels, zodat er niks wrapt
	# en op elkaar valt (v0.30.0: Sell, Lunch bell en Crowd kwamen erbij).
	var y0 := 400.0
	canvas.add_child(_lbl("SOUNDS", Vector2(24, y0 - 14)))
	var sounds := [["Auto", "auto"], ["Arty", "ceo"], ["Phones", "phones"],
		["Coffee", "coffee"], ["Kill", "kill"], ["Buy", "buy"], ["Upgrade", "upgrade"],
		["Sell", "sell"], ["Focus", "leak"], ["Lunch", "lunch"], ["Crowd", "crowd"]]
	for i in sounds.size():
		var key: String = String(sounds[i][1])
		var pos := Vector2(24 + float(i) * 84.0, y0)
		if key in ["auto", "ceo", "phones"]:
			canvas.add_child(_btn(String(sounds[i][0]), func(): _demo_shot(key), pos, 78))
		else:
			canvas.add_child(_btn(String(sounds[i][0]), func(): _play(key), pos, 78))

	var y1 := 444.0
	canvas.add_child(_lbl("STATUS EFFECTS  (on every enemy)", Vector2(24, y1 - 14)))
	for i in [["Stun (zzz)", "stun"], ["Slow (coffee ring)", "slow"], ["Shield", "shield"],
			["Damage them", "hurt"], ["Reset", "reset"]]:
		var what: String = String(i[1])
		var idx: int = [["stun"], ["slow"], ["shield"], ["hurt"], ["reset"]].find([what])
		canvas.add_child(_btn(String(i[0]), func(): _demo_status(what),
			Vector2(24 + float(idx) * 118.0, y1), 112))

	# AMBIENT staat rechts naast de status-knoppen: daar is ruimte vrij.
	canvas.add_child(_lbl("AMBIENT", Vector2(760, y1 - 14)))
	canvas.add_child(_btn("Play", func(): _play("ambient"), Vector2(760, y1), 60))
	canvas.add_child(_btn("Stop", func():
		var p: AudioStreamPlayer = _players.get("ambient")
		if p != null:
			p.stop(), Vector2(824, y1), 60))

	var y2 := 488.0
	canvas.add_child(_lbl("EVENTS", Vector2(24, y2 - 14)))
	canvas.add_child(_btn("Kill puff + coins", _demo_kill, Vector2(24, y2), 118))
	canvas.add_child(_btn("Coffee made", _demo_coffee, Vector2(148, y2), 100))
	canvas.add_child(_btn("FIRE ALARM", _demo_alarm, Vector2(254, y2), 100))
	canvas.add_child(_btn("LUNCH BREAK", _demo_lunch, Vector2(360, y2), 106))
	canvas.add_child(_btn("Boss phase", _demo_boss_phase, Vector2(472, y2), 96))
	canvas.add_child(_btn("Clear effects", func(): fx.clear(), Vector2(574, y2), 96))
	canvas.add_child(_btn("Projector QTE", _demo_qte, Vector2(676, y2), 130))

	_lbl("Enemies walk their own loop — that is the walk animation. Coffee machines bubble on their own.",
		Vector2(24, 522), canvas)

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
