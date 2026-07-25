extends CanvasLayer
# Update-check bij het opstarten. Haalt version.json van de site, vergelijkt met res://VERSION
# en biedt bij een nieuwere versie twee routes aan (keuze van de speler):
#
#   1. AUTOMATIC — download, vervang de .exe en herstart. Alleen op Windows.
#      Windows laat een DRAAIENDE .exe niet overschrijven of verwijderen, maar wel HERNOEMEN.
#      Daarop rust de hele truc: huidige exe -> *_old.exe, nieuwe op de vrijgekomen plek,
#      nieuwe starten, zelf afsluiten. De *_old.exe wordt bij de volgende start opgeruimd.
#   2. SAFE — zet de zip in Downloads en toon 'm in de verkenner; de speler wisselt zelf.
#      Werkt overal en raakt geen antivirus-heuristiek.
#
# Faalt de automatische route ergens (geen schrijfrechten, hernoemen geweigerd), dan draaien
# we de boel terug en sturen we de speler naar route 2 — nooit een half vervangen installatie.
#
# Uitzetten: ENABLED op false.

const ENABLED := true
# "releases/latest/download/..." wijst altijd naar de nieuwste release, dus dit adres hoeft
# bij een nieuwe versie nooit bijgewerkt te worden. Bewust GitHub en niet de eigen server:
# de game installeert wat hier staat, en dan wil je die binary niet naast tien andere
# diensten op een zelfbeheerde VPS hebben liggen.
const VERSION_URL := "https://github.com/Malse-Makker/CTRL-ALT-DEFEND/releases/latest/download/version.json"
const CHECK_TIMEOUT := 8.0

const PlaytestScript = preload("res://scripts/playtest.gd")

var _info: Dictionary = {}
var _panel: Control = null
var _http: HTTPRequest = null
var _progress: Label = null
var _zip_target: String = ""
var _auto_mode: bool = false


func _ready() -> void:
	layer = 100
	_cleanup_leftovers()
	if ENABLED:
		_check()


# ---------- Opruimen van een vorige update ----------

func _cleanup_leftovers() -> void:
	# De hernoemde oude .exe kan pas weg als hij niet meer draait — dus nu, bij de start
	# van de nieuwe versie. Idem voor een half afgebroken download.
	var dir_path := OS.get_executable_path().get_base_dir()
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with("_old.exe") or f.begins_with("_update_"):
			DirAccess.remove_absolute(dir_path.path_join(f))


# ---------- De check ----------

func _check() -> void:
	_http = HTTPRequest.new()
	_http.timeout = CHECK_TIMEOUT
	# GitHub stuurt "latest/download/..." door naar zijn opslag-CDN; zonder redirects krijg je
	# alleen de 302 te pakken.
	_http.max_redirects = 8
	add_child(_http)
	_http.request_completed.connect(_on_check_done)
	if _http.request(VERSION_URL) != OK:
		_drop_http()


func _on_check_done(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_drop_http()
	if code != 200:
		return   # server plat of geen internet: stilzwijgend doorspelen
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var info: Dictionary = parsed
	var remote: String = str(info.get("version", ""))
	if remote == "" or not _is_newer(remote, PlaytestScript.version()):
		return
	_info = info
	_show_available()


static func _is_newer(remote: String, local: String) -> bool:
	# Kale SemVer-vergelijking. Een onleesbare lokale versie (de "?"-bug uit v0.61) telt als
	# 0.0.0, zodat juist die oude builds wél een melding krijgen.
	var a := remote.split(".")
	var b := local.split(".")
	for i in 3:
		var x: int = int(a[i]) if i < a.size() else 0
		var y: int = int(b[i]) if i < b.size() else 0
		if x != y:
			return x > y
	return false


func _drop_http() -> void:
	if _http != null and is_instance_valid(_http):
		_http.queue_free()
	_http = null


# ---------- UI-bouwstenen ----------

func _open_panel(title: String, w: float = 720.0, h: float = 400.0) -> VBoxContainer:
	_close_panel()
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	_panel.add_child(dim)

	var box := PanelContainer.new()
	box.position = Vector2((960.0 - w) / 2.0, (540.0 - h) / 2.0)
	box.custom_minimum_size = Vector2(w, h)
	box.size = Vector2(w, h)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.14, 0.18)
	sb.border_color = Color(0.35, 0.55, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(18)
	box.add_theme_stylebox_override("panel", sb)
	_panel.add_child(box)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	box.add_child(vb)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vb.add_child(t)
	return vb


func _close_panel() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null


func _text(vb: VBoxContainer, s: String, size: int = 13, col: Color = Color(0.82, 0.84, 0.9)) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(660, 0)
	vb.add_child(l)
	return l


func _row(vb: VBoxContainer) -> HBoxContainer:
	# Knoppen in een VBox rekken over de volle panelbreedte uit; een rij eromheen
	# houdt ze op hun eigen maat.
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	vb.add_child(h)
	return h


func _button(vb: Node, text: String, cb: Callable, w: float = 230.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 38)
	b.pressed.connect(cb)
	vb.add_child(b)
	return b


# ---------- Scherm 1: er is een update ----------

func _show_available() -> void:
	var vb := _open_panel("UPDATE AVAILABLE")
	_text(vb, "You are playing v%s  -  v%s is out." % [PlaytestScript.version(), str(_info.get("version", "?"))], 15, Color(0.95, 0.95, 1.0))

	var changes: Array = _info.get("changes", [])
	if changes.is_empty():
		_text(vb, "No change notes for this version.")
	else:
		_text(vb, "What's new:", 13, Color(0.6, 0.85, 0.95))
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(660, 170)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vb.add_child(scroll)
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 5)
		scroll.add_child(list)
		for c in changes:
			var l := Label.new()
			l.text = "- " + str(c)
			l.add_theme_font_size_override("font_size", 12)
			l.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(630, 0)
			list.add_child(l)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_button(row, "Update", _show_choice, 200)
	_button(row, "Cancel", _close_panel, 140)


