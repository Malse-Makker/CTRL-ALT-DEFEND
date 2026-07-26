extends Node
# Autoload singleton: progressie, instellingen, meta-economie, save/load.
# Toegankelijk als "GameState" vanuit elk script.

const SAVE_PATH := "user://save.json"
const LEVEL_COUNT := 15   # blok 1 (junior) + 2 (medior) + 3 (senior)
const BASE_SIZE := Vector2i(960, 540)
const DISPLAY_MODES := ["Windowed", "Borderless windowed", "Fullscreen"]

# Progressie
var highest_unlocked: int = 1
var stars: Dictionary = {}            # str(level_id) -> int
# Per level onthouden of de flawless-bonus al is uitgekeerd; die is eenmalig.
var flawless_levels: Dictionary = {}
var recognition: int = 0

# Meta-aankopen
var upgrades: Dictionary = {}         # id -> bool/level
var consumables: Dictionary = {}      # id -> count
var seen_enemies: Dictionary = {}     # type_id -> true zodra de speler 'm bekeken heeft
var enemy_panel_open: bool = false    # laatste keuze van de speler, onthouden per sessie

# Instellingen
var resolution_index: int = 1   # standaard 1920x1080 (2x)
var display_mode: int = 0        # 0 windowed, 1 borderless, 2 fullscreen
var integer_scale: bool = true   # pixel-perfect schalen (kan randen geven)
# Standaardvolumes bewust laag: testers meldden dat het spel op de oude waarden veel te
# hard startte ("je kan snel doof worden"). Wie meer wil, schuift het in Settings omhoog.
var master_volume: float = 0.55  # regelt de Master-bus; op 0 = alles stil
var music_volume: float = 0.5
var shoot_volume: float = 0.45
var buy_volume: float = 0.6
var coffee_volume: float = 0.6  # eigen bus: horen wanneer de economie oplevert
var event_volume: float = 0.55   # alarm, lunchbel, geroezemoes, focus-verlies

func _ready() -> void:
	load_game()
	_ensure_buses()
	apply_settings()

# ---------- Levels ----------

