class_name Tower
extends Node2D

# Data-driven tower. Rollen: "damage", "stun", "economy", "area", "support".

var def_id: String = "auto"
var level: int = 1
var level_name: String = ""
var level_flavour: String = ""
var role: String = "damage"
var invested: int = 0
# Wat DEZE toren heeft gedaan (niet dit toren-TYPE): voedt het detailpaneel als je 'm aanklikt,
# zodat je kunt zien of een plek zijn Coffee waard is.
var stat_damage: float = 0.0
var stat_time: float = 0.0

var range_radius: float = 135.0
var fire_rate: float = 0.45
var damage: float = 1.0
var stun_dur: float = 0.0
var cc_slow: float = 1.0        # stun-tower: vertraging op lagere levels (1.0 = geen)
var cc_slow_dur: float = 0.0
var coffee_amount: int = 0
var coffee_interval: float = 3.0
var area_dot: float = 0.0
var area_slow: float = 1.0
var buff_dmg: float = 1.0
var buff_rate: float = 1.0
var buff_range: float = 1.0

# ontvangen buffs / verstoring (elke frame gezet door level.gd)
var buff_dmg_mult: float = 1.0
var buff_rate_mult: float = 1.0
var buff_range_mult: float = 1.0
var silenced: bool = false
var suppressed: bool = false     # The Cleaner-boss legt een area-toren (Shredder) stil zolang hij ernaast staat
var disrupt_rate_mult: float = 1.0

var target_mode: String = "closest"  # first / last / closest / farthest / least_hp / most_hp
var target_mode_chosen: bool = false  # true zodra de speler zelf een modus koos
# Onzichtbare vijanden zijn een aparte kwestie, geen targeting-stand: je wilt kunnen
# kiezen "richt op de sterkste, maar pak onzichtbare eerst". sees_hidden komt uit de
# defs (niet elke tower kan ze zien), prefer_hidden is de keuze van de speler.
var sees_hidden: bool = false
var prefer_hidden: bool = false
var buff_targets: Array = []          # support: welke torens hij buft
# Zolang dit false is vult level.gd de doelen automatisch met de dichtstbijzijnde torens.
# Reden: de Poster buffte alleen wie je HANDMATIG had aangeklikt, dus wie hem kocht en die
# tweede, nergens aangekondigde handeling niet deed, kreeg helemaal niets -- terwijl hij
# per Coffee de sterkste aankoop van het spel is (0,574 DPS/C) en nul keer gekocht werd.
# Zelfde patroon als target_mode_chosen: automatisch tot de speler zelf kiest.
var buff_chosen: bool = false
var max_targets: int = 1

# multishot: aantal doelen per salvo. chain: schot springt door naar volgende vijanden.
var multi_shots: int = 1
var chain_jumps: int = 0               # aantal extra sprongen na het eerste doel
var chain_range: float = 90.0          # maximale sprongafstand tussen vijanden
var chain_falloff: float = 0.75        # schade × dit per sprong

# trap: een val op het pad. De tower staat ernaast.
var trap_path: PackedVector2Array = PackedVector2Array()
var trap_paths: Array = []             # alle lanes (multi-path): de val strooit over álle banen
var trap_pos: Vector2 = Vector2.ZERO
var trap_pos_chosen: bool = false     # true zodra de speler (lvl 3) zelf een plek koos
var trap_radius: float = 20.0
var throw_interval: float = 1.5        # elke zoveel sec gooit hij een punaise
var tack_lifetime: float = 4.5         # hoe lang een punaise blijft liggen voor hij wegroest
var pick_spot: bool = false            # lvl 3 mag de doeltegel zelf kiezen
var _throw_timer: float = 0.0
var _tacks_list: Array = []            # [{pos, age}] — losse punaises op de baan
var on_throw: Callable                 # (from, to) — level.gd zet dit voor het worp-projectiel

# splash (Reply All): schade rondom de treffer, beweegt mee met het doel.
var splash_radius: float = 0.0
var splash_falloff: float = 0.6        # omstanders krijgen damage × dit
# burst (Pomodoro): laadt op (fire_rate = laadtijd) en lost dan één AoE-klap op alles in bereik.
# forcequit (Ctrl+Alt+Del): laadt op (charge_time) en force-quit dan de sterkste vijand. Eenmalig.
var charge_time: float = 30.0
var _spent: bool = false               # Ctrl+Alt+Del: al gebruikt

# special: gedeelde vlaggen
var is_special: bool = false
var on_path: bool = false              # deze tower hoort óp/aan het pad geplaatst te worden
# smash (Keyboard Smash)
var smash_damage: float = 0.0
var smash_cooldown: float = 6.0
var barrier_duration: float = 2.5
var barrier_active: bool = false
var _smash_cd: float = 0.0
var _barrier_timer: float = 0.0
var on_smash: Callable                 # (pos) — level.gd zet dit voor de letters-fx + geluid

var _cooldown: float = 0.0
var _coffee_timer: float = 0.0
var _shot_target: Node2D = null
var _shot_time: float = 0.0

var get_enemies: Callable
var get_walls: Callable    # () -> Array van Rect2: zicht-muren die het schootzicht blokkeren
var on_coffee: Callable
var on_fire: Callable
var on_damage: Callable   # (def_id, amount) — voor de statistieken op het eindscherm

var sprite: Sprite2D = null
var use_sprite: bool = false

