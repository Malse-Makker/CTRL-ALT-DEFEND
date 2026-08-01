extends Node2D

# Speelbaar level (basis 960x540, exact 2x op 1080p).
# Layout: info-strip boven, enemy-overzicht links (uitklapbaar), tower-shop rechts
# (uitklapbaar), start/pauze/snelheid rechtsonder. Alle in-game tekst Engels.

signal finished           # terug naar level select
signal retry(level_id)    # zelfde level opnieuw

const SCREEN_W := 960.0
const SCREEN_H := 540.0
const TOP_H := 34.0
const SHOP_W := 154.0
const LEFT_W := 174.0   # icoon + naam + aantal + NEW-badge moeten er samen in passen
const CTRL_H := 96.0
const HudIconScript = preload("res://scripts/hud_icon.gd")
const StarsScript = preload("res://scripts/stars.gd")

const GRID := 40.0
const PATH_WIDTH := 40.0
const BAR_ORDER := ["auto", "coffee", "ceo", "phones", "filter", "scrum", "trap", "chain", "machinegun", "multishot", "pomodoro", "splash"]
# Specials: aparte sectie onderin de shop, eigen regels (max 1 per level, geen upgrades).
const SPECIALS := ["keyboard", "ctrlaltdel"]

func _buildable() -> Array:
	# Volgorde = wanneer je ze vrijspeelt (GameState.TOWERS_PER_LEVEL), niet de volgorde waarin
	# ze ooit gebouwd zijn. Zowel de shop-tegels als de sneltoetsnummers lopen hierlangs, dus
	# die kunnen niet uit elkaar lopen. Core eerst, specials daarna (eigen sectie in de shop).
	var seen: Array = []
	for lvl in range(1, GameState.LEVEL_COUNT + 1):
		for id in GameState.TOWERS_PER_LEVEL.get(lvl, []):
			if not seen.has(id):
				seen.append(id)
	var core: Array = []
	var specials: Array = []
	for id in seen:
		if SPECIALS.has(id):
			specials.append(id)
		elif BAR_ORDER.has(id):
			core.append(id)
	# Vangnet: een toren die nergens vrijgespeeld wordt, valt anders uit de shop.
	for id in BAR_ORDER:
		if not core.has(id):
			core.append(id)
	for id in SPECIALS:
		if not specials.has(id):
			specials.append(id)
	return core + specials

func _core_order() -> Array:
	var out: Array = []
	for id in _buildable():
		if not SPECIALS.has(id):
			out.append(id)
	return out

func _special_order() -> Array:
	var out: Array = []
	for id in _buildable():
		if SPECIALS.has(id):
			out.append(id)
	return out
# Snelheden verdubbelen telkens -- leest lekker en is een knipoog naar binair.
const SPEEDS := [1.0, 2.0, 4.0, 8.0]

const TARGET_MODES := ["first", "last", "closest", "farthest", "least_hp", "most_hp"]
const TARGET_LABELS := ["First (furthest along)", "Last (just arrived)", "Closest",
	"Farthest", "Least HP", "Most HP"]
const WAVE_INTERVAL := 16.0
const POST_CLEAR_DELAY := 5.0
const EARLY_POINTS_PER_SEC := 5
const EARLY_POINTS_MAX := 40      # cap per wave: zonder cap was alles direct oproepen
                                   # ~1500 punten per run, meer dan het level zelf opleverde

const EnemyScript = preload("res://scripts/enemy.gd")
const TowerScript = preload("res://scripts/tower.gd")
const Playtest = preload("res://scripts/playtest.gd")
const Sfx = preload("res://scripts/sfx.gd")
const FxLayer = preload("res://scripts/fx_layer.gd")

# Telemetrie voor de playtest-builds: wat gebeurde er deze ronde? Doorbraken per
# vijandtype zijn het waardevolst — die wijzen aan wáár de balans wringt.
var _stats := {
	"kills": {}, "leaks": {}, "built": {}, "upgraded": {},
	"damage": {}, "made": {},
	"sold": 0, "coffee_earned": 0.0, "coffee_spent": 0,
	"early_calls": 0, "max_speed": 1.0, "t0": 0,
}

var level_id: int = 1
var level_name: String = "Level"
var path: PackedVector2Array
var paths_all: Array = []            # multi-path: meerdere ingangen; per wave rouleren
var obstacles: Array = []            # massieve blokken (tafel/racks): niet bouwbaar, pad loopt eromheen
var walls: Array = []                # zicht-muren (schotten): blokkeren line-of-sight + bouwen
var pay_zones: Array = []            # [{rect, cost, unlocked}] — met koffie te ontgrendelen bouwvlakken
var nobuild: Array = []              # geen-bouw-hatch-zones: niet bouwbaar (wel doorloopbaar)
var reveals: Array = []              # [{trigger_wave, path, done}] — extra paden die gaandeweg openen
const CORRIDOR_BUILD_DIST := 100.0   # ~2,5 tegel: breedte van de bouwstrook rond het pad
var corridor_build: bool = false     # hele map geen-bouw, behalve binnen CORRIDOR_BUILD_DIST van een pad
var available_towers: Array = []   # lescurve: welke towers dit level gebouwd mogen worden
var special_mode: bool = false     # Tutorial/Boss Rush/Endless (level_id >= 100): geen sterren/opslag
var tutorial: bool = false
var endless: bool = false
var tutorial_lessons: Array = []
var _lesson: int = 0               # huidige tutorial-les
var _lesson_hint: String = ""      # waar de tutorial-pijl naar wijst
var _start_coffee: float = 40.0    # beginbedrag, om per tutorial-les te herstellen
var banned_towers: Array = []      # dit level expliciet verboden (bv. HR Room)

var focus: int = 100
var start_focus: int = 100
var coffee: float = 30.0   # float: zwermvijanden leveren minder dan 1 Coffee op
var cost_mult: float = 1.0
var run_score: int = 0

var phase: String = "plan"
var total_waves: int = 0
var wave_index: int = 0
var next_wave_timer: float = 0.0
var spawning_count: int = 0
var paused: bool = false
var current_speed: float = 1.0
var game_over: bool = false
var _pre_menu_scale: float = 1.0

var enemies: Array = []
var towers: Array = []
var waves: Array = []
var selected_def_id: String = ""
var selected_tower: Node2D = null
var hover_pos: Vector2 = Vector2(-999, -999)
var _arrows_were_on: bool = false    # richting-pijltjes stonden vorig frame aan (om ze schoon te wissen)
var scrum_selecting: Node2D = null
var trap_selecting: Node2D = null    # lvl-3 trap-tower waarvan je de val-plek kiest
var hazard_type: String = ""
var hazard_active: bool = false
var building_blocked: bool = false
var _hazard_timer: float = 0.0
var _hazard_warned: bool = false
var modifiers: Array = []            # hele-ronde-regels (GDD §8): half_coffee, few_spots, multi_path, ...
# Quick-time event "Connect the projector" (vergaderzaal). De mini-game zelf zit in de
# herbruikbare component scripts/qte_projector.gd (ook gebruikt in de Art Room). Dit level
# regelt alleen wanneer hij verschijnt/sluit en de auto-skip-aftelling; het spel loopt door,
# je kunt alleen niet bouwen tot je 'm oplost of hij auto-skipt.
const QteProjector = preload("res://scripts/qte_projector.gd")
const QtePizza = preload("res://scripts/qte_pizza.gd")
const QteDino = preload("res://scripts/qte_dino.gd")
var qte_active: bool = false
var qte: Control                     # de projector-mini-game-component
var pizza_active: bool = false
var pizza_qte: Control               # de Eat the Pizza-mini-game (Release Night)
var dino_active: bool = false
var dino_qte: Control                # de No Internet-mini-game (Work From Home)
var _dino_total: float = 10.0        # startduur, om de voortgangsbalk te kunnen vullen
var click_active: bool = false
var click_qte: Control               # lichte klik-events: telefoon (Town Hall) / formulier (HR Room)
const QteClick = preload("res://scripts/qte_click.gd")
var _zone_timer: float = 8.0         # zone_block-modifier (The Merger): pulseert bouwblokkade
var _zone_active: bool = false
var _tex_cache: Dictionary = {}
var _enemy_tex_cache: Dictionary = {}
var _panel_timer: float = 0.0

# Effecten (projectielen, poef bij een kill, zwevende tekst). Puur visueel: schade is
# al toegepast op het moment van vuren, het projectiel haalt zijn doel dus altijd.
# Eén lijst met een "kind" per item, zodat alles op dezelfde manier verouderd en getekend
# wordt. Bij time_scale 0 (plan-fase, pauze, game over) is delta 0 en bevriest alles mee.
var fx: Node2D

# UI
var focus_label: Label
var focus_bar: ColorRect
var coffee_label: Label
var wave_label: Label
var score_label: Label
var hazard_label: Label
var msg_label: Label
var action_button: Button
var pause_button: Button
var speed_buttons: Dictionary = {}
var focus_icon: Control = null
var _left_user_closed: bool = false
var smoke_button: Button
var bar_buttons: Dictionary = {}
var shop_panel: Control
var shop_toggle: Button
var left_panel: Control
var left_toggle: Button
var enemy_rows: Dictionary = {}
var shop_open: bool = true
var left_open: bool = false
var hover_shop_id: String = ""   # shopknop waar de muis boven zweeft (range-preview)
var overlay: Control
var overlay_label: Label
var overlay_stats: Label
var overlay_buttons: HBoxContainer
var confirm: Control
var pause_menu: Control
var panel: PanelContainer
var upg_name: Label
var upg_stats: Label
var upg_target: OptionButton
var upg_hidden: CheckBox
var upg_scrum: Label
var upg_upgrade: Button
var upg_sell: Button
var _sounds: Dictionary = {}
var _players: Dictionary = {}
var music_player: AudioStreamPlayer
var _last_shot_ms: int = 0
var _msg_timer: float = 0.0
var _last_recognition: int = 0   # voor het playtest-logboek
var _warned_stealth: bool = false
var _new_types_this_run: Dictionary = {}   # types die deze ronde langskwamen

# Grote melding midden in beeld voor gebeurtenissen die je niet mag missen (brandalarm,
# lunchpauze, boss-fases). De kleine gele regel linksboven blijft voor kosten en foutjes;
# op 3x snelheid lees je die gegarandeerd niet op tijd.
var big_label: Label
var _big_timer: float = 0.0
var flash_rect: ColorRect          # schermbrede kleurflits (rood bij brandalarm)
var _flash_time: float = 0.0
var _flash_col: Color = Color(1, 0, 0)
var _smoke_timer: float = 0.0
var _focus_flash: float = 0.0
# Boss-balk bovenin: de kleine balk boven de sprite is te klein voor 420 HP + 120 schild.
var boss_box: Control
var boss_bar: ColorRect
var boss_shield_bar: ColorRect
var boss_label: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var data: Dictionary = GameState.get_level(level_id)
	level_id = int(data["id"])
	level_name = String(data["name"])
	path = data["path"]
	paths_all = data.get("paths", [path])
	obstacles = data.get("obstacles", [])
	walls = data.get("walls", [])
	pay_zones = []
	for pz in data.get("pay_zones", []):
		pay_zones.append({"rect": pz["rect"], "cost": int(pz["cost"]), "unlocked": false})
	nobuild = data.get("nobuild", [])
	reveals = []
	for r in data.get("reveals", []):
		reveals.append({"trigger_wave": int(r["trigger_wave"]), "path": r["path"], "done": false})
	corridor_build = bool(data.get("corridor_build", false))
	start_focus = int(data["start_focus"])
	focus = start_focus
	coffee = float(data["start_coffee"])
	_start_coffee = coffee
	waves = data["waves"]
	total_waves = waves.size()
	# Speciale modi: Tutorial (per-les reset + beperkte torens), Endless (genereert waves), Boss Rush.
	special_mode = level_id >= 100
	tutorial = bool(data.get("tutorial", false))
	endless = bool(data.get("endless", false))
	tutorial_lessons = data.get("tutorial_lessons", [])
	# .duplicate(): data["towers"] wijst naar de const-array in game_state; erase() zou die muteren.
	available_towers = (data.get("towers", BAR_ORDER) as Array).duplicate()
	# HR Room e.d.: bepaalde torens zijn verboden — uit de beschikbare lijst halen.
	banned_towers = data.get("banned", [])
	for b in banned_towers:
		available_towers.erase(b)
	hazard_type = String(data.get("hazard", ""))
	modifiers = data.get("modifiers", [])
	if hazard_type == "fire_alarm":
		_hazard_timer = 22.0
	elif hazard_type == "lunch":
		_hazard_timer = 28.0
	elif hazard_type == "beamer":
		_hazard_timer = 20.0
	elif hazard_type == "smoke":
		_hazard_timer = 20.0
	elif hazard_type == "overheat":
		_hazard_timer = 18.0
	elif hazard_type == "pizza":
		_hazard_timer = 25.0
	elif hazard_type == "no_internet":
		_hazard_timer = 18.0
	elif hazard_type == "phone" or hazard_type == "form":
		_hazard_timer = 16.0
	if GameState.has_upgrade("startup_budget"):
		coffee += 15
	if GameState.has_upgrade("extra_caffeine"):
		focus += 10
		start_focus += 10
	if GameState.has_upgrade("bulk_discount"):
		cost_mult = 0.9
	fx = FxLayer.new()
	fx.z_index = 5   # projectielen over de towers en vijanden heen
	add_child(fx)
	_stats["t0"] = Time.get_ticks_msec()
	_build_audio()
	_build_hud()
	Engine.time_scale = 0.0   # plan-fase: tijd bevroren
	_update_labels()
	_update_flow()
	if tutorial and not tutorial_lessons.is_empty():
		_flash_msg(String(tutorial_lessons[0]["text"]))
		_lesson_hint = String(tutorial_lessons[0].get("hint", ""))
	else:
		_flash_msg("PLAN PHASE - place towers, then press Start.")
	queue_redraw()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0:
			msg_label.text = ""
	_panel_timer += delta
	if _panel_timer > 0.25:
		_panel_timer = 0.0
		_update_enemy_panel()
	_update_notices(delta)
	# Bewegende richting-pijltjes (cosmetisch): alleen in de plan-fase of tijdens het plaatsen
	# van een toren. Draait dóór de vroege return hieronder heen, want in de plan-fase staat
	# time_scale op 0 (delta = 0) — de animatietijd komt daarom uit de wandklok in _draw.
	var show_arrows: bool = (phase == "plan" or selected_def_id != "") and not game_over and not paused
	if show_arrows or _arrows_were_on:
		queue_redraw()
	_arrows_were_on = show_arrows
	if game_over or phase != "run":
		return
	_update_boss_bar()
	_update_hazard(delta)
	# zone_block-modifier (The Merger): pulseert een bouwblokkade, ook op levels zonder hazard.
	if modifiers.has("zone_block"):
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_zone_active = not _zone_active
			_zone_timer = 3.0 if _zone_active else 9.0
			if _zone_active:
				_flash_msg("Restructuring - a build zone is off-limits for a moment.")
		if hazard_type == "":
			building_blocked = _zone_active
	_apply_buffs_and_disrupt()
	# Tutorial: elke les is een eigen mini-ronde. Zodra de vijanden van deze les weg zijn, terug naar
	# de plan-fase voor de volgende les (bord wordt gereset) — of klaar na de laatste les.
	if tutorial and wave_index >= 1 and spawning_count == 0 and enemies.is_empty():
		_tutorial_advance()
		return
	if wave_index < total_waves:
		if enemies.is_empty() and spawning_count == 0 and next_wave_timer > POST_CLEAR_DELAY:
			next_wave_timer = POST_CLEAR_DELAY
		next_wave_timer -= delta
		if next_wave_timer <= 0.0:
			_start_next_wave()
	_update_flow()

