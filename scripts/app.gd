extends Node2D

# Root: schermbeheer. Wisselt tussen Main Menu, Level Select, Settings, Shop en een Level.
# Basis 960x540 (exact 2x op 1080p). Alle UI-tekst in het Engels.

const SCREEN_W := 960.0
const SCREEN_H := 540.0
const LevelScript = preload("res://scripts/level.gd")
const TowerScript = preload("res://scripts/tower.gd")
const ArtRoomScript = preload("res://scripts/artroom.gd")
const PlaytestScript = preload("res://scripts/playtest.gd")
const UpdaterScript = preload("res://scripts/updater.gd")
const ChangelogScript = preload("res://scripts/changelog.gd")
const BuildInfoScript = preload("res://scripts/build_info.gd")
const StarsScript = preload("res://scripts/stars.gd")

const FEEDBACK_EMAIL := "games@makkers.net"

var current: Node = null

# Feedback-pagina (pre-release): stem-items + vrije velden, geëxporteerd naar een bestand.
var _fb_items: Array = []
var _fb_votes: Array = []
var _fb_up_btns: Array = []
var _fb_dn_btns: Array = []
var _fb_comment_edits: Array = []
var _fb_fields: Dictionary = {}
var _fb_colleague_edits: Dictionary = {}

func _ready() -> void:
	show_main_menu()
	# Losse laag boven de schermen: overleeft _swap en meldt zichzelf als er een
	# nieuwere build op de site staat.
	add_child(UpdaterScript.new())

func _swap(n: Node) -> void:
	if current != null and is_instance_valid(current):
		remove_child(current)
		current.queue_free()
	current = n
	add_child(n)

# ---------- Bouwstenen ----------

func _screen(title: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.10, 0.11, 0.14)
	root.add_child(bg)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 30)
	t.position = Vector2(40, 26)
	root.add_child(t)
	return root

func _btn(text: String, cb: Callable, w: float = 220.0, h: float = 40.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.pressed.connect(cb)
	return b

func _vbox(root: Control, pos: Vector2) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.position = pos
	vb.add_theme_constant_override("separation", 10)
	root.add_child(vb)
	return vb

# ---------- Main menu ----------

func show_main_menu() -> void:
	var root := _screen("CTRL-ALT-DEFEND")
	var sub := Label.new()
	sub.text = "I'll put this with the rest of the focus."
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	sub.position = Vector2(42, 66)
	root.add_child(sub)

	# Versie + vingerafdruk in beeld, zodat een tester kan melden welke build hij speelde en
	# kan controleren dat die overeenkomt met wat op de site staat. De hash komt uit een
	# thread; tot die klaar is staat alleen de versie er.
	var ver := Label.new()
	ver.text = "v" + PlaytestScript.version()
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(0.45, 0.48, 0.56))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.size = Vector2(300, 16)
	ver.position = Vector2(SCREEN_W - 312, SCREEN_H - 24)
	root.add_child(ver)
	BuildInfoScript.start()
	_await_build_id(ver)
	var vb := _vbox(root, Vector2(SCREEN_W / 2.0 - 110, 150))
	vb.add_child(_btn("Play", show_level_select))
	vb.add_child(_btn("Shop", show_shop))
	vb.add_child(_btn("Settings", show_settings))
	vb.add_child(_btn("Art Room", show_art_room))
	# Pre-release: de feedback-/exportpagina (playtest-export is hierheen verhuisd).
	if PlaytestScript.ENABLED:
		vb.add_child(_btn("Feedback", show_feedback))
	vb.add_child(_btn("What's New", show_changelog))
	vb.add_child(_btn("Quit", func(): get_tree().quit()))
	_swap(root)

func _await_build_id(label: Label) -> void:
	for _i in 40:
		if BuildInfoScript.done():
			break
		await get_tree().create_timer(0.25).timeout
	if not is_instance_valid(label):
		return
	var id: String = BuildInfoScript.short()
	if id != "" and id != "dev":
		label.text = "v%s   build %s" % [PlaytestScript.version(), id]

# ---------- What's New ----------