static func defs() -> Dictionary:
	# BALANS-REGEL: kracht-per-Coffee moet STIJGEN per level, zodat upgraden altijd
	# efficienter is dan een tweede exemplaar kopen. Bereik groeit juist nauwelijks,
	# zodat een tweede toren nodig blijft om een tweede stuk map te dekken.
	return {
		"auto": {
			"name": "Auto-Reply", "role": "damage", "color": Color(0.25, 0.55, 0.9),
			"desc": "Fast, low damage. Reliable workhorse.",
			"levels": [
				# 10 was te goedkoop: de op één na goedkoopste schadetoren kostte 18, dus met je
				# startkoffie kocht je drie Auto-Replies of één van iets anders. Vroeg in een level
				# wint dekking van DPS, dus die keuze had altijd hetzelfde antwoord en de rest van
				# de toolkit deed niet mee. Nu 14, met Quick Reply op 16 ernaast als echte rivaal
				# met een ander profiel. Zie 06_SYSTEEM_AUDIT.md §4.1 (A8).
				{"name": "Auto-Reply", "flavour": "I\'ll get back to you.", "cost": 14, "range": 135.0, "rate": 0.45, "damage": 1.4},
				{"name": "Out of Office", "flavour": "Currently unavailable. Forever.", "cost": 12, "range": 142.0, "rate": 0.40, "damage": 2.4},
				{"name": "Inbox Zero", "flavour": "Nothing left to answer.", "cost": 25, "range": 150.0, "rate": 0.32, "damage": 4.0},
			],
		},
		"coffee": {
			"name": "Coffee Machine", "role": "economy", "color": Color(0.6, 0.4, 0.22),
			"desc": "Generates passive Coffee. No damage.",
			"levels": [
				{"name": "Coffee Machine", "flavour": "It\'s something.", "cost": 20, "coffee_amount": 1, "coffee_interval": 5.0},
				{"name": "Espresso Machine", "flavour": "Aaah, that\'s better.", "cost": 20, "coffee_amount": 2, "coffee_interval": 5.0},
				{"name": "Barista Station", "flavour": "Finally, some good coffee.", "cost": 30, "coffee_amount": 4, "coffee_interval": 5.0},
			],
		},
		"ceo": {
			"name": "Office Artillery", "role": "damage", "color": Color(0.85, 0.35, 0.35),
			"desc": "Slow, huge single-target hit. Staples one distraction shut.",
			"levels": [
				{"name": "Rubber Band", "flavour": "Ow. That actually stung.", "cost": 25, "range": 220.0, "rate": 2.6, "damage": 15.0},
				{"name": "Stapler", "flavour": "It\'s a Swingline.", "cost": 28, "range": 228.0, "rate": 2.5, "damage": 35.0},
				{"name": "Industrial Tacker", "flavour": "That is going in the wall.", "cost": 45, "range": 236.0, "rate": 2.4, "damage": 80.0},
			],
		},
		"phones": {
			"name": "Headphones", "role": "stun", "color": Color(0.6, 0.75, 0.4),
			"desc": "Slows one target; the top tier stops it dead.",
			"levels": [
				# Ladder: eerst dempen, dan sterker dempen, dan helemaal afsnijden. Alleen
				# lvl 3 stunt echt — en dat is ook de enige die de Kletskous stilkrijgt.
				{"name": "Earbuds", "flavour": "Can\'t quite hear you.", "cost": 20, "range": 130.0, "rate": 2.0, "slow": 0.65, "slow_dur": 1.6},
				{"name": "Over-Ear", "flavour": "Can\'t hear anything.", "cost": 22, "range": 136.0, "rate": 1.8, "slow": 0.45, "slow_dur": 2.2},
				# Stun én vertraging: de stun verzwakt bij herhaald gebruik op hetzelfde
				# doel (STUN_FALLOFF), dus zonder de slow erbij zou lvl 3 een doelwit
				# minder ophouden dan lvl 2 — en dat mag nooit.
				{"name": "Noise Cancelling", "flavour": "Blissful silence.", "cost": 35, "range": 142.0, "rate": 1.6, "stun": 3.2, "slow": 0.40, "slow_dur": 3.0},
			],
		},
		"filter": {
			"name": "The Shredder", "role": "area", "color": Color(0.35, 0.7, 0.7),
			"desc": "Zone that slows everything inside it. Its damage is shared out over everyone in the zone, so it holds swarms up rather than deleting them.",
			"levels": [
				{"name": "Wastebasket", "flavour": "Round filing.", "cost": 30, "range": 95.0, "dot": 2.0, "slow": 0.6},
				{"name": "Paper Shredder", "flavour": "Cross-cut, obviously.", "cost": 30, "range": 110.0, "dot": 5.0, "slow": 0.5},
				{"name": "Industrial Shredder", "flavour": "Nothing leaves this room intact.", "cost": 50, "range": 125.0, "dot": 11.0, "slow": 0.4},
			],
		},
		"trap": {
			"name": "Thumbtacks", "role": "trap", "color": Color(0.8, 0.7, 0.35),
			"desc": "Lays a tack trap on the path. Spikes enemies that step on it.",
			"levels": [
				# Strooit punaises op de baan: elke throw_interval gooit hij er één (projectiel)
				# naar een WILLEKEURIGE tegel op het pad binnen bereik. Start op 0 en blijft gooien.
				# Elke punaise heeft een leeftijd (lifetime); is hij te oud en niet gebruikt, dan
				# roest hij weg. Zo liggen er bij lvl 1 gemiddeld ~3, bij lvl 2 ~5 tegelijk. Een
				# vijand die over een punaise loopt krijgt 'damage' en verbruikt 'm. lvl 3: je kiest
				# zelf de tegel waar hij naartoe gooit (concentreert de punaises daar).
				{"name": "Loose Tacks", "flavour": "Watch your step.", "cost": 22, "range": 120.0, "damage": 2.0, "throw_interval": 1.5, "lifetime": 4.5},
				{"name": "Spilled Box", "flavour": "Someone knocked the box over.", "cost": 24, "range": 126.0, "damage": 3.0, "throw_interval": 1.4, "lifetime": 7.0},
				{"name": "Tack Carpet", "flavour": "The whole floor. Every step.", "cost": 40, "range": 132.0, "damage": 4.0, "throw_interval": 1.3, "lifetime": 7.8, "pick_spot": true},
			],
		},
		"scrum": {
			"name": "Motivational Poster", "role": "support", "color": Color(0.7, 0.55, 0.85),
			"desc": "Buffs the nearest towers in range (damage, speed, range). Works the moment you place it; click a tower to choose different ones.",
			"levels": [
				{"name": "Hang In There", "flavour": "A cat. A branch. A message.", "cost": 25, "range": 130.0, "buff_dmg": 1.2, "buff_rate": 0.92, "buff_range": 1.03, "targets": 1},
				{"name": "Framed Print", "flavour": "Now it has a frame. It is serious.", "cost": 28, "range": 140.0, "buff_dmg": 1.45, "buff_rate": 0.84, "buff_range": 1.06, "targets": 2},
				{"name": "LED Wall", "flavour": "Synergy. In 4K. On loop.", "cost": 45, "range": 150.0, "buff_dmg": 1.8, "buff_rate": 0.72, "buff_range": 1.09, "targets": 3},
			],
		},
		"chain": {
			"name": "Delegation", "role": "chain", "color": Color(0.95, 0.85, 0.30),
			"desc": "Passes the problem along, and every hop hits HARDER than the last - it keeps going further up the chain. Nearly useless on a lone target, brutal in a tight crowd.",
			"levels": [
				# damage = eerste treffer; elke sprong daarna is damage × falloff. jumps = extra
				# sprongen, chain_range = hoe ver hij nog naar de volgende vijand mag springen.
				#
				# falloff staat BOVEN 1.0: elke sprong slaat harder. Stond op 0.70-0.80 (elke
				# sprong zwakker), en dan was deze toren tegen groepen slechter dan Self-Service
				# (die kost 8 Coffee minder en deed 26% meer) en tegen één doel slechter dan
				# Artillery. Hij zat dus nergens in een eigen vak. Nu is de grondschade laag en
				# telt alleen hoe vol het pad staat, en dat is meteen de betere kantoorgrap:
				# escaleren maakt het erger, niet minder erg. Zie 06_SYSTEEM_AUDIT.md §4.1.
				{"name": "Delegate", "flavour": "Can you take this one?", "cost": 28, "range": 150.0, "rate": 1.0, "damage": 2.0, "jumps": 1, "chain_range": 90.0, "falloff": 1.25},
				{"name": "Escalate", "flavour": "I\'m looping in my manager.", "cost": 30, "range": 158.0, "rate": 0.9, "damage": 2.5, "jumps": 2, "chain_range": 95.0, "falloff": 1.30},
				{"name": "Company Policy", "flavour": "It now applies to everyone.", "cost": 48, "range": 165.0, "rate": 0.8, "damage": 3.0, "jumps": 4, "chain_range": 100.0, "falloff": 1.35},
			],
		},
		"machinegun": {
			"name": "Quick Reply", "role": "damage", "color": Color(0.55, 0.60, 0.68),
			"desc": "Fast, tiny replies. Shorter and faster each level. Chews through weak swarms, but the hits are far too light to dent a shield.",
			"levels": [
				{"name": "\"Got it\"", "flavour": "Two words. Efficient.", "cost": 16, "range": 115.0, "rate": 0.13, "damage": 0.5},
				{"name": "\"OK\"", "flavour": "Down to two letters.", "cost": 20, "range": 120.0, "rate": 0.10, "damage": 0.9},
				{"name": "Thumbs-Up", "flavour": "No words left. Just the emoji.", "cost": 35, "range": 125.0, "rate": 0.075, "damage": 1.6},
			],
		},
		"multishot": {
			"name": "Self-Service", "role": "multi", "color": Color(0.90, 0.55, 0.25),
			"desc": "Deflects several distractions at once. Great vs crowds.",
			"levels": [
				# shots = aantal doelen per salvo (2 → 5 → 8). Slecht tegen één sterk doel.
				{"name": "Send the FAQ", "flavour": "It\'s all in there. Probably.", "cost": 25, "range": 125.0, "rate": 0.9, "damage": 1.5, "shots": 2},
				{"name": "Send the Wiki", "flavour": "Fourth link, third heading.", "cost": 28, "range": 132.0, "rate": 0.8, "damage": 2.5, "shots": 5},
				{"name": "Send to Service Desk", "flavour": "They\'ll get back to you. Eventually.", "cost": 45, "range": 140.0, "rate": 0.7, "damage": 4.0, "shots": 8},
			],
		},
		"pomodoro": {
			"name": "Pomodoro Timer", "role": "burst", "color": Color(0.9, 0.35, 0.3),
			"desc": "Charges up, then unleashes one big AoE burst on everything in range.",
			"levels": [
				# rate = laadtijd (sec); damage = burst-klap op iedereen in bereik. Loont een druk pad.
				{"name": "Pomodoro Timer", "flavour": "25 minutes. Go.", "cost": 26, "range": 130.0, "rate": 4.0, "damage": 6.0},
				{"name": "Focus Sprint", "flavour": "Do not disturb.", "cost": 28, "range": 138.0, "rate": 3.5, "damage": 12.0},
				{"name": "Deep Work", "flavour": "In the zone.", "cost": 45, "range": 145.0, "rate": 3.0, "damage": 22.0},
			],
		},
		"splash": {
			"name": "Reply All", "role": "splash", "color": Color(0.3, 0.7, 0.55),
			"desc": "Hits one target and splashes everyone around it. The splash moves with the target.",
			"levels": [
				{"name": "Reply All", "flavour": "You didn\'t need to reply all.", "cost": 26, "range": 135.0, "rate": 1.1, "damage": 2.0, "splash_radius": 45.0, "splash_falloff": 0.60},
				{"name": "CC the Team", "flavour": "+12 people who don\'t care.", "cost": 28, "range": 142.0, "rate": 1.0, "damage": 3.5, "splash_radius": 52.0, "splash_falloff": 0.65},
				{"name": "Company-Wide Email", "flavour": "To: everyone@. Regards.", "cost": 45, "range": 150.0, "rate": 0.9, "damage": 6.0, "splash_radius": 60.0, "splash_falloff": 0.70},
			],
		},
		# --- Specials: gedeelde regels — max 1 per level, geen upgrade-levels, één sterk effect.
		"keyboard": {
			"name": "Keyboard Smash", "role": "smash", "color": Color(0.4, 0.42, 0.5),
			"desc": "SPECIAL: slams the path for big AoE, then blocks it like a barrier. Max 1.",
			"special": true, "on_path": true,
			"levels": [
				# range = de klap-straal. Slaat toe zodra er een vijand in bereik is, doet AoE-schade
				# aan iedereen eromheen en blokkeert daarna het pad (barrier) een paar seconden.
				{"name": "Keyboard Smash", "flavour": "AAAAARGH.", "cost": 60, "range": 90.0, "smash_damage": 14.0, "smash_cooldown": 6.0, "barrier": 2.5},
			],
		},
		"ctrlaltdel": {
			"name": "Ctrl+Alt+Del", "role": "forcequit", "color": Color(0.75, 0.3, 0.75),
			"desc": "SPECIAL: charges over the level, then force-quits the strongest distraction on screen. One use. Max 1.",
			"special": true,
			"levels": [
				# charge = laadtijd (sec). Vol → force-quit (instakill) de vijand met de meeste HP. Eenmalig.
				{"name": "Ctrl+Alt+Del", "flavour": "Not responding.", "cost": 60, "range": 180.0, "charge": 32.0},
			],
		},
	}