# ---------- Invoer ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_key(event as InputEventKey):
			get_viewport().set_input_as_handled()
			return
	if game_over or paused or (confirm != null and confirm.visible):
		return
	if event is InputEventMouseMotion:
		hover_pos = _snap(get_global_mouse_position())
		queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var raw: Vector2 = get_global_mouse_position()
		# lvl-3 trap: klik op het pad verlegt de val. Klik op een tower valt hieronder door.
		if trap_selecting != null and is_instance_valid(trap_selecting):
			var on_tower := false
			for t in towers:
				if raw.distance_to(t.position) <= 22.0:
					on_tower = true
					break
			if not on_tower and raw.x < SCREEN_W - SHOP_W:
				if _near_path(raw, 28.0):
					if trap_selecting.set_trap_spot(raw):
						_flash_msg("Trap moved.")
					else:
						_flash_msg("Out of the tower's range.")
				else:
					_flash_msg("Click on the path to aim the throws.")
				return
		# Betaal-om-te-bouwen: klik op een vergrendelde zone → ontgrendel met koffie.
		for pz in pay_zones:
			if not pz["unlocked"] and (pz["rect"] as Rect2).has_point(raw):
				if coffee >= float(pz["cost"]):
					coffee -= float(pz["cost"])
					_stats["coffee_spent"] = int(_stats["coffee_spent"]) + int(pz["cost"])
					pz["unlocked"] = true
					_update_labels()
					_play("buy")
					_flash_msg("Build zone unlocked.")
					queue_redraw()
				else:
					_flash_msg("Need %d Coffee to unlock this build zone." % int(pz["cost"]))
				return
		for t in towers:
			if raw.distance_to(t.position) <= 22.0:
				if scrum_selecting != null and t != scrum_selecting and t.role != "support":
					if scrum_selecting.position.distance_to(t.position) <= scrum_selecting.range_radius:
						_toggle_buff_target(scrum_selecting, t)
					else:
						_flash_msg("Out of the Motivational Poster's range.")
					return
				selected_def_id = ""   # selectie loslaten zodat je normaal kunt klikken
				_update_bar()
				_open_upgrade(t)
				return
		if selected_def_id != "":
			var snapped: Vector2 = _snap(raw)
			var sdef: Dictionary = TowerScript.defs()[selected_def_id]
			if _can_place_at(snapped):
				_try_place(snapped)
			elif bool(sdef.get("special", false)):
				for t in towers:
					if t.def_id == selected_def_id:
						_flash_msg("Only one %s per level." % String(sdef["name"]))
						break
			# klik = selectie altijd loslaten
			selected_def_id = ""
			_update_bar()
			queue_redraw()
		else:
			_close_upgrade()

func _handle_key(k: InputEventKey) -> bool:
	# Snelheid op de plus/min-toetsen: 1 t/m 6 zijn al bezet door de towers.
	match k.keycode:
		KEY_ESCAPE:
			if confirm != null and confirm.visible:
				_cancel_menu()
			elif paused:
				_toggle_pause()           # pauzemenu sluiten
			elif selected_def_id != "":
				selected_def_id = ""      # eerst de bouwselectie loslaten
				_update_bar()
				queue_redraw()
			elif panel != null and panel.visible:
				_close_upgrade()          # dan het upgrade-paneel
			elif phase == "run" and not game_over:
				_toggle_pause()           # anders pauzeren
			else:
				_request_menu()
			return true
		KEY_SPACE:
			if not game_over and (action_button == null or not action_button.disabled):
				_on_action()              # Start in de plan-fase, daarna Call Wave
			return true
		KEY_P:
			_toggle_pause()
			return true
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			_set_speed(_speed_step(1))
			return true
		KEY_MINUS, KEY_KP_SUBTRACT:
			_set_speed(_speed_step(-1))
			return true
	# Torenselectie: 1-9 → toren 1-9, 0 → toren 10, shift+1..4 → toren 11/12 + de twee specials.
	var order: Array = _buildable()
	var idx: int = -1
	if k.keycode == KEY_0:
		idx = 9
	elif k.keycode >= KEY_1 and k.keycode <= KEY_9:
		idx = k.keycode - KEY_1
		if k.shift_pressed:
			idx += 10
	if idx >= 0 and idx < order.size() and not game_over:
		_select_def(String(order[idx]))
		return true
	return false

func _snap(p: Vector2) -> Vector2:
	return (p / GRID).floor() * GRID + Vector2(GRID * 0.5, GRID * 0.5)

func _can_place_at(p: Vector2) -> bool:
	if p.y < TOP_H + 14.0 or p.y > SCREEN_H - 14.0:
		return false
	if p.x < 24.0 or p.x > SCREEN_W - SHOP_W - 14.0:
		return false
	# Betaal-om-te-bouwen-zones EERST: een ONTGRENDELDE zone maakt de tegel bouwbaar en overrulet het
	# obstakel-/geen-bouw-/corridor-verbod ("root access" op de racks). Een vergrendelde zone blokkeert.
	var in_unlocked_pz: bool = false
	for pz in pay_zones:
		if (pz["rect"] as Rect2).has_point(p):
			if pz["unlocked"]:
				in_unlocked_pz = true
			else:
				return false
	if not in_unlocked_pz:
		# Obstakels (tafel/racks) en geen-bouw-zones: niet bouwen (iets opgerekt tegen half-erin vallen).
		for r in obstacles:
			if (r as Rect2).grow(14.0).has_point(p):
				return false
		for r in nobuild:
			if (r as Rect2).has_point(p):
				return false
		# Corridor-bouwen: alleen binnen een smalle strook rond een actief pad mag je bouwen.
		if corridor_build and _min_path_dist(p) > CORRIDOR_BUILD_DIST:
			return false
	# Zicht-muren blokkeren altijd (ook binnen een betaal-zone).
	for w in walls:
		if (w as Rect2).grow(14.0).has_point(p):
			return false
	var def: Dictionary = TowerScript.defs()[selected_def_id] if selected_def_id != "" else {}
	if bool(def.get("on_path", false)):
		# on-path special (Keyboard Smash): moet júist óp/aan het pad staan.
		if not _near_path(p, 24.0):
			return false
	else:
		if _near_path(p, 30.0):
			return false
		if selected_def_id != "" and _min_path_dist(p) > _placement_max_dist(selected_def_id):
			return false
	# Specials: maximaal één per level.
	if bool(def.get("special", false)):
		for t in towers:
			if t.def_id == selected_def_id:
				return false
	for t in towers:
		if p.distance_to(t.position) < 40.0:
			return false
	return true

func _near_path(p: Vector2, thresh: float) -> bool:
	# Alle ingangen tellen mee (multi-ingang-levels): je mag op géén enkele lane bouwen,
	# ook niet op een baan die deze wave toevallig niet actief is.
	for pp in paths_all:
		for i in range(pp.size() - 1):
			if _dist_point_segment(p, pp[i], pp[i + 1]) <= thresh:
				return true
	return false

func _min_path_dist(p: Vector2) -> float:
	# Afstand tot de dichtstbijzijnde lane (over alle ingangen), zodat een toren die naast een
	# andere baan staat ook als 'binnen bereik' telt.
	var best: float = INF
	for pp in paths_all:
		for i in range(pp.size() - 1):
			best = minf(best, _dist_point_segment(p, pp[i], pp[i + 1]))
	return best

func _dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	var t: float = 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _placement_max_dist(id: String) -> float:
	var d: Dictionary = TowerScript.defs()[id]
	var r: String = String(d["role"])
	if r == "damage" or r == "stun" or r == "area" or r == "trap" or r == "multi" or r == "chain":
		# trap moet binnen bereik van het pad staan, zodat de auto-plek gegarandeerd raakt.
		return float(d["levels"][0].get("range", 130.0)) - 8.0
	return 150.0

func _selected_range() -> float:
	if selected_def_id == "":
		return 0.0
	return float(TowerScript.defs()[selected_def_id]["levels"][0].get("range", 0.0))

func _tower_texture(id: String) -> Texture2D:
	if _tex_cache.has(id):
		return _tex_cache[id]
	var p := "res://art/towers/%s_1.png" % id      # level-1 sprite voor shop/preview
	if not ResourceLoader.exists(p):
		p = "res://art/towers/%s.png" % id
	var tex: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_tex_cache[id] = tex
	return tex

func _enemy_texture(id: String) -> Texture2D:
	if _enemy_tex_cache.has(id):
		return _enemy_tex_cache[id]
	var p := "res://art/enemies/%s.png" % id
	var tex: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_enemy_tex_cache[id] = tex
	return tex

# ---------- Bouwen / upgraden ----------

func _role_tag(role: String) -> String:
	# Korte rolaanduiding, zodat je niet hoeft te raden wat een toren doet.
	match role:
		"economy": return "ECO"
		"stun": return "CC"
		"area": return "AREA"
		"support": return "BUFF"
		"trap": return "TRAP"
		"smash": return "SMASH"
		"multi": return "MULTI"
		"chain": return "CHAIN"
		_: return "DMG"

func _tower_summary(id: String, lvl: int) -> String:
	# Eén regel met het kerngetal per rol, voor in de shop-tooltip.
	var d: Dictionary = TowerScript.defs()[id]
	var s: Dictionary = d["levels"][lvl - 1]
	match String(d["role"]):
		"economy":
			var per: float = float(s["coffee_amount"]) / float(s["coffee_interval"])
			var cost: float = float(s["cost"])
			return "\n%.1f Coffee/s - pays for itself in %ds" % [per, int(cost / maxf(per, 0.01))]
		"stun":
			if float(s.get("stun", 0.0)) > 0.0:
				return "\nStuns %.1fs every %.1fs" % [float(s.get("stun", 0.0)), float(s.get("rate", 1.0))]
			return "\nSlows to %d%% for %.1fs, every %.1fs" % [
				int(float(s.get("slow", 1.0)) * 100.0), float(s.get("slow_dur", 0.0)),
				float(s.get("rate", 1.0))]
		"area":
			return "\n%.0f damage/s shared across the zone, slows" % float(s.get("dot", 0.0))
		"support":
			return "\n+%d%% damage to chosen towers" % int((float(s.get("buff_dmg", 1.0)) - 1.0) * 100.0)
		"multi":
			return "\n%.0f dmg to %d targets at once, every %.1fs" % [
				float(s.get("damage", 0.0)), int(s.get("shots", 1)), float(s.get("rate", 1.0))]
		"chain":
			return "\n%.0f dmg, jumps to %d more (x%.0f%% each), every %.1fs" % [
				float(s.get("damage", 0.0)), int(s.get("jumps", 0)),
				float(s.get("falloff", 0.75)) * 100.0, float(s.get("rate", 1.0))]
		"trap":
			return "\n%.0f dmg/tack, throws one every %.1fs (lasts %.1fs)" % [
				float(s.get("damage", 0.0)), float(s.get("throw_interval", 0.0)), float(s.get("lifetime", 0.0))]
		"smash":
			return "\n%.0f AoE damage, then blocks the path %.1fs (every %.0fs)" % [
				float(s.get("smash_damage", 0.0)), float(s.get("barrier", 0.0)), float(s.get("smash_cooldown", 0.0))]
		_:
			var dps: float = float(s.get("damage", 0.0)) / maxf(float(s.get("rate", 1.0)), 0.01)
			return "\n%.1f damage/s (%.0f per shot)" % [dps, float(s.get("damage", 0.0))]

func _tower_unlock_level(id: String) -> int:
	for lvl in range(1, GameState.LEVEL_COUNT + 1):
		if GameState.TOWERS_PER_LEVEL.get(lvl, []).has(id):
			return lvl
	return GameState.LEVEL_COUNT

func _select_def(id: String) -> void:
	var d: Dictionary = TowerScript.defs()[id]
	if d.get("locked", false) or not available_towers.has(id):
		_flash_msg("%s unlocks in level %d." % [String(d["name"]), _tower_unlock_level(id)])
		return
	selected_def_id = id
	_close_upgrade()
	_update_bar()

# Elke toren van hetzelfde type die je al hebt maakt de vólgende duurder. Zonder dit is
# vijf keer level 1 neerzetten altijd beter dan één toren upgraden (playtest-feedback v0.68:
# "je doet meer damage en je verspreidt het"), en dan is de hele upgrade-ladder decoratie.
# Alleen op plaatsen (lvl 1) -- upgraden zelf wordt nooit duurder.
const DUPLICATE_SURCHARGE := 0.25
const DUPLICATE_SURCHARGE_MAX := 1.0

func _duplicate_mult(id: String) -> float:
	var n: int = 0
	for t in towers:
		if is_instance_valid(t) and t.def_id == id:
			n += 1
	return 1.0 + minf(float(n) * DUPLICATE_SURCHARGE, DUPLICATE_SURCHARGE_MAX)

func _tower_cost(id: String, lvl: int) -> int:
	var base: float = float(TowerScript.defs()[id]["levels"][lvl - 1]["cost"]) * cost_mult
	if lvl == 1:
		base *= _duplicate_mult(id)
	return int(round(base))

const FEW_SPOTS_CAP := 8
# Vast bedrag per overleefde wave; loopt via _add_coffee en volgt dus half_coffee.
const WAVE_INCOME := 4

func _try_place(p: Vector2) -> void:
	if building_blocked:
		_flash_msg("Can't build right now.")
		return
	# few_spots-modifier (Boardroom-finales, Server Room): beperkt aantal bouwplekken.
	if modifiers.has("few_spots") and towers.size() >= FEW_SPOTS_CAP:
		_flash_msg("No room to build - this floor only fits %d towers." % FEW_SPOTS_CAP)
		return
	var cost: int = _tower_cost(selected_def_id, 1)
	if coffee < cost:
		_flash_msg("Not enough Coffee (need %d)." % cost)
		return
	coffee -= cost
	_stats["built"][selected_def_id] = int(_stats["built"].get(selected_def_id, 0)) + 1
	_stats["coffee_spent"] = int(_stats["coffee_spent"]) + cost
	var t = TowerScript.new()
	t.position = p
	t.get_enemies = func(): return enemies
	t.get_walls = func(): return walls
	t.on_coffee = func(a):
		_stats["made"][t.def_id] = float(_stats["made"].get(t.def_id, 0.0)) + float(a)
		_play("coffee")
		_fx_float(t.position + Vector2(0, -16), "+%d" % int(a), Color(0.92, 0.80, 0.55))
		_add_coffee(a)
	t.on_damage = func(id, amt):
		_stats["damage"][id] = float(_stats["damage"].get(id, 0.0)) + amt
		t.stat_damage += amt
	t.on_fire = func(from, to, id, role): _play_shot(id); _fx_shot(from, to, id, role)
	t.trap_path = path        # dichtstbijzijnde pad-punt (lvl-3 default)
	t.trap_paths = paths_all  # trap strooit over ÁLLE lanes (multi-path)
	t.on_throw = func(from, to): fx.toss(from, to)   # punaise-worp
	t.on_smash = func(pos):     # Keyboard Smash: letters-explosie + geluid
		fx.letters(pos, 10)
		_fx_puff(pos, Color(0.5, 0.52, 0.6), 30.0)
		_play("kill")
	t.invested = cost
	add_child(t)
	t.configure(selected_def_id, 1)
	towers.append(t)
	_play_buy()
	_update_labels()
	queue_redraw()