func show_changelog() -> void:
	var root := _screen("WHAT'S NEW")
	var sub := Label.new()
	sub.text = "You are playing v%s." % PlaytestScript.version()
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.7, 0.72, 0.82))
	sub.position = Vector2(42, 62)
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 92)
	scroll.custom_minimum_size = Vector2(900, 386)
	scroll.size = Vector2(900, 386)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(880, 0)
	vb.add_theme_constant_override("separation", 6)
	scroll.add_child(vb)

	var entries: Array = ChangelogScript.entries()
	if entries.is_empty():
		_fb_note(vb, "No changelog found in this build.")
	for e in entries:
		var head := Label.new()
		var v: String = str(e.get("version", ""))
		var d: String = str(e.get("date", ""))
		head.text = ("v%s   -   %s" % [v, d]) if d != "" else ("v" + v)
		head.add_theme_font_size_override("font_size", 15)
		# De versie die je nu speelt lichten we op, de rest is historie.
		head.add_theme_color_override("font_color",
			Color(0.55, 0.9, 0.65) if v == PlaytestScript.version() else Color(0.95, 0.85, 0.45))
		vb.add_child(head)
		for it in e.get("items", []):
			var l := Label.new()
			l.text = "   - " + str(it)
			l.add_theme_font_size_override("font_size", 12)
			l.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(860, 0)
			vb.add_child(l)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 8)
		vb.add_child(gap)

	var back := _btn("< Back", show_main_menu, 130, 36)
	back.position = Vector2(40, SCREEN_H - 44)
	root.add_child(back)
	_swap(root)

# ---------- Feedback-pagina (pre-release) ----------

func show_feedback() -> void:
	var root := _screen("HELP US SHAPE THE GAME")
	var sub := Label.new()
	sub.text = "Pre-release feedback. Vote on the plans, tell us what's missing, then send it back -- copy-paste or email, whatever suits you."
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.7, 0.72, 0.82))
	sub.position = Vector2(42, 62)
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 88)
	scroll.custom_minimum_size = Vector2(900, 396)
	scroll.size = Vector2(900, 396)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(880, 0)
	vb.add_theme_constant_override("separation", 7)
	scroll.add_child(vb)

	# --- Je playtests ---
	_fb_section(vb, "YOUR PLAYTESTS")
	var runs: Array = PlaytestScript.all_runs()
	if runs.is_empty():
		_fb_note(vb, "No playtests logged yet — play a few rounds first.")
	else:
		_fb_note(vb, "%d rounds logged. Most recent:" % runs.size())
		for i in range(maxi(0, runs.size() - 8), runs.size()):
			_fb_note(vb, "  - " + _fb_run_line(runs[i]))

	# --- Stem-items ---
	_fb_section(vb, "PLANS & IDEAS   (up = yes please, down = rather not, click again to clear)")
	_fb_items = _fb_plan_list()
	_fb_votes = []
	_fb_comment_edits = []
	_fb_up_btns = []
	_fb_dn_btns = []
	for i in _fb_items.size():
		_fb_vote_row(vb, i, String(_fb_items[i]))

	# --- Vrije velden ---
	_fb_section(vb, "TELL US MORE")
	_fb_fields = {}
	_fb_colleague_edits = {}
	_fb_field(vb, "towers", "Towers - which would you change and how? Any you're missing, and what would they do?")
	_fb_field(vb, "enemies", "Enemies - which would you change and how? Any you're missing, and what would they do?")
	_fb_field(vb, "maps", "Maps - which would you change and how? Any you're missing?")
	_fb_colleague_list(vb)
	_fb_field(vb, "ideas", "Your own ideas:")

	# --- Export ---
	_fb_section(vb, "SEND IT BACK")
	var result := Label.new()
	result.add_theme_font_size_override("font_size", 12)
	result.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(860, 0)
	_fb_note(vb, "Any of these is fine -- pick whatever is easiest for you. Copy works for Discord, a text file or pastebin.com.")
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.add_child(_btn("COPY ALL TO CLIPBOARD", func(): _copy_feedback(result), 280, 36))
	btns.add_child(_btn("Email it to " + FEEDBACK_EMAIL, func(): _email_feedback(result), 300, 36))
	vb.add_child(btns)
	vb.add_child(_btn("Save as files (Downloads)", func(): _export_feedback(result), 260, 36))
	vb.add_child(result)

	var back := _btn("< Back", show_main_menu, 130, 36)
	back.position = Vector2(40, SCREEN_H - 44)
	root.add_child(back)
	_swap(root)

