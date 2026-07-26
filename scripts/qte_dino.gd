extends Control

# Mini-game "No Internet" (Work From Home, GDD §8). Chrome-offline-runner in kantoor-thema:
# een figuurtje rent automatisch, SPATIE = springen, PIJL-OMLAAG = bukken. Obstakels op de grond
# (koffiebeker) spring je over, een vliegend papieren vliegtuigje duik je onder. Snelheid loopt op.
#
# Je hoeft niks te "winnen": het level telt ~10s af tot de verbinding terug is. Elk ontweken
# obstakel stuurt `dodged` → het level haalt er seconden af, dus spelen maakt het korter. Een
# botsing is geen game-over: je struikelt kort en die tijdsbonus mis je.

signal dodged

const SCREEN_W := 960.0
const SCREEN_H := 540.0
const GROUND_Y := 360.0
const RUN_X := 180.0

var _active: bool = false
var _y: float = 0.0                 # verticale offset (spring), 0 = op de grond, negatief = omhoog
var _vel: float = 0.0
var _ducking: bool = false
var _speed: float = 240.0           # px/sec, loopt op
var _obstacles: Array = []          # [{x, kind, hit}]  kind = "ground" / "air"
var _spawn_in: float = 0.9
var _run: float = 0.0               # loop-fase voor de beentjes
var _stumble: float = 0.0
# Voortgang van "de verbinding komt terug", 0..1. De aanroeper zet 'm elke frame; wij tekenen
# 'm als balk. Zonder dit zag een tester niet dat ontwijken iets deed en leek het eindeloos.
var progress: float = 0.0
var _dodge_flash: float = 0.0
var _dodges: int = 0
var _timer_label: Label
var _runner_tex: Texture2D = load("res://art/ui/mg_runner.png")
var _cup_tex: Texture2D = load("res://art/ui/mg_cup.png")
var _plane_tex: Texture2D = load("res://art/ui/mg_plane.png")

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(SCREEN_W, SCREEN_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	_build_labels()

func _build_labels() -> void:
	# Alleen de timer nog als Label; titel en uitleg worden in _draw naast de balk getekend.
	_timer_label = Label.new()
	_timer_label.position = Vector2(150, SCREEN_H - 40)
	_timer_label.size = Vector2(660, 20)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 11)
	_timer_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_label)

func start_event() -> void:
	_active = true
	progress = 0.0
	_dodges = 0
	_dodge_flash = 0.0
	_y = 0.0
	_vel = 0.0
	_ducking = false
	_speed = 240.0
	_obstacles.clear()
	_spawn_in = 0.8
	_stumble = 0.0
	visible = true
	queue_redraw()

func hide_event() -> void:
	_active = false
	visible = false

func set_progress(p: float) -> void:
	progress = clampf(p, 0.0, 1.0)

func set_timer_text(txt: String) -> void:
	if _timer_label != null:
		_timer_label.text = txt

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()   # niet doorlaten (zou een wave starten)
		if _y == 0.0 and _stumble <= 0.0:        # alleen springen vanaf de grond
			_vel = -560.0

func _process(delta: float) -> void:
	if not _active:
		return
	var rt: float = delta / maxf(Engine.time_scale, 0.001)   # los van 1x/2x/3x
	_ducking = Input.is_physical_key_pressed(KEY_DOWN) and _y == 0.0
	# springfysica
	if _y < 0.0 or _vel < 0.0:
		_vel += 1500.0 * rt
		_y += _vel * rt
		if _y >= 0.0:
			_y = 0.0
			_vel = 0.0
	if _stumble > 0.0:
		_stumble -= rt
	_speed += 10.0 * rt                          # loopt langzaam op
	_run += _speed * rt
	# obstakels verplaatsen + spawnen
	_spawn_in -= rt
	if _spawn_in <= 0.0:
		_spawn_in = randf_range(0.9, 1.6)
		var kind: String = "air" if randf() < 0.32 else "ground"
		_obstacles.append({"x": SCREEN_W + 40.0, "kind": kind, "hit": false})
	var keep: Array = []
	for o in _obstacles:
		o["x"] = float(o["x"]) - _speed * rt
		# botsing?
		if not o["hit"] and _overlaps(o):
			o["hit"] = true
			_stumble = 0.4
			_speed = maxf(180.0, _speed * 0.7)   # struikelen remt af
		# net voorbij de renner en niet geraakt → ontweken
		if float(o["x"]) < RUN_X - 30.0 and not o.get("counted", false):
			o["counted"] = true
			if not o["hit"]:
				dodged.emit()
		if float(o["x"]) > -50.0:
			keep.append(o)
	_obstacles = keep
	if _dodge_flash > 0.0:
		_dodge_flash = maxf(0.0, _dodge_flash - rt * 1.4)
	queue_redraw()

func _runner_rect() -> Rect2:
	var top: float = GROUND_Y - (24.0 if _ducking else 44.0) + _y
	var h: float = (24.0 if _ducking else 44.0)
	return Rect2(RUN_X - 14.0, top, 28.0, h)

func _obstacle_rect(o: Dictionary) -> Rect2:
	if String(o["kind"]) == "air":
		return Rect2(float(o["x"]) - 14.0, GROUND_Y - 62.0, 28.0, 20.0)
	return Rect2(float(o["x"]) - 11.0, GROUND_Y - 26.0, 22.0, 26.0)