func _upgrade_delta_text(t: Node2D) -> String:
	# Laat zien wat een upgrade precies verandert (+/-), voor in de tooltip.
	if t.level >= 3:
		return "Fully upgraded."
	var lv: Array = TowerScript.defs()[t.def_id]["levels"]
	var cur: Dictionary = lv[t.level - 1]
	var nxt: Dictionary = lv[t.level]
	var lines: Array = ["%s - \"%s\"" % [String(nxt.get("name", "")), String(nxt.get("flavour", ""))], ""]
	var rows := [
		["damage", "Damage", 1.0, false],
		["dot", "Damage/sec", 1.0, false],
		["stun", "Stun", 1.0, false],
		["slow", "Slow to", 1.0, true],        # lager = trager = beter
		["slow_dur", "Slow lasts", 1.0, false],
		["range", "Range", 1.0, false],
		["rate", "Every", 1.0, true],          # lager = beter
		["coffee_amount", "Coffee", 1.0, false],
		["coffee_interval", "Interval", 1.0, true],
		["targets", "Buff targets", 1.0, false],
		["throw_interval", "Throws every", 1.0, true],   # lager = sneller gooien = beter
		["lifetime", "Tack lasts", 1.0, false],          # langer = meer liggen = beter
	]
	for r in rows:
		var key: String = r[0]
		if not cur.has(key) and not nxt.has(key):
			continue
		var a: float = float(cur.get(key, 0.0))
		var b: float = float(nxt.get(key, 0.0))
		if is_equal_approx(a, b):
			continue
		var diff: float = b - a
		var better: bool = (diff < 0.0) if bool(r[3]) else (diff > 0.0)
		lines.append("%s %s -> %s  (%s%s)" % [
			String(r[1]), _num(a), _num(b), "+" if diff > 0.0 else "", _num(diff)])
		if not better:
			lines[lines.size() - 1] += " !"
	if float(cur.get("buff_dmg", 0.0)) != float(nxt.get("buff_dmg", 0.0)):
		lines.append("Buff %d%% -> %d%%  (+%d%%)" % [
			int((float(cur["buff_dmg"]) - 1.0) * 100.0),
			int((float(nxt["buff_dmg"]) - 1.0) * 100.0),
			int((float(nxt["buff_dmg"]) - float(cur["buff_dmg"])) * 100.0)])
	return "\n".join(lines)

func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, round(v)) else ("%.2f" % v)

func _tower_performance(t: Node2D) -> String:
	# Wat heeft juist DEZE toren opgeleverd voor de Coffee die erin zit? Zonder dit moest je
	# op gevoel bepalen of een plek goed was (tester-feedback v0.72).
	var inv: float = maxf(float(t.invested), 1.0)
	if t.role == "economy":
		var made: float = float(_stats["made"].get(t.def_id, 0.0))
		return "\n\nThis machine's type has made %d Coffee this run." % int(made)
	var dmg: float = float(t.stat_damage)
	if dmg <= 0.0:
		return "\n\nNo damage yet - it may be out of range of the path."
	return "\n\nDamage dealt: %d   (%.1f per Coffee invested)" % [int(dmg), dmg / inv]

func _open_upgrade(t: Node2D) -> void:
	selected_tower = t
	var d: Dictionary = TowerScript.defs()[t.def_id]
	upg_name.text = "%s  (Lv %d)" % [t.level_name, t.level]
	upg_stats.text = "\"%s\"\n%s%s" % [t.level_flavour, _tower_stats_text(t), _tower_performance(t)]
	if t.role == "damage" or t.role == "stun" or t.role == "multi" or t.role == "chain":
		upg_target.visible = true
		upg_target.selected = TARGET_MODES.find(t.target_mode)
		upg_hidden.visible = t.sees_hidden
		upg_hidden.set_pressed_no_signal(t.prefer_hidden)
	else:
		upg_target.visible = false
		upg_hidden.visible = false
	if t.role == "support":
		scrum_selecting = t
		upg_scrum.visible = true
		_refresh_scrum_label()
		_flash_msg("Click towers in range to buff (max %d)." % t.max_targets)
	else:
		scrum_selecting = null
		upg_scrum.visible = false
	# lvl-3 trap: laat de speler de val-plek verleggen door op het pad te klikken.
	if t.role == "trap" and t.pick_spot:
		trap_selecting = t
		_flash_msg("Click a path tile within range to aim the throws.")
	else:
		trap_selecting = null
	var max_lvl: int = TowerScript.defs()[t.def_id]["levels"].size()
	if t.is_special:
		upg_upgrade.text = "Special - no upgrades"
		upg_upgrade.disabled = true
	elif t.level < max_lvl:
		var next_cost: int = _tower_cost(t.def_id, t.level + 1)
		var next_name: String = String(TowerScript.defs()[t.def_id]["levels"][t.level].get("name", ""))
		upg_upgrade.text = "-> %s  (%d C)" % [next_name, next_cost]
		upg_upgrade.disabled = false
	else:
		upg_upgrade.text = "Max level"
		upg_upgrade.disabled = true
	upg_upgrade.tooltip_text = _upgrade_delta_text(t)
	upg_sell.text = "Sell (+%d C)" % int(t.invested * 0.6)
	var pos: Vector2 = t.position + Vector2(24, -20)
	pos.x = clampf(pos.x, 8.0, SCREEN_W - SHOP_W - 200.0)
	pos.y = clampf(pos.y, TOP_H + 4.0, SCREEN_H - 180.0)
	panel.position = pos
	panel.visible = true

func _close_upgrade() -> void:
	selected_tower = null
	scrum_selecting = null
	trap_selecting = null
	panel.visible = false

func _refresh_scrum_label() -> void:
	if selected_tower != null and selected_tower.role == "support":
		var cnt: int = 0
		for x in selected_tower.buff_targets:
			if is_instance_valid(x):
				cnt += 1
		upg_scrum.text = "Buffing %d / %d towers" % [cnt, selected_tower.max_targets]

func _on_target_selected(idx: int) -> void:
	if selected_tower != null and idx >= 0 and idx < TARGET_MODES.size():
		selected_tower.target_mode = TARGET_MODES[idx]
		selected_tower.target_mode_chosen = true   # upgraden mag deze keuze niet resetten

func _toggle_buff_target(sm: Node2D, t: Node2D) -> void:
	if sm.buff_targets.has(t):
		sm.buff_targets.erase(t)
	elif sm.buff_targets.size() < sm.max_targets:
		sm.buff_targets.append(t)
	else:
		_flash_msg("Already buffing %d tower(s)." % sm.max_targets)
	_refresh_scrum_label()
	queue_redraw()

func _tower_stats_text(t: Node2D) -> String:
	# Sluit af met wat er in deze toren zit: dat maakt de afweging "upgraden of een
	# tweede toren kopen" zichtbaar (de balansregel uit GDD §11).
	var invested: String = "\nInvested: %d Coffee" % int(t.invested)
	match t.role:
		"economy":
			var per: float = float(t.coffee_amount) / maxf(t.coffee_interval, 0.01)
			return "+%d Coffee / %.1fs  (%.1f/s)\nPays for itself in %ds%s" % [
				t.coffee_amount, t.coffee_interval, per,
				int(float(t.invested) / maxf(per, 0.01)), invested]
		"stun":
			if t.stun_dur > 0.0:
				return "Stuns %.1fs + slows to %d%%, every %.1fs\nRange %d%s" % [
					t.stun_dur, int(t.cc_slow * 100.0), t.fire_rate,
					int(t.range_radius), invested]
			return "Slows to %d%% for %.1fs, every %.1fs\nRange %d%s" % [
				int(t.cc_slow * 100.0), t.cc_slow_dur, t.fire_rate,
				int(t.range_radius), invested]
		"area":
			return "%.1f dmg/s in zone, slows\nRadius %d%s" % [
				t.area_dot, int(t.range_radius), invested]
		"support":
			return "Buff +%d%% dmg, faster, more range\nUp to %d towers%s" % [
				int((t.buff_dmg - 1.0) * 100.0), int(t.max_targets), invested]
		"multi":
			return "%.0f dmg to %d targets, every %.2fs\nRange %d%s" % [
				t.damage, int(t.multi_shots), t.fire_rate, int(t.range_radius), invested]
		"chain":
			return "%.0f dmg, jumps to %d more (x%d%% each)\nRange %d%s" % [
				t.damage, int(t.chain_jumps), int(t.chain_falloff * 100.0),
				int(t.range_radius), invested]
		"trap":
			var spot: String = "\nClick the path to aim the throws" if t.pick_spot else "\nThrows land randomly on the path"
			return "%.0f dmg per tack, one every %.1fs\nEach tack lasts %.1fs - Range %d%s%s" % [
				t.damage, t.throw_interval, t.tack_lifetime, int(t.range_radius), spot, invested]
		"smash":
			return "%.0f AoE damage, blocks path %.1fs\nEvery %.0fs - Radius %d%s" % [
				t.smash_damage, t.barrier_duration, t.smash_cooldown, int(t.range_radius), invested]
		_:
			var dps: float = float(t.damage) / maxf(t.fire_rate, 0.01)
			return "%.1f damage/s  (%d per shot, every %.2fs)\nRange %d  -  %.3f DPS per Coffee%s" % [
				dps, int(t.damage), t.fire_rate, int(t.range_radius),
				dps / maxf(float(t.invested), 1.0), invested]

func _do_upgrade() -> void:
	var t = selected_tower
	if t == null or t.level >= 3:
		return
	if building_blocked:
		_flash_msg("Can't build during lunch break.")
		return
	var cost: int = _tower_cost(t.def_id, t.level + 1)
	if coffee < cost:
		_flash_msg("Not enough Coffee (need %d)." % cost)
		return
	coffee -= cost
	_stats["upgraded"][t.def_id] = int(_stats["upgraded"].get(t.def_id, 0)) + 1
	_stats["coffee_spent"] = int(_stats["coffee_spent"]) + cost
	t.invested += cost
	t.configure(t.def_id, t.level + 1)
	_play("upgrade")
	_update_labels()
	_open_upgrade(t)

func _do_sell() -> void:
	var t = selected_tower
	if t == null:
		return
	if building_blocked:
		_flash_msg("Can't sell during lunch break.")
		return
	_stats["sold"] = int(_stats["sold"]) + 1
	_add_coffee(int(t.invested * 0.6))
	towers.erase(t)
	t.queue_free()
	_close_upgrade()
	_play("sell")
	queue_redraw()

# ---------- Wave-flow ----------

func _on_action() -> void:
	if phase == "plan":
		_begin_run()
	else:
		_call_next_wave()

func _begin_run() -> void:
	phase = "run"
	paused = false
	current_speed = 1.0
	Engine.time_scale = 1.0
	_flash_msg("The day begins. No turning back now.")
	_start_next_wave()

func _call_next_wave() -> void:
	if phase != "run" or wave_index >= total_waves:
		return
	var bonus: int = mini(int(ceil(next_wave_timer)) * EARLY_POINTS_PER_SEC, EARLY_POINTS_MAX)
	run_score += bonus
	_stats["early_calls"] = int(_stats["early_calls"]) + 1
	# Vroeg oproepen geeft punten, maar waves stapelen op. In de playtest riep een tester
	# 21 van de 22 waves vroeg op en werd bedolven -- het spel juichte alleen maar mee.
	# Nu waarschuwt hij zodra het bord al vol staat.
	if enemies.size() >= 25 and focus > start_focus / 2:
		_flash_msg("+%d points -- but %d are still on the board. Waves stack up." % [bonus, enemies.size()])
	else:
		_flash_msg("Wave called early! +%d points." % bonus)
	_start_next_wave()

func _start_next_wave() -> void:
	# Endless: houd altijd een buffer van komende waves klaar → wave_index haalt total_waves nooit in
	# (dus geen win), oplopend in moeilijkheid. Speel tot je Focus op is.
	if endless:
		while waves.size() <= wave_index + 2:
			waves.append(GameState._parse_wave(GameState._endless_spec(waves.size() + 1)))
		total_waves = waves.size()
	if wave_index >= total_waves:
		return
	var w: Array = waves[wave_index]
	# Salaris per overleefde wave. Zonder dit zit je vast aan je openingskeuze: koop je twee
	# torens die niet werken tegen dit level, dan komt er nooit genoeg Coffee binnen om het
	# recht te trekken (playtest-feedback v0.68). Klein bedrag -- het is een vangnet, geen
	# inkomstenbron die de Coffee Machine overbodig maakt.
	# Via _add_coffee, zodat de half_coffee-modifier en de Out of Order-boss (die alle
	# koffie-inkomsten stopzet) hier net zo goed voor gelden als voor kills.
	if wave_index > 0 and not _coffee_blocked():
		_add_coffee(float(WAVE_INCOME))
		_flash_msg("Payday: +%dC for surviving wave %d." % [WAVE_INCOME, wave_index])
	wave_index += 1
	# Onthul-paden: bij elke trigger-wave opent een extra vijand-pad. In corridor-levels wordt de
	# strook eromheen meteen bouwbaar. De speler zag dit vooraf niet aankomen.
	for r in reveals:
		if not r["done"] and wave_index >= int(r["trigger_wave"]):
			r["done"] = true
			paths_all = paths_all + [r["path"]]
			_flash_msg("A new lane opens up - and new ground to build on!")
			queue_redraw()
	# Multi-path: elke wave komt uit een andere ingang.
	if paths_all.size() > 1:
		path = paths_all[(wave_index - 1) % paths_all.size()]
	next_wave_timer = WAVE_INTERVAL
	spawning_count += 1
	_spawn_wave_async(w)
	_update_flow()

func _spawn_wave_async(groups: Array) -> void:
	for g in groups:
		for n in int(g["count"]):
			if game_over:
				spawning_count -= 1
				return
			_spawn_enemy(String(g["type"]))
			await get_tree().create_timer(float(g["interval"])).timeout
	spawning_count -= 1
	_check_end()

func _spawn_enemy(type: String) -> void:
	_spawn_enemy_at(type, path[0], 1, true)

func _spawn_enemy_at(type: String, pos: Vector2, idx: int, at_start: bool) -> void:
	var e = EnemyScript.new()
	e.configure(type)
	if e.is_boss:
		var bdef: Dictionary = EnemyScript.defs()[type]
		var add_type: String = String(bdef.get("boss_add", "feedback"))
		e.on_spawn_adds = func(p, i, c): _spawn_adds(p, i, c, add_type)
		e.phase_changed.connect(_on_boss_phase)
		if e.cameo:
			e.on_spawn_cameo = func(p, i, bt): _spawn_cameo(p, i, bt)
			_flash_msg("360-degree feedback - past managers return as peer reviewers. Do you feel stressed?")
		_big_msg(String(bdef["name"]).to_upper(), Color(1.0, 0.5, 0.5))
		_play("alarm")
		match e.boss_kind:
			"outoforder": _flash_msg("Out of Order! No Coffee income until you defeat it.")
			"beamer": _flash_msg("Break the 'loading' shield first - burst it down.")
			"reorg": _flash_msg("It restructures - burst it before it splits too often.")
			"allhands": _flash_msg("It keeps calling everyone in. Clear the crowd.")
			"cleaner": _flash_msg("The Cleaner! It speeds up the crowd and wipes your zones and traps.")
			"smoking": _flash_msg("The Smoking Colleague - the haze keeps your towers' range short.")
			"baby": _flash_msg("The Baby! Towers nearby get distracted and fire slower.")
			"floater": _flash_msg("The Floater keeps pulling in a crowd. Cover every lane.")
			"hrmanager": _flash_msg("The HR Manager is auditing - one of your tower types keeps getting shut down.")
			"legacy": _flash_msg("The Legacy System won't die and keeps spewing errors. Grind it down.")
			"consultant": _flash_msg("The Consultant buffs everything. Kill it to weaken the wave.")
			"deadline": _flash_msg("The Deadline! Everything speeds up the longer it lives - burst it NOW.")
	elif e.spawn_interval > 0.0:
		var st: String = e.spawn_type
		e.on_spawn_adds = func(p, i, c): _spawn_adds(p, i, c, st)
	add_child(e)
	if at_start:
		e.setup(path)
	else:
		e.setup_at(path, pos, idx)
	e.died.connect(_on_enemy_died)
	e.reached_end.connect(_on_enemy_reached_end)
	enemies.append(e)

