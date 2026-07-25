extends Control

# Lichte klik-events (GDD §8): een telefoontje dat je op rood moet ophangen (Town Hall) en het
# HR-formulier dat je moet tekenen (HR Room). Kleiner dan de grote mini-games: één knop wegklikken.
# Zelfde patroon als de andere events: het level toont/sluit 'm, auto-skip via de level-timer.

signal finished

const SCREEN_W := 960.0
const SCREEN_H := 540.0

var _kind: String = "phone"          # "phone" of "form"
var _timer_label: Label
var _title: Label

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(SCREEN_W, SCREEN_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()

func _build() -> void:
	# dim-overlay
	var bg := ColorRect.new()
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.color = Color(0.04, 0.05, 0.08, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# venster
	var box := ColorRect.new()
	box.position = Vector2(SCREEN_W / 2.0 - 160.0, SCREEN_H / 2.0 - 90.0)
	box.size = Vector2(320, 180)
	box.color = Color(0.14, 0.15, 0.2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_title = Label.new()
	_title.position = box.position + Vector2(0, 24)
	_title.size = Vector2(320, 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 18)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	var sub := Label.new()
	sub.name = "Sub"
	sub.position = box.position + Vector2(20, 58)
	sub.size = Vector2(280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)
	var btn := Button.new()
	btn.name = "Action"
	btn.position = box.position + Vector2(90, 116)
	btn.custom_minimum_size = Vector2(140, 40)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func(): finished.emit())
	add_child(btn)
	_timer_label = Label.new()
	_timer_label.position = Vector2(150, SCREEN_H - 40)
	_timer_label.size = Vector2(660, 20)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 11)
	_timer_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_label)

func setup(kind: String) -> void:
	_kind = kind
	var sub: Label = get_node("Sub")
	var btn: Button = get_node("Action")
	if kind == "form":
		_title.text = "HR COMPLIANCE FORM"
		_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		sub.text = "Please sign to acknowledge you have read the policy."
		btn.text = "Sign here"
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		_title.text = "INCOMING CALL"
		_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
		sub.text = "Unknown number. Again."
		btn.text = "Hang up"
		btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))

func show_event() -> void:
	visible = true

func hide_event() -> void:
	visible = false

func set_timer_text(txt: String) -> void:
	if _timer_label != null:
		_timer_label.text = txt