# ---------- Scherm 2: hoe wil je updaten? ----------

func _show_choice() -> void:
	var vb := _open_panel("HOW DO YOU WANT TO UPDATE?", 760.0, 440.0)
	var can_auto := OS.has_feature("windows")

	if can_auto:
		_text(vb, "1. AUTOMATIC  -  the game replaces itself and restarts", 15, Color(0.6, 0.9, 0.7))
		_text(vb, "Downloads the new version, swaps it in and restarts. Takes about a minute; your progress and settings are kept.", 12)
		_text(vb, "Heads up: some antivirus software distrusts a program that replaces its own .exe -- it looks like malware behaviour, even though it isn't. If the update gets blocked or the game disappears after restarting, open Windows Security -> Virus & threat protection -> Protection history and choose Allow / Restore for CTRL-ALT-DEFEND. Or just use option 2, which never runs into this.", 12, Color(0.95, 0.78, 0.45))
		_button(_row(vb), "Update automatically", func(): _start_download(true), 300)
	else:
		_text(vb, "Automatic updating is Windows-only. Use the safe option below.", 13, Color(0.95, 0.78, 0.45))

	_text(vb, "2. SAFE  -  download it and swap it yourself", 15, Color(0.6, 0.85, 0.95))
	_text(vb, "Downloads the zip to your Downloads folder and opens it for you. You unzip it and drag the new CTRL-ALT-DEFEND.exe over the old one. Always works, no antivirus trouble -- just a bit more work.", 12)
	_button(_row(vb), "Download the safe way", func(): _start_download(false), 300)
	_button(_row(vb), "Back", _show_available, 140)


# ---------- Downloaden ----------

func _start_download(auto: bool) -> void:
	_auto_mode = auto
	var url: String = str(_info.get("zip", ""))
	if url == "":
		_show_failed("The update location is missing from version.json.")
		return

	var target_dir: String = ""
	if auto:
		# Naast de .exe, zodat het hernoemen straks binnen hetzelfde volume blijft.
		target_dir = OS.get_executable_path().get_base_dir()
		if not _can_write(target_dir):
			_show_failed("The game folder is read-only, so it cannot update itself.\n\nUse the safe option instead, or move the game to a normal folder such as Downloads or your Desktop.")
			return
		_zip_target = target_dir.path_join("_update_%s.zip" % str(_info.get("version", "new")))
	else:
		target_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
		if target_dir == "":
			target_dir = OS.get_user_data_dir()
		_zip_target = target_dir.path_join(url.get_file())

	var vb := _open_panel("DOWNLOADING")
	_text(vb, "Fetching v%s ..." % str(_info.get("version", "?")), 14)
	_progress = _text(vb, "0 MB", 13, Color(0.6, 0.9, 0.7))
	_text(vb, "You can keep this window open; it will tell you when it's done.", 12, Color(0.6, 0.62, 0.7))

	_http = HTTPRequest.new()
	_http.use_threads = true
	_http.timeout = 0
	_http.max_redirects = 8
	_http.download_file = _zip_target
	add_child(_http)
	_http.request_completed.connect(_on_zip_done)
	if _http.request(url) != OK:
		_drop_http()
		_show_failed("Could not start the download. Check your internet connection.")
		return
	set_process(true)