func _spawn_lunch_rush() -> void:
	# De lunchpauze legt je towers niet meer stil, maar stuurt de hele afdeling tegelijk de
	# gang op. Zwakke, snelle types in dichte drom: je towers vuren gewoon door, de vraag is
	# of ze het tempo bijhouden. Groeit mee met de wave-index, zodat een lunch laat in het
	# level zwaarder is dan de eerste.
	var extra: int = wave_index / 3
	var groups := [
		{"type": "nudge", "count": 12 + extra, "interval": 0.10},
		{"type": "noti", "count": 6 + extra, "interval": 0.14},
		{"type": "hulp", "count": 4 + extra / 2, "interval": 0.20},
	]
	spawning_count += 1
	_spawn_wave_async(groups)

func _spawn_adds(pos: Vector2, idx: int, count: int, type_id: String = "feedback") -> void:
	var col: Color = EnemyScript.defs()[type_id]["color"]
	for n in count:
		var off := Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
		_spawn_enemy_at(type_id, pos + off, idx, false)
		_fx_puff(pos + off, col, 12.0)   # zichtbaar dat ze ergens uit komen

func _spawn_cameo(pos: Vector2, idx: int, boss_type: String) -> void:
	# "360° feedback": een mini-versie van een eerdere boss als peer reviewer. Neemt de kleur/sprite
	# van de boss over, maar wordt gedegradeerd tot een zwakke, gewone add (geen boss-AI, geen HP-balk).
	var e = EnemyScript.new()
	e.configure(boss_type)
	e.is_boss = false
	e.boss_kind = ""
	e.max_hp = 26.0
	e.hp = 26.0
	e.radius = e.radius * 0.55
	e.coffee_reward = 4.0
	e.focus_damage = 4
	add_child(e)
	e.setup_at(path, pos + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)), idx)
	e.died.connect(_on_enemy_died)
	e.reached_end.connect(_on_enemy_reached_end)
	enemies.append(e)
	_fx_puff(e.position, e.color, 16.0)

func _on_enemy_died(e) -> void:
	enemies.erase(e)
	if game_over:
		return
	var was_at: Vector2 = e.position
	_stats["kills"][e.type_id] = int(_stats["kills"].get(e.type_id, 0)) + 1
	_stats["coffee_earned"] = float(_stats["coffee_earned"]) + e.coffee_reward
	_add_coffee(e.coffee_reward)
	run_score += 1
	# Zwaardere vijanden geven een grotere poef, zodat een tank neerhalen anders voelt
	# dan een vodje wegtikken.
	_fx_puff(was_at, e.color, clampf(e.radius * 0.9, 8.0, 34.0))
	_play("kill")
	# Coffee is fractioneel; onder de 1 zou "+0" in beeld komen, dus die tonen we niet.
	if e.coffee_reward >= 1.0:
		_fx_float(was_at + Vector2(0, -e.radius), "+%d" % int(round(e.coffee_reward)),
			Color(0.95, 0.8, 0.45))
	if e.split_count > 0 and e.split_type != "":
		for k in e.split_count:
			var off := Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
			_spawn_enemy_at(e.split_type, was_at + off, e.target_index, false)
			_fx_puff(was_at + off, Color(0.6, 0.9, 0.7), 14.0)   # splitsing zichtbaar maken
	_check_end()

func _on_enemy_reached_end(e) -> void:
	enemies.erase(e)
	if game_over:
		return
	_stats["leaks"][e.type_id] = int(_stats["leaks"].get(e.type_id, 0)) + 1
	# Een onzichtbare vijand die doorglipt is anders een raadsel: je ziet Focus zakken
	# zonder te begrijpen waardoor. Eén keer per ronde uitleggen wat er gebeurde.
	if e.invisible and not e.revealed and not _warned_stealth:
		_warned_stealth = true
		_flash_msg("Something slipped past unseen - a Shredder zone reveals hidden enemies.")
	focus -= e.focus_damage
	_play("leak")
	_flash_focus()
	if focus <= 0:
		focus = 0
		_update_labels()
		_lose()
		return
	_update_labels()
	_check_end()

func _check_end() -> void:
	if game_over:
		return
	# Tutorial regelt zijn eigen einde per les (_tutorial_advance); niet hier winnen.
	if phase == "run" and not tutorial and wave_index >= total_waves and spawning_count == 0 and enemies.is_empty():
		_win()
	_update_labels()

func _tutorial_advance() -> void:
	# Volgende les of, na de laatste, klaar. Reset het bord en ga terug naar de plan-fase.
	if wave_index >= total_waves:
		_win()
		return
	_tutorial_reset()
	_lesson = wave_index
	available_towers = (tutorial_lessons[_lesson]["towers"] as Array).duplicate()
	_rebuild_shop()
	phase = "plan"
	Engine.time_scale = 0.0
	next_wave_timer = WAVE_INTERVAL
	if action_button != null:
		action_button.text = ">  START"
		action_button.disabled = false
	_flash_msg(String(tutorial_lessons[_lesson]["text"]))
	_lesson_hint = String(tutorial_lessons[_lesson].get("hint", ""))
	_update_labels()

func _tutorial_reset() -> void:
	_close_upgrade()
	selected_def_id = ""
	for t in towers:
		if is_instance_valid(t):
			t.queue_free()
	towers.clear()
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	coffee = _start_coffee   # elke les met een schone, toereikende beurs beginnen
	focus = start_focus
	queue_redraw()

func _rebuild_shop() -> void:
	# Tutorial: de beschikbare torens wisselen per les, dus de shop-knoppen opnieuw opbouwen.
	if shop_panel == null:
		return
	var canvas: Node = shop_panel.get_parent()
	var was_open: bool = shop_open
	shop_panel.queue_free()
	if shop_toggle != null:
		shop_toggle.queue_free()
	bar_buttons.clear()
	_build_shop(canvas)
	shop_open = was_open
	shop_panel.visible = shop_open
	if not shop_open and shop_toggle != null:
		shop_toggle.text = "<"
		shop_toggle.position.x = SCREEN_W - 18
	_update_bar()

func _apply_buffs_and_disrupt() -> void:
	for t in towers:
		t.buff_dmg_mult = 1.0
		t.buff_rate_mult = 1.0
		t.buff_range_mult = 1.0
		t.silenced = false
		t.suppressed = false
		t.disrupt_rate_mult = 1.0
	for sm in towers:
		if sm.role != "support":
			continue
		var valid: Array = []
		for t in sm.buff_targets:
			if is_instance_valid(t) and towers.has(t):
				valid.append(t)
		sm.buff_targets = valid
		for t in sm.buff_targets:
			if sm.position.distance_to(t.position) <= sm.range_radius:
				# Alleen de sterkste buff telt. Vermenigvuldigen liet twee Transformation
				# Leads oplopen tot 3,2x schade en een halve cooldown — bijna 6x DPS, en
				# dat maakte een tweede Motivational Poster lonender dan upgraden (GDD §11).
				t.buff_dmg_mult = maxf(t.buff_dmg_mult, sm.buff_dmg)
				t.buff_rate_mult = minf(t.buff_rate_mult, sm.buff_rate)   # lager = sneller
				t.buff_range_mult = maxf(t.buff_range_mult, sm.buff_range)
	var alarm: bool = hazard_active and hazard_type == "fire_alarm"
	for e in enemies:
		if not is_instance_valid(e):
			continue
		e.hazard_speed_mult = 1.7 if alarm else 1.0
		# Keyboard Smash-slagboom: vijanden binnen bereik van een liggend toetsenbord staan stil.
		e.blocked = false
		for t in towers:
			if t.role == "smash" and t.barrier_active and e.position.distance_to(t.position) <= t.range_radius:
				e.blocked = true
				break
		# Een gestunte Kletskous zwijgt: zijn aura ligt stil zolang de stun duurt. Dat
		# maakt Headphones lvl 3 de harde counter uit GDD §6 — stunnen én de mond snoeren.
		if e.disrupt_radius > 0.0 and e.stun_time <= 0.0:
			for t in towers:
				if e.position.distance_to(t.position) <= e.disrupt_radius:
					if e.disrupt_mode == "silence":
						t.silenced = true
					else:
						t.disrupt_rate_mult = maxf(t.disrupt_rate_mult, 2.0)
		if e.is_boss and e.phase >= 3:
			for t in towers:
				if e.position.distance_to(t.position) <= 170.0:
					t.disrupt_rate_mult = maxf(t.disrupt_rate_mult, 1.8)
	# Brandalarm én oververhitting (server room) leggen de towers stil zolang ze actief zijn.
	# De lunchpauze doet dat bewust NIET (v0.30.0): daar komt de druk van de swarm.
	if hazard_active and (hazard_type == "fire_alarm" or hazard_type == "overheat"):
		for t in towers:
			t.silenced = true
	# Rook (The Parking): zolang de walm hangt, verkort de range van alle towers.
	if hazard_active and hazard_type == "smoke":
		for t in towers:
			t.buff_range_mult *= 0.6
	# The Baby-boss: torens in de buurt raken afgeleid en vuren trager.
	for b in enemies:
		if is_instance_valid(b) and b.is_boss and b.boss_kind == "baby":
			for t in towers:
				if b.position.distance_to(t.position) <= 150.0:
					t.disrupt_rate_mult = maxf(t.disrupt_rate_mult, 1.8)
	# The Cleaner-boss: speed-aura op vijanden in de buurt, en veegt Shredder-zones (onderdrukt de
	# area-toren zolang hij ernaast staat) en punaisenvallen weg die hij passeert.
	for c in enemies:
		if not (is_instance_valid(c) and c.is_boss and c.boss_kind == "cleaner"):
			continue
		for e in enemies:
			if is_instance_valid(e) and e != c and c.position.distance_to(e.position) <= 130.0:
				e.hazard_speed_mult *= 1.5
		for t in towers:
			if t.role == "area" and c.position.distance_to(t.position) <= 100.0:
				t.suppressed = true
			elif t.role == "trap":
				t.clear_tacks_near(c.position, 45.0)
	# --- Blok 3-bosses ---
	var deadline_menace: float = 0.0
	var hr_alive: bool = false
	for b in enemies:
		if not (is_instance_valid(b) and b.is_boss):
			continue
		match b.boss_kind:
			"consultant":
				# Buft alle andere vijanden: sneller lopen én een schild (eenmalig per vijand, zodat
				# doorgaand toppen ze niet onsterfelijk maakt). Kill de Consultant om de buff te stoppen.
				for e in enemies:
					if is_instance_valid(e) and e != b:
						e.hazard_speed_mult *= 1.3
						if not e._consultant_shielded:
							e._consultant_shielded = true
							e.shield += 8.0
							e.max_shield = maxf(e.max_shield, e.shield)
			"deadline":
				deadline_menace = maxf(deadline_menace, b.menace)
			"hrmanager":
				hr_alive = true
	if deadline_menace > 0.0:
		for e in enemies:
			if is_instance_valid(e):
				e.hazard_speed_mult *= (1.0 + deadline_menace)
	if hr_alive:
		# Audit: rouleert elke ~5s door de gebouwde torentypes en legt dat type stil.
		var types: Array = []
		for t in towers:
			if not types.has(t.def_id):
				types.append(t.def_id)
		if not types.is_empty():
			var audited: String = String(types[int(Time.get_ticks_msec() / 5000) % types.size()])
			for t in towers:
				if t.def_id == audited:
					t.silenced = true

func _update_hazard(delta: float) -> void:
	if hazard_type == "":
		return
	_hazard_timer -= delta
	if hazard_type == "fire_alarm":
		if not hazard_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("Fire alarm approaching!")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 4.5
				# Knipoog naar The IT Crowd (het beroemde noodnummer).
				_flash_msg("FIRE ALARM! Quick, call 0118 999 881 999 119 725 3!")
				_big_msg("FIRE ALARM", Color(1.0, 0.45, 0.4))
				_screen_flash(Color(1.0, 0.25, 0.2), 4.5)
				_play("alarm")
		elif _hazard_timer <= 0.0:
			hazard_active = false
			_hazard_timer = 24.0
			_hazard_warned = false
			_screen_flash(Color(1.0, 0.25, 0.2), 0.0)
	elif hazard_type == "smoke":
		if not hazard_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("Someone's lighting up outside - haze incoming.")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 6.0
				_flash_msg("SMOKE BREAK! The haze shortens your towers' range.")
				_big_msg("SMOKE", Color(0.72, 0.74, 0.72))
				_screen_flash(Color(0.6, 0.62, 0.6), 6.0)
		elif _hazard_timer <= 0.0:
			hazard_active = false
			_hazard_timer = 22.0
			_hazard_warned = false
			_screen_flash(Color(0.6, 0.62, 0.6), 0.0)
	elif hazard_type == "overheat":
		if not hazard_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("The server room is heating up...")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 4.0
				_flash_msg("OVERHEATING! Towers pause until it cools down.")
				_big_msg("OVERHEATING", Color(1.0, 0.6, 0.3))
				_screen_flash(Color(1.0, 0.5, 0.25), 4.0)
		elif _hazard_timer <= 0.0:
			hazard_active = false
			_hazard_timer = 20.0
			_hazard_warned = false
			_screen_flash(Color(1.0, 0.5, 0.25), 0.0)
	elif hazard_type == "lunch":
		if not hazard_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("Lunch break approaching - build now!")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 7.0
				_flash_msg("LUNCH BREAK! Everyone heads out at once - no building.")
				_big_msg("LUNCH BREAK", Color(1.0, 0.85, 0.45))
				_screen_flash(Color(1.0, 0.8, 0.35), 7.0)
				_play("lunch")
				_play("crowd")
				_spawn_lunch_rush()
		elif _hazard_timer <= 0.0:
			hazard_active = false
			# 55s rust (was 30): ~4-5 lunches per level in plaats van 8-9. Elke lunch is dan
			# een echte gebeurtenis en niet bijna-constante swarm. De rush zelf is iets groter.
			_hazard_timer = 55.0
			_hazard_warned = false
			_screen_flash(Color(1.0, 0.8, 0.35), 0.0)
	elif hazard_type == "beamer":
		if not qte_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("Someone needs to connect the projector...")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 10.0     # auto-skip-venster (spel loopt door)
				_show_qte()              # de QTE toont zelf al de titel
		elif _hazard_timer <= 0.0:
			_finish_qte(false)           # niet op tijd opgelost → auto-skip
	elif hazard_type == "pizza":
		if not pizza_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("Pizza's here! Grab a slice before it's gone.")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 10.0     # auto-skip-venster
				_show_pizza()
		elif _hazard_timer <= 0.0:
			_finish_pizza(false)         # niet op tijd → auto-skip
	elif hazard_type == "no_internet":
		if not dino_active:
			if _hazard_timer <= 3.0 and not _hazard_warned:
				_hazard_warned = true
				_flash_msg("Connection dropped...")
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 10.0     # tijd tot de verbinding terug is (dodgen versnelt dit)
				_dino_total = 10.0
				_show_dino()
		else:
			# Voortgang doorgeven zodat de balk in de mini-game meeloopt -- en zichtbaar
			# vooruitspringt zodra je een obstakel ontwijkt.
			if dino_qte != null:
				dino_qte.set_progress(1.0 - _hazard_timer / maxf(_dino_total, 0.001))
			if _hazard_timer <= 0.0:
				_finish_dino()           # verbinding terug (vanzelf of sneller door te dodgen)
	elif hazard_type == "phone" or hazard_type == "form":
		if not click_active:
			if _hazard_timer <= 0.0:
				hazard_active = true
				_hazard_timer = 8.0      # auto-skip als je 'm negeert
				_show_click()
		elif _hazard_timer <= 0.0:
			_finish_click(false)
	# Bouwen blokkeren tijdens de lunch, tijdens mini-game-events, en tijdens de zone_block-puls.
	building_blocked = (hazard_active and hazard_type == "lunch") or qte_active or pizza_active or dino_active or click_active or _zone_active
	if qte_active:
		qte.set_timer_text("Auto-skips in %ds" % int(ceil(maxf(_hazard_timer, 0.0))))
	if pizza_active:
		pizza_qte.set_timer_text("Auto-skips in %ds" % int(ceil(maxf(_hazard_timer, 0.0))))
	if dino_active:
		dino_qte.set_timer_text("Back online in %ds  -  dodge to speed it up" % int(ceil(maxf(_hazard_timer, 0.0))))
	if click_active:
		click_qte.set_timer_text("Auto-dismiss in %ds" % int(ceil(maxf(_hazard_timer, 0.0))))
	if hazard_label != null:
		var naam: String = "Fire alarm"
		if hazard_type == "lunch":
			naam = "Lunch break"
		elif hazard_type == "beamer":
			naam = "Projector"
		elif hazard_type == "smoke":
			naam = "Smoke"
		elif hazard_type == "overheat":
			naam = "Overheat"
		elif hazard_type == "pizza":
			naam = "Pizza"
		elif hazard_type == "no_internet":
			naam = "Connection"
		elif hazard_type == "phone":
			naam = "Phone"
		elif hazard_type == "form":
			naam = "HR form"
		if hazard_active:
			hazard_label.text = "%s ACTIVE  %ds" % [naam, int(ceil(maxf(_hazard_timer, 0.0)))]
			hazard_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		else:
			hazard_label.text = "%s in %ds" % [naam, int(ceil(maxf(_hazard_timer, 0.0)))]
			hazard_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	# Rookwolkjes tijdens het brandalarm: verspreid over het speelveld, niet op het pad
	# zelf, zodat ze de vijanden niet onleesbaar maken.
	if hazard_active and hazard_type == "fire_alarm":
		_smoke_timer -= delta
		if _smoke_timer <= 0.0:
			_smoke_timer = 0.18
			var p := Vector2(randf_range(40.0, SCREEN_W - SHOP_W - 40.0),
				randf_range(TOP_H + 30.0, SCREEN_H - 30.0))
			fx.smoke(p, randf_range(14.0, 26.0), randf_range(-12.0, 12.0))