func _fb_plan_list() -> Array:
	return [
		"Colleagues idea: turn all object-enemies into COLLEAGUES (people), same behaviour; towers stay objects that keep you focused.",
		"Full art pass: office tileset for the floor, a desk sprite, door sprites at the spawn points.",
		"Sprites for the newest towers (Pomodoro, Reply All, Ctrl+Alt+Del) and enemies (Phone Caller, System Update).",
		"Audio: a different note per tower so your layout plays a little tune.",
		"Sound effects for the mini-games and events.",
		"Balance pass across all 15 levels (actually played, not just calculated).",
		"Tutorial polish: strict one-tower-per-lesson and clearer visuals.",
		"Endless mode: save a highscore / leaderboard.",
		"Boss Rush: rewards or unlockables for clearing it.",
		"More pop-culture flavour texts (Office Space, The IT Crowd).",
		"Decorate dead build-space (whiteboards, plants) so it reads as decor, not broken.",
		"Spawn-door sprites so enemies don't look like they come out of the UI.",
		"Difficulty options (easy / normal / hard).",
		"A short story / intro for the career mode.",
		"Colour-blind friendly palette and accessibility options.",
		"Finale boss cameo polish (the returning mini peer-reviewers).",
	]

func _fb_section(vb: VBoxContainer, title: String) -> void:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.88, 0.76, 0.5))
	vb.add_child(l)

func _fb_note(vb: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(860, 0)
	vb.add_child(l)

func _fb_vote_row(vb: VBoxContainer, idx: int, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	# Driehoekjes getekend in plaats van ▲/▼ als tekst: dat font heeft die glyphs niet en
	# onder Proton werden het lege blokjes (tester-melding v0.70).
	var up := Button.new()
	up.custom_minimum_size = Vector2(36, 30)
	_add_arrow(up, true)
	var dn := Button.new()
	dn.custom_minimum_size = Vector2(36, 30)
	_add_arrow(dn, false)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(470, 0)
	var comment := LineEdit.new()
	comment.placeholder_text = "comment (optional)"
	comment.custom_minimum_size = Vector2(230, 30)
	_fb_votes.append("")
	_fb_comment_edits.append(comment)
	_fb_up_btns.append(up)
	_fb_dn_btns.append(dn)
	up.pressed.connect(func(): _fb_set_vote(idx, "up", up, dn))
	dn.pressed.connect(func(): _fb_set_vote(idx, "down", up, dn))
	row.add_child(up)
	row.add_child(dn)
	row.add_child(lbl)
	row.add_child(comment)
	vb.add_child(row)

func _add_arrow(b: Button, up: bool) -> void:
	var a := Control.new()
	a.custom_minimum_size = Vector2(14, 12)
	a.size = Vector2(14, 12)
	a.position = Vector2(11, 9)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.draw.connect(func():
		var pts := PackedVector2Array([Vector2(7, 0), Vector2(14, 12), Vector2(0, 12)] if up
			else [Vector2(0, 0), Vector2(14, 0), Vector2(7, 12)])
		a.draw_colored_polygon(pts, Color(0.85, 0.87, 0.92)))
	b.add_child(a)

func _fb_set_vote(idx: int, v: String, up: Button, dn: Button) -> void:
	if _fb_votes[idx] == v:
		v = ""   # nog eens klikken = stem intrekken
	_fb_votes[idx] = v
	_fb_paint_vote(up, v == "up", Color(0.30, 0.68, 0.38))
	_fb_paint_vote(dn, v == "down", Color(0.80, 0.35, 0.35))

func _fb_paint_vote(b: Button, active: bool, col: Color) -> void:
	# Gekozen = gevulde knop met donkere pijl; de oude modulate-tint was op het
	# donkere thema nauwelijks te zien (playtest-feedback v0.62).
	if active:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(4)
		for k in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(k, sb)
		b.add_theme_color_override("font_color", Color(0.10, 0.11, 0.13))
		b.add_theme_color_override("font_hover_color", Color(0.10, 0.11, 0.13))
		b.add_theme_color_override("font_pressed_color", Color(0.10, 0.11, 0.13))
	else:
		for k in ["normal", "hover", "pressed", "focus"]:
			b.remove_theme_stylebox_override(k)
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.remove_theme_color_override(k)

func _fb_field(vb: VBoxContainer, key: String, prompt: String) -> void:
	var l := Label.new()
	l.text = prompt
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.75, 0.77, 0.85))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(860, 0)
	vb.add_child(l)
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(860, 54)
	te.placeholder_text = "your answer..."
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_fb_fields[key] = te
	vb.add_child(te)