func get_level(level_id: int) -> Dictionary:
	if level_id >= 100:
		return _special_level(level_id)   # 101 Tutorial · 102 Boss Rush · 103 Endless
	# Basis 960x540. Alle punten op grid-vakmiddens (40k+20) zodat het pad precies 1 vakje
	# breed op het raster ligt. Paden blijven links van de shop-balk (x <= 780).
	# L5/L10/L15 delen dezelfde Boardroom-layout: een lus rond de centrale vergadertafel
	# (obstakel-vlak 360,180..600,340), bureau rechtsboven. Ze lopen op in restricties, niet
	# in vorm. (const met een PackedVector2Array-literal mag niet in GDScript → var.)
	var boardroom := PackedVector2Array([Vector2(-60,100),Vector2(140,100),Vector2(140,420),Vector2(700,420),Vector2(700,100),Vector2(780,100)])
	var paths := {
		# --- Blok 1 (junior): ongewijzigd, al gespeeld/gebalanceerd (behalve L5 = boardroom) ---
		1: PackedVector2Array([Vector2(-60,100),Vector2(300,100),Vector2(300,300),Vector2(580,300),Vector2(580,140),Vector2(780,140)]),
		2: PackedVector2Array([Vector2(-60,260),Vector2(340,260),Vector2(340,100),Vector2(620,100),Vector2(620,420),Vector2(780,420)]),
		3: PackedVector2Array([Vector2(-60,420),Vector2(180,420),Vector2(180,140),Vector2(420,140),Vector2(420,420),Vector2(660,420),Vector2(660,140),Vector2(780,140)]),
		4: PackedVector2Array([Vector2(-60,100),Vector2(700,100),Vector2(700,420),Vector2(180,420),Vector2(180,260),Vector2(780,260)]),
		5: boardroom,
		# --- Blok 2 (medior) --- (6↔7 gewisseld: WFH = zachte LOS-intro vóór de gespreide Parking)
		6: PackedVector2Array([Vector2(-60,260),Vector2(220,260),Vector2(220,140),Vector2(580,140),Vector2(580,420),Vector2(340,420),Vector2(340,260),Vector2(780,260)]),  # Work From Home: compacte spiraal-lus (triple-pocket, gesplitst door zicht-muren)
		7: PackedVector2Array([Vector2(-60,60),Vector2(700,60),Vector2(700,300),Vector2(100,300),Vector2(100,500),Vector2(780,500)]),                                       # The Parking: écht gespreide switchback (banen 240/200 px), buitenste twee zijn rand-banen; bureau rechtsonder
		10: boardroom,
		# --- Blok 3 (senior) --- (12↔13 gewisseld: Merger vóór Server Room)
		11: PackedVector2Array([Vector2(-60,100),Vector2(300,100),Vector2(300,420),Vector2(540,420),Vector2(540,100),Vector2(780,100)]),                                   # HR Room: kam (240 px) — dezelfde vorm als L3, maar de middenmuur pakt je oude pocket af
		12: PackedVector2Array([Vector2(-60,140),Vector2(300,140),Vector2(300,380),Vector2(620,380),Vector2(620,220),Vector2(780,220)]),                                   # The Merger: haak-pad van links, open bouwen; wave ~12 voegt een pad in op de onderrun (invoegend onthul-pad)
		13: PackedVector2Array([Vector2(-60,60),Vector2(700,60),Vector2(700,240),Vector2(220,240),Vector2(220,420),Vector2(780,420)]),                                     # Server Room: gangpaden-slinger tussen rack-rijen; vrije bouw alleen aan de marges
		14: PackedVector2Array([Vector2(-60,60),Vector2(300,60),Vector2(300,180),Vector2(580,180),Vector2(580,60),Vector2(740,60),Vector2(740,260)]),                      # Release Night: corridor-bouwen, zigzag met 4 bochten; bureau (740,260). 2e gescheiden front bij wave 10 (zie reveals)
		15: boardroom,                                                                                                                                                          # senior FINALE = Boardroom III: zelfde arena als L5/L10, maar met corridor-bouwen als grote knijp
	}
	# Multi-ingang / bureau-in-het-midden: level.gd rouleert per wave door een andere ingang;
	# alle ingangen van een level delen hetzelfde eindpunt (= waar het bureau getekend wordt).
	var multi := {
		# L8 The Flexplek: 4 deuren (W/W/N/Z) mergen bij (500,260), staart 280 px naar bureau (780,260).
		# De zuid-deur valt de staart halverwege binnen zodat één AoE-fort niet álles meer dekt.
		8: [
			PackedVector2Array([Vector2(-60,140),Vector2(500,140),Vector2(500,260),Vector2(780,260)]),
			PackedVector2Array([Vector2(-60,380),Vector2(500,380),Vector2(500,260),Vector2(780,260)]),
			PackedVector2Array([Vector2(260,-60),Vector2(260,260),Vector2(500,260),Vector2(780,260)]),
			PackedVector2Array([Vector2(620,600),Vector2(620,260),Vector2(780,260)]),   # zuid-deur: valt de staart halverwege binnen
		],
		# L9 Town Hall: bureau in het MIDDEN (460,260), 3 fronten met ELLEBOGEN (i.p.v. rechte spaken)
		# zodat er mid-field kwaliteits-pockets ontstaan en de rechterhelft meedoet.
		9: [
			PackedVector2Array([Vector2(-60,260),Vector2(460,260)]),                                          # west (hoofdingang, recht)
			PackedVector2Array([Vector2(220,-60),Vector2(220,140),Vector2(460,140),Vector2(460,260)]),        # noord met elleboog
			PackedVector2Array([Vector2(700,600),Vector2(700,380),Vector2(460,380),Vector2(460,260)]),        # zuidoost met elleboog
		],
	}
	# Obstakels: massieve blokken waar het pad omheen loopt en waar je NIET op kunt bouwen.
	# L5/L10/L15 delen de centrale vergadertafel; L13 (Server Room) heeft twee rack-rijen.
	var boardroom_table := Rect2(360, 180, 240, 160)
	var obstacles := {
		5: [boardroom_table],
		10: [boardroom_table],
		13: [Rect2(140, 120, 520, 80), Rect2(300, 280, 480, 80)],   # rack-rij A en B; gangpaden ertussen
		15: [boardroom_table],
	}
	# Zicht-muren: dunne schotten die het SCHOOTZICHT blokkeren (line-of-sight). Een toren kan een
	# vijand niet raken als er een muur tussen zit → torens dekken maar een klein gebied. Je kunt er
	# ook niet op bouwen. Bewust weg van de pad-lijnen geplaatst.
	var walls := {
		6: [Rect2(400, 180, 20, 130), Rect2(180, 330, 130, 20)],                              # WFH meubels (verhuisd van 7)
		10: [Rect2(260, 150, 18, 90), Rect2(650, 300, 18, 90)],                               # Boardroom II pilaren
		11: [Rect2(150, 210, 18, 150), Rect2(420, 170, 18, 170), Rect2(640, 240, 18, 150)],   # HR cubicles (middenmuur in de aangeleerde pocket)
		15: [Rect2(260, 150, 18, 90), Rect2(650, 300, 18, 90)],                               # Boardroom III: zelfde pilaren als L10 (blijven staan in de finale)
	}
	# Betaal-om-te-bouwen-zones: vergrendelde bouwvlakken die je met koffie ontgrendelt voordat je
	# er torens kunt neerzetten. {rect, cost}. In open bouwgebied geplaatst, weg van pad/obstakels.
	# Betaal-om-te-bouwen-zones. L13 Server Room: "root access" — de zones liggen BOVENOP de racks; een
	# toren daar staat op ~80-100 px van twee gangpaden (de enige dubbel-dek-plekken van het level).
	var pay_zones := {
		13: [{"rect": Rect2(300, 120, 160, 80), "cost": 45}, {"rect": Rect2(460, 280, 160, 80), "cost": 45}],
	}
	# Geen-bouw-hatch-zones: gewoon niet bouwbaar. L4 wet-floor (zachte intro, thema The Cleaner);
	# L7 Parking-auto's op de nieuwe tussenbanden; L11 HR-rode-draad.
	var nobuild := {
		4: [Rect2(340, 140, 80, 80), Rect2(500, 140, 80, 80)],       # wet-floor in de dominante binnenband
		7: [Rect2(300, 150, 130, 72), Rect2(300, 360, 130, 72)],     # geparkeerde auto's in de tussenbanden
		11: [Rect2(620, 420, 120, 80)],
	}
	# Onthul-paden: bij elke 'trigger_wave' verschijnt er een extra vijand-pad (moet op hetzelfde
	# bureau eindigen als het basispad!). In corridor-levels wordt de strook rond dat nieuwe pad
	# meteen bouwbaar. De speler ziet vooraf niet dat daar een pad komt. Lijst = meerdere onthullingen.
	var reveals := {
		# L12 The Merger — INVOEGEND (zacht): het overgenomen bedrijf komt van rechtsonder buiten beeld,
		# voegt in op jouw onderrun bij (460,380) en volgt daarna jouw eigen route naar het bureau.
		12: [{"trigger_wave": 12, "path": PackedVector2Array([Vector2(840,460),Vector2(460,460),Vector2(460,380),Vector2(620,380),Vector2(620,220),Vector2(780,220)])}],
		# L14 Release Night — GESCHEIDEN front (hard): een volledig eigen zigzag-route tot vlak vóór het
		# bureau. Deelt alleen de laatste kolom (x=740) met het hoofdpad → tweede volwaardige verdediging.
		14: [{"trigger_wave": 10, "path": PackedVector2Array([Vector2(-60,460),Vector2(220,460),Vector2(220,340),Vector2(500,340),Vector2(500,460),Vector2(740,460),Vector2(740,260)])}],
	}
	# Corridor-bouwen: de hele map is geen-bouw, behalve een smalle strook rond een ACTIEF pad
	# (zie CORRIDOR_BUILD_DIST in level.gd). Levels waarvoor dit aanstaat:
	var corridor := {14: true, 15: true}   # 14 leert corridor-bouwen, 15 (finale) examineert het
	# Volgorde-wissels uit de map-review: 6↔7 (WFH vóór Parking) en 12↔13 (Merger vóór Server Room).
	var names := {1:"Open-Plan Office", 2:"Coffee Corner", 3:"Meeting Room", 4:"Canteen", 5:"Boardroom",
		6:"Work From Home", 7:"The Parking", 8:"The Flexplek", 9:"Town Hall", 10:"Boardroom",
		11:"HR Room", 12:"The Merger", 13:"Server Room", 14:"Release Night", 15:"Boardroom"}
	# Hazard/event per level. Brandalarm verhuisd 2→10 (fire drill mid-review); projector-QTE is nu de
	# eerste hazard (L3) en keert terug op L15 ("your final presentation"). Rook(7)/no_internet(6) en
	# overheat(13) volgen de thema-wissels.
	var hazards := {3: "beamer", 4: "lunch", 6: "no_internet", 7: "smoke", 9: "phone", 10: "fire_alarm", 11: "form", 13: "overheat", 14: "pizza", 15: "beamer"}
	# Modifiers (hele ronde) per level. Modifier-budget: junior 0-1, medior 1, senior 2 (map-review §2.6).
	var modifiers := {
		9: ["half_coffee"],          # Town Hall = 3-deurs center-desk (multi), 50% koffie
		10: ["few_spots"],           # Boardroom II: pilaren + weinig bouwplekken
		11: ["banned"],              # verboden torens (formulier is nu een hazard-event)
		12: ["half_coffee"],         # The Merger: "consultancy fees" — de Consultant kost je halve budget
		14: ["low_focus"],           # start 10 Focus (Eat the Pizza is nu een hazard-event)
	}
	# HR Room verbiedt Auto-Reply + Quick Reply ("informal communication violates our tone-of-voice
	# policy"). NIET Headphones bannen: dat is de enige Chatterbox-counter → softlock (map-review §7).
	var banned := {11: ["auto", "machinegun"]}
	# Laag-Focus-levels (blok 3) zetten start_focus lager; blok 1-2 op 100.
	var start_focus := 10 if level_id == 14 else 100
	var waves := []
	for spec in WAVES.get(level_id, WAVES[1]):
		waves.append(_parse_wave(String(spec)))
	var mods_out: Array = modifiers.get(level_id, [])
	# Multi-ingang/center-desk-levels halen hun paden uit 'multi'; de rest heeft één pad.
	var level_paths: Array = multi[level_id] if multi.has(level_id) else [paths.get(level_id, paths[1])]
	return {
		"id": level_id,
		"name": names.get(level_id, "Level %d" % level_id),
		"path": level_paths[0],
		"paths": level_paths,
		"start_focus": start_focus,
		"start_coffee": 30,
		"waves": waves,
		"towers": TOWERS_PER_LEVEL.get(level_id, TOWERS_PER_LEVEL[5]),
		"hazard": hazards.get(level_id, ""),
		"modifiers": mods_out,
		"banned": banned.get(level_id, []),
		"obstacles": obstacles.get(level_id, []),
		"walls": walls.get(level_id, []),
		"pay_zones": pay_zones.get(level_id, []),
		"nobuild": nobuild.get(level_id, []),
		"reveals": reveals.get(level_id, []),
		"corridor_build": corridor.get(level_id, false),
	}