# ---------- Pauze / snelheid / menu ----------

func _toggle_pause() -> void:
	if game_over or phase != "run":
		return
	paused = not paused
	Engine.time_scale = 0.0 if paused else current_speed
	pause_button.text = ">" if paused else "||"
	if pause_menu != null:
		pause_menu.visible = paused

func _build_pause_menu(canvas: CanvasLayer) -> void:
	pause_menu = Control.new()
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu.visible = false
	canvas.add_child(pause_menu)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09, 0.72)
	pause_menu.add_child(bg)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(SCREEN_W / 2.0 - 150, 150)
	title.size = Vector2(300, 40)
	title.add_theme_font_size_override("font_size", 30)
	pause_menu.add_child(title)
	var vb := VBoxContainer.new()
	vb.position = Vector2(SCREEN_W / 2.0 - 90, 210)
	vb.add_theme_constant_override("separation", 8)
	pause_menu.add_child(vb)
	vb.add_child(_button("Resume", _toggle_pause, 180, 34))
	vb.add_child(_button("Restart level", func(): retry.emit(level_id), 180, 34))
	vb.add_child(_button("Quit run", _request_menu, 180, 34))
	var hint := Label.new()
	hint.text = "P or Esc to resume  -  1-6 towers  -  Space starts a wave"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(SCREEN_W / 2.0 - 220, 370)
	hint.size = Vector2(440, 20)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	pause_menu.add_child(hint)

func _build_qte(canvas: CanvasLayer) -> void:
	# De mini-game zelf zit in de herbruikbare component (scripts/qte_projector.gd). Dit level
	# geeft alleen het geluid mee en luistert naar de afloop.
	qte = QteProjector.new()
	qte.play_cb = Callable(self, "_play")
	qte.solved.connect(func(): _finish_qte(true))
	qte.message.connect(_flash_msg)
	canvas.add_child(qte)
	# Eat the Pizza (Release Night) — zelfde patroon: aparte component, level regelt timing.
	pizza_qte = QtePizza.new()
	pizza_qte.finished.connect(func(): _finish_pizza(true))
	canvas.add_child(pizza_qte)
	# No Internet (Work From Home) — dodgen versnelt de auto-skip (verbinding komt eerder terug).
	dino_qte = QteDino.new()
	dino_qte.dodged.connect(func(): _hazard_timer = maxf(0.0, _hazard_timer - 1.5))
	canvas.add_child(dino_qte)
	# Lichte klik-events (telefoon / formulier) — soort bepaald door het level.
	click_qte = QteClick.new()
	click_qte.finished.connect(func(): _finish_click(true))
	canvas.add_child(click_qte)
	if hazard_type == "phone" or hazard_type == "form":
		click_qte.setup(hazard_type)

func _show_qte() -> void:
	qte_active = true
	qte.show_qte()

func _finish_qte(solved: bool) -> void:
	qte_active = false
	qte.hide_qte()
	hazard_active = false
	_hazard_timer = 26.0
	_hazard_warned = false
	if solved:
		_play("upgrade")
		_flash_msg("Projector connected. Back to work.")
	else:
		_flash_msg("The meeting gave up on the projector.")

func _show_pizza() -> void:
	pizza_active = true
	pizza_qte.start_event()

func _finish_pizza(eaten: bool) -> void:
	pizza_active = false
	pizza_qte.hide_event()
	hazard_active = false
	_hazard_timer = 30.0
	_hazard_warned = false
	if eaten:
		_play("upgrade")
		_flash_msg("Pizza demolished. Back to the release.")
	else:
		_flash_msg("The pizza went cold - back to work.")

func _show_dino() -> void:
	dino_active = true
	dino_qte.start_event()

func _finish_dino() -> void:
	dino_active = false
	dino_qte.hide_event()
	hazard_active = false
	_hazard_timer = 28.0
	_hazard_warned = false
	_play("upgrade")
	_flash_msg("Back online. Where were we?")

func _show_click() -> void:
	click_active = true
	click_qte.show_event()

func _finish_click(clicked: bool) -> void:
	click_active = false
	click_qte.hide_event()
	hazard_active = false
	_hazard_timer = 16.0             # telefoon/formulier komen vaker terug (kleiner event)
	_hazard_warned = false
	if clicked:
		_play("sell")
		_flash_msg("Handled. Where were we?" if hazard_type == "phone" else "Signed. Carry on.")

func _speed_step(dir: int) -> float:
	# +/- loopt door de vaste reeks; buiten de reeks blijven we op de rand staan.
	var i := SPEEDS.find(current_speed)
	if i == -1:
		return SPEEDS[0]
	return SPEEDS[clampi(i + dir, 0, SPEEDS.size() - 1)]

func _set_speed(s: float) -> void:
	if paused or game_over or phase != "run":
		return
	current_speed = s
	_stats["max_speed"] = maxf(float(_stats["max_speed"]), s)
	Engine.time_scale = s
	_update_speed_buttons()

func _update_speed_buttons() -> void:
	for spd in speed_buttons.keys():
		var b: Button = speed_buttons[spd]
		b.modulate = Color(1.0, 0.9, 0.4) if is_equal_approx(spd, current_speed) else Color(1, 1, 1)

func _request_menu() -> void:
	if phase == "run" and not game_over:
		_pre_menu_scale = Engine.time_scale
		Engine.time_scale = 0.0
		confirm.visible = true
	else:
		_leave_to_menu()

func _surrender() -> void:
	confirm.visible = false
	Engine.time_scale = 1.0
	_lose()

func _cancel_menu() -> void:
	confirm.visible = false
	Engine.time_scale = _pre_menu_scale

func _leave_to_menu() -> void:
	Engine.time_scale = 1.0
	finished.emit()

# ---------- Economie / labels ----------

func _add_coffee(amount: float) -> void:
	# Out of Order-boss: zolang de "monteur" leeft krijg je geen Coffee erbij (kills én machines).
	if amount > 0.0 and _coffee_blocked():
		return
	# Town Hall-modifier: koffie-inkomen gehalveerd.
	if amount > 0.0 and modifiers.has("half_coffee"):
		amount *= 0.5
	coffee += amount
	_update_labels()

func _coffee_blocked() -> bool:
	for e in enemies:
		if is_instance_valid(e) and e.is_boss and e.boss_kind == "outoforder":
			return true
	return false

func _update_labels() -> void:
	focus_label.text = str(focus)
	var ratio: float = clampf(float(focus) / float(maxi(1, start_focus)), 0.0, 1.0)
	if focus_bar != null:
		focus_bar.size.x = 62.0 * ratio
		# groen -> oranje -> rood, zodat je in één oogopslag ziet hoe je ervoor staat
		if ratio > 0.5:
			focus_bar.color = Color(0.35, 0.85, 0.45)
		elif ratio > 0.25:
			focus_bar.color = Color(0.95, 0.7, 0.3)
		else:
			focus_bar.color = Color(0.9, 0.35, 0.35)
		if focus_icon != null:
			focus_icon.set_tint(focus_bar.color)
	coffee_label.text = "%d" % int(floor(coffee))
	score_label.text = "Score %d" % run_score
	_update_bar()

func _update_flow() -> void:
	if phase == "plan":
		wave_label.text = "Plan Phase"
		action_button.text = ">  START"
		action_button.disabled = false
	else:
		var shown: int = min(wave_index, total_waves)
		if wave_index < total_waves:
			wave_label.text = "Wave %d/%d  -  next %ds" % [shown, total_waves, int(ceil(max(0.0, next_wave_timer)))]
			action_button.text = "CALL WAVE\n+points"
			action_button.disabled = false
		else:
			wave_label.text = "Wave %d/%d  -  final" % [shown, total_waves]
			action_button.text = "All waves out"
			action_button.disabled = true

func _update_bar() -> void:
	var order: Array = _buildable()
	for id in bar_buttons.keys():
		var b: Button = bar_buttons[id]
		var cost: int = _tower_cost(String(id), 1)
		var sel: bool = (id == selected_def_id)
		var afford: bool = coffee >= cost
		# De prijs loopt op met het aantal dat je al hebt, dus die moet live meelopen --
		# anders staat er een bedrag op de knop dat niet klopt met wat er afgeschreven wordt.
		b.text = "%d - %dC" % [order.find(String(id)) + 1, cost]
		b.modulate = Color(1.0, 0.9, 0.4) if sel else (Color(1, 1, 1) if afford else Color(0.55, 0.55, 0.55))

func _flash_msg(text: String) -> void:
	msg_label.text = text
	_msg_timer = 4.0

func _flash_focus() -> void:
	# Korte klap op de Focus-balk. Een schermbrede flits bij élke doorbraak zou te veel
	# zijn — er komen er in latere waves tientallen.
	_focus_flash = 1.0

func _big_msg(text: String, col: Color) -> void:
	if big_label == null:
		return
	big_label.text = text
	big_label.add_theme_color_override("font_color", col)
	_big_timer = 2.4

func _screen_flash(col: Color, dur: float) -> void:
	_flash_col = col
	_flash_time = dur

func _update_notices(delta: float) -> void:
	if _focus_flash > 0.0:
		_focus_flash = maxf(0.0, _focus_flash - delta * 4.0)
		if focus_bar != null:
			focus_bar.modulate = Color(1, 1, 1).lerp(Color(2.5, 2.5, 2.5), _focus_flash)
	if _big_timer > 0.0:
		_big_timer -= delta
		# even blijven staan, dan uitfaden
		var a: float = clampf(_big_timer / 0.8, 0.0, 1.0)
		big_label.modulate = Color(1, 1, 1, a)
		if _big_timer <= 0.0:
			big_label.text = ""
	if _flash_time > 0.0:
		_flash_time -= delta
		# pulseren in plaats van één vlakke kleur, zodat het als alarm leest
		var pulse: float = 0.20 + 0.10 * sin(Time.get_ticks_msec() * 0.012)
		flash_rect.color = Color(_flash_col.r, _flash_col.g, _flash_col.b,
			pulse * clampf(_flash_time, 0.0, 1.0))
	elif flash_rect != null and flash_rect.color.a > 0.0:
		flash_rect.color = Color(_flash_col.r, _flash_col.g, _flash_col.b, 0.0)

func _update_boss_bar() -> void:
	if boss_box == null:
		return
	var boss: Node2D = null
	for e in enemies:
		if is_instance_valid(e) and e.is_boss:
			boss = e
			break
	if boss == null:
		boss_box.visible = false
		return
	boss_box.visible = true
	var w: float = SCREEN_W - SHOP_W - 62.0
	boss_bar.size.x = w * clampf(boss.hp / maxf(boss.max_hp, 1.0), 0.0, 1.0)
	if boss.max_shield > 0.0:
		boss_shield_bar.visible = boss.shield > 0.0
		boss_shield_bar.size.x = w * clampf(boss.shield / boss.max_shield, 0.0, 1.0)
	else:
		boss_shield_bar.visible = false
	boss_label.text = "%s - %s" % [EnemyScript.defs()[boss.type_id]["name"], _boss_phase_name(boss)]

func _boss_phase_name(boss: Node2D) -> String:
	if boss.boss_kind == "review":
		match boss.phase:
			2: return "Phase 2: Peer Feedback"
			3: return "Phase 3: Improvement Plan"
			_: return "Phase 1: Self-Assessment"
	return "Phase %d" % boss.phase

func _on_boss_phase(e, p: int) -> void:
	match e.boss_kind:
		"review":
			match p:
				2:
					_big_msg("PHASE 2\nPEER FEEDBACK", Color(1.0, 0.75, 0.4))
					_flash_msg("The boss stops to gather feedback - adds incoming.")
				3:
					_big_msg("PHASE 3\nIMPROVEMENT PLAN", Color(1.0, 0.45, 0.4))
					_flash_msg("It speeds up and slows your towers. Last stand.")
					_screen_flash(Color(1.0, 0.3, 0.3), 1.2)
		"reorg":
			# Elke fase splitst hij een Manager af (twee Change-splitters die naar je bureau rennen).
			if p >= 2:
				_big_msg("RESTRUCTURING", Color(0.8, 0.85, 0.6))
				_flash_msg("It splits off a Manager - burst it down.")
				_spawn_adds(e.position, e.target_index, 2, "change")
		"beamer":
			if p >= 2:
				_flash_msg("No signal! The projector beams slides at your desk.")
		"allhands":
			if p >= 2:
				_flash_msg("It invites even more people in.")

# ---------- Effecten ----------

func _fx_shot(from: Vector2, to: Vector2, id: String, role: String) -> void:
	fx.shot(from, to, id, role)

func _fx_puff(pos: Vector2, col: Color, size: float) -> void:
	fx.puff(pos, col, size)

func _fx_float(pos: Vector2, text: String, col: Color) -> void:
	fx.floater(pos, text, col)

# ---------- Enemy-overzicht ----------