# De grote "maak van elke voorwerp-vijand een collega"-vraag was eerst één open tekstvak; een
# tester merkte terecht op dat je dan moet raden waar het over gaat. Nu staat er per bestaande
# vijand wat hij DOET, met een veld ernaast voor de collega die dat gedrag heeft.
const FB_COLLEAGUES := [
	["noti", "The Notification", "Plain and fast, no tricks. Just keeps coming."],
	["hulp", "The Question", "A tougher version of the same thing."],
	["nudge", "The Nudge", "Very fast, arrives as a swarm. Needs area damage or slows."],
	["thread", "The Thread", "Arrives as one big pile at once. Paper -- the shredder eats it."],
	["change", "The Change", "Splits into two smaller ones when you kill it."],
	["micro", "The Micro-manager", "Speeds up the more damage it takes."],
	["printer", "The Printer", "Jams every few seconds and spits out Error messages."],
	["phish", "Suspicious Link", "Invisible until a Shredder zone reveals it."],
	["board", "The Board Member", "Immune to burst damage -- never physically there."],
	["cold", "The Cold Caller", "Immune to chip damage. Only burst stops it."],
	["tank", "The Old Guard", "Shielded and slow. Break the shield first."],
	["update", "System Update", "Briefly invulnerable while it installs, then keeps coming."],
]

func _fb_colleague_list(vb: VBoxContainer) -> void:
	_fb_note(vb, "Big idea on the table: every enemy that is now an OBJECT becomes a COLLEAGUE -- a person who behaves exactly the same. The towers stay objects. We already have one: The Chatterbox, the colleague who corners you and talks until your towers go quiet.")
	_fb_note(vb, "Below is what each enemy does. Write the kind of colleague that fits that behaviour -- a job title, a nickname, whatever. Leave blank what you have no idea for.")
	for item in FB_COLLEAGUES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var l := Label.new()
		l.text = "%s -- %s" % [String(item[1]), String(item[2])]
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_color", Color(0.78, 0.8, 0.88))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(600, 0)
		row.add_child(l)
		var e := LineEdit.new()
		e.placeholder_text = "which colleague?"
		e.custom_minimum_size = Vector2(240, 26)
		_fb_colleague_edits[String(item[0])] = e
		row.add_child(e)
		vb.add_child(row)

func _fb_run_line(r: Dictionary) -> String:
	# De versie hoort er per ronde bij: zonder dat weten we niet of een klacht over iets gaat
	# dat inmiddels al gerepareerd is.
	var fun_txt := "no rating"
	if r.has("fun_0_10"):
		fun_txt = "fun %d/10" % int(r.get("fun_0_10", 0))
	elif r.has("difficulty_0_10"):
		fun_txt = "difficulty %d/10 (old scale)" % int(r.get("difficulty_0_10", 0))
	return "[v%s] %s: %s  (%d stars, wave %d/%d, %s)" % [
		str(r.get("version", "?")), str(r.get("level_name", "?")), str(r.get("outcome", "?")),
		int(r.get("stars", 0)), int(r.get("wave_reached", 0)), int(r.get("wave_total", 0)), fun_txt]