# --- Speciale modi (level_id >= 100): Tutorial (101), Boss Rush (102), Endless (103) ---
func _special_level(level_id: int) -> Dictionary:
	var full: Array = TOWERS_PER_LEVEL[15]   # volledige toolkit
	if level_id == 101:
		# Tutorial: 5 lessen. Per les één les-vijand + beperkte torens; level.gd reset ertussen.
		var straight := PackedVector2Array([Vector2(-60,260),Vector2(780,260)])
		# Lessen zijn HAALBAAR bedoeld: met de aangeboden torens moet je nul Focus verliezen.
		# Tester-feedback v0.72: je liep altijd schade op. Oorzaken waren te grote groepen voor
		# de beperkte toolkit, en les 4 leerde Headphones (single-target) tegen een zwerm van 20
		# -- dat kan die toren per definitie niet. Aantallen omlaag, koffie omhoog, en de
		# Headphones-les gaat nu over EEN doelwit afremmen zodat je schade-toren het afmaakt.
		var lessons := [
			{"towers":["coffee","auto"],          "spec":"noti:5@1.10",              "hint":"shop",
				"text":"LESSON 1/7 - Pick Auto-Reply in the shop on the right, then click beside the path to place it."},
			{"towers":["coffee","auto"],          "spec":"noti:5@1.10 + hulp:2@1.60", "hint":"shop",
				"text":"LESSON 2/7 - Build a Coffee Machine first: it deals no damage but pays for everything else."},
			{"towers":["coffee","filter"],        "spec":"thread:12@0.22",            "hint":"path",
				"text":"LESSON 3/7 - The Thread is a paper pile. Drop a Shredder ON the path: it slows everything in the zone so the pile bunches up."},
			{"towers":["coffee","phones","auto"], "spec":"nudge:6@0.55",              "hint":"path",
				"text":"LESSON 4/7 - Nudges are fast. Headphones slow ONE of them right down; your Auto-Reply finishes it. Use both."},
			{"towers":["coffee","ceo","auto"],    "spec":"tank:1@2.00",               "hint":"shop",
				"text":"LESSON 5/7 - The Old Guard has a shield. Only Office Artillery hits hard enough to break through."},
			{"towers":["coffee","auto","ceo"],    "spec":"noti:8@0.70 + hulp:3@1.20", "hint":"speed",
				"text":"LESSON 6/7 - Bottom right: START begins a wave, || pauses, and 1x-8x sets the speed. Try 4x - you can always pause to think."},
			{"towers":["coffee","auto","phones"], "spec":"noti:4@1.00 + nudge:4@0.70","hint":"tower",
				"text":"LESSON 7/7 - Click a tower you placed to open it. There you upgrade it and set targeting: First aims at whoever is furthest along."},
		]
		var tw := []
		for l in lessons:
			tw.append(_parse_wave(String(l["spec"])))
		return _special_base(101, "Tutorial", straight, full, 100, 70, tw, {"tutorial": true, "tutorial_lessons": lessons, "towers": lessons[0]["towers"]})
	elif level_id == 102:
		# Boss Rush: alle 15 per-level bosses in volgorde, elk met een kleine escorte.
		var p := PackedVector2Array([Vector2(-60,120),Vector2(620,120),Vector2(620,420),Vector2(180,420),Vector2(180,260),Vector2(780,260)])
		var bosses := ["allhands","outoforder","beamer","cleaner","boss","baby","smoking","floater","reorg","boss","hrmanager","consultant","legacy","deadline","boss360"]
		var bw := []
		for i in bosses.size():
			bw.append(_parse_wave("%s:1@2.00 + noti:%d@0.60" % [bosses[i], 4 + i]))
		return _special_base(102, "Boss Rush", p, full, 150, 80, bw, {})
	else:
		# Endless: procedureel oplopend, oneindig. level.gd genereert onderweg meer waves.
		var p := PackedVector2Array([Vector2(-60,100),Vector2(700,100),Vector2(700,260),Vector2(100,260),Vector2(100,420),Vector2(780,420)])
		var ew := []
		for i in range(3):
			ew.append(_parse_wave(_endless_spec(i + 1)))
		return _special_base(103, "Endless", p, full, 100, 40, ew, {"endless": true})