func _process(_dt: float) -> void:
	if _http == null or not is_instance_valid(_http) or _progress == null or not is_instance_valid(_progress):
		return
	var got := _http.get_downloaded_bytes()
	var total := _http.get_body_size()
	if total > 0:
		_progress.text = "%.1f / %.1f MB  (%d%%)" % [got / 1048576.0, total / 1048576.0, int(got * 100.0 / total)]
	else:
		_progress.text = "%.1f MB" % [got / 1048576.0]


func _on_zip_done(_result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	set_process(false)
	_drop_http()
	if code != 200:
		DirAccess.remove_absolute(_zip_target)
		_show_failed("The download failed (server said %d). Try again later." % code)
		return

	var want: String = str(_info.get("sha256", ""))
	if want != "":
		var got := FileAccess.get_sha256(_zip_target)
		if got.to_lower() != want.to_lower():
			DirAccess.remove_absolute(_zip_target)
			_show_failed("The downloaded file did not match its checksum, so it was thrown away.\n\nThat usually means the download got interrupted. Please try again.")
			return

	if _auto_mode:
		_install()
	else:
		_show_downloaded()


# ---------- Route 2: klaargezet, speler doet de rest ----------

func _show_downloaded() -> void:
	var vb := _open_panel("DOWNLOAD READY")
	_text(vb, "Saved v%s to:" % str(_info.get("version", "?")), 14, Color(0.6, 0.9, 0.7))
	_text(vb, _zip_target, 12)
	_text(vb, "Unzip it and replace your old CTRL-ALT-DEFEND.exe with the new one. Your saved progress lives elsewhere, so nothing is lost.", 13)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_button(row, "Show me the file", func(): OS.shell_show_in_file_manager(_zip_target, false), 220)
	_button(row, "Close", _close_panel, 140)


# ---------- Route 1: zichzelf vervangen ----------

func _install() -> void:
	var exe := OS.get_executable_path()
	var dir := exe.get_base_dir()
	var entry: String = str(_info.get("exe", "CTRL-ALT-DEFEND.exe"))

	var zr := ZIPReader.new()
	if zr.open(_zip_target) != OK:
		_fail_install("The downloaded file could not be opened.")
		return
	var found := ""
	for f in zr.get_files():
		if f.get_file() == entry:
			found = f
			break
	if found == "":
		zr.close()
		_fail_install("The update did not contain %s." % entry)
		return
	var data := zr.read_file(found)
	zr.close()
	if data.is_empty():
		_fail_install("The new version came out empty.")
		return

	var staged := dir.path_join("_update_new.exe")
	var f := FileAccess.open(staged, FileAccess.WRITE)
	if f == null:
		_fail_install("Could not write to the game folder.")
		return
	f.store_buffer(data)
	f.close()

	# Hernoemen mag op een draaiende .exe, verwijderen niet. Lukt stap 1 maar stap 2 niet,
	# dan zetten we de oude terug -- liever geen update dan een kapotte installatie.
	var backup := dir.path_join(exe.get_file().get_basename() + "_old.exe")
	DirAccess.remove_absolute(backup)
	if DirAccess.rename_absolute(exe, backup) != OK:
		DirAccess.remove_absolute(staged)
		_fail_install("Windows would not let the game rename itself.")
		return
	if DirAccess.rename_absolute(staged, exe) != OK:
		DirAccess.rename_absolute(backup, exe)   # terugdraaien
		DirAccess.remove_absolute(staged)
		_fail_install("The new version could not be put in place, so nothing was changed.")
		return

	DirAccess.remove_absolute(_zip_target)
	if OS.create_process(exe, []) == -1:
		_show_failed("The update is installed, but the game could not restart itself.\n\nClose this window and start CTRL-ALT-DEFEND again.")
		return
	get_tree().quit()


func _fail_install(reason: String) -> void:
	DirAccess.remove_absolute(_zip_target)
	var vb := _open_panel("AUTOMATIC UPDATE DID NOT WORK")
	_text(vb, reason, 14, Color(0.95, 0.78, 0.45))
	_text(vb, "Nothing was changed -- the game you are playing is untouched. If your antivirus blocked it, allow CTRL-ALT-DEFEND in Windows Security. Otherwise use the safe route: it downloads the zip and you swap the file yourself.", 13)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_button(row, "Download the safe way", func(): _start_download(false), 240)
	_button(row, "Close", _close_panel, 140)


func _show_failed(reason: String) -> void:
	var vb := _open_panel("UPDATE FAILED")
	_text(vb, reason, 14, Color(0.95, 0.78, 0.45))
	_button(vb, "Close", _close_panel, 160)


func _can_write(dir: String) -> bool:
	var probe := dir.path_join("_update_probe.tmp")
	var f := FileAccess.open(probe, FileAccess.WRITE)
	if f == null:
		return false
	f.close()
	DirAccess.remove_absolute(probe)
	return true