func _fb_compose() -> String:
	var lines: Array = []
	lines.append("CTRL-ALT-DEFEND - FEEDBACK")
	lines.append("version: " + PlaytestScript.version())
	lines.append("player: " + PlaytestScript.player_id())
	lines.append("timestamp: " + Time.get_datetime_string_from_system())
	lines.append("")
	lines.append("== PLAN VOTES ==")
	for i in _fb_items.size():
		var v: String = String(_fb_votes[i]) if i < _fb_votes.size() else ""
		var mark: String = "[+UP]" if v == "up" else ("[-DOWN]" if v == "down" else "[ ... ]")
		var line: String = "%s %s" % [mark, String(_fb_items[i])]
		var c: String = _fb_comment_edits[i].text.strip_edges() if i < _fb_comment_edits.size() else ""
		if c != "":
			line += "   | comment: " + c
		lines.append(line)
	lines.append("")
	lines.append("== COLLEAGUES (which colleague fits this behaviour?) ==")
	for item in FB_COLLEAGUES:
		var ed: LineEdit = _fb_colleague_edits.get(String(item[0]), null)
		var val: String = ed.text.strip_edges() if ed != null else ""
		if val != "":
			lines.append("%-20s -> %s" % [String(item[1]), val])
	lines.append("")
	for key in ["towers", "enemies", "maps", "ideas"]:
		lines.append("== " + key.to_upper() + " ==")
		var te: TextEdit = _fb_fields.get(key, null)
		lines.append(te.text.strip_edges() if te != null else "")
		lines.append("")
	var runs: Array = PlaytestScript.all_runs()
	lines.append("== PLAYTEST RUNS: %d ==" % runs.size())
	for r in runs:
		lines.append(_fb_run_line(r))
		var c: String = str(r.get("comment", "")).strip_edges()
		if c != "":
			lines.append("      " + c)
	return "\n".join(lines) + "\n"

func _fb_all_text() -> String:
	# Feedback + de playtest-CSV in één lap, zodat er nooit een tweede bestand nodig is.
	var text: String = _fb_compose()
	var csv: String = PlaytestScript.csv_text()
	if csv != "":
		text += "\n---- PLAYTEST CSV ----\n" + csv
	return text

func _copy_feedback(result: Label) -> void:
	DisplayServer.clipboard_set(_fb_all_text())
	result.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
	result.text = "Copied! Paste it wherever suits you: a Discord message, an email, a text file or pastebin.com."

func _email_feedback(result: Label) -> void:
	# Een mailto-link kan de volle feedback niet dragen (URL-lengtelimieten in mailclients, en
	# de CSV erbij loopt tegen de tienduizenden tekens). Daarom: alles op het klembord en een
	# lege mail met het juiste adres + onderwerp openen, zodat de tester alleen hoeft te plakken.
	var text: String = _fb_all_text()
	DisplayServer.clipboard_set(text)
	var subject: String = "CTRL-ALT-DEFEND feedback - v%s - %s" % [
		PlaytestScript.version(), PlaytestScript.player_id()]
	var body: String = "Paste the feedback here (it is already on your clipboard: Ctrl+V)."
	OS.shell_open("mailto:%s?subject=%s&body=%s" % [FEEDBACK_EMAIL, subject.uri_encode(), body.uri_encode()])
	result.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
	result.text = "Your mail program should open with a message to %s.\nThe feedback is on your clipboard -- paste it into the mail (Ctrl+V) and send.\n\nNo mail program? Use COPY and paste it into Discord instead." % FEEDBACK_EMAIL

func _export_feedback(result: Label) -> void:
	var dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if dir == "":
		dir = OS.get_user_data_dir()
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var fpath: String = "%s/ctrl_alt_defend_feedback_%s.txt" % [dir, stamp]
	var f := FileAccess.open(fpath, FileAccess.WRITE)
	if f == null:
		fpath = "%s/ctrl_alt_defend_feedback_%s.txt" % [OS.get_user_data_dir(), stamp]
		f = FileAccess.open(fpath, FileAccess.WRITE)
	if f == null:
		result.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
		result.text = "Could not write the feedback file."
		return
	f.store_string(_fb_compose())
	f.close()
	var csv: String = PlaytestScript.export_csv()
	result.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
	var msg: String = "Saved feedback to:\n" + fpath
	if csv != "":
		msg += "\nSaved playtest CSV to:\n" + csv
	else:
		msg += "\n(no playtest rounds logged yet)"
	result.text = msg

# ---------- Art room ----------

func show_art_room() -> void:
	var room = ArtRoomScript.new()
	room.closed.connect(show_main_menu)
	_swap(room)