func _special_base(id: int, nm: String, p: PackedVector2Array, towers: Array, focus: int, coffee: int, waves: Array, extra: Dictionary) -> Dictionary:
	var d := {
		"id": id, "name": nm, "special": true,
		"path": p, "paths": [p],
		"start_focus": focus, "start_coffee": coffee,
		"waves": waves, "towers": towers,
		"hazard": "", "modifiers": [], "banned": [],
		"obstacles": [], "walls": [], "pay_zones": [], "nobuild": [], "reveals": [], "corridor_build": false,
		"tutorial": false, "endless": false, "tutorial_lessons": [],
	}
	for k in extra:
		d[k] = extra[k]
	return d

func _endless_spec(n: int) -> String:
	# Oplopende-moeilijkheid-generator: pool groeit met het wave-nummer, aantallen omhoog, tempo omlaag.
	var pool := ["noti", "hulp", "nudge"]
	if n >= 4: pool.append("change")
	if n >= 6: pool.append("tank")
	if n >= 8: pool.append("cold")
	if n >= 10: pool.append("board")
	if n >= 12: pool.append("micro")
	if n >= 14: pool.append("kletskous")
	if n >= 16: pool.append("caller")
	var parts := []
	var groups: int = 2 + n / 6
	for g in groups:
		var typ: String = pool[randi() % pool.size()]
		var cnt: int = 5 + n + randi() % 6
		var itv: float = maxf(0.10, 0.55 - n * 0.02)
		parts.append("%s:%d@%.2f" % [typ, cnt, itv])
	return " + ".join(parts)

# Welke towers de speler in dit level mag bouwen (lescurve uit GDD §4): elk level
# introduceert er een paar, zodat het spel zichzelf uitlegt en counters op tijd
# beschikbaar zijn. Het stealth-trio in level 4 heeft filter, auto en ceo (allen ≤ L2).
const TOWERS_PER_LEVEL := {
	1: ["coffee", "auto"],
	2: ["coffee", "auto", "phones", "ceo", "filter"],
	3: ["coffee", "auto", "phones", "ceo", "filter", "keyboard"],
	4: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	5: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	# Blok 2 (medior): volledige toolkit beschikbaar.
	6: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	7: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	8: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	9: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	10: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	# Blok 3 (senior): volledige toolkit (HR Room verbiedt phones+machinegun via 'banned', zie get_level).
	11: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	12: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	13: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	14: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
	15: ["coffee", "auto", "filter", "phones", "ceo", "scrum", "trap", "keyboard", "chain", "machinegun", "multishot", "pomodoro", "splash", "ctrlaltdel"],
}