func configure(id: String, lvl: int) -> void:
	def_id = id
	var d: Dictionary = defs()[id]
	# Clamp naar het aantal levels: specials (bv. Keyboard Smash) hebben er maar één.
	level = clampi(lvl, 1, d["levels"].size())
	role = String(d["role"])
	var s: Dictionary = d["levels"][level - 1]
	range_radius = float(s.get("range", 130.0))
	fire_rate = float(s.get("rate", 1.0))
	damage = float(s.get("damage", 0.0))
	stun_dur = float(s.get("stun", 0.0))
	cc_slow = float(s.get("slow", 1.0))
	cc_slow_dur = float(s.get("slow_dur", 0.0))
	coffee_amount = int(s.get("coffee_amount", 0))
	coffee_interval = float(s.get("coffee_interval", 3.0))
	area_dot = float(s.get("dot", 0.0))
	area_slow = float(s.get("slow", 1.0))
	buff_dmg = float(s.get("buff_dmg", 1.0))
	buff_rate = float(s.get("buff_rate", 1.0))
	buff_range = float(s.get("buff_range", 1.0))
	max_targets = int(s.get("targets", 1))
	multi_shots = int(s.get("shots", 1))
	chain_jumps = int(s.get("jumps", 0))
	chain_range = float(s.get("chain_range", 90.0))
	chain_falloff = float(s.get("falloff", 0.75))
	# Standaard-targeting per tower (GDD §5.3): een stun of een sniper hoort op het
	# zwaarste doel te mikken, niet op het eerste het beste vodje dat langsloopt.
	# Alleen zetten zolang de speler niet zelf gekozen heeft — configure() draait ook
	# bij elke upgrade en mag die keuze niet overschrijven.
	if not target_mode_chosen:
		# Standaard "first" (verst op het pad): dat is wat spelers verwachten en wat je
		# meestal wilt. Was "closest", waardoor torens op de achterste vijand bleven hangen
		# terwijl de voorste doorliep (tester-feedback v0.71).
		target_mode = String(d.get("default_target", "first"))
	sees_hidden = bool(d.get("sees_hidden", false))
	if not sees_hidden:
		prefer_hidden = false
	throw_interval = float(s.get("throw_interval", 1.5))
	tack_lifetime = float(s.get("lifetime", 4.5))
	pick_spot = bool(s.get("pick_spot", false))
	splash_radius = float(s.get("splash_radius", 0.0))
	splash_falloff = float(s.get("splash_falloff", 0.6))
	charge_time = float(s.get("charge", 30.0))
	# Burst laadt op via fire_rate, force-quit via charge_time; bij plaatsing eerst vol laten laden.
	if role == "burst" and _cooldown <= 0.0:
		_cooldown = fire_rate
	if role == "forcequit" and _cooldown <= 0.0:
		_cooldown = charge_time
	is_special = bool(d.get("special", false))
	on_path = bool(d.get("on_path", false))
	smash_damage = float(s.get("smash_damage", 0.0))
	smash_cooldown = float(s.get("smash_cooldown", 6.0))
	barrier_duration = float(s.get("barrier", 2.5))
	if role == "smash":
		_smash_cd = smash_cooldown
	if role == "trap":
		# trap_pos is de doeltegel voor lvl 3 (default = dichtstbijzijnde pad-punt tot je kiest).
		# Alleen zetten zolang de speler niet zelf koos — configure() draait ook bij elke upgrade.
		if not trap_pos_chosen:
			trap_pos = _tile(_closest_path_point())
	level_name = String(s.get("name", String(d["name"])))
	level_flavour = String(s.get("flavour", ""))
	_apply_art()
	queue_redraw()