# ---------- Level select ----------

func show_level_select() -> void:
	var root := _screen("SELECT LEVEL")
	var info := Label.new()
	info.text = "Rank: %s   ·   Recognition: %d" % [GameState.current_rank().capitalize(), GameState.recognition]
	info.add_theme_font_size_override("font_size", 16)
	info.position = Vector2(SCREEN_W - 340, 40)
	root.add_child(info)

	# Tutorial staat los van de carrière (GDD §8): niet verplicht, telt niet mee voor sterren.
	# Daarom bovenaan in het midden en niet tussen de levels -- daar las hij als "level 0"
	# (playtest-feedback v0.68).
	var tut := _btn("TUTORIAL  ·  learn the basics", func(): start_level(101), 300, 34)
	tut.position = Vector2(SCREEN_W / 2.0 - 150, 56)
	tut.add_theme_font_size_override("font_size", 13)
	root.add_child(tut)

	# Carrière in blokken van vijf (GDD §8): junior / medior / senior.
	var block_titles := ["JUNIOR  ·  levels 1-5", "MEDIOR  ·  levels 6-10", "SENIOR  ·  levels 11-15"]
	var vb := VBoxContainer.new()
	vb.position = Vector2(44, 100)
	vb.add_theme_constant_override("separation", 8)
	root.add_child(vb)
	var block_count: int = int(ceil(GameState.LEVEL_COUNT / 5.0))
	for blk in block_count:
		var hdr := Label.new()
		hdr.text = block_titles[blk] if blk < block_titles.size() else "BLOCK %d" % (blk + 1)
		hdr.add_theme_font_size_override("font_size", 13)
		hdr.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		vb.add_child(hdr)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		vb.add_child(hb)
		for j in 5:
			var i: int = blk * 5 + j + 1
			if i > GameState.LEVEL_COUNT:
				break
			var data: Dictionary = GameState.get_level(i)
			var unlocked: bool = GameState.is_unlocked(i)
			var s: int = GameState.get_stars(i)
			var b := Button.new()
			b.custom_minimum_size = Vector2(168, 82)
			b.add_theme_font_size_override("font_size", 12)
			if unlocked:
				b.text = "%d\n%s" % [i, String(data["name"])]
				# Sterren als eigen tekening bovenop de knop: als tekst werden het blokjes.
				var sr = StarsScript.new()
				sr.setup(s, 3, 6.0)
				sr.position = Vector2(168.0 / 2.0 - 33.0, 60.0)
				sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.add_child(sr)
				var lid := i
				b.pressed.connect(func(): start_level(lid))
			else:
				b.text = "%d\n[ LOCKED ]" % i
				b.disabled = true
			hb.add_child(b)

	# Boss Rush en Endless zijn de specialist-beloning: pas zichtbaar als je die rang haalt
	# (playtest-feedback v0.68 -- ze stonden er al vanaf level 1, waardoor ze als gewone
	# levels lazen in plaats van als iets dat je verdient).
	if GameState.current_rank() == "specialist":
		var modes_hdr := Label.new()
		modes_hdr.text = "SPECIAL MODES"
		modes_hdr.add_theme_font_size_override("font_size", 13)
		modes_hdr.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		vb.add_child(modes_hdr)
		var mhb := HBoxContainer.new()
		mhb.add_theme_constant_override("separation", 10)
		vb.add_child(mhb)
		for m in [[102, "Boss Rush"], [103, "Endless"]]:
			var mb := Button.new()
			mb.custom_minimum_size = Vector2(168, 46)
			mb.add_theme_font_size_override("font_size", 12)
			mb.text = String(m[1])
			var mid: int = int(m[0])
			mb.pressed.connect(func(): start_level(mid))
			mhb.add_child(mb)

	var back := _vbox(root, Vector2(44, SCREEN_H - 62))
	back.add_child(_btn("< Back", show_main_menu, 130, 36))
	_swap(root)

func start_level(level_id: int) -> void:
	var lvl = LevelScript.new()
	lvl.level_id = level_id
	lvl.finished.connect(show_level_select)
	lvl.retry.connect(func(lid): start_level(lid))
	_swap(lvl)