# Wave-tabellen per level. Notatie: "type:aantal@interval", groepen gescheiden met " + ".
# Elk level heeft zijn eigen karakter (GDD §4) in plaats van één formule met een
# moeilijkheidsfactor. Balanceren gebeurt hier, zonder code aan te raken.
const WAVES := {
	# --- Level 1: Open-Plan Office. Rustig. Alleen de basic-familie: leer dat economie
	#     en schade samen moeten groeien. Geen boss.
	1: [
		"noti:5@0.80",
		"noti:7@0.75",
		"noti:9@0.70",
		"noti:12@0.60",
		"noti:8@0.70 + hulp:2@1.20",
		"noti:10@0.60 + hulp:3@1.10",
		"noti:12@0.55 + hulp:4@1.00",
		"noti:14@0.50 + hulp:5@1.00",
		"noti:10@0.50 + hulp:7@0.90",
		"noti:16@0.45 + hulp:6@0.90",
		"noti:12@0.50 + hulp:5@1.00 + story:1@1.50",
		"noti:14@0.45 + hulp:6@0.90 + story:2@1.40",
		"noti:18@0.40 + hulp:7@0.85",
		"noti:12@0.45 + hulp:8@0.80 + story:3@1.30",
		"noti:20@0.35 + hulp:9@0.80",
		"noti:16@0.40 + hulp:8@0.80 + story:4@1.20",
		"noti:22@0.35 + hulp:10@0.75",
		"noti:18@0.35 + hulp:10@0.70 + story:5@1.10",
		"noti:24@0.30 + hulp:12@0.70 + story:4@1.20",
		"noti:28@0.28 + hulp:14@0.65 + story:7@1.00",
		"allhands:1@2.00 + noti:6@0.60",
	],
	# --- Level 3: Meeting Room. Zwerm versus area. The Thread komt als één grote tros
	#     printjes; de Oude Garde is er juist immuun voor (bewaarplicht). Event: projector-QTE.
	3: [
		"noti:8@0.70 + hulp:2@1.20",
		"noti:10@0.65 + hulp:3@1.10",
		"thread:14@0.12",
		"noti:10@0.60 + hulp:4@1.00",
		"tank:1@2.00 + noti:8@0.70",
		"thread:18@0.12 + noti:8@0.70",
		"noti:12@0.55 + hulp:5@1.00 + story:2@1.40",
		"tank:2@1.80 + thread:16@0.12",
		"thread:22@0.10 + hulp:5@1.00",
		"noti:14@0.50 + hulp:6@0.90 + tank:2@1.80",
		"thread:26@0.10 + story:2@1.40",
		"tank:3@1.60 + noti:12@0.50",
		"thread:24@0.10 + hulp:7@0.90 + story:3@1.30",
		"noti:16@0.45 + tank:3@1.60",
		"thread:30@0.09 + hulp:8@0.85",
		"tank:4@1.50 + story:4@1.20 + noti:14@0.50",
		"thread:28@0.09 + noti:16@0.45 + hulp:8@0.80",
		"tank:4@1.40 + thread:24@0.10 + story:4@1.20",
		"noti:20@0.40 + hulp:10@0.75 + tank:3@1.50",
		"thread:36@0.08 + tank:5@1.30 + story:6@1.10 + hulp:10@0.80",
		"beamer:1@2.00 + thread:12@0.14",
	],
	# --- Level 2: Coffee Corner. Snelheid en crowd control. Sprinters die je trage towers
	#     ontlopen, een manager die sneller wordt naarmate je hem raakt, de Kletskous die
	#     je towers stilzet, en de Printer: traag, maar blijft foutmeldingen uitspugen tot
	#     je hem neerhaalt. Bewust hier en niet in level 4 — daar levert de lunchpauze al
	#     een swarm, en dan wordt het onleesbaar druk.
	#     21 waves in plaats van 20: de Printer krijgt een eigen rustige introductiewave,
	#     want elke andere wave introduceert al iets anders en twee nieuwe vijanden tegelijk
	#     leert slecht.
	2: [
		"noti:10@0.65 + hulp:3@1.10",
		"nudge:10@0.20",
		"noti:12@0.60 + thread:14@0.12",
		"nudge:16@0.18 + hulp:4@1.00",
		"micro:1@2.00 + noti:10@0.60",
		"printer:1@2.00 + noti:8@0.60",
		"nudge:20@0.16 + tank:1@2.00",
		"kletskous:1@2.00 + noti:12@0.55",
		"nudge:24@0.15 + micro:2@1.80",
		"thread:20@0.11 + kletskous:1@2.00 + hulp:6@0.90",
		"nudge:28@0.14 + tank:2@1.80 + printer:1@2.00",
		"micro:3@1.60 + noti:14@0.50 + story:2@1.40",
		"nudge:32@0.13 + kletskous:2@1.80",
		"thread:24@0.10 + micro:3@1.60 + hulp:7@0.85 + printer:2@1.80",
		"nudge:36@0.12 + tank:3@1.60",
		"kletskous:2@1.80 + micro:4@1.50 + noti:16@0.45",
		"nudge:40@0.11 + story:4@1.20 + printer:2@1.70",
		"thread:28@0.10 + kletskous:3@1.60 + tank:3@1.50",
		"nudge:44@0.10 + micro:5@1.40 + printer:3@1.60",
		"noti:20@0.40 + hulp:10@0.75 + kletskous:3@1.60 + tank:3@1.50",
		"nudge:50@0.09 + micro:6@1.30 + kletskous:4@1.50 + tank:4@1.40 + printer:3@1.60",
		"outoforder:1@2.00 + nudge:12@0.16",
	],
	# --- Level 4: Canteen. Volledige diversiteit: splitters plus het stealth-trio.
	#     Hier moet je alle rollen tegelijk hebben staan. Hazard: lunchpauze.
	4: [
		"noti:12@0.60 + hulp:4@1.00",
		"change:2@1.50",
		"nudge:20@0.16 + noti:10@0.60",
		"phish:2@1.20 + hulp:5@1.00",
		"change:3@1.40 + thread:16@0.12",
		"board:1@2.00 + noti:12@0.55",
		"cold:2@1.40 + nudge:24@0.15",
		"change:4@1.30 + phish:3@1.10",
		"board:2@1.80 + tank:2@1.80 + hulp:6@0.90",
		"cold:3@1.30 + thread:22@0.11",
		"change:5@1.20 + micro:3@1.60",
		"phish:4@1.10 + nudge:30@0.14 + board:2@1.80",
		"cold:4@1.20 + kletskous:2@1.80 + noti:14@0.50",
		"change:6@1.10 + tank:3@1.60 + story:3@1.30",
		"board:3@1.70 + phish:5@1.00 + thread:26@0.10",
		"cold:5@1.10 + micro:4@1.50 + nudge:34@0.13",
		"change:7@1.00 + kletskous:3@1.60 + tank:3@1.50",
		"board:4@1.60 + cold:5@1.10 + phish:5@1.00",
		"nudge:40@0.11 + change:6@1.10 + micro:5@1.40 + story:5@1.10",
		"board:5@1.50 + cold:6@1.00 + change:8@1.00 + tank:4@1.40 + phish:6@0.95",
		"cleaner:1@2.00 + change:3@1.40",
	],
	# --- Level 5: Boardroom. Alles samen, moeilijkheidspiek, en als enige level een
	#     eindboss: The Performance Review.
	5: [
		"noti:14@0.55 + hulp:5@1.00",
		"thread:20@0.11 + nudge:20@0.16",
		"tank:2@1.80 + change:3@1.40",
		"micro:3@1.60 + phish:3@1.10",
		"kletskous:2@1.80 + board:2@1.80",
		"cold:4@1.20 + nudge:26@0.15",
		"thread:26@0.10 + tank:3@1.60",
		"change:5@1.20 + micro:4@1.50 + noti:16@0.45",
		"board:3@1.70 + phish:4@1.10 + hulp:8@0.85",
		"nudge:34@0.13 + cold:5@1.10",
		"tank:4@1.50 + kletskous:3@1.60 + story:4@1.20",
		"thread:30@0.09 + change:6@1.10",
		"micro:5@1.40 + board:4@1.60 + nudge:36@0.12",
		"cold:6@1.00 + phish:5@1.00 + tank:4@1.40",
		"change:8@1.00 + kletskous:4@1.50 + noti:20@0.40",
		"thread:34@0.09 + micro:6@1.30 + story:5@1.10",
		"board:5@1.50 + cold:6@1.00 + nudge:42@0.11",
		"tank:5@1.30 + change:8@1.00 + phish:6@0.95",
		"nudge:48@0.10 + micro:7@1.20 + kletskous:5@1.40 + hulp:12@0.70",
		"boss:1@1.00 + noti:8@0.50 + hulp:3@1.00",
	],
	# ===== BLOK 2 — MEDIOR (6-10). Pittiger: dichtere golven, meer mix. Balans nog niet gespeeld. =====
	# --- Level 7: The Parking. Rook verkort toren-range (hazard). Boss: Smoking Colleague. (was Level 6)
	7: [
		"nudge:18@0.15 + noti:12@0.55",
		"cold:3@1.30 + hulp:6@0.90",
		"nudge:26@0.14 + tank:2@1.80",
		"micro:3@1.60 + phish:3@1.10",
		"thread:26@0.10 + cold:4@1.20",
		"board:2@1.80 + nudge:32@0.13",
		"kletskous:2@1.80 + micro:4@1.50 + noti:14@0.50",
		"printer:2@1.70 + tank:3@1.60 + cold:5@1.10",
		"change:5@1.20 + board:3@1.70 + thread:24@0.10",
		"kletskous:3@1.60 + printer:3@1.60 + nudge:40@0.11",
		"tank:4@1.40 + micro:5@1.40 + phish:5@1.00 + story:4@1.20",
		"board:4@1.60 + change:7@1.00 + cold:6@1.00",
		"nudge:48@0.10 + kletskous:4@1.50 + tank:4@1.40",
		"printer:3@1.60 + micro:6@1.30 + board:4@1.50 + noti:18@0.40",
		"smoking:1@2.00 + nudge:18@0.15 + tank:2@1.60",
	],
	# --- Level 6: Work From Home. Event: No Internet (dino-mini-game). Boss: The Baby. (was Level 7)
	6: [
		"noti:16@0.45 + nudge:16@0.16",
		"change:3@1.40 + hulp:6@0.90",
		"phish:3@1.10 + thread:22@0.11",
		"micro:3@1.60 + cold:4@1.20",
		"tank:3@1.60 + nudge:28@0.14",
		"board:3@1.70 + change:5@1.20",
		"kletskous:2@1.80 + printer:2@1.70 + noti:16@0.45",
		"phish:5@1.00 + micro:4@1.50 + hulp:8@0.85",
		"tank:4@1.50 + thread:28@0.09 + cold:5@1.10",
		"change:6@1.10 + board:4@1.60 + nudge:38@0.12",
		"kletskous:3@1.60 + micro:5@1.40 + phish:5@1.00",
		"printer:3@1.60 + tank:4@1.40 + story:5@1.10",
		"board:5@1.50 + change:7@1.00 + cold:6@1.00",
		"nudge:46@0.10 + micro:6@1.30 + kletskous:4@1.50 + noti:18@0.40",
		"baby:1@2.00 + change:4@1.30 + phish:3@1.10",
	],
	# --- Level 8: The Flexplek. Multi-path (nu stub: één pad). Boss: The Floater.
	8: [
		"nudge:24@0.14 + noti:14@0.50",
		"cold:4@1.20 + phish:3@1.10",
		"nudge:32@0.13 + tank:3@1.60",
		"micro:4@1.50 + thread:24@0.10",
		"board:3@1.70 + cold:5@1.10",
		"kletskous:2@1.80 + nudge:38@0.12",
		"printer:2@1.70 + change:5@1.20 + noti:16@0.45",
		"tank:4@1.40 + micro:5@1.40 + phish:5@1.00",
		"board:4@1.60 + kletskous:3@1.60 + hulp:8@0.85",
		"nudge:46@0.10 + change:7@1.00 + cold:6@1.00",
		"printer:3@1.60 + tank:4@1.40 + micro:6@1.30",
		"board:5@1.50 + phish:6@0.95 + story:5@1.10",
		"kletskous:4@1.50 + change:8@1.00 + nudge:52@0.09",
		"tank:5@1.30 + micro:7@1.20 + printer:3@1.50 + noti:20@0.40",
		"floater:1@2.00 + nudge:24@0.14",
	],
	# --- Level 9: Town Hall. Event: telefoon-ophangen (stub) + 50% koffie. Boss: The Reorganisation.
	9: [
		"nudge:22@0.14 + change:3@1.40",
		"tank:3@1.60 + cold:4@1.20",
		"micro:4@1.50 + phish:4@1.10",
		"board:3@1.70 + thread:26@0.10",
		"kletskous:2@1.80 + nudge:34@0.13 + caller:2@1.60",
		"change:5@1.20 + printer:2@1.70 + noti:16@0.45",
		"tank:4@1.50 + micro:5@1.40 + cold:5@1.10",
		"board:4@1.60 + phish:5@1.00 + hulp:8@0.85 + caller:2@1.40",
		"kletskous:3@1.60 + change:7@1.00 + nudge:42@0.11",
		"printer:3@1.60 + tank:4@1.40 + micro:6@1.30",
		"board:5@1.50 + cold:6@1.00 + story:5@1.10",
		"change:8@1.00 + kletskous:4@1.50 + phish:6@0.95 + caller:3@1.30",
		"tank:5@1.30 + micro:7@1.20 + nudge:50@0.09",
		"board:5@1.40 + printer:3@1.50 + change:8@1.00 + noti:20@0.40",
		"reorg:1@2.00 + change:4@1.30 + nudge:16@0.16",
	],
	# --- Level 10: Boardroom (medior finale). Modifier: weinig bouwplekken. Boss: Performance Review.
	10: [
		"noti:16@0.45 + nudge:20@0.15",
		"thread:26@0.10 + change:4@1.30",
		"tank:3@1.60 + micro:4@1.50",
		"board:3@1.70 + phish:4@1.10",
		"kletskous:3@1.60 + cold:5@1.10",
		"printer:2@1.70 + nudge:38@0.12 + noti:16@0.45",
		"tank:4@1.50 + change:6@1.10 + micro:5@1.40",
		"board:4@1.60 + phish:5@1.00 + thread:30@0.09",
		"kletskous:4@1.50 + cold:6@1.00 + hulp:10@0.75",
		"printer:3@1.60 + tank:4@1.40 + nudge:46@0.10",
		"board:5@1.50 + micro:6@1.30 + change:8@1.00",
		"kletskous:4@1.50 + phish:6@0.95 + story:6@1.10",
		"tank:5@1.30 + printer:3@1.50 + micro:7@1.20 + noti:20@0.40",
		"board:5@1.40 + change:9@0.95 + kletskous:5@1.40 + nudge:52@0.09",
		"boss:1@1.00 + noti:10@0.45 + hulp:4@1.00 + change:3@1.30",
	],
	# ===== BLOK 3 — SENIOR (11-15). Hardst: min. 2 prikkels per level, dichte gemengde golven. =====
	# --- Level 11: HR Room. Verboden torens (Headphones + Quick Reply) + formulier-event (stub). Boss: HR Manager.
	11: [
		"nudge:26@0.13 + change:4@1.30",
		"micro:4@1.50 + phish:4@1.10",
		"tank:3@1.60 + cold:5@1.10",
		"board:3@1.70 + thread:28@0.09",
		"kletskous:3@1.60 + printer:2@1.70 + noti:16@0.45",
		"change:6@1.10 + micro:5@1.40 + cold:6@1.00",
		"board:4@1.60 + phish:5@1.00 + tank:4@1.40",
		"printer:3@1.60 + kletskous:4@1.50 + nudge:44@0.10",
		"board:5@1.50 + change:8@1.00 + micro:6@1.30",
		"tank:5@1.30 + cold:6@1.00 + phish:6@0.95 + story:5@1.10",
		"printer:3@1.50 + kletskous:5@1.40 + board:4@1.50",
		"change:9@0.95 + micro:7@1.20 + nudge:52@0.09",
		"board:6@1.40 + tank:5@1.30 + phish:6@0.90 + noti:20@0.40",
		"kletskous:5@1.40 + printer:4@1.50 + change:9@0.95 + cold:7@0.95",
		"hrmanager:1@2.00 + change:5@1.20 + micro:3@1.60",
	],
	# --- Level 13: Server Room. Oververhitting + betaal-zones op de racks. Boss: The Legacy System. (was Level 12)
	13: [
		"nudge:30@0.12 + noti:16@0.45",
		"printer:2@1.70 + tank:3@1.60",
		"micro:5@1.40 + cold:6@1.00 + update:2@1.60",
		"board:4@1.60 + thread:30@0.09",
		"kletskous:4@1.50 + change:6@1.10 + phish:5@1.00",
		"printer:3@1.60 + board:4@1.50 + nudge:42@0.11 + update:2@1.50",
		"tank:5@1.30 + micro:6@1.30 + cold:6@1.00",
		"kletskous:5@1.40 + change:8@1.00 + hulp:10@0.75",
		"board:5@1.50 + phish:6@0.95 + printer:3@1.50 + update:3@1.40",
		"tank:5@1.30 + micro:7@1.20 + nudge:50@0.09",
		"board:6@1.40 + change:9@0.95 + kletskous:5@1.40",
		"printer:4@1.50 + cold:7@0.95 + story:6@1.10",
		"tank:6@1.20 + micro:8@1.10 + board:5@1.40 + noti:20@0.40",
		"kletskous:6@1.30 + printer:4@1.40 + change:10@0.90 + phish:7@0.90",
		"legacy:1@2.00 + error:6@0.50 + tank:3@1.50",
	],
	# --- Level 12: The Merger. Invoegend onthul-pad + half_coffee. Boss: The Consultant. (was Level 13)
	12: [
		"nudge:34@0.11 + change:5@1.20",
		"board:4@1.60 + micro:5@1.40",
		"tank:4@1.50 + phish:5@1.00",
		"kletskous:4@1.50 + cold:6@1.00 + noti:18@0.40",
		"printer:3@1.60 + change:7@1.00 + thread:30@0.09",
		"board:5@1.50 + micro:6@1.30 + tank:4@1.40",
		"kletskous:5@1.40 + phish:6@0.95 + nudge:46@0.10",
		"printer:3@1.50 + board:5@1.40 + change:8@1.00",
		"tank:6@1.20 + micro:7@1.20 + cold:7@0.95",
		"board:6@1.40 + kletskous:5@1.40 + phish:7@0.90 + story:6@1.10",
		"printer:4@1.50 + change:10@0.90 + micro:8@1.10",
		"tank:6@1.20 + board:6@1.30 + nudge:54@0.08",
		"kletskous:6@1.30 + printer:4@1.40 + cold:8@0.90 + noti:22@0.38",
		"board:7@1.30 + tank:6@1.15 + change:10@0.90 + phish:8@0.88",
		"consultant:1@2.00 + tank:3@1.50 + board:3@1.60",
	],
	# --- Level 14: Release Night. Start met 10 Focus + Eat the Pizza (stub). Boss: The Deadline.
	14: [
		"nudge:30@0.12 + noti:14@0.45",
		"cold:6@1.00 + phish:4@1.10",
		"micro:5@1.40 + change:5@1.20",
		"tank:4@1.50 + board:3@1.70",
		"kletskous:4@1.50 + nudge:40@0.11",
		"printer:3@1.60 + micro:6@1.30 + cold:6@1.00",
		"board:5@1.50 + phish:6@0.95 + tank:4@1.40",
		"change:8@1.00 + kletskous:5@1.40 + noti:18@0.40",
		"printer:3@1.50 + board:5@1.40 + micro:7@1.20",
		"tank:6@1.20 + cold:7@0.95 + nudge:50@0.09",
		"kletskous:5@1.40 + change:9@0.95 + phish:7@0.90",
		"board:6@1.40 + printer:4@1.50 + micro:8@1.10",
		"tank:6@1.15 + kletskous:6@1.30 + story:6@1.10",
		"board:6@1.30 + change:10@0.90 + printer:4@1.40 + cold:8@0.88",
		"deadline:1@2.00 + nudge:24@0.13 + micro:3@1.50",
	],
	# --- Level 15: Boardroom (senior finale). Weinig bouwplekken + 50% koffie. Boss: Performance Review.
	15: [
		"noti:18@0.40 + nudge:26@0.13",
		"tank:4@1.50 + change:5@1.20",
		"board:4@1.60 + micro:5@1.40",
		"kletskous:4@1.50 + phish:5@1.00 + thread:30@0.09",
		"printer:3@1.60 + cold:6@1.00 + tank:4@1.40",
		"board:5@1.50 + change:7@1.00 + micro:6@1.30",
		"kletskous:5@1.40 + printer:3@1.50 + nudge:46@0.10",
		"tank:5@1.30 + board:5@1.40 + phish:6@0.95",
		"micro:7@1.20 + change:9@0.95 + cold:7@0.95",
		"board:6@1.40 + kletskous:5@1.40 + tank:5@1.30 + noti:20@0.40",
		"printer:4@1.50 + micro:8@1.10 + phish:7@0.90",
		"board:6@1.30 + change:10@0.90 + kletskous:6@1.30",
		"tank:6@1.20 + printer:4@1.40 + micro:8@1.10 + story:6@1.10",
		"board:7@1.30 + kletskous:6@1.25 + change:11@0.88 + phish:8@0.88 + tank:5@1.30",
		"boss360:1@1.00 + board:2@1.50 + change:4@1.20 + noti:10@0.45",   # finale-review met 360°-cameo's
	],
}