func _overlaps(o: Dictionary) -> bool:
	return _runner_rect().intersects(_obstacle_rect(o))

func _draw() -> void:
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color(0.04, 0.05, 0.08, 0.78))
	var ink := Color(0.82, 0.84, 0.88)

	# Kop: waaróm zit je hier. Plus een balk die volloopt naarmate de verbinding terugkomt --
	# elke ontweken hindernis duwt die zichtbaar vooruit.
	var bx := 230.0
	var bw := 500.0
	var by := 96.0
	draw_string(ThemeDB.fallback_font, Vector2(bx, by - 34.0), "NO INTERNET",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.75, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(bx, by - 14.0),
		"Reconnecting... every obstacle you dodge gets you back online sooner.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.73, 0.8))
	draw_rect(Rect2(bx, by, bw, 16.0), Color(0.16, 0.17, 0.22))
	var fill: Color = Color(0.4, 0.85, 0.55).lerp(Color(1, 1, 1), _dodge_flash * 0.7)
	draw_rect(Rect2(bx, by, bw * progress, 16.0), fill)
	draw_rect(Rect2(bx, by, bw, 16.0), Color(0.4, 0.44, 0.52), false, 1.0)
	if _dodge_flash > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(bx + bw + 10.0, by + 13.0), "+ back online sooner!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.6, _dodge_flash))
	draw_string(ThemeDB.fallback_font, Vector2(bx, by + 34.0), "Dodged: %d" % _dodges,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.64, 0.72))

	# grondlijn
	draw_line(Vector2(60, GROUND_Y + 1), Vector2(SCREEN_W - 60, GROUND_Y + 1), ink, 2.0)
	_draw_dino(ink)
	# obstakel-sprites
	for o in _obstacles:
		if String(o["kind"]) == "air":
			var pr := Rect2(float(o["x"]) - 20.0, GROUND_Y - 66.0, 40.0, 28.0)
			if _plane_tex != null:
				draw_texture_rect(_plane_tex, pr, false)
		else:
			var cr := Rect2(float(o["x"]) - 17.0, GROUND_Y - 36.0, 34.0, 36.0)
			if _cup_tex != null:
				draw_texture_rect(_cup_tex, cr, false)


func _draw_dino(ink: Color) -> void:
	# Klassieke offline-dino uit blokken, kijkend naar rechts (waar de obstakels vandaan komen).
	# Was een poppetje-sprite; een tester wilde terecht een dino, want dan zie je meteen
	# waar de mini-game over gaat.
	var col: Color = Color(1.0, 0.55, 0.5) if _stumble > 0.0 else ink
	var u: float = 5.0
	var base: float = GROUND_Y + _y
	var x: float = RUN_X

	if _ducking:
		draw_rect(Rect2(x - 5.0 * u, base - 4.0 * u, 8.0 * u, 3.0 * u), col)      # romp, plat
		draw_rect(Rect2(x + 3.0 * u, base - 5.0 * u, 4.0 * u, 3.0 * u), col)      # kop vooruit
		draw_rect(Rect2(x + 6.0 * u, base - 3.5 * u, 1.5 * u, 1.0 * u), col)      # snuit
		draw_rect(Rect2(x + 5.2 * u, base - 4.4 * u, 0.7 * u, 0.7 * u), Color(0.06, 0.07, 0.1))
		draw_rect(Rect2(x - 8.0 * u, base - 3.6 * u, 3.0 * u, 1.4 * u), col)      # staart
		draw_rect(Rect2(x - 3.0 * u, base - u, 1.6 * u, u), col)
		draw_rect(Rect2(x + 0.5 * u, base - u, 1.6 * u, u), col)
		return

	draw_rect(Rect2(x - 7.0 * u, base - 6.0 * u, 3.5 * u, 1.6 * u), col)          # staartpunt
	draw_rect(Rect2(x - 4.5 * u, base - 7.0 * u, 3.0 * u, 2.6 * u), col)          # staartaanzet
	draw_rect(Rect2(x - 2.5 * u, base - 8.0 * u, 4.5 * u, 5.0 * u), col)          # romp
	draw_rect(Rect2(x + 0.5 * u, base - 10.5 * u, 2.6 * u, 3.5 * u), col)         # hals
	draw_rect(Rect2(x + 0.5 * u, base - 13.0 * u, 4.5 * u, 3.0 * u), col)         # kop
	draw_rect(Rect2(x + 4.0 * u, base - 11.2 * u, 1.8 * u, 1.2 * u), col)         # snuit
	draw_rect(Rect2(x + 3.4 * u, base - 12.4 * u, 0.8 * u, 0.8 * u), Color(0.06, 0.07, 0.1))
	draw_rect(Rect2(x + 1.8 * u, base - 9.4 * u, 1.4 * u, 0.9 * u), col)          # armpje

	if _y < 0.0:
		draw_rect(Rect2(x - 1.6 * u, base - 3.0 * u, 1.6 * u, 3.0 * u), col)
		draw_rect(Rect2(x + 0.4 * u, base - 3.0 * u, 1.6 * u, 3.0 * u), col)
	else:
		var phase: bool = fmod(_run / 24.0, 2.0) < 1.0
		draw_rect(Rect2(x - 1.8 * u, base - 3.0 * u, 1.6 * u, 3.0 * u if phase else 1.6 * u), col)
		draw_rect(Rect2(x + 0.4 * u, base - 3.0 * u, 1.6 * u, 1.6 * u if phase else 3.0 * u), col)