# ---------- Settings ----------

func show_settings() -> void:
	var root := _screen("SETTINGS")
	var vb := _vbox(root, Vector2(44, 130))

	# Display mode
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 14)
	var mode_lbl := Label.new()
	mode_lbl.text = "Display mode"
	mode_lbl.custom_minimum_size = Vector2(150, 0)
	mode_lbl.add_theme_font_size_override("font_size", 16)
	mode_row.add_child(mode_lbl)
	var mode_opt := OptionButton.new()
	for m in GameState.DISPLAY_MODES:
		mode_opt.add_item(m)
	mode_opt.selected = GameState.display_mode
	mode_row.add_child(mode_opt)
	vb.add_child(mode_row)

	# Resolutie (alleen relevant in Windowed)
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 14)
	var res_label := Label.new()
	res_label.text = "Resolution"
	res_label.custom_minimum_size = Vector2(150, 0)
	res_label.add_theme_font_size_override("font_size", 16)
	res_row.add_child(res_label)
	var res_opt := OptionButton.new()
	var res_list := GameState.available_resolutions()
	for r in res_list:
		res_opt.add_item(GameState.resolution_label(r))
	res_opt.selected = clampi(GameState.resolution_index, 0, res_list.size() - 1)
	res_opt.disabled = GameState.display_mode != 0
	res_row.add_child(res_opt)
	vb.add_child(res_row)
	mode_opt.item_selected.connect(func(idx): res_opt.disabled = idx != 0)

	# Pixel-perfect schalen
	var ps_row := HBoxContainer.new()
	ps_row.add_theme_constant_override("separation", 14)
	var ps_lbl := Label.new()
	ps_lbl.text = "Pixel-perfect"
	ps_lbl.custom_minimum_size = Vector2(150, 0)
	ps_lbl.add_theme_font_size_override("font_size", 16)
	ps_row.add_child(ps_lbl)
	var ps_check := CheckBox.new()
	ps_check.button_pressed = GameState.integer_scale
	ps_check.tooltip_text = "Scales the game by whole numbers only, so pixels stay sharp.\nMay add small black borders on non-matching resolutions."
	ps_row.add_child(ps_check)
	vb.add_child(ps_row)

	var apply_row := HBoxContainer.new()
	apply_row.add_theme_constant_override("separation", 14)
	var status := Label.new()
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	status.custom_minimum_size = Vector2(240, 0)
	status.text = "Now: %d x %d" % [GameState.current_window_size().x, GameState.current_window_size().y]
	apply_row.add_child(_btn("Apply", func():
		GameState.display_mode = mode_opt.selected
		GameState.integer_scale = ps_check.button_pressed
		if mode_opt.selected == 0:
			GameState.resolution_index = res_opt.selected
		GameState.apply_settings()
		GameState.save_game()
		await get_tree().process_frame
		status.text = "Now: %d x %d" % [GameState.current_window_size().x, GameState.current_window_size().y],
		140, 34))
	apply_row.add_child(status)
	vb.add_child(apply_row)

	# Audio in een eigen kolom rechts: zes sliders passen niet meer onder de display-rijen.
	var disp_lbl := Label.new()
	disp_lbl.text = "DISPLAY"
	disp_lbl.position = Vector2(44, 104)
	disp_lbl.add_theme_font_size_override("font_size", 13)
	disp_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	root.add_child(disp_lbl)

	var audio_lbl := Label.new()
	audio_lbl.text = "AUDIO"
	audio_lbl.position = Vector2(500, 104)
	audio_lbl.add_theme_font_size_override("font_size", 13)
	audio_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	root.add_child(audio_lbl)

	# Master bovenaan: regelt alles tegelijk (op 0 = stil). Daaronder de losse categorieën.
	var av := _vbox(root, Vector2(500, 130))
	av.add_child(_slider_row("Master", GameState.master_volume, func(v):
		GameState.master_volume = v
		GameState.apply_settings()
		GameState.save_game()))
	av.add_child(_slider_row("Ambient", GameState.music_volume, func(v):
		GameState.music_volume = v
		GameState.apply_settings()
		GameState.save_game()))
	av.add_child(_slider_row("Shooting", GameState.shoot_volume, func(v):
		GameState.shoot_volume = v
		GameState.apply_settings()
		GameState.save_game()))
	av.add_child(_slider_row("Buying", GameState.buy_volume, func(v):
		GameState.buy_volume = v
		GameState.apply_settings()
		GameState.save_game()))
	av.add_child(_slider_row("Coffee", GameState.coffee_volume, func(v):
		GameState.coffee_volume = v
		GameState.apply_settings()
		GameState.save_game()))
	av.add_child(_slider_row("Events", GameState.event_volume, func(v):
		GameState.event_volume = v
		GameState.apply_settings()
		GameState.save_game()))

	var back := _vbox(root, Vector2(44, SCREEN_H - 70))
	back.add_child(_btn("< Back", show_main_menu, 130, 36))
	_swap(root)

