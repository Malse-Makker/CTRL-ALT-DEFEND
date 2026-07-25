extends RefCounted
# Playtest-telemetrie: legt per gespeelde ronde vast wat er gebeurde en wat de speler
# ervan vond, zodat balanceren op echte data kan in plaats van op berekeningen.
#
# UITZETTEN VOOR DE DEFINITIEVE VERSIE: zet ENABLED op false. Dan verdwijnt het
# feedback-formulier na een ronde én de exportknop in het hoofdmenu, en wordt er niets
# meer weggeschreven. Verder hoeft er niets verwijderd te worden.
#
# Opslag: user://playtest_runs.json (groeit per ronde).
#   macOS: ~/Library/Application Support/Godot/app_userdata/<project>/playtest_runs.json
# Export: een CSV in de Downloads-map, zodat testers 'm makkelijk kunnen terugsturen.

const ENABLED := true

const RUNS_PATH := "user://playtest_runs.json"
const ID_PATH := "user://playtest_id.txt"

const EnemyScript = preload("res://scripts/enemy.gd")
const TowerScript = preload("res://scripts/tower.gd")


static func player_id() -> String:
	# Anoniem en willekeurig, alleen om runs van dezelfde tester te kunnen groeperen.
	if FileAccess.file_exists(ID_PATH):
		var f := FileAccess.open(ID_PATH, FileAccess.READ)
		if f != null:
			var s := f.get_as_text().strip_edges()
			f.close()
			if s != "":
				return s
	var id := "p%d%04d" % [Time.get_unix_time_from_system(), randi() % 10000]
	var w := FileAccess.open(ID_PATH, FileAccess.WRITE)
	if w != null:
		w.store_string(id)
		w.close()
	return id


static func version() -> String:
	if FileAccess.file_exists("res://VERSION"):
		var f := FileAccess.open("res://VERSION", FileAccess.READ)
		if f != null:
			var v := f.get_as_text().strip_edges()
			f.close()
			return v
	return "?"


static func all_runs() -> Array:
	if not FileAccess.file_exists(RUNS_PATH):
		return []
	var f := FileAccess.open(RUNS_PATH, FileAccess.READ)
	if f == null:
		return []
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	return data if typeof(data) == TYPE_ARRAY else []


static func record(run: Dictionary) -> void:
	if not ENABLED:
		return
	var runs := all_runs()
	runs.append(run)
	var f := FileAccess.open(RUNS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(runs))
		f.close()


static func run_count() -> int:
	return all_runs().size()


static func clear() -> void:
	var f := FileAccess.open(RUNS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("[]")
		f.close()


# ---------- CSV ----------

static func _csv_cell(v) -> String:
	# Alles tussen quotes: opmerkingen kunnen komma's, quotes en regeleindes bevatten.
	# JSON kent alleen doubles, dus hele getallen komen terug als 7.0 — die schrijven we
	# als 7, anders staat de hele tabel vol met nutteloze decimalen.
	var s: String
	if typeof(v) == TYPE_FLOAT and is_equal_approx(v, round(v)):
		s = str(int(v))
	else:
		s = str(v)
	s = s.replace("\"", "\"\"").replace("\n", " ").replace("\r", " ")
	return "\"%s\"" % s


static func _columns() -> Array:
	# Vaste kolommen eerst, daarna één kolom per vijand (kills en doorbraken) en per
	# tower (gebouwd en geüpgraded). Zo blijft de CSV kloppen als er types bijkomen.
	var cols := ["run_id", "player_id", "timestamp", "version", "level_id", "level_name",
		# difficulty_0_10 is de oude vraag ("hoe moeilijk was dit"), vervangen door fun_0_10 in
		# v0.65.0. De kolom blijft staan zodat rondes van vóór die wissel hun antwoord houden —
		# ze door elkaar halen zou betekenen dat je twee verschillende vragen optelt.
		"outcome", "stars", "fun_0_10", "difficulty_0_10", "comment",
		"focus_start", "focus_left", "score", "wave_reached", "wave_total",
		"duration_sec", "max_speed", "early_calls",
		"coffee_earned", "coffee_spent", "towers_sold", "recognition_gained"]
	for id in EnemyScript.defs().keys():
		cols.append("kill_%s" % id)
	for id in EnemyScript.defs().keys():
		cols.append("leak_%s" % id)
	for id in TowerScript.defs().keys():
		cols.append("built_%s" % id)
	for id in TowerScript.defs().keys():
		cols.append("upg_%s" % id)
	return cols


static func _value_for(run: Dictionary, col: String):
	if run.has(col):
		return run[col]
	for prefix in [["kill_", "kills"], ["leak_", "leaks"], ["built_", "built"], ["upg_", "upgraded"]]:
		if col.begins_with(str(prefix[0])):
			var sub: Dictionary = run.get(str(prefix[1]), {})
			return sub.get(col.substr(str(prefix[0]).length()), 0)
	return ""


static func csv_text() -> String:
	var runs := all_runs()
	if runs.is_empty():
		return ""
	var cols := _columns()
	var lines := [",".join(cols)]
	for r in runs:
		var row := []
		for c in cols:
			row.append(_csv_cell(_value_for(r, str(c))))
		lines.append(",".join(row))
	return "\n".join(lines) + "\n"


static func export_csv() -> String:
	var text := csv_text()
	if text == "":
		return ""

	var dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if dir == "":
		dir = OS.get_user_data_dir()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/office_td_playtest_%s.csv" % [dir, stamp]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		# Downloads kan geblokkeerd zijn; val terug op de user-map
		path = "%s/office_td_playtest_%s.csv" % [OS.get_user_data_dir(), stamp]
		f = FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			return ""
	f.store_string(text)
	f.close()
	return path