func _parse_wave(spec: String) -> Array:
	# "noti:12@0.5 + tank:2@1.8" -> [{type,count,interval}, ...]
	var groups := []
	for part in spec.split("+", false):
		var s: String = part.strip_edges()
		if s.is_empty():
			continue
		var at: PackedStringArray = s.split("@")
		var tc: PackedStringArray = at[0].split(":")
		groups.append({
			"type": tc[0].strip_edges(),
			"count": int(tc[1]) if tc.size() > 1 else 1,
			"interval": float(at[1]) if at.size() > 1 else 1.0,
		})
	return groups

# ---------- Progressie ----------

func is_unlocked(level_id: int) -> bool:
	return level_id <= highest_unlocked

func get_stars(level_id: int) -> int:
	return int(stars.get(str(level_id), 0))


# Recognition per level is een VAST potje dat je met sterren openmaakt, niet iets dat met je
# score meeschaalt. Reden (tester-feedback v0.71): op score meeliften leverde bergen Recognition
# op voor hetzelfde level nog een keer spelen. Nu: 3 sterren = het hele potje, 2 sterren = 2/3,
# 1 ster = 1/3. Kom je later terug en doe je het beter, dan krijg je alléén het verschil
# bijbetaald -- nooit twee keer voor dezelfde ster.
const RECOGNITION_PER_LEVEL := 12
# Zonder ook maar één Focus te verliezen: een verborgen extra bovenop de drie sterren.
const BONUS_FLAWLESS := 8


