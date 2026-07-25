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
	var title := Label.new()
	title.text = "NO INTERNET"
	title.position = Vector2(150, 46)
	title.size = Vector2(660, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var hint := Label.new()
	hint.text = "SPACE to jump, DOWN to duck. Every obstacle you dodge gets you back online sooner."
	hint.position = Vector2(120, 84)
	hint.size = Vector2(720, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
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
	# grondlijn
	draw_line(Vector2(60, GROUND_Y + 1), Vector2(SCREEN_W - 60, GROUND_Y + 1), ink, 2.0)
	# runner-sprite (feet aan de grond + sprong; gebukt = platter). Rood tintje bij struikelen.
	var rh: float = 34.0 if _ducking else 58.0
	var rw: float = 52.0
	var rrect := Rect2(RUN_X - rw * 0.5, GROUND_Y + _y - rh, rw, rh)
	var mod: Color = Color(1.0, 0.6, 0.55) if _stumble > 0.0 else Color(1, 1, 1)
	if _runner_tex != null:
		draw_texture_rect(_runner_tex, rrect, false, mod)
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
