extends Control

# Mini-game "Eat the Pizza" (Release Night, GDD §8). Timing-balk in Abiotic-Factor-stijl: een
# pijltje sweept heen-en-weer; met spatie stop je het. Groen vak = grote hap (50%), geel = 25%,
# de rest = 5%. De pizza krimpt tot 0% (klaar). Cooldown per druk zodat rammen niet sneller is
# dan gewoon 10s wachten; het pijltje versnelt naarmate de pizza slinkt. Auto-skip regelt het level.
#
# Zelfstandige component: het level toont/sluit 'm en zet de aftel-tekst; deze node draait de
# mini-game en meldt via `finished` dat de pizza op is.

signal finished

const SCREEN_W := 960.0
const SCREEN_H := 540.0

var _active: bool = false
var _pizza: float = 100.0            # % over
var _pos: float = 0.0                # pijltje-positie 0..1
var _dir: float = 1.0
var _base_speed: float = 0.85        # sweeps per seconde bij een volle pizza
var _cooldown: float = 0.0
var _zone_center: float = 0.5        # midden van het doelvak (verschuift per hap)
var _msg_time: float = 0.0
var _bar := Rect2(230, 330, 500, 34)
var _timer_label: Label
var _msg_label: Label
var _pizza_tex: Texture2D = load("res://art/ui/mg_pizza.png")

const GREEN_HALF := 0.04             # halve breedte groen vak (→ hap 50%)
const YELLOW_HALF := 0.12            # halve breedte geel vak (→ hap 25%)

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(SCREEN_W, SCREEN_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	_build_labels()

func _build_labels() -> void:
	var title := Label.new()
	title.text = "EAT THE PIZZA"
	title.position = Vector2(150, 50)
	title.size = Vector2(660, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var hint := Label.new()
	hint.text = "Press SPACE to bite. Green = big bite, yellow = ok, edges = crumb."
	hint.position = Vector2(150, 88)
	hint.size = Vector2(660, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	_msg_label = Label.new()
	_msg_label.position = Vector2(150, 288)
	_msg_label.size = Vector2(660, 24)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.add_theme_font_size_override("font_size", 18)
	_msg_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_msg_label)
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
	_pizza = 100.0
	_pos = 0.0
	_dir = 1.0
	_cooldown = 0.0
	_zone_center = randf_range(0.35, 0.65)
	_msg_label.text = ""
	visible = true
	queue_redraw()

func hide_event() -> void:
	_active = false
	visible = false

func set_timer_text(txt: String) -> void:
	if _timer_label != null:
		_timer_label.text = txt

func _process(delta: float) -> void:
	if not _active:
		return
	# Onafhankelijk van de spelsnelheid (1x/2x/3x): anders zou het pijltje mee-versnellen.
	var rt: float = delta / maxf(Engine.time_scale, 0.001)
	# Sneller naarmate de pizza slinkt (tot ~2x).
	var spd: float = _base_speed * (1.0 + (100.0 - _pizza) / 100.0)
	_pos += _dir * spd * rt
	if _pos >= 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos <= 0.0:
		_pos = 0.0
		_dir = 1.0
	if _cooldown > 0.0:
		_cooldown -= rt
	if _msg_time > 0.0:
		_msg_time -= rt
		if _msg_time <= 0.0:
			_msg_label.text = ""
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	# Muisklik doet hetzelfde als spatie: een tester verwachtte te kunnen klikken en zat
	# vast omdat alleen het toetsenbord werkte.
	var bite: bool = false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		bite = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		bite = true
	if bite:
		# Altijd de spatie opeten (anders start hij een wave); happen alleen als de cooldown klaar is.
		get_viewport().set_input_as_handled()
		if _cooldown <= 0.0:
			_bite()

func _bite() -> void:
	var d: float = absf(_pos - _zone_center)
	var amount: float = 5.0
	if d <= GREEN_HALF:
		amount = 50.0
	elif d <= YELLOW_HALF:
		amount = 25.0
	_pizza = maxf(0.0, _pizza - amount)
	_cooldown = 0.5
	_zone_center = randf_range(0.32, 0.68)   # verschuift zodat je niet kunt memoriseren
	_msg_label.text = "%d%% bite!" % int(amount)
	_msg_time = 0.6
	queue_redraw()
	if _pizza <= 0.0:
		_active = false
		finished.emit()

func _draw() -> void:
	# dim-overlay
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color(0.04, 0.05, 0.08, 0.72))
	# pizza-sprite; het opgegeten deel wordt met een donkere taartpunt overdekt (weggehapt)
	var c := Vector2(480, 200)
	var r := 66.0
	if _pizza_tex != null:
		draw_texture_rect(_pizza_tex, Rect2(c - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false)
	var frac: float = _pizza / 100.0
	if frac < 0.998:
		var pts := PackedVector2Array([c])
		var steps := 44
		var a0: float = -PI / 2.0 + TAU * frac
		var a1: float = -PI / 2.0 + TAU
		for i in steps + 1:
			var a: float = lerpf(a0, a1, float(i) / float(steps))
			pts.append(c + Vector2(cos(a), sin(a)) * (r + 2.0))
		draw_colored_polygon(pts, Color(0.04, 0.05, 0.08, 0.85))
	# timing-balk
	draw_rect(_bar, Color(0.15, 0.16, 0.2))
	var yx: float = _bar.position.x + (_zone_center - YELLOW_HALF) * _bar.size.x
	draw_rect(Rect2(yx, _bar.position.y, YELLOW_HALF * 2.0 * _bar.size.x, _bar.size.y), Color(0.9, 0.8, 0.3, 0.7))
	var gx: float = _bar.position.x + (_zone_center - GREEN_HALF) * _bar.size.x
	draw_rect(Rect2(gx, _bar.position.y, GREEN_HALF * 2.0 * _bar.size.x, _bar.size.y), Color(0.4, 0.9, 0.45, 0.9))
	# pijltje + driehoekje eronder
	var px: float = _bar.position.x + _pos * _bar.size.x
	draw_rect(Rect2(px - 2.0, _bar.position.y - 6.0, 4.0, _bar.size.y + 12.0), Color(1, 1, 1))
	var by: float = _bar.position.y + _bar.size.y + 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 7.0, by), Vector2(px + 7.0, by), Vector2(px, by + 12.0)]), Color(1, 1, 1))