func _slider_row(label_text: String, value: float, cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(150, 0)
	l.add_theme_font_size_override("font_size", 16)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(260, 22)
	s.value_changed.connect(cb)
	row.add_child(s)
	return row

# ---------- Shop ----------

func show_shop() -> void:
	var root := _screen("SHOP")
	var rec := Label.new()
	rec.text = "Recognition: %d" % GameState.recognition
	rec.add_theme_font_size_override("font_size", 18)
	rec.position = Vector2(SCREEN_W - 210, 34)
	rec.name = "Rec"
	root.add_child(rec)

	var tt := Label.new()
	tt.text = "Tech Tree — permanent upgrades"
	tt.add_theme_font_size_override("font_size", 16)
	tt.position = Vector2(44, 90)
	root.add_child(tt)
	var tvb := _vbox(root, Vector2(44, 118))
	tvb.add_child(_shop_upgrade_row(root, "startup_budget", "Startup Budget", "+15 Coffee at level start", 30))
	tvb.add_child(_shop_upgrade_row(root, "extra_caffeine", "Extra Caffeine", "+10 Focus at level start", 30))
	tvb.add_child(_shop_upgrade_row(root, "bulk_discount", "Bulk Discount", "All towers cost 10% less", 55))

	var ct := Label.new()
	ct.text = "Consumables — one-shot, taken into a level"
	ct.add_theme_font_size_override("font_size", 16)
	ct.position = Vector2(44, 280)
	root.add_child(ct)
	var cvb := _vbox(root, Vector2(44, 308))
	cvb.add_child(_shop_consumable_row(root, "smoke_break", "Smoke Break", "Restore +15 Focus in a level", 12))

	var back := _vbox(root, Vector2(44, SCREEN_H - 70))
	back.add_child(_btn("< Back", show_main_menu, 130, 36))
	_swap(root)

func _refresh_shop_labels(root: Control) -> void:
	var rec := root.get_node_or_null("Rec")
	if rec != null:
		(rec as Label).text = "Recognition: %d" % GameState.recognition

func _shop_upgrade_row(root: Control, id: String, title: String, desc: String, cost: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = "%s — %s" % [title, desc]
	l.custom_minimum_size = Vector2(480, 0)
	l.add_theme_font_size_override("font_size", 14)
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(130, 30)
	b.add_theme_font_size_override("font_size", 13)
	if GameState.has_upgrade(id):
		b.text = "Owned"
		b.disabled = true
	else:
		b.text = "Buy (%d R)" % cost
		b.pressed.connect(func():
			if GameState.buy_upgrade(id, cost):
				b.text = "Owned"
				b.disabled = true
				_refresh_shop_labels(root))
	row.add_child(b)
	return row

func _shop_consumable_row(root: Control, id: String, title: String, desc: String, cost: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = "%s (x%d) — %s" % [title, int(GameState.consumables.get(id, 0)), desc]
	l.custom_minimum_size = Vector2(480, 0)
	l.add_theme_font_size_override("font_size", 14)
	row.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(130, 30)
	b.add_theme_font_size_override("font_size", 13)
	b.text = "Buy (%d R)" % cost
	b.pressed.connect(func():
		if GameState.buy_consumable(id, cost):
			l.text = "%s (x%d) — %s" % [title, int(GameState.consumables.get(id, 0)), desc]
			_refresh_shop_labels(root))
	row.add_child(b)
	return row