func _update_enemy_panel() -> void:
	if left_panel == null:
		return
	var counts: Dictionary = {}
	for e in enemies:
		if is_instance_valid(e):
			counts[e.type_id] = int(counts.get(e.type_id, 0)) + 1
	# Een type dat de speler nog nooit gezien heeft: paneel openklappen en markeren,
	# anders ontdekt niemand dat die informatie er is.
	var found_new: bool = false
	for id in counts.keys():
		if not GameState.seen_enemies.has(id):
			found_new = true
			break
	# Alleen ongevraagd openklappen als de speler het paneel niet zelf heeft dichtgedaan;
	# anders klapt het bij elk nieuw vijandtype terug open (playtest-feedback v0.68).
	if found_new and not left_open and not _left_user_closed:
		_toggle_left()
	for id in enemy_rows.keys():
		var row: Dictionary = enemy_rows[id]
		var n: int = int(counts.get(id, 0))
		(row["root"] as Control).visible = n > 0
		if n > 0:
			(row["count"] as Label).text = "x%d" % n
			(row["new"] as Label).visible = not GameState.seen_enemies.has(id)
			# Alleen onthouden dát dit type langskwam. Wegschrijven gebeurt pas aan het
			# eind van de ronde: markeer je 'm meteen, dan verdwijnt de NEW-badge in
			# dezelfde frame waarin het paneel opengaat en zie je 'm nooit.
			_new_types_this_run[id] = true

# ---------- Win / lose ----------

func _stars() -> int:
	var ratio: float = float(focus) / float(max(1, start_focus))
	if ratio >= 0.9:
		return 3
	elif ratio >= 0.5:
		return 2
	return 1

func _win() -> void:
	game_over = true
	Engine.time_scale = 0.0
	# Speciale modi tellen niet mee voor sterren/Recognition (geen opslag).
	if special_mode:
		var t: String = "COMPLETE"
		if tutorial:
			t = "TUTORIAL COMPLETE"
		elif level_id == 102:
			t = "BOSS RUSH CLEARED!"
		_show_overlay(t, Color(0.2, 0.7, 0.35), true, "Nice work - score %d." % run_score)
		return
	var s: int = _stars()
	var flawless: bool = (focus >= start_focus)
	var r: Dictionary = GameState.complete_level(level_id, s, flawless)
	_last_recognition = int(r["total"])
	# Opbouw op eigen regels: als een lange zin stond dit over de knoppen heen te lopen.
	var lines: Array = []
	lines.append("Score %d   -   Focus left %d/%d" % [run_score, focus, start_focus])
	if int(r["stars_pay"]) > 0:
		lines.append("Recognition for %d/3 stars:  +%d" % [int(r["best"]), int(r["stars_pay"])])
	elif int(r["best"]) > 0:
		lines.append("You already earned the Recognition for %d/3 stars here." % int(r["best"]))
	if int(r["flawless_pay"]) > 0:
		lines.append("FLAWLESS - not a single Focus lost:  +%d" % int(r["flawless_pay"]))
	if int(r["best"]) < 3:
		lines.append("Come back with 3 stars to collect the rest (%d of %d so far)." % [
			GameState.recognition_for_stars(int(r["best"])), int(r["max_for_level"])])
	lines.append("Total this run:  +%d Recognition" % int(r["total"]))
	var detail: String = "\n".join(lines)
	var title: String = "LEVEL COMPLETE"
	var promo: String = String(r.get("promotion", ""))
	if promo != "":
		title = "PROMOTED!\nYou are now a %s" % promo
	_show_overlay(title, Color(0.2, 0.7, 0.35), true, detail)
	# Sterren als tekening op het winscherm; als tekst werden het blokjes onder Proton.
	if overlay != null:
		var sr = StarsScript.new()
		sr.setup(s, 3, 14.0)
		# Vaste plek tussen de titel en de opsomming; op halve schermhoogte liepen ze
		# dwars door de Recognition-regels heen.
		sr.position = Vector2(SCREEN_W / 2.0 - sr.size.x / 2.0, 74.0)
		sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(sr)
		if flawless:
			# De verborgen "geen Focus verloren"-ster: groter en apart, naast de drie.
			var big = StarsScript.new()
			big.setup(1, 1, 20.0)
			big.position = Vector2(SCREEN_W / 2.0 + sr.size.x / 2.0 + 18.0, 68.0)
			big.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(big)

func _lose() -> void:
	game_over = true
	Engine.time_scale = 0.0
	_show_overlay("BURN-OUT\nOut of Focus  -  wave %d/%d  -  score %d" % [
		wave_index, total_waves, run_score], Color(0.75, 0.25, 0.3), false)

func _show_overlay(text: String, tint: Color, _won: bool, detail: String = "") -> void:
	# Ronde voorbij: de types die langskwamen zijn nu bekend, dus geen NEW-badge meer.
	if not _new_types_this_run.is_empty():
		for id in _new_types_this_run.keys():
			GameState.seen_enemies[id] = true
		GameState.save_game()
	overlay.visible = true
	overlay_label.text = text
	(overlay.get_node("BG") as ColorRect).color = Color(tint.r, tint.g, tint.b, 0.4)
	overlay_stats.text = _run_summary() + ("\n" + detail if detail != "" else "")
	for c in overlay_buttons.get_children():
		c.queue_free()
	# Na een gewonnen ronde wil je meestal dóór of het nog eens beter doen; alleen "Level
	# Select" aanbieden kostte twee extra klikken (tester-feedback v0.71).
	overlay_buttons.add_child(_button("Retry", func(): retry.emit(level_id), 110, 36))
	if _won and not special_mode and level_id < GameState.LEVEL_COUNT \
			and GameState.is_unlocked(level_id + 1):
		var nxt: int = level_id + 1
		overlay_buttons.add_child(_button("Next Level", func(): retry.emit(nxt), 120, 36))
	overlay_buttons.add_child(_button("Level Select", func(): finished.emit(), 130, 36))
	# Knoppen onder de tekst schuiven: het "wat deed je pijn"-overzicht is langer dan de oude
	# vaste plek toeliet, en dan stonden Retry/Level Select dwars over de adviezen heen.
	var lines_n: int = overlay_stats.text.count("\n") + 1
	overlay_buttons.position.y = 118.0 + float(lines_n) * 20.0 + 16.0
	if Playtest.ENABLED:
		_build_feedback(_won)

func _run_summary() -> String:
	# Wat deed welke toren? Zonder dit leer je niets van een verloren ronde.
	var lines: Array = []
	var tdefs: Dictionary = TowerScript.defs()
	for id in _buildable():
		var sid: String = String(id)
		var n: int = int(_stats["built"].get(sid, 0))
		if n <= 0:
			continue
		var up: int = int(_stats["upgraded"].get(sid, 0))
		var dmg: float = float(_stats["damage"].get(sid, 0.0))
		var made: float = float(_stats["made"].get(sid, 0.0))
		var what: String = ""
		if made > 0.0:
			what = "%d Coffee made" % int(made)
		elif dmg > 0.0:
			what = "%d damage" % int(dmg)
		elif String(tdefs[sid]["role"]) == "stun":
			what = "crowd control"
		elif String(tdefs[sid]["role"]) == "support":
			what = "buffed your towers"
		else:
			what = "no damage dealt"
		# Middenstip in plaats van spatie-padding: het font is proportioneel, dus
		# uitlijnen met spaties levert een scheve kolom op.
		lines.append("%s x%d%s  -  %s" % [String(tdefs[sid]["name"]), n,
			(" (+%d upgraded)" % up) if up > 0 else "", what])
	if lines.is_empty():
		lines.append("No towers built.")
	# Wat heeft je pijn gedaan, en wat doe je daaraan? Op FOCUS-schade sorteren en niet op
	# aantal: drie Old Guards kosten je meer dan twintig Notifications, en juist die volgorde
	# vertelt je waar je verdediging het echt liet afweten.
	var leaks: Array = []
	var edefs: Dictionary = EnemyScript.defs()
	for k in _stats["leaks"].keys():
		var id: String = String(k)
		var n: int = int(_stats["leaks"][k])
		if n <= 0 or not edefs.has(id):
			continue
		var per: int = int(edefs[id].get("damage", 1))
		leaks.append([n * per, n, String(edefs[id]["name"]), String(edefs[id].get("counter", ""))])
	leaks.sort_custom(func(a, b): return a[0] > b[0])
	if not leaks.is_empty():
		lines.append("")
		lines.append("WHAT HURT YOU  (Focus lost, worst first)")
		for i in mini(3, leaks.size()):
			var l: Array = leaks[i]
			lines.append("  -%d Focus   %dx %s" % [int(l[0]), int(l[1]), String(l[2])])
			if String(l[3]) != "":
				lines.append("      Fix: %s" % String(l[3]))
	return "\n".join(lines)

# ---------- Playtest-feedback ----------

func _build_feedback(won: bool) -> void:
	# Verschijnt na elke ronde in playtest-builds. Overslaan mag: liever een ronde
	# zonder oordeel dan een tester die afhaakt op een verplicht formulier.
	var box := VBoxContainer.new()
	# Onder de knoppen beginnen, niet op een vaste hoogte: bij een lang "wat deed je pijn"-
	# overzicht schuiven die knoppen naar beneden en stond het formulier er anders dwars doorheen.
	box.position = Vector2(SCREEN_W / 2.0 - 210,
		maxf(SCREEN_H / 2.0 + 84, overlay_buttons.position.y + 46.0))
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 4)
	overlay.add_child(box)

	var q := Label.new()
	q.text = "How much FUN was this level?   0 = no fun, barely playable   -   10 = loved it"
	q.add_theme_font_size_override("font_size", 12)
	q.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(q)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	var chosen := {"v": -1}
	var buttons := []
	for i in range(11):
		var n: int = i
		var b := Button.new()
		b.text = str(n)
		b.custom_minimum_size = Vector2(34, 30)
		b.add_theme_font_size_override("font_size", 12)
		row.add_child(b)
		buttons.append(b)
		b.pressed.connect(func():
			chosen["v"] = n
			for other in buttons:
				(other as Button).modulate = Color(1, 1, 1)
			b.modulate = Color(1.0, 0.85, 0.35))

	var note := LineEdit.new()
	note.placeholder_text = "Anything you want to add? (optional)"
	note.custom_minimum_size = Vector2(420, 28)
	note.add_theme_font_size_override("font_size", 12)
	box.add_child(note)

	var status := Label.new()
	status.add_theme_font_size_override("font_size", 11)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
	box.add_child(status)

	var send := _button("Save feedback", func():
		if chosen["v"] < 0:
			status.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
			status.text = "Pick a number from 0 to 10 first."
			return
		_save_run(won, int(chosen["v"]), note.text)
		status.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6))
		status.text = "Saved. Thanks! (%d runs logged)" % Playtest.run_count()
		note.editable = false
		for b2 in buttons:
			(b2 as Button).disabled = true
		, 160, 30)
	var send_row := HBoxContainer.new()
	send_row.alignment = BoxContainer.ALIGNMENT_CENTER
	send_row.add_child(send)
	box.add_child(send_row)

func _save_run(won: bool, fun: int, comment: String) -> void:
	var dur: float = float(Time.get_ticks_msec() - int(_stats["t0"])) / 1000.0
	Playtest.record({
		"run_id": "%d" % Time.get_unix_time_from_system(),
		"player_id": Playtest.player_id(),
		"timestamp": Time.get_datetime_string_from_system(),
		"version": Playtest.version(),
		"level_id": level_id,
		"level_name": level_name,
		"outcome": "win" if won else "loss",
		"stars": _stars() if won else 0,
		"fun_0_10": fun,
		"comment": comment,
		"focus_start": start_focus,
		"focus_left": focus,
		"score": run_score,
		"wave_reached": wave_index,
		"wave_total": total_waves,
		"duration_sec": int(dur),
		"max_speed": _stats["max_speed"],
		"early_calls": _stats["early_calls"],
		"coffee_earned": int(float(_stats["coffee_earned"])),
		"coffee_spent": _stats["coffee_spent"],
		"towers_sold": _stats["sold"],
		"recognition_gained": _last_recognition,
		"kills": _stats["kills"],
		"leaks": _stats["leaks"],
		"built": _stats["built"],
		"upgraded": _stats["upgraded"],
	})

# ---------- Audio ----------

func _build_audio() -> void:
	# Elk geluid krijgt een eigen speler: één gedeelde speler kapt zichzelf af zodra er
	# twee dingen tegelijk gebeuren, en dat gebeurt hier constant.
	_sounds = {
		"auto": Sfx.noise(0.09, 0.30, 0.30, 2.5),          # papieren vliegtuigje suist
		"ceo": Sfx.thump(190.0, 0.26, 0.50),               # zware klap van de sniper
		"phones": Sfx.sweep(900.0, 300.0, 0.18, 0.22),     # gedempt wegzakkend geluid
		"kill": Sfx.noise(0.13, 0.26, 0.5, 2.0),           # poef
		"buy": Sfx.sweep(420.0, 720.0, 0.12, 0.35),        # omhoog = gelukt
		"upgrade": Sfx.sweep(520.0, 1040.0, 0.22, 0.35),
		"sell": Sfx.chime(880.0, 0.34, 0.32),              # je krijgt iets terug
		"leak": Sfx.tone(150.0, 0.30, 0.45, 1.4),          # je verliest Focus
		"alarm": Sfx.siren(2.6, 0.30),
		"lunch": Sfx.alarm_clock(0.28),                    # bureauwekker: lunchtijd
		"crowd": Sfx.crowd(2.2, 0.22),                     # iedereen staat tegelijk op
		"coffee": Sfx.bubble(0.5, 0.30),                   # de machine levert wat op
	}
	# Aparte bussen per categorie, zodat elke los te regelen is in Settings. Koffie heeft een
	# eigen bus: handig om te horen wanneer de economie oplevert, ook als je de rest zacht zet.
	var event_keys := ["leak", "alarm", "lunch", "crowd"]
	for key in _sounds.keys():
		var p := AudioStreamPlayer.new()
		p.stream = _sounds[key]
		if key in ["buy", "upgrade", "sell"]:
			p.bus = "BuySFX"
		elif key == "coffee":
			p.bus = "CoffeeSFX"
		elif key in event_keys:
			p.bus = "EventSFX"
		else:
			p.bus = "ShootSFX"
		add_child(p)
		_players[key] = p
	# Kantoor-ambient op de muziekbus: die stond er wel, maar er speelde nooit iets op.
	music_player = AudioStreamPlayer.new()
	var amb: AudioStreamWAV = Sfx.typing(12.0, 0.30)
	amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
	amb.loop_end = amb.data.size() / 2
	music_player.stream = amb
	music_player.bus = "Music"
	add_child(music_player)
	music_player.play()

func _play(key: String) -> void:
	var p: AudioStreamPlayer = _players.get(key)
	if p != null:
		p.play()

func _play_shot(id: String) -> void:
	# Bij 3x snelheid en een volle wave vallen er tientallen schoten per seconde; zonder
	# deze rem wordt dat een aanhoudende ruis.
	var now: int = Time.get_ticks_msec()
	if now - _last_shot_ms < 55:
		return
	_last_shot_ms = now
	_play(id if _players.has(id) else "auto")

func _play_buy() -> void:
	_play("buy")