func recognition_for_stars(st: int) -> int:
	return int(round(float(RECOGNITION_PER_LEVEL) * float(clampi(st, 0, 3)) / 3.0))


func complete_level(level_id: int, earned_stars: int, flawless: bool = false) -> Dictionary:
	var key := str(level_id)
	var had: int = get_stars(level_id)
	var best: int = maxi(had, earned_stars)
	# Alleen het verschil met wat je eerder al verdiende voor dit level.
	var already: int = recognition_for_stars(had)
	var stars_pay: int = maxi(0, recognition_for_stars(best) - already)
	# De flawless-bonus is eenmalig per level.
	var flawless_pay: int = 0
	if flawless and not flawless_levels.has(key):
		flawless_pay = BONUS_FLAWLESS
		flawless_levels[key] = true
	var total: int = stars_pay + flawless_pay
	stars[key] = best
	var promotion := ""
	if level_id == highest_unlocked and level_id < LEVEL_COUNT:
		highest_unlocked = level_id + 1
		# Promotie bij het afronden van het laatste level van een blok van vijf.
		if level_id == 5: promotion = "medior"
		elif level_id == 10: promotion = "senior"
	elif level_id == 15 and had == 0:
		promotion = "specialist"   # laatste level voor het eerst uitgespeeld -> top van de carriere
	recognition += total
	save_game()
	return {"stars_pay": stars_pay, "flawless_pay": flawless_pay, "total": total,
		"promotion": promotion, "had": had, "best": best,
		"max_for_level": RECOGNITION_PER_LEVEL}