func _trap_lanes() -> Array:
	# Alle lanes (multi-path); bij één pad is dat gewoon dat ene pad.
	return trap_paths if not trap_paths.is_empty() else [trap_path]

func _closest_path_point() -> Vector2:
	var best: Vector2 = position
	var best_d: float = INF
	for lane in _trap_lanes():
		for i in range(lane.size() - 1):
			var a: Vector2 = lane[i]
			var b: Vector2 = lane[i + 1]
			var ab: Vector2 = b - a
			var t: float = 0.0
			if ab.length_squared() > 0.0:
				t = clampf((position - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var pt: Vector2 = a + ab * t
			var dd: float = position.distance_to(pt)
			if dd < best_d:
				best_d = dd
				best = pt
	return best

func _tile(p: Vector2) -> Vector2:
	# Snap naar het midden van een tegel (GRID = 40 in level.gd): elke punaise op één blokje.
	return (p / 40.0).floor() * 40.0 + Vector2(20.0, 20.0)

func _random_path_point_in_range() -> Vector2:
	# Verzamel tegelplekken op het pad binnen bereik en kies er willekeurig één.
	var r: float = range_radius * buff_range_mult
	var cands: Array = []
	for lane in _trap_lanes():
		for i in range(lane.size() - 1):
			var a: Vector2 = lane[i]
			var b: Vector2 = lane[i + 1]
			var seg: float = a.distance_to(b)
			var steps: int = maxi(1, int(seg / 40.0))
			for s in steps + 1:
				var pt: Vector2 = a.lerp(b, float(s) / float(steps))
				if position.distance_to(pt) <= r:
					var tl: Vector2 = _tile(pt)
					if not cands.has(tl):
						cands.append(tl)
	if cands.is_empty():
		return Vector2.ZERO
	return cands[randi() % cands.size()]

# Zet de doeltegel (lvl 3) op een door de speler gekozen punt, begrensd tot binnen bereik.
func set_trap_spot(p: Vector2) -> bool:
	if position.distance_to(p) > range_radius * buff_range_mult:
		return false
	trap_pos = _tile(p)
	trap_pos_chosen = true
	queue_redraw()
	return true

func clear_tacks_near(p: Vector2, r: float) -> void:
	# The Cleaner veegt punaises weg die hij passeert.
	if _tacks_list.is_empty():
		return
	var keep: Array = []
	for tk in _tacks_list:
		if Vector2(tk["pos"]).distance_to(p) > r:
			keep.append(tk)
	if keep.size() != _tacks_list.size():
		_tacks_list = keep
		queue_redraw()

func _apply_art() -> void:
	# Per upgrade-level een eigen sprite: art/towers/<def_id>_<level>.png.
	# Valt terug op art/towers/<def_id>.png, en anders op de getekende vorm.
	var path := "res://art/towers/%s_%d.png" % [def_id, level]
	if not ResourceLoader.exists(path):
		path = "res://art/towers/%s.png" % def_id
	if ResourceLoader.exists(path):
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.z_index = 1
			add_child(sprite)
		var tex: Texture2D = load(path)
		sprite.texture = tex
		var dim: float = float(maxi(tex.get_width(), tex.get_height()))
		if dim > 0.0:
			sprite.scale = Vector2.ONE * (38.0 / dim)
		use_sprite = true
	else:
		use_sprite = false
		if sprite != null:
			sprite.visible = false

func _process(delta: float) -> void:
	match role:
		"economy":
			_coffee_timer += delta
			queue_redraw()          # bubbels blijven pruttelen
			if _coffee_timer >= coffee_interval:
				_coffee_timer = 0.0
				if on_coffee.is_valid():
					on_coffee.call(coffee_amount)
		"support":
			pass
		"smash":
			# Slaat toe zodra hij scherp is én er een vijand in bereik komt: AoE-schade rondom,
			# en daarna ligt het toetsenbord er als slagboom (level.gd blokkeert dan de vijanden).
			if barrier_active:
				_barrier_timer -= delta
				if _barrier_timer <= 0.0:
					barrier_active = false
					_smash_cd = smash_cooldown
					queue_redraw()
			else:
				_smash_cd -= delta
				if _smash_cd <= 0.0 and get_enemies.is_valid():
					var hit_any := false
					for e in get_enemies.call():
						if not is_instance_valid(e):
							continue
						if position.distance_to(e.position) <= range_radius:
							e.call("take_damage", smash_damage * buff_dmg_mult)
							if on_damage.is_valid():
								on_damage.call(def_id, smash_damage * buff_dmg_mult)
							hit_any = true
					if hit_any:
						barrier_active = true
						_barrier_timer = barrier_duration
						if on_smash.is_valid():
							on_smash.call(position)
						queue_redraw()
		"trap":
			# Passief en fysiek: silence (Kletskous) doet er niets aan. Gooit elke throw_interval
			# een punaise naar een willekeurige tegel op het pad (lvl 3: naar de gekozen tegel).
			# Punaises verouderen en roesten weg; een vijand die eroverheen loopt verbruikt ze.
			_throw_timer -= delta
			if _throw_timer <= 0.0:
				_throw_timer = throw_interval
				var target: Vector2 = trap_pos if pick_spot else _random_path_point_in_range()
				if target != Vector2.ZERO:
					_tacks_list.append({"pos": target, "age": 0.0})
					if on_throw.is_valid():
						on_throw.call(position, target)
					queue_redraw()
			if not _tacks_list.is_empty():
				var enemies: Array = get_enemies.call() if get_enemies.is_valid() else []
				var keep: Array = []
				for tk in _tacks_list:
					tk["age"] = float(tk["age"]) + delta
					if float(tk["age"]) > tack_lifetime:
						continue        # verouderd → weg
					var hit := false
					for e in enemies:
						if is_instance_valid(e) and e.hp > 0.0 and Vector2(tk["pos"]).distance_to(e.position) <= trap_radius:
							e.call("take_damage", damage * buff_dmg_mult)
							if on_damage.is_valid():
								on_damage.call(def_id, damage * buff_dmg_mult)
							hit = true
							break
					if not hit:
						keep.append(tk)
				if keep.size() != _tacks_list.size():
					queue_redraw()
				_tacks_list = keep
		"area":
			if get_enemies.is_valid() and not suppressed:
				var r: float = range_radius * buff_range_mult
				var in_zone: Array = []
				for e in get_enemies.call().duplicate():
					if not is_instance_valid(e):
						continue
					if position.distance_to(e.position) <= r:
						in_zone.append(e)
				# De zone heeft een VAST schadebudget dat over iedereen erin wordt verdeeld
				# (playtest-feedback v0.68: per vijand volle schade maakte hem een
				# swarm-verdelger die alle andere torens overbodig maakte). Tegen één doel
				# doet hij nog steeds alles; tegen tien doet hij een tiende per stuk. Zijn
				# rol is nu vertragen, en de damage-torens maken het af.
				var share: float = 1.0 / float(maxi(1, in_zone.size()))
				for e in in_zone:
					if e.invisible and not e.revealed:
						e.call("reveal")
					e.call("apply_slow", area_slow, 0.3)
					# zone_mult: papier gaat er extra hard doorheen (1.6), een archief met
					# bewaarplicht helemaal niet (0.0).
					var amt: float = area_dot * share * buff_dmg_mult * e.zone_mult * delta
					e.call("take_damage", amt)
					if on_damage.is_valid():
						on_damage.call(def_id, amt)
		"stun":
			if not silenced:
				_cooldown -= delta
				if _cooldown <= 0.0:
					var t := _find_target()
					if t != null:
						if stun_dur > 0.0:
							t.call("apply_stun", stun_dur, level)
						if cc_slow < 1.0:
							t.call("apply_slow", cc_slow, cc_slow_dur)
						_cooldown = fire_rate * buff_rate_mult * disrupt_rate_mult
						_flash(t)
		"multi":
			# Salvo: raakt tot multi_shots doelen tegelijk. Slecht tegen één sterk doel,
			# sterk tegen groepen.
			if not silenced:
				_cooldown -= delta
				if _cooldown <= 0.0:
					var targets: Array = _find_targets(multi_shots)
					if not targets.is_empty():
						for e in targets:
							e.call("take_damage", damage * buff_dmg_mult)
							if on_damage.is_valid():
								on_damage.call(def_id, damage * buff_dmg_mult)
							if on_fire.is_valid():
								on_fire.call(position, e.position, def_id, role)
						_cooldown = fire_rate * buff_rate_mult * disrupt_rate_mult
						_shot_time = 0.09
		"chain":
			# Schot springt van vijand naar vijand (chain_range), met schade-afname per sprong.
			if not silenced:
				_cooldown -= delta
				if _cooldown <= 0.0:
					if _chain_fire():
						_cooldown = fire_rate * buff_rate_mult * disrupt_rate_mult
		"burst":
			# Pomodoro: laadt op (fire_rate = laadtijd), lost dan één AoE-klap op alles in bereik.
			if not silenced:
				_cooldown -= delta
				if _cooldown <= 0.0:
					var r: float = range_radius * buff_range_mult
					var first: Node2D = null
					var hit_any := false
					if get_enemies.is_valid():
						for e in get_enemies.call().duplicate():
							if not is_instance_valid(e):
								continue
							if position.distance_to(e.position) <= r and _los_clear(e.position):
								e.call("take_damage", damage * buff_dmg_mult)
								if on_damage.is_valid():
									on_damage.call(def_id, damage * buff_dmg_mult)
								if first == null:
									first = e
								hit_any = true
					_cooldown = fire_rate * buff_rate_mult * disrupt_rate_mult
					if hit_any:
						_shot_time = 0.15
						if on_fire.is_valid() and first != null:
							on_fire.call(position, first.position, def_id, role)
					queue_redraw()
		"splash":
			# Reply All: raakt één doel + splash-schade rondom dat doel (beweegt mee met het doel).
			if not silenced:
				_cooldown -= delta
				if _cooldown <= 0.0:
					var t := _find_target()
					if t != null:
						var center: Vector2 = t.position
						if get_enemies.is_valid():
							for e in get_enemies.call():
								if not is_instance_valid(e):
									continue
								if center.distance_to(e.position) <= splash_radius:
									var amt: float = damage * buff_dmg_mult * (1.0 if e == t else splash_falloff)
									e.call("take_damage", amt)
									if on_damage.is_valid():
										on_damage.call(def_id, amt)
						_cooldown = fire_rate * buff_rate_mult * disrupt_rate_mult
						_flash(t)
		"forcequit":
			# Ctrl+Alt+Del: laadt op (charge_time), force-quit dan de vijand met de meeste HP. Eenmalig;
			# is er nog geen doel, dan blijft hij scherp staan tot er iemand verschijnt.
			if not _spent:
				_cooldown -= delta
				queue_redraw()
				if _cooldown <= 0.0:
					var best: Node2D = null
					var best_hp: float = -1.0
					if get_enemies.is_valid():
						for e in get_enemies.call():
							if is_instance_valid(e) and e.hp > best_hp:
								best_hp = e.hp
								best = e
					if best != null:
						best.call("take_damage", 99999.0)
						if on_damage.is_valid():
							on_damage.call(def_id, 99999.0)
						_spent = true
						_shot_time = 0.3
						if on_fire.is_valid():
							on_fire.call(position, best.position, def_id, role)
		_:  # damage
			if not silenced:
				_cooldown -= delta
				if _cooldown <= 0.0:
					var t := _find_target()
					if t != null:
						t.call("take_damage", damage * buff_dmg_mult)
						if on_damage.is_valid():
							on_damage.call(def_id, damage * buff_dmg_mult)
						_cooldown = fire_rate * buff_rate_mult * disrupt_rate_mult
						_flash(t)
	if _shot_time > 0.0:
		_shot_time -= delta
		queue_redraw()

func _flash(t: Node2D) -> void:
	_shot_time = 0.09   # korte terugstoot op de toren zelf
	if on_fire.is_valid():
		on_fire.call(position, t.position, def_id, role)

func _find_target() -> Node2D:
	if not get_enemies.is_valid():
		return null
	var r: float = range_radius * buff_range_mult
	var best: Node2D = null
	var best_score: float = -INF
	for e in get_enemies.call():
		if not is_instance_valid(e):
			continue
		if e.immune_to == def_id:
			continue
		# Een stun-tower die te laag is voor dit doelwit mikt liever op iets anders dan
		# zijn schoten te verspillen aan iemand die er niets van merkt.
		if role == "stun" and e.cc_immune_below > 0 and level < e.cc_immune_below:
			continue
		if e.invisible and not e.revealed and not sees_hidden:
			continue
		var d: float = position.distance_to(e.position)
		if d > r:
			continue
		if not _los_clear(e.position):
			continue
		var score: float = _target_score(e, d)
		if score > best_score:
			best_score = score
			best = e
	return best

func _target_score(e: Node2D, d: float) -> float:
	# De gekozen targeting-stand als getal; hoger = liever. De voorkeur voor onzichtbaren
	# ligt erbovenop (binnen die groep geldt first/last/closest nog steeds).
	var score: float = 0.0
	match target_mode:
		"first": score = e.progress()          # het verst op het pad
		"last": score = -e.progress()          # net binnengekomen
		"farthest": score = d
		"least_hp": score = -e.hp
		"most_hp": score = e.hp
		_: score = -d  # closest
	if e.aggro:
		score += 500000.0   # Phone Caller trekt de aandacht: single-target torens mikken éérst op hem
	if prefer_hidden and e.invisible:
		score += 1000000.0
	return score

func _valid_targets() -> Array:
	# Alle geldige vijanden binnen bereik (zonder de stun-specifieke filter; multi/chain
	# zijn schade-torens).
	var out: Array = []
	if not get_enemies.is_valid():
		return out
	var r: float = range_radius * buff_range_mult
	for e in get_enemies.call():
		if not is_instance_valid(e):
			continue
		if e.immune_to == def_id:
			continue
		if e.invisible and not e.revealed and not sees_hidden:
			continue
		if position.distance_to(e.position) <= r and _los_clear(e.position):
			out.append(e)
	return out

func _los_clear(target: Vector2) -> bool:
	# Vals als er een zicht-muur tussen de toren en het doel zit (line-of-sight geblokkeerd).
	if not get_walls.is_valid():
		return true
	for w in get_walls.call():
		if _seg_hits_rect(position, target, w):
			return false
	return true

func _seg_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b):
		return true
	var c0: Vector2 = r.position
	var c1: Vector2 = Vector2(r.end.x, r.position.y)
	var c2: Vector2 = r.end
	var c3: Vector2 = Vector2(r.position.x, r.end.y)
	return (Geometry2D.segment_intersects_segment(a, b, c0, c1) != null
		or Geometry2D.segment_intersects_segment(a, b, c1, c2) != null
		or Geometry2D.segment_intersects_segment(a, b, c2, c3) != null
		or Geometry2D.segment_intersects_segment(a, b, c3, c0) != null)

func _find_targets(n: int) -> Array:
	# De n beste doelen volgens de gekozen targeting-stand (voor Multi-Shot).
	var cands: Array = _valid_targets()
	cands.sort_custom(func(a, b):
		return _target_score(a, position.distance_to(a.position)) > _target_score(b, position.distance_to(b.position)))
	if cands.size() > n:
		cands = cands.slice(0, n)
	return cands

func _nearest_unhit(from: Node2D, hit: Array) -> Node2D:
	# Dichtstbijzijnde nog-niet-geraakte vijand binnen chain_range (voor Chain Shot).
	if not get_enemies.is_valid():
		return null
	var best: Node2D = null
	var best_d: float = chain_range
	for e in get_enemies.call():
		if not is_instance_valid(e) or hit.has(e):
			continue
		if e.immune_to == def_id:
			continue
		if e.invisible and not e.revealed and not sees_hidden:
			continue
		var d: float = from.position.distance_to(e.position)
		if d <= best_d:
			best_d = d
			best = e
	return best

func _chain_fire() -> bool:
	# Raak het eerste doel, spring dan chain_jumps keer door naar de dichtstbijzijnde
	# volgende vijand; schade neemt per sprong af met chain_falloff.
	var first := _find_target()
	if first == null:
		return false
	var hit: Array = [first]
	var dmg: float = damage * buff_dmg_mult
	first.call("take_damage", dmg)
	if on_damage.is_valid():
		on_damage.call(def_id, dmg)
	_flash(first)
	var last: Node2D = first
	for j in chain_jumps:
		var nxt := _nearest_unhit(last, hit)
		if nxt == null:
			break
		dmg *= chain_falloff
		nxt.call("take_damage", dmg)
		if on_damage.is_valid():
			on_damage.call(def_id, dmg)
		if on_fire.is_valid():
			on_fire.call(last.position, nxt.position, def_id, role)
		hit.append(nxt)
		last = nxt
	return true

func _draw() -> void:
	var col: Color = defs()[def_id]["color"]
	if role == "area":
		draw_circle(Vector2.ZERO, range_radius * buff_range_mult, Color(col.r, col.g, col.b, 0.12))
		draw_arc(Vector2.ZERO, range_radius * buff_range_mult, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.5), 1.5)
	elif role == "support":
		draw_arc(Vector2.ZERO, range_radius, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.25), 1.5)
	elif role == "damage" or role == "stun" or role == "multi" or role == "chain" or role == "burst" or role == "splash":
		draw_arc(Vector2.ZERO, range_radius * buff_range_mult, 0.0, TAU, 48, Color(1, 1, 1, 0.06), 1.0)
	if not use_sprite:
		draw_circle(Vector2.ZERO, 17.0, col)
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color(0, 0, 0, 0.4), 2.0)
	if role == "forcequit":
		# Laad-ring: hoe voller, hoe verder de boog. Verbruikt = gedimd kruisje.
		if _spent:
			draw_line(Vector2(-8, -8), Vector2(8, 8), Color(0.6, 0.4, 0.6, 0.7), 2.5)
			draw_line(Vector2(-8, 8), Vector2(8, -8), Color(0.6, 0.4, 0.6, 0.7), 2.5)
		else:
			var frac: float = clampf(1.0 - _cooldown / maxf(charge_time, 0.01), 0.0, 1.0)
			draw_arc(Vector2.ZERO, 22.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 32, Color(0.9, 0.55, 0.95, 0.9), 3.0)
	if silenced:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(0.85, 0.4, 0.4, 0.9), 2.0)
	for i in level:
		draw_circle(Vector2(-8.0 + i * 8.0, 0.0), 2.2, Color(1, 1, 1, 0.9))
	if _shot_time > 0.0:
		# korte flits op de toren zelf; het schot zelf is een projectiel in level.gd
		draw_circle(Vector2.ZERO, 20.0, Color(1, 1, 0.7, _shot_time * 2.0))
	if role == "economy":
		# Koffiebubbels: stijgen op en versnellen naarmate de volgende opbrengst nadert,
		# zodat je aan de toren ziet dat er zo iets komt.
		var fill: float = clampf(_coffee_timer / maxf(coffee_interval, 0.01), 0.0, 1.0)
		for i in 4:
			var t: float = fmod(fill * 1.5 + float(i) * 0.25, 1.0)
			var x: float = sin((t + float(i)) * 5.0) * 5.0
			draw_circle(Vector2(x, 2.0 - t * 26.0), (1.0 - t) * 4.0 + 1.2,
				Color(0.92, 0.80, 0.58, (1.0 - t) * 0.85))