func _draw_tutorial_hint() -> void:
	# Een pulserende pijl die aanwijst waar je moet klikken. Zonder dit moest een tester
	# zelf raden welk deel van het scherm bij de lestekst hoorde (feedback v0.72).
	if _lesson_hint == "" or game_over:
		return
	var target := Vector2.ZERO
	var from_left := true          # pijl komt van links en wijst naar rechts
	match _lesson_hint:
		"shop":
			target = Vector2(SCREEN_W - SHOP_W - 6.0, TOP_H + 70.0)
		"start":
			target = Vector2(SCREEN_W - SHOP_W - 6.0, SCREEN_H - CTRL_H + 28.0)
		"speed":
			target = Vector2(SCREEN_W - SHOP_W - 6.0, SCREEN_H - 30.0)
		"path":
			# Wijs naar een plek NAAST het pad, halverwege: daar hoort de toren te komen.
			if not path.is_empty():
				var mid: Vector2 = path[path.size() / 2]
				target = mid + Vector2(0, -58.0)
				from_left = false
		"tower":
			if towers.is_empty():
				target = Vector2(SCREEN_W - SHOP_W - 6.0, TOP_H + 70.0)
			else:
				target = towers[0].position + Vector2(0, -44.0)
				from_left = false
		_:
			return
	if target == Vector2.ZERO:
		return
	# Pulseren op de wandklok: in de plan-fase staat time_scale op 0, dus delta is daar 0.
	var t: float = float(Time.get_ticks_msec()) * 0.004
	var puls: float = 8.0 + sin(t) * 5.0
	var col := Color(1.0, 0.85, 0.35)
	if from_left:
		var tip := target - Vector2(puls, 0)
		draw_colored_polygon(PackedVector2Array([tip, tip - Vector2(18, -9), tip - Vector2(18, 9)]), col)
		draw_line(tip - Vector2(18, 0), tip - Vector2(46, 0), col, 4.0)
	else:
		var tip2 := target - Vector2(0, -puls)
		draw_colored_polygon(PackedVector2Array([tip2, tip2 - Vector2(-9, 18), tip2 - Vector2(9, 18)]), col)
		draw_line(tip2 - Vector2(0, 18), tip2 - Vector2(0, 46), col, 4.0)

func _draw_path_arrows() -> void:
	# Zachte, vooruit stromende groene chevrons langs elke ingang → tonen welke kant de
	# vijanden op lopen. Puur cosmetisch. Wandkloktijd, want time_scale is 0 in de plan-fase.
	var spacing: float = 46.0
	var speed: float = 34.0           # px/s waarmee de pijltjes stromen
	var t: float = Time.get_ticks_msec() / 1000.0
	var green := Color(0.34, 0.86, 0.45)
	for pp in paths_all:
		if pp.size() < 2:
			continue
		var total: float = 0.0
		for i in range(pp.size() - 1):
			total += pp[i].distance_to(pp[i + 1])
		var d: float = fmod(t * speed, spacing)
		while d < total:
			var hit: Array = _sample_path(pp, d)
			var pos: Vector2 = hit[0]
			var dir: Vector2 = hit[1]
			var a: float = 0.55
			if d < 60.0:
				a *= d / 60.0                          # infaden vanaf de deur
			if d > total - 40.0:
				a *= maxf(0.0, (total - d) / 40.0)     # uitfaden bij het bureau
			if a > 0.02:
				var perp := Vector2(-dir.y, dir.x)
				var s: float = 8.0
				var tip: Vector2 = pos + dir * s
				var l: Vector2 = pos - dir * s + perp * s
				var r: Vector2 = pos - dir * s - perp * s
				draw_polyline(PackedVector2Array([l, tip, r]), Color(green.r, green.g, green.b, a), 3.0)
			d += spacing

func _sample_path(pp: PackedVector2Array, dist: float) -> Array:
	# Punt + genormaliseerde richting op afstand 'dist' langs de polyline.
	var acc: float = 0.0
	for i in range(pp.size() - 1):
		var seg: Vector2 = pp[i + 1] - pp[i]
		var seglen: float = seg.length()
		if seglen <= 0.001:
			continue
		if acc + seglen >= dist:
			return [pp[i].lerp(pp[i + 1], (dist - acc) / seglen), seg / seglen]
		acc += seglen
	return [pp[pp.size() - 1], (pp[pp.size() - 1] - pp[pp.size() - 2]).normalized()]

# ---------- Tekenen ----------

func _draw() -> void:
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color(0.12, 0.13, 0.16))
	# Corridor-bouwen: de smalle bouwbare strook rond elk actief pad oplichten (rest is geen-bouw).
	if corridor_build:
		for pp in paths_all:
			if pp.size() >= 2:
				draw_polyline(pp, Color(0.24, 0.46, 0.30, 0.20), CORRIDOR_BUILD_DIST * 2.0)
	# Alle ingangen tekenen (bij één pad is dit gewoon dat ene pad).
	for pp in paths_all:
		if pp.size() >= 2:
			draw_polyline(pp, Color(0.28, 0.30, 0.36), PATH_WIDTH)
	# Obstakels (vergadertafel, serverracks): massief blok, niet bouwbaar, pad loopt eromheen.
	for r in obstacles:
		var rr: Rect2 = r
		draw_rect(rr, Color(0.17, 0.18, 0.22))
		draw_rect(rr, Color(0.33, 0.36, 0.43), false, 2.0)
	# Zicht-muren (schotten): blokkeren het schootzicht. Eigen kleur zodat de speler ze herkent.
	for w in walls:
		var wr: Rect2 = w
		draw_rect(wr, Color(0.34, 0.30, 0.46))
		draw_rect(wr, Color(0.62, 0.55, 0.82), false, 2.0)
	# Betaal-om-te-bouwen-zones: nog vergrendeld = amber vlak met de koffieprijs erin.
	for pz in pay_zones:
		if pz["unlocked"]:
			continue
		var pr: Rect2 = pz["rect"]
		draw_rect(pr, Color(0.50, 0.38, 0.14, 0.30))
		draw_rect(pr, Color(0.85, 0.66, 0.28), false, 2.0)
		draw_string(ThemeDB.fallback_font, pr.position + Vector2(0, pr.size.y * 0.5 + 7),
			"%dC" % int(pz["cost"]), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 18, Color(0.95, 0.78, 0.35))
	# Geen-bouw-zones + nog-verborgen verrassingszone: roodachtig "niet bouwen"-vlak. Bewust
	# dezelfde stijl, zodat de speler niet ziet dat er bij de verrassingszone straks een pad komt.
	for r in nobuild:
		var nr: Rect2 = r
		draw_rect(nr, Color(0.52, 0.24, 0.22, 0.26))
		draw_rect(nr, Color(0.78, 0.40, 0.34), false, 2.0)
	var desk: Vector2 = path[path.size() - 1]
	draw_rect(Rect2(desk - Vector2(14, 24), Vector2(28, 48)), Color(0.7, 0.35, 0.35))
	if (phase == "plan" or selected_def_id != "") and not game_over and not paused:
		_draw_path_arrows()
	if tutorial:
		_draw_tutorial_hint()
	if selected_def_id != "" and not game_over and not paused:
		var top: float = 40.0
		var bot: float = SCREEN_H
		var gcol := Color(1, 1, 1, 0.08)
		var gx: float = 0.0
		while gx <= SCREEN_W - SHOP_W:
			draw_line(Vector2(gx, top), Vector2(gx, bot), gcol, 1.0)
			gx += GRID
		var gy: float = top
		while gy <= bot:
			draw_line(Vector2(0, gy), Vector2(SCREEN_W - SHOP_W, gy), gcol, 1.0)
			gy += GRID
	for sm in towers:
		if sm.role != "support":
			continue
		if sm == scrum_selecting:
			draw_arc(sm.position, sm.range_radius, 0.0, TAU, 48, Color(0.8, 0.6, 1.0, 0.6), 2.0)
			for other in towers:
				if other == sm or other.role == "support":
					continue
				if sm.position.distance_to(other.position) <= sm.range_radius:
					var chosen: bool = sm.buff_targets.has(other)
					draw_arc(other.position, 21.0, 0.0, TAU, 20,
						Color(0.85, 0.65, 1.0, 0.95) if chosen else Color(0.85, 0.65, 1.0, 0.4),
						3.0 if chosen else 2.0)
		for target in sm.buff_targets:
			if is_instance_valid(target):
				draw_line(sm.position, target.position, Color(0.75, 0.6, 0.95, 0.6), 2.0)
	# Trap-towers: teken de losse punaises op de baan; bij lvl 3 de gekozen doeltegel.
	for tr in towers:
		if tr.role != "trap":
			continue
		if tr == trap_selecting or (tr.pick_spot and tr == selected_tower):
			draw_arc(tr.position, tr.range_radius, 0.0, TAU, 48, Color(0.9, 0.8, 0.4, 0.6), 2.0)
			# markeer de gekozen doeltegel
			var c := Rect2(tr.trap_pos - Vector2(GRID, GRID) * 0.5, Vector2(GRID, GRID))
			draw_rect(c, Color(0.9, 0.8, 0.4, 0.5), false, 2.0)
		for tk in tr._tacks_list:
			var age: float = float(tk["age"])
			# vervaagt naarmate hij ouder wordt (roest weg)
			var fade: float = clampf(1.0 - age / maxf(tr.tack_lifetime, 0.01), 0.15, 1.0)
			var tp: Vector2 = tk["pos"]
			# een paar puntjes per punaise-plek zodat het als een groepje leest
			for j in 3:
				var a: float = float(int(tp.x) * 7 + int(tp.y) * 13 + j * 121 % 360) * 0.0174533
				var pt: Vector2 = tp + Vector2(cos(a), sin(a) * 0.6) * 6.0
				draw_circle(pt, 2.2, Color(0.85, 0.75, 0.35, fade))
	# Keyboard Smash: klap-straal + de slagboom als hij ligt.
	for ks in towers:
		if ks.role != "smash":
			continue
		if ks.barrier_active:
			# volle "muur" op het pad
			draw_circle(ks.position, ks.range_radius, Color(0.55, 0.58, 0.68, 0.22))
			draw_arc(ks.position, ks.range_radius, 0.0, TAU, 40, Color(0.7, 0.72, 0.85, 0.9), 3.0)
			var kb := Rect2(ks.position - Vector2(20, 8), Vector2(40, 16))
			draw_rect(kb, Color(0.3, 0.32, 0.4))
			draw_rect(kb, Color(0.75, 0.77, 0.85), false, 2.0)
		else:
			draw_arc(ks.position, ks.range_radius, 0.0, TAU, 40, Color(0.6, 0.62, 0.72, 0.3), 1.5)
	# Bereik-preview bij zweven over een shopknop: op de laatste muispositie in het veld,
	# of midden op het speelveld als de muis er nog niet geweest is.
	if hover_shop_id != "" and selected_def_id == "" and not game_over:
		var d: Dictionary = TowerScript.defs()[hover_shop_id]
		var rng: float = float(d["levels"][0].get("range", 0.0))
		if rng > 0.0:
			var at: Vector2 = hover_pos if hover_pos.x > -900 else Vector2(
				(SCREEN_W - SHOP_W) * 0.5, SCREEN_H * 0.5)
			var col: Color = d["color"]
			draw_circle(at, rng, Color(col.r, col.g, col.b, 0.10))
			draw_arc(at, rng, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.65), 2.0)
	# Bij het zweven over een geplaatste toren meteen tonen wat 'ie oplevert bij verkoop,
	# zodat je je opstelling kunt scannen zonder overal op te klikken.
	if selected_def_id == "" and not game_over and hover_pos.x > -900:
		var mouse: Vector2 = get_global_mouse_position()
		for t in towers:
			if mouse.distance_to(t.position) <= 22.0:
				var tip: String = "Lv %d  -  sell +%d C" % [t.level, int(t.invested * 0.6)]
				draw_string(ThemeDB.fallback_font, t.position + Vector2(-30, -26), tip,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.9, 0.65))
				break
	if selected_def_id != "" and not game_over and not paused and hover_pos.x > -900:
		var valid: bool = _can_place_at(hover_pos)
		var col: Color = Color(0.35, 0.95, 0.5) if valid else Color(1.0, 0.35, 0.35)
		var rng: float = _selected_range()
		if rng > 0.0:
			draw_circle(hover_pos, rng, Color(col.r, col.g, col.b, 0.07))
			draw_arc(hover_pos, rng, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.7), 2.0)
		var cell := Rect2(hover_pos - Vector2(GRID, GRID) * 0.5, Vector2(GRID, GRID))
		draw_rect(cell, Color(col.r, col.g, col.b, 0.18), true)
		draw_rect(cell, Color(col.r, col.g, col.b, 0.75), false, 2.0)
		var tex := _tower_texture(selected_def_id)
		if tex != null:
			var s := 38.0
			var r := Rect2(hover_pos - Vector2(s, s) * 0.5, Vector2(s, s))
			draw_texture_rect(tex, r, false, Color(1, 1, 1, 0.85) if valid else Color(1, 0.45, 0.45, 0.9))
		else:
			draw_circle(hover_pos, 15.0, Color(col.r, col.g, col.b, 0.35))

# ---------- HUD ----------

func _label(text: String, pos: Vector2, size: int, parent: Node) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l

func _button(text: String, cb: Callable, w: float = 110.0, h: float = 30.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.pressed.connect(cb)
	return b

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# --- info-strip boven ---
	var top_bg := ColorRect.new()
	top_bg.color = Color(0.08, 0.09, 0.12, 0.92)
	top_bg.size = Vector2(SCREEN_W, TOP_H)
	canvas.add_child(top_bg)
	# Focus als balk: een getal lees je te traag op het moment dat het spannend wordt.
	var fb_bg := ColorRect.new()
	fb_bg.position = Vector2(24, 10)
	fb_bg.size = Vector2(64, 15)
	fb_bg.color = Color(0, 0, 0, 0.45)
	canvas.add_child(fb_bg)
	focus_bar = ColorRect.new()
	focus_bar.position = Vector2(25, 11)
	focus_bar.size = Vector2(62, 13)
	focus_bar.color = Color(0.35, 0.85, 0.45)
	canvas.add_child(focus_bar)
	# getal náást de balk, niet erin: anders botst het met het uiteinde als de balk krimpt
	focus_label = _label("100", Vector2(92, 7), 14, canvas)
	focus_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	# Bliksem bij Focus, kopje bij Coffee: in één oogopslag te herkennen zonder te lezen.
	focus_icon = HudIconScript.new()
	focus_icon.setup("bolt", Color(0.35, 0.85, 0.45), Vector2(11, 15))
	focus_icon.position = Vector2(9, 10)   # vóór de balk, anders lijkt hij bij Coffee te horen
	canvas.add_child(focus_icon)
	var cup := HudIconScript.new()
	cup.setup("cup", Color(0.85, 0.7, 0.45), Vector2(15, 15))
	cup.position = Vector2(126, 10)
	canvas.add_child(cup)
	coffee_label = _label("30", Vector2(145, 7), 16, canvas)
	coffee_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.45))
	score_label = _label("Score 0", Vector2(225, 7), 16, canvas)
	wave_label = _label("Plan Phase", Vector2(330, 8), 15, canvas)
	wave_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_label(level_name, Vector2(560, 9), 14, canvas).add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	# Aftelling naar de volgende hazard: bij de lunchpauze is timing van je opstelling
	# alles (GDD §4), dus die moet je kunnen zien aankomen.
	hazard_label = _label("", Vector2(700, 9), 13, canvas)
	hazard_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.4))
	var menu_btn := _button("Menu", _request_menu, 62, 24)
	menu_btn.position = Vector2(SCREEN_W - 70, 5)
	canvas.add_child(menu_btn)
	msg_label = _label("", Vector2(10, TOP_H + 4), 13, canvas)
	msg_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))

	# Schermflits ligt onder de tekst maar boven het speelveld
	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(SCREEN_W, SCREEN_H)
	flash_rect.color = Color(1, 0, 0, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(flash_rect)

	big_label = Label.new()
	big_label.position = Vector2(0, 150)
	big_label.size = Vector2(SCREEN_W - SHOP_W, 60)
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.add_theme_font_size_override("font_size", 30)
	big_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_label.modulate = Color(1, 1, 1, 0)
	canvas.add_child(big_label)

	_build_boss_bar(canvas)

func _build_boss_bar(canvas: CanvasLayer) -> void:
	boss_box = Control.new()
	# Onder de meldingsregel (die staat op TOP_H + 4), anders overlapt de bossnaam ermee.
	boss_box.position = Vector2(0, TOP_H + 30)
	boss_box.visible = false
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(boss_box)
	var w: float = SCREEN_W - SHOP_W - 60.0
	var bg := ColorRect.new()
	bg.position = Vector2(30, 16)
	bg.size = Vector2(w, 14)
	bg.color = Color(0, 0, 0, 0.6)
	boss_box.add_child(bg)
	boss_bar = ColorRect.new()
	boss_bar.position = Vector2(31, 17)
	boss_bar.size = Vector2(w - 2, 12)
	boss_bar.color = Color(0.85, 0.25, 0.3)
	boss_box.add_child(boss_bar)
	# schild als aparte dunne balk erboven, want die telt niet mee voor doorbraakschade
	boss_shield_bar = ColorRect.new()
	boss_shield_bar.position = Vector2(31, 11)
	boss_shield_bar.size = Vector2(w - 2, 5)
	boss_shield_bar.color = Color(0.45, 0.7, 1.0)
	boss_box.add_child(boss_shield_bar)
	boss_label = Label.new()
	boss_label.position = Vector2(30, -4)
	boss_label.add_theme_font_size_override("font_size", 12)
	boss_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8))
	boss_box.add_child(boss_label)

	_build_shop(canvas)
	_build_controls(canvas)
	_build_left_panel(canvas)
	_build_upgrade_panel(canvas)
	_build_overlay(canvas)
	_build_confirm(canvas)
	_build_pause_menu(canvas)
	_build_qte(canvas)
	_update_speed_buttons()