# ---------- Rang / carrière ----------

func current_rank() -> String:
	# Je rang volgt je hoogst ontgrendelde level: 1-5 junior, 6-10 medior, 11-15 senior.
	if highest_unlocked <= 5: return "junior"
	elif highest_unlocked <= 10: return "medior"
	elif highest_unlocked <= 15: return "senior"
	return "specialist"

func block_of(level_id: int) -> int:
	return int((level_id - 1) / 5)   # 0=junior, 1=medior, 2=senior

# ---------- Meta-aankopen ----------

func has_upgrade(id: String) -> bool:
	return bool(upgrades.get(id, false))

func buy_upgrade(id: String, cost: int) -> bool:
	if has_upgrade(id) or recognition < cost:
		return false
	recognition -= cost
	upgrades[id] = true
	save_game()
	return true

func buy_consumable(id: String, cost: int) -> bool:
	if recognition < cost:
		return false
	recognition -= cost
	consumables[id] = int(consumables.get(id, 0)) + 1
	save_game()
	return true

func use_consumable(id: String) -> bool:
	var n := int(consumables.get(id, 0))
	if n <= 0:
		return false
	consumables[id] = n - 1
	save_game()
	return true

# ---------- Instellingen / audio ----------

func _ensure_buses() -> void:
	for bus_name in ["Music", "ShootSFX", "BuySFX", "CoffeeSFX", "EventSFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func apply_settings() -> void:
	var win := get_window()
	if win != null:
		win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if integer_scale else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		match display_mode:
			2:
				win.borderless = false
				win.mode = Window.MODE_FULLSCREEN
			1:
				win.mode = Window.MODE_WINDOWED
				win.borderless = true
				var scr: Rect2i = DisplayServer.screen_get_usable_rect(win.current_screen)
				win.size = scr.size
				win.position = scr.position
			_:
				win.mode = Window.MODE_WINDOWED
				win.borderless = false
				var res_list := available_resolutions()
				resolution_index = clampi(resolution_index, 0, res_list.size() - 1)
				win.size = res_list[resolution_index]
				win.move_to_center()
	# Master regelt alles tegelijk (op 0 = stil); de andere bussen sturen ernaartoe.
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("ShootSFX", shoot_volume)
	_set_bus_volume("BuySFX", buy_volume)
	_set_bus_volume("CoffeeSFX", coffee_volume)
	_set_bus_volume("EventSFX", event_volume)

# De resolutielijst is bewust ALLEEN de 16:9-maten die op je scherm passen — nooit de
# schermresolutie zelf als die een andere verhouding heeft (ultrawide). De game rendert op
# 960x540 (16:9); een venster met een andere verhouding geeft vervorming of loopt van het
# scherm af (dat was de bug). Voor beeldvullend spelen op een ultrawide is er Borderless /
# Fullscreen: daar schaalt de content scherp met zwarte balken op de zijkanten. Dit is de
# aanpak die de meeste pixel-art Godot-games volgen (zie de bronnen in HANDOFF.md).
const RES_CANDIDATES: Array[Vector2i] = [
	Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3200, 1800), Vector2i(3840, 2160),
]

func available_resolutions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var win := get_window()
	# Iets marge onder de usable hoogte: een windowed venster heeft ook nog een titelbalk.
	var usable: Vector2i = BASE_SIZE * 2
	if win != null:
		usable = DisplayServer.screen_get_usable_rect(win.current_screen).size
	for r in RES_CANDIDATES:
		if r.x <= usable.x and r.y <= usable.y:
			out.append(r)
	if out.is_empty():
		out.append(BASE_SIZE)
	return out

func resolution_label(res: Vector2i) -> String:
	var txt := "%d x %d" % [res.x, res.y]
	# Een heel veelvoud van de 960x540-basis betekent dat elke art-pixel precies N
	# schermpixels wordt: dat blijft messcherp. De rest is 16:9 maar niet-integer.
	if res.x % BASE_SIZE.x == 0 and res.y % BASE_SIZE.y == 0 and res.x / BASE_SIZE.x == res.y / BASE_SIZE.y:
		return txt + "   (%dx, crisp)" % (res.x / BASE_SIZE.x)
	return txt

func current_window_size() -> Vector2i:
	var win := get_window()
	return win.size if win != null else Vector2i.ZERO

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))

# ---------- Save / load ----------

func save_game() -> void:
	var data := {
		"highest_unlocked": highest_unlocked,
		"stars": stars,
		"flawless_levels": flawless_levels,
		"recognition": recognition,
		"upgrades": upgrades,
		"consumables": consumables,
		"seen_enemies": seen_enemies,
		"enemy_panel_open": enemy_panel_open,
		"resolution_index": resolution_index,
		"display_mode": display_mode,
		"integer_scale": integer_scale,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"shoot_volume": shoot_volume,
		"buy_volume": buy_volume,
		"coffee_volume": coffee_volume,
		"event_volume": event_volume,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return
	highest_unlocked = int(data.get("highest_unlocked", 1))
	stars = data.get("stars", {})
	flawless_levels = data.get("flawless_levels", {})
	recognition = int(data.get("recognition", 0))
	upgrades = data.get("upgrades", {})
	consumables = data.get("consumables", {})
	seen_enemies = data.get("seen_enemies", {})
	enemy_panel_open = bool(data.get("enemy_panel_open", false))
	resolution_index = int(data.get("resolution_index", 1))
	display_mode = int(data.get("display_mode", 0))
	integer_scale = bool(data.get("integer_scale", true))
	master_volume = float(data.get("master_volume", 0.9))
	music_volume = float(data.get("music_volume", 0.8))
	shoot_volume = float(data.get("shoot_volume", 0.8))
	buy_volume = float(data.get("buy_volume", 0.8))
	coffee_volume = float(data.get("coffee_volume", 0.8))
	event_volume = float(data.get("event_volume", 0.8))