func _build_shop(canvas: CanvasLayer) -> void:
	shop_panel = Control.new()
	shop_panel.position = Vector2(SCREEN_W - SHOP_W, TOP_H)
	canvas.add_child(shop_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.95)
	bg.size = Vector2(SHOP_W, SCREEN_H - TOP_H - CTRL_H)
	shop_panel.add_child(bg)
	_label("TOWERS", Vector2(8, 4), 13, shop_panel).add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	# 2-koloms grid (Bloons-achtig): core-towers boven, een SPECIALS-sectie eronder. Met
	# icoontjes past een enkele kolom niet voor 8+ towers, en twee kolommen leest compacter.
	var vb := VBoxContainer.new()
	vb.position = Vector2(4, 20)
	vb.add_theme_constant_override("separation", 2)
	shop_panel.add_child(vb)
	var order: Array = _buildable()
	var core_grid := GridContainer.new()
	core_grid.columns = 2
	core_grid.add_theme_constant_override("h_separation", 3)
	core_grid.add_theme_constant_override("v_separation", 1)
	vb.add_child(core_grid)
	for id in _core_order():
		core_grid.add_child(_shop_cell(String(id), order))
	var sep := Label.new()
	sep.text = "SPECIALS"
	sep.add_theme_font_size_override("font_size", 10)
	sep.add_theme_color_override("font_color", Color(0.55, 0.6, 0.72))
	vb.add_child(sep)
	var spec_grid := GridContainer.new()
	spec_grid.columns = 2
	spec_grid.add_theme_constant_override("h_separation", 3)
	spec_grid.add_theme_constant_override("v_separation", 1)
	vb.add_child(spec_grid)
	for id in _special_order():
		spec_grid.add_child(_shop_cell(String(id), order))

	shop_toggle = _button(">", _toggle_shop, 18, 44)
	shop_toggle.position = Vector2(SCREEN_W - SHOP_W - 18, TOP_H + 6)
	canvas.add_child(shop_toggle)

func _shop_cell(sid: String, order: Array) -> Control:
	# Eén tegel = knop met het icoon + de naam eronder. De naam stond eerst alleen in de
	# tooltip, maar dan moet je elke toren aanwijzen om te weten wat het is.
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 0)
	var b := _shop_button(sid, order)
	cell.add_child(b)
	var nm := Label.new()
	nm.text = String(TowerScript.defs()[sid]["name"])
	nm.add_theme_font_size_override("font_size", 8)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2((SHOP_W - 11) / 2.0, 15)
	nm.add_theme_color_override("font_color",
		Color(0.78, 0.82, 0.9) if available_towers.has(sid) else Color(0.45, 0.48, 0.56))
	cell.add_child(nm)
	return cell

func _shop_button(sid: String, order: Array) -> Button:
	# Compacte grid-knop: icoon boven, daaronder de sneltoets + prijs. Naam/rol/uitleg in de
	# tooltip, want in een halve kolom past geen volledige naam.
	var unlock: int = _tower_unlock_level(sid)
	var available: bool = available_towers.has(sid)
	var d: Dictionary = TowerScript.defs()[sid]
	var b := Button.new()
	# Compacter (40 i.p.v. 50) + expand_icon: met 10 core-torens + specials moet alles binnen
	# het paneel passen. expand_icon schaalt het icoon mee zodat de knop niet uitdijt.
	b.custom_minimum_size = Vector2((SHOP_W - 11) / 2.0, 22)
	# Zonder deze cap rekt het 48px-icoon de knop op tot ~60px per rij, en dan valt de
	# SPECIALS-sectie onder de onderrand van het paneel.
	b.add_theme_constant_override("icon_max_width", 15)
	b.expand_icon = true
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_font_size_override("font_size", 10)
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var icon := _tower_texture(sid)
	if icon != null:
		b.icon = icon
	var nm: String = String(d["levels"][0].get("name", d["name"]))
	if available:
		b.text = "%d - %dC" % [order.find(sid) + 1, _tower_cost(sid, 1)]
		b.tooltip_text = "%d  %s  [%s]\n%s%s" % [order.find(sid) + 1, nm,
			_role_tag(String(d["role"])), String(d.get("desc", "")), _tower_summary(sid, 1)]
		b.pressed.connect(func(): _select_def(sid))
		b.mouse_entered.connect(func(): hover_shop_id = sid; queue_redraw())
		b.mouse_exited.connect(func(): hover_shop_id = ""; queue_redraw())
		bar_buttons[sid] = b
	elif banned_towers.has(sid):
		b.text = "X"
		b.tooltip_text = "%s\n\nNot allowed on this level." % nm
		b.disabled = true
	else:
		b.text = "Lv %d" % unlock
		b.tooltip_text = "%s\n%s\n\nUnlocks in level %d." % [nm, String(d.get("desc", "")), unlock]
		b.disabled = true
	return b

func _toggle_shop() -> void:
	shop_open = not shop_open
	shop_panel.visible = shop_open
	shop_toggle.text = ">" if shop_open else "<"
	shop_toggle.position.x = (SCREEN_W - SHOP_W - 18) if shop_open else (SCREEN_W - 18)

func _build_controls(canvas: CanvasLayer) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10, 0.95)
	bg.position = Vector2(SCREEN_W - SHOP_W, SCREEN_H - CTRL_H)
	bg.size = Vector2(SHOP_W, CTRL_H)
	canvas.add_child(bg)

	action_button = _button(">  START", _on_action, SHOP_W - 12, 44)
	action_button.position = Vector2(SCREEN_W - SHOP_W + 6, SCREEN_H - CTRL_H + 6)
	action_button.add_theme_font_size_override("font_size", 13)
	canvas.add_child(action_button)

	var hb := HBoxContainer.new()
	hb.position = Vector2(SCREEN_W - SHOP_W + 6, SCREEN_H - 42)
	hb.add_theme_constant_override("separation", 2)
	canvas.add_child(hb)
	pause_button = _button("||", _toggle_pause, 28, 26)
	hb.add_child(pause_button)
	for spd in SPEEDS:
		var sp: float = spd
		var b := _button("%dx" % int(spd), func(): _set_speed(sp), 25, 26)
		hb.add_child(b)
		speed_buttons[spd] = b

	if int(GameState.consumables.get("smoke_break", 0)) > 0:
		smoke_button = _button("Smoke (%d)" % int(GameState.consumables["smoke_break"]), _use_smoke_break, SHOP_W - 12, 22)
		smoke_button.add_theme_font_size_override("font_size", 11)
		smoke_button.position = Vector2(SCREEN_W - SHOP_W + 6, SCREEN_H - 14)
		canvas.add_child(smoke_button)

func _build_left_panel(canvas: CanvasLayer) -> void:
	left_open = GameState.enemy_panel_open   # respecteer wat de speler laatst koos
	left_panel = Control.new()
	left_panel.position = Vector2(0, TOP_H)
	left_panel.visible = left_open
	canvas.add_child(left_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.92)
	bg.size = Vector2(LEFT_W, SCREEN_H - TOP_H)
	left_panel.add_child(bg)
	_label("ON THE FLOOR", Vector2(8, 4), 12, left_panel).add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	var vb := VBoxContainer.new()
	vb.position = Vector2(4, 22)
	vb.add_theme_constant_override("separation", 2)
	left_panel.add_child(vb)
	for id in EnemyScript.defs().keys():
		var sid: String = String(id)
		var d: Dictionary = EnemyScript.defs()[sid]
		var tip: String = "%s\nHP %d" % [String(d["name"]), int(d["hp"])]
		if float(d.get("shield", 0.0)) > 0.0:
			tip += "  (+%d shield)" % int(d["shield"])
		tip += "\nSpeed %d" % int(d["speed"])
		tip += "\nFocus damage: %d" % int(d.get("damage", 1))
		tip += "\nCoffee reward: %d" % int(d["reward"])
		tip += "\n%s" % String(d.get("ability", ""))

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(LEFT_W - 8, 24)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.tooltip_text = tip
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = _enemy_texture(sid)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.tooltip_text = tip
		row.add_child(icon)
		var nm := Label.new()
		nm.text = String(d["name"])
		nm.add_theme_font_size_override("font_size", 10)
		nm.custom_minimum_size = Vector2(92, 0)
		nm.mouse_filter = Control.MOUSE_FILTER_STOP
		nm.tooltip_text = tip
		row.add_child(nm)
		var cnt := Label.new()
		cnt.text = "x0"
		cnt.add_theme_font_size_override("font_size", 10)
		cnt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		cnt.mouse_filter = Control.MOUSE_FILTER_STOP
		cnt.tooltip_text = tip
		row.add_child(cnt)
		var badge := Label.new()
		badge.text = " NEW"
		badge.add_theme_font_size_override("font_size", 9)
		badge.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
		badge.mouse_filter = Control.MOUSE_FILTER_STOP
		badge.tooltip_text = tip
		badge.visible = false
		row.add_child(badge)
		row.visible = false
		vb.add_child(row)
		enemy_rows[sid] = {"root": row, "count": cnt, "new": badge}

	left_toggle = _button("<" if left_open else ">", func(): _toggle_left(true), 18, 44)
	left_toggle.position = Vector2((LEFT_W + 2) if left_open else 2, TOP_H + 6)
	canvas.add_child(left_toggle)

func _toggle_left(by_player: bool = false) -> void:
	left_open = not left_open
	if by_player and not left_open:
		_left_user_closed = true
	elif left_open:
		_left_user_closed = false
	left_panel.visible = left_open
	left_toggle.text = "<" if left_open else ">"
	left_toggle.position.x = (LEFT_W + 2) if left_open else 2
	GameState.enemy_panel_open = left_open   # keuze onthouden voor het volgende level

func _use_smoke_break() -> void:
	if paused or game_over:
		return
	if GameState.use_consumable("smoke_break"):
		focus += 15
		_flash_msg("Smoke break: +15 Focus.")
		var n := int(GameState.consumables.get("smoke_break", 0))
		if n > 0:
			smoke_button.text = "Smoke (%d)" % n
		else:
			smoke_button.visible = false
		_update_labels()

func _build_upgrade_panel(canvas: CanvasLayer) -> void:
	panel = PanelContainer.new()
	panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	upg_name = Label.new()
	upg_name.add_theme_font_size_override("font_size", 14)
	vb.add_child(upg_name)
	upg_stats = Label.new()
	upg_stats.add_theme_font_size_override("font_size", 11)
	vb.add_child(upg_stats)
	upg_target = OptionButton.new()
	upg_target.add_theme_font_size_override("font_size", 11)
	for lbl in TARGET_LABELS:
		upg_target.add_item(lbl)
	upg_target.item_selected.connect(_on_target_selected)
	upg_target.visible = false
	vb.add_child(upg_target)
	# Los van de targeting-stand: alleen zichtbaar bij towers die onzichtbare vijanden
	# überhaupt kunnen zien.
	upg_hidden = CheckBox.new()
	upg_hidden.text = "Hidden enemies first"
	upg_hidden.add_theme_font_size_override("font_size", 11)
	upg_hidden.visible = false
	upg_hidden.toggled.connect(func(on):
		if selected_tower != null:
			selected_tower.prefer_hidden = on)
	vb.add_child(upg_hidden)
	upg_scrum = Label.new()
	upg_scrum.add_theme_font_size_override("font_size", 11)
	upg_scrum.add_theme_color_override("font_color", Color(0.82, 0.72, 0.96))
	upg_scrum.visible = false
	vb.add_child(upg_scrum)
	upg_upgrade = _button("Upgrade", _do_upgrade, 170, 28)
	upg_upgrade.add_theme_font_size_override("font_size", 12)
	vb.add_child(upg_upgrade)
	upg_sell = _button("Sell", _do_sell, 170, 24)
	upg_sell.add_theme_font_size_override("font_size", 12)
	vb.add_child(upg_sell)
	var close_btn := _button("Close", _close_upgrade, 170, 22)
	close_btn.add_theme_font_size_override("font_size", 11)
	vb.add_child(close_btn)
	canvas.add_child(panel)

func _build_overlay(canvas: CanvasLayer) -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	canvas.add_child(overlay)
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.4)
	overlay.add_child(bg)
	# Layout van boven naar beneden: titel, statistieken, knoppen, feedbackformulier.
	overlay_label = Label.new()
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.position = Vector2(SCREEN_W / 2.0 - 250, 26)
	overlay_label.size = Vector2(500, 90)
	overlay_label.add_theme_font_size_override("font_size", 24)
	overlay.add_child(overlay_label)
	overlay_stats = Label.new()
	overlay_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_stats.position = Vector2(SCREEN_W / 2.0 - 250, 118)
	overlay_stats.size = Vector2(500, 120)
	overlay_stats.add_theme_font_size_override("font_size", 12)
	overlay_stats.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
	overlay.add_child(overlay_stats)
	overlay_buttons = HBoxContainer.new()
	overlay_buttons.add_theme_constant_override("separation", 12)
	overlay_buttons.position = Vector2(SCREEN_W / 2.0 - 125, 252)
	overlay.add_child(overlay_buttons)

func _build_confirm(canvas: CanvasLayer) -> void:
	confirm = Control.new()
	confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm.visible = false
	canvas.add_child(confirm)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	confirm.add_child(bg)
	var lbl := Label.new()
	lbl.text = "End this run?\nGive up shows your results; quitting drops them."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(SCREEN_W / 2.0 - 180, SCREEN_H / 2.0 - 60)
	lbl.custom_minimum_size = Vector2(360, 50)
	lbl.add_theme_font_size_override("font_size", 18)
	confirm.add_child(lbl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.position = Vector2(SCREEN_W / 2.0 - 125, SCREEN_H / 2.0 + 10)
	confirm.add_child(hb)
	# "Give up" gaat naar het eindscherm mét cijfers en feedbackformulier. Zonder die route
	# was doodgaan de enige manier om je resultaten te zien, en dus spamden testers waves om
	# een verloren ronde af te raffelen (playtest v0.71: 21 van de 22 waves vroeg opgeroepen,
	# ronde in 61 seconden uit). Dat is geen fout van de speler maar een gat in de uitgangen.
	hb.add_child(_button("Give up", _surrender, 110, 32))
	hb.add_child(_button("Quit run", _leave_to_menu, 110, 32))
	hb.add_child(_button("Keep playing", _cancel_menu, 130, 32))
