class_name Enemy
extends Node2D

# Data-driven vijand. Focus-schade bij doorbraak = resterende HP (schild telt niet mee).

signal died(enemy)
signal reached_end(enemy)
signal phase_changed(enemy, new_phase)

var type_id: String = "noti"
var max_hp: float = 3.0
var hp: float = 3.0
var speed: float = 90.0
var base_speed: float = 90.0
var coffee_reward: float = 3.0   # float: zwermvijanden moeten minder dan 1 op kunnen leveren
var focus_damage: int = 1     # vaste Focus-schade bij doorbraak
var color: Color = Color(0.9, 0.72, 0.3)
var radius: float = 11.0

var max_shield: float = 0.0
var shield: float = 0.0
var rage: float = 0.0                # snelheid neemt toe met opgelopen schade
var split_count: int = 0             # aantal kinderen bij dood
var split_type: String = ""
var disrupt_radius: float = 0.0      # verstoort towers in straal
var disrupt_mode: String = "silence" # "silence" of "slow"
var is_boss: bool = false
var invisible: bool = false          # niet targetbaar tot onthuld
var revealed: bool = false
var zone_mult: float = 1.0           # gevoeligheid voor area-zones (papier 1.6, archief 0.0)
var immune_to: String = ""           # def_id van tower waar 'ie immuun voor is
var sprite: Sprite2D = null
var use_sprite: bool = false

var slow_mult: float = 1.0
var slow_time: float = 0.0
var stun_time: float = 0.0

# Stun-weerstand. Zonder dit houdt één Headphones lvl 3 (stun 3.2s, cooldown 1.6s) elk
# doelwit permanent stil, ook de eindbaas. Elke stun op hetzelfde doelwit werkt korter;
# blijft het doelwit even ongemoeid, dan herstelt de weerstand.
const STUN_FALLOFF := 0.5      # elke volgende stun duurt de helft van de vorige
const STUN_FALLOFF_MIN := 0.15 # maar nooit korter dan dit deel van de volle duur
const STUN_RECOVER := 5.0      # seconden zonder stun voor volledig herstel
var stun_resist: float = 1.0   # type-eigen weerstand (bosses laag)
var cc_immune_below: int = 0   # stun van een tower onder dit level doet niets (0 = geen immuniteit)
var _stun_falloff: float = 1.0
var _stun_recover_timer: float = 0.0
var hazard_speed_mult: float = 1.0   # brandalarm: iedereen sprint
var aggro: bool = false               # Phone Caller: single-target torens richten éérst op hem
var _consultant_shielded: bool = false  # The Consultant heeft hem al één keer een schild gegeven
var update_interval: float = 0.0      # System Update: elke zoveel sec begint een 'installing'-fase
var update_dur: float = 0.0           # hoe lang 'installing' (onkwetsbaar) duurt
var _update_timer: float = 0.0
var installing: bool = false          # nu onkwetsbaar aan het 'updaten'
var blocked: bool = false            # Keyboard Smash-slagboom: staat stil zolang die ligt

var path: PackedVector2Array
var target_index: int = 1
var _dead: bool = false
var _walk: float = 0.0   # afgelegde weg, voedt de loopanimatie

# boss
var phase: int = 1
var boss_kind: String = ""
var menace: float = 0.0        # The Deadline: loopt op zolang hij leeft → bord-brede speed-up
var _add_timer: float = 4.0
var on_spawn_adds: Callable
# cameo (finale-review "360° feedback"): roept mini-versies van eerdere bosses op als peer reviewers.
var cameo: bool = false
var cameo_pool: Array = []
var _cameo_timer: float = 6.0
var on_spawn_cameo: Callable   # (pos, idx, boss_type) — level.gd spawnt een mini-cameo

# spawner (de printer): interval, wat er uit komt en hoeveel per keer
var spawn_interval: float = 0.0
var spawn_type: String = ""
var spawn_count: int = 0
var _spawn_timer: float = 0.0

static func defs() -> Dictionary:
	return {
		"noti":  {"name": "The Notification", "ability": "Plain and fast. No tricks.", "counter": "Any cheap damage tower. Auto-Reply is enough.",
			"hp": 4.0, "speed": 105.0, "reward": 0.8, "damage": 1, "radius": 11.0, "color": Color(0.9, 0.72, 0.3)},
		"hulp":  {"name": "The Question", "ability": "Tougher basic enemy.", "counter": "Auto-Reply, but upgrade it - level 1 is too slow for these.",
			"hp": 12.0, "speed": 80.0, "reward": 1.6, "damage": 2, "radius": 15.0, "color": Color(0.85, 0.4, 0.5)},
		"story": {"name": "User Story", "ability": "Heavy basic enemy.", "counter": "Sustained damage. Upgraded Auto-Reply or Quick Reply.",
			"hp": 26.0, "speed": 70.0, "reward": 2.8, "damage": 4, "radius": 18.0, "color": Color(0.8, 0.45, 0.7)},
		"tank":  {"name": "The Old Guard", "ability": "Shielded: break the shield first. Burst it down. That archive is legally required to be kept - the shredder won't touch it.", "counter": "Office Artillery. Only burst breaks the shield; chip damage bounces off.",
			"hp": 46.0, "speed": 50.0, "reward": 4.5, "damage": 8, "radius": 19.0, "color": Color(0.55, 0.55, 0.6), "shield": 30.0, "zone_mult": 0.0},
		"nudge": {"name": "The Nudge", "ability": "Very fast swarm. Needs area damage or slows.", "counter": "Area damage. A Shredder on the path slows the swarm so your towers can hit it.",
			"hp": 3.0, "speed": 190.0, "reward": 0.35, "damage": 1, "radius": 8.0, "color": Color(0.95, 0.85, 0.3)},
		"thread": {"name": "The Thread", "ability": "Arrives as one big printed pile. Paper - the shredder eats it.", "counter": "The Shredder. It is paper, and the zone slows the whole pile at once.",
			"hp": 2.0, "speed": 88.0, "reward": 0.3, "damage": 1, "radius": 9.0, "color": Color(0.88, 0.87, 0.82), "zone_mult": 1.6},
		"change":{"name": "The Change", "ability": "Splits into two Tasks when killed.", "counter": "Area damage - it splits when killed, so be ready for the halves.",
			"hp": 16.0, "speed": 80.0, "reward": 2.0, "damage": 3, "radius": 16.0, "color": Color(0.5, 0.7, 0.55), "split_count": 2, "split_type": "task"},
		"task":  {"name": "Task", "ability": "Small and quick. Spawned by The Change.", "counter": "Anything fast. They are weak but quick.",
			"hp": 4.0, "speed": 135.0, "reward": 0.4, "damage": 1, "radius": 9.0, "color": Color(0.5, 0.75, 0.6)},
		"micro": {"name": "The Micro-manager", "ability": "Speeds up the more damage it takes.", "counter": "Burst it down early, or stun it - it speeds up as it takes damage.",
			"hp": 20.0, "speed": 60.0, "reward": 2.5, "damage": 4, "radius": 15.0, "color": Color(0.9, 0.55, 0.2), "rage": 2.5},
		"kletskous": {"name": "The Chatterbox", "ability": "Silences nearby towers while passing. Shrugs off crowd control - only Noise Cancelling (Headphones lvl 3) shuts him up.", "counter": "Headphones level 3, or keep your towers off its route entirely.",
			"hp": 22.0, "speed": 75.0, "reward": 3.0, "damage": 5, "radius": 16.0, "color": Color(0.75, 0.6, 0.85), "disrupt": 95.0, "disrupt_mode": "silence", "cc_immune_below": 3},
		"feedback": {"name": "Feedback", "ability": "Spawned by the boss.", "counter": "Area damage near your desk; they spawn in from the boss.",
			"hp": 3.0, "speed": 120.0, "reward": 0.3, "damage": 1, "radius": 8.0, "color": Color(0.7, 0.6, 0.5)},
		# De printer: traag en taai, maar het echte probleem is wat er uit komt. Elke paar
		# seconden spuwt hij een foutmelding uit die zelfstandig doorloopt. Laat je hem te
		# lang leven, dan sta je tegen een file aan foutmeldingen te vechten in plaats van
		# tegen de printer.
		"printer": {"name": "The Printer", "ability": "Jams every few seconds and spits out Error messages. Kill it early or drown in them.", "counter": "Kill it fast, or stun it - a stunned printer stops spitting out Errors.",
			"hp": 34.0, "speed": 44.0, "reward": 4.0, "damage": 6, "radius": 19.0, "color": Color(0.62, 0.66, 0.72),
			"spawner": 3.4, "spawn_type": "error", "spawn_count": 2},
		"error": {"name": "Error Message", "ability": "Have you tried turning it off and on again? Spawned by The Printer.", "counter": "Area damage. They come in groups from the Printer.",
			"hp": 5.0, "speed": 118.0, "reward": 0.4, "damage": 1, "radius": 9.0, "color": Color(0.85, 0.75, 0.35)},
		"phish": {"name": "Suspicious Link", "ability": "Invisible until a Shredder zone reveals it.", "counter": "A Shredder zone reveals it. Nothing else can even see it.",
			"hp": 10.0, "speed": 100.0, "reward": 2.0, "damage": 3, "radius": 12.0, "color": Color(0.5, 0.85, 0.7), "invisible": true},
		"board": {"name": "The Board Member", "ability": "Immune to Office Artillery. Grind it down.", "counter": "Auto-Reply. Artillery does nothing - it is never physically there.",
			"hp": 40.0, "speed": 60.0, "reward": 3.5, "damage": 8, "radius": 18.0, "color": Color(0.4, 0.45, 0.55), "immune_to": "ceo"},
		"cold":  {"name": "The Cold Caller", "ability": "Immune to Auto-Reply. Needs burst.", "counter": "Office Artillery. Auto-Reply chip damage bounces off.",
			"hp": 24.0, "speed": 92.0, "reward": 3.0, "damage": 4, "radius": 15.0, "color": Color(0.7, 0.5, 0.35), "immune_to": "auto"},
		"caller": {"name": "The Phone Caller", "ability": "On a loud call. Single-target towers fire at him FIRST - and he can take it, so the rest slips by.", "counter": "Ignore the taunt: use area damage, or place single-target towers out of its reach.",
			"hp": 34.0, "speed": 86.0, "reward": 3.5, "damage": 5, "radius": 16.0, "color": Color(0.45, 0.7, 0.85), "aggro": true},
		"update": {"name": "System Update", "ability": "Installing... briefly invulnerable while it updates, then keeps coming. Burst it between updates.", "counter": "Burst it between updates - it is invulnerable while installing.",
			"hp": 30.0, "speed": 70.0, "reward": 3.2, "damage": 5, "radius": 16.0, "color": Color(0.4, 0.6, 0.9), "update_interval": 3.5, "update_dur": 1.5},
		"boss":  {"name": "The Performance Review", "ability": "3 phases: shield, spawns Feedback, then speeds up and slows your towers. Barely affected by stuns.",
			"hp": 420.0, "speed": 46.0, "reward": 40.0, "damage": 50, "radius": 30.0, "color": Color(0.8, 0.3, 0.35), "shield": 120.0, "boss": true, "boss_kind": "review", "boss_add": "feedback", "stun_resist": 0.3},
		# Finale-variant (L15): "360° feedback" — vanaf fase 2 keren eerdere bosses terug als
		# mini-"peer reviewers". "Do you feel stressed?" Zwaarder dan de gewone review.
		"boss360": {"name": "The Performance Review", "ability": "The final review. 360-degree feedback: past managers return as peer reviewers. Do you feel stressed?",
			"hp": 520.0, "speed": 46.0, "reward": 60.0, "damage": 50, "radius": 30.0, "color": Color(0.85, 0.28, 0.4), "shield": 140.0, "boss": true, "boss_kind": "review", "boss_add": "feedback", "stun_resist": 0.3,
			"cameo": true, "cameo_pool": ["allhands", "cleaner", "consultant", "smoking", "baby", "reorg"]},
		# Per-level eindbazen (laatste wave). boss_kind bepaalt de eigen mechaniek.
		"allhands": {"name": "The All-Hands Meeting", "ability": "This could have been an email. Keeps calling everyone in.",
			"hp": 160.0, "speed": 40.0, "reward": 22.0, "damage": 20, "radius": 26.0, "color": Color(0.85, 0.7, 0.35), "boss": true, "boss_kind": "allhands", "boss_add": "noti", "stun_resist": 0.6},
		"beamer": {"name": "The Broken Projector", "ability": "Shielded 'loading' screen - break it first. Beams slides at your desk.",
			"hp": 240.0, "speed": 42.0, "reward": 26.0, "damage": 24, "radius": 26.0, "color": Color(0.5, 0.55, 0.7), "shield": 90.0, "boss": true, "boss_kind": "beamer", "boss_add": "feedback", "stun_resist": 0.5},
		"outoforder": {"name": "Out of Order", "ability": "Here to 'repair' the coffee machine. No Coffee income while it lives.",
			"hp": 260.0, "speed": 52.0, "reward": 30.0, "damage": 28, "radius": 24.0, "color": Color(0.6, 0.45, 0.3), "boss": true, "boss_kind": "outoforder", "stun_resist": 0.5},
		"reorg": {"name": "The Reorganisation", "ability": "We're restructuring. Splits off a Manager at each phase.",
			"hp": 340.0, "speed": 48.0, "reward": 34.0, "damage": 34, "radius": 28.0, "color": Color(0.55, 0.6, 0.5), "boss": true, "boss_kind": "reorg", "boss_add": "change", "stun_resist": 0.5},
		"cleaner": {"name": "The Cleaner", "ability": "The janitor. Speeds up nearby distractions and sweeps away Shredder zones and tack traps.",
			"hp": 320.0, "speed": 54.0, "reward": 32.0, "damage": 30, "radius": 26.0, "color": Color(0.35, 0.6, 0.62), "boss": true, "boss_kind": "cleaner", "stun_resist": 0.5},
		# --- Blok 2 (medior) bosses ---
		"smoking": {"name": "The Smoking Colleague", "ability": "Takes a smoke break. The haze shortens every tower's range.",
			"hp": 360.0, "speed": 46.0, "reward": 34.0, "damage": 32, "radius": 27.0, "color": Color(0.5, 0.52, 0.5), "boss": true, "boss_kind": "smoking", "stun_resist": 0.5},
		"baby": {"name": "The Baby", "ability": "Demands all attention. Nearby towers get distracted and fire slower.",
			"hp": 300.0, "speed": 50.0, "reward": 32.0, "damage": 28, "radius": 24.0, "color": Color(0.92, 0.78, 0.7), "boss": true, "boss_kind": "baby", "stun_resist": 0.5},
		"floater": {"name": "The Floater", "ability": "No fixed desk. Keeps pulling in a crowd from every direction.",
			"hp": 320.0, "speed": 52.0, "reward": 34.0, "damage": 30, "radius": 26.0, "color": Color(0.6, 0.62, 0.7), "boss": true, "boss_kind": "floater", "boss_add": "nudge", "stun_resist": 0.5},
		# --- Blok 3 (senior) bosses ---
		"hrmanager": {"name": "The HR Manager", "ability": "Conducts audits: shuts down one of your tower types for a few seconds.",
			"hp": 380.0, "speed": 48.0, "reward": 38.0, "damage": 34, "radius": 26.0, "color": Color(0.6, 0.5, 0.65), "boss": true, "boss_kind": "hrmanager", "stun_resist": 0.45},
		"legacy": {"name": "The Legacy System", "ability": "Ancient and unkillable. Spews Error Messages the whole time.",
			"hp": 460.0, "speed": 38.0, "reward": 40.0, "damage": 40, "radius": 30.0, "color": Color(0.45, 0.5, 0.5), "boss": true, "boss_kind": "legacy", "boss_add": "error", "stun_resist": 0.6},
		"consultant": {"name": "The Consultant", "ability": "Buffs every other distraction (speed and shields). Kill it to weaken the wave.",
			"hp": 400.0, "speed": 50.0, "reward": 40.0, "damage": 36, "radius": 27.0, "color": Color(0.4, 0.55, 0.7), "boss": true, "boss_kind": "consultant", "stun_resist": 0.5},
		"deadline": {"name": "The Deadline", "ability": "The longer it lives, the faster EVERYTHING moves. Burst it fast.",
			"hp": 320.0, "speed": 56.0, "reward": 40.0, "damage": 38, "radius": 26.0, "color": Color(0.85, 0.3, 0.3), "boss": true, "boss_kind": "deadline", "stun_resist": 0.4},
	}

func configure(id: String) -> void:
	type_id = id
	var d: Dictionary = defs()[id]
	max_hp = float(d["hp"])
	hp = max_hp
	speed = float(d["speed"])
	base_speed = speed
	coffee_reward = float(d["reward"])
	focus_damage = int(d.get("damage", 1))
	radius = float(d["radius"])
	color = d["color"]
	max_shield = float(d.get("shield", 0.0))
	shield = max_shield
	rage = float(d.get("rage", 0.0))
	split_count = int(d.get("split_count", 0))
	split_type = String(d.get("split_type", ""))
	disrupt_radius = float(d.get("disrupt", 0.0))
	disrupt_mode = String(d.get("disrupt_mode", "silence"))
	aggro = bool(d.get("aggro", false))
	update_interval = float(d.get("update_interval", 0.0))
	update_dur = float(d.get("update_dur", 0.0))
	_update_timer = update_interval
	is_boss = bool(d.get("boss", false))
	boss_kind = String(d.get("boss_kind", ""))
	cameo = bool(d.get("cameo", false))
	cameo_pool = d.get("cameo_pool", [])
	invisible = bool(d.get("invisible", false))
	revealed = false
	zone_mult = float(d.get("zone_mult", 1.0))
	stun_resist = float(d.get("stun_resist", 1.0))
	cc_immune_below = int(d.get("cc_immune_below", 0))
	spawn_interval = float(d.get("spawner", 0.0))
	spawn_type = String(d.get("spawn_type", ""))
	spawn_count = int(d.get("spawn_count", 0))
	# Eerste lading pas na een hele cyclus, zodat hij niet meteen bij het spawnpunt begint.
	_spawn_timer = spawn_interval
	_stun_falloff = 1.0
	immune_to = String(d.get("immune_to", ""))
	_apply_art()

func _apply_art() -> void:
	# Laadt art/enemies/<type_id>.png als die bestaat; anders fallback naar getekende vorm.
	var path := "res://art/enemies/%s.png" % type_id
	if ResourceLoader.exists(path):
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(sprite)
		var tex: Texture2D = load(path)
		sprite.texture = tex
		var dim: float = float(maxi(tex.get_width(), tex.get_height()))
		if dim > 0.0:
			sprite.scale = Vector2.ONE * ((radius * 2.4) / dim)
		use_sprite = true
	else:
		use_sprite = false
		if sprite != null:
			sprite.visible = false

func progress() -> float:
	# Hoe ver deze vijand op het pad is: hoger = dichter bij je bureau. Voor de
	# targeting-standen "First" en "Last", die kijken naar padpositie en niet naar
	# afstand tot de toren.
	if path.is_empty():
		return 0.0
	var p: float = float(target_index) * 1000.0
	if target_index < path.size():
		p -= position.distance_to(path[target_index])
	return p

func reveal() -> void:
	if invisible and not revealed:
		revealed = true
		queue_redraw()

func setup(p: PackedVector2Array) -> void:
	path = p
	position = p[0]
	target_index = 1
	queue_redraw()

func setup_at(p: PackedVector2Array, pos: Vector2, idx: int) -> void:
	path = p
	position = pos
	target_index = clampi(idx, 1, max(1, p.size() - 1))
	queue_redraw()

func apply_stun(duration: float, source_level: int = 3) -> void:
	# De Kletskous laat zich alleen door Active Noise Cancelling het zwijgen opleggen
	# (GDD §6); lagere Headphones ketsen af.
	if cc_immune_below > 0 and source_level < cc_immune_below:
		return
	var effective: float = duration * stun_resist * _stun_falloff
	if effective <= 0.05:
		return
	stun_time = maxf(stun_time, effective)
	_stun_falloff = maxf(STUN_FALLOFF_MIN, _stun_falloff * STUN_FALLOFF)
	_stun_recover_timer = STUN_RECOVER

func apply_slow(mult: float, duration: float) -> void:
	slow_mult = minf(slow_mult, mult)
	slow_time = maxf(slow_time, duration)

func _current_speed() -> float:
	if blocked:
		return 0.0            # tegen de slagboom: geen stap verder
	var s: float = base_speed
	if rage > 0.0:
		s *= 1.0 + rage * (1.0 - hp / max_hp)
	if is_boss and phase >= 3:
		s *= 1.8
	if slow_time > 0.0:
		s *= slow_mult
	s *= hazard_speed_mult
	return s

func _process(delta: float) -> void:
	if _dead or path.is_empty():
		return
	if is_boss:
		_boss_update(delta)
	elif spawn_interval > 0.0:
		_spawner_update(delta)
	# System Update: wisselt tussen normaal en 'installing' (onkwetsbaar). Blijft doorlopen.
	if update_interval > 0.0:
		_update_timer -= delta
		if _update_timer <= 0.0:
			installing = not installing
			_update_timer = update_dur if installing else update_interval
			queue_redraw()
	if slow_time > 0.0:
		slow_time -= delta
	if slow_time <= 0.0:
		slow_mult = 1.0
	if _stun_falloff < 1.0:
		_stun_recover_timer -= delta
		if _stun_recover_timer <= 0.0:
			_stun_falloff = 1.0
	if stun_time > 0.0:
		stun_time -= delta
		queue_redraw()
		return
	if target_index >= path.size():
		_reach_end()
		return
	var target: Vector2 = path[target_index]
	var to_target: Vector2 = target - position
	var dist: float = to_target.length()
	var step: float = _current_speed() * delta
	if step >= dist:
		position = target
		target_index += 1
		if target_index >= path.size():
			_reach_end()
			return
	else:
		position += to_target / dist * step
	# Loopwiebel: kost geen nieuwe art, maar haalt de statischheid eruit. De fase hangt
	# af van de afgelegde weg, dus wie sneller loopt, wiebelt sneller.
	_walk += step
	if sprite != null:
		sprite.rotation = sin(_walk * 0.09) * 0.10
		sprite.position.y = -absf(sin(_walk * 0.18)) * 1.5
	queue_redraw()

func _spawner_update(delta: float) -> void:
	# Stilgezet telt niet: een gestunte printer print ook niet. Dat maakt de Headphones een
	# echte counter tegen hem, naast hem gewoon neerschieten.
	if stun_time > 0.0:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		if on_spawn_adds.is_valid():
			on_spawn_adds.call(position, target_index, spawn_count)

func _boss_update(delta: float) -> void:
	# Algemene HP-fases (66% / 33%). phase_changed stuurt de per-boss reacties in level.gd.
	var ratio: float = hp / max_hp
	var new_phase: int = 1
	if ratio <= 0.33:
		new_phase = 3
	elif ratio <= 0.66:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(self, phase)
	# Per-boss mechaniek.
	match boss_kind:
		"review":
			# Vanaf fase 2 periodiek feedback-adds.
			if phase >= 2:
				_add_timer -= delta
				if _add_timer <= 0.0:
					_add_timer = 4.5
					_boss_spawn(3)
			# Finale ("360° feedback"): roept vanaf fase 2 mini-versies van eerdere bosses op.
			if cameo and phase >= 2 and not cameo_pool.is_empty():
				_cameo_timer -= delta
				if _cameo_timer <= 0.0:
					_cameo_timer = 6.0
					if on_spawn_cameo.is_valid():
						on_spawn_cameo.call(position, target_index, String(cameo_pool[randi() % cameo_pool.size()]))
		"allhands":
			# Roept doorlopend een paar Notificaties erbij.
			_add_timer -= delta
			if _add_timer <= 0.0:
				_add_timer = 5.0
				_boss_spawn(2)
		"beamer":
			# "No Signal": beamt periodiek een zwerm slides naar je bureau.
			_add_timer -= delta
			if _add_timer <= 0.0:
				_add_timer = 5.0
				_boss_spawn(4)
		"floater":
			# Trekt doorlopend een groepje erbij (multi-path volgt later).
			_add_timer -= delta
			if _add_timer <= 0.0:
				_add_timer = 4.5
				_boss_spawn(3)
		"legacy":
			# Spuwt doorlopend Error Messages uit (Printer op boss-schaal).
			_add_timer -= delta
			if _add_timer <= 0.0:
				_add_timer = 3.2
				_boss_spawn(2)
		"deadline":
			# Menace loopt op zolang hij leeft; level.gd versnelt hiermee álle vijanden.
			menace = minf(menace + delta * 0.05, 1.2)
		# "reorg" spawnt op de fase-wissel (in level.gd), "outoforder" heeft een aura (level.gd).

func _boss_spawn(n: int) -> void:
	if on_spawn_adds.is_valid():
		on_spawn_adds.call(position, target_index, n)

func take_damage(amount: float) -> void:
	if _dead:
		return
	if installing:
		queue_redraw()   # System Update: onkwetsbaar zolang hij 'updatet'
		return
	if shield > 0.0:
		var over: float = amount - shield
		shield = maxf(0.0, shield - amount)
		if over > 0.0:
			hp -= over
	else:
		hp -= amount
	if hp <= 0.0:
		_dead = true
		died.emit(self)
		queue_free()
	else:
		queue_redraw()

func _reach_end() -> void:
	if _dead:
		return
	_dead = true
	reached_end.emit(self)
	queue_free()

func _draw() -> void:
	var a: float = 0.35 if (invisible and not revealed) else 1.0
	# Rage is anders onzichtbaar: de Micro-manager wordt sneller naarmate je hem raakt,
	# maar ziet er hetzelfde uit. Nu kleurt hij op, zodat je ziet dat schieten hem
	# gevaarlijker maakt.
	var heat: float = 0.0
	if rage > 0.0:
		heat = clampf(1.0 - hp / max_hp, 0.0, 1.0)
	if use_sprite and sprite != null:
		sprite.modulate = Color(1, 1.0 - heat * 0.45, 1.0 - heat * 0.55, a)
	else:
		var c: Color = Color(color.r + (1.0 - color.r) * heat * 0.7,
			color.g * (1.0 - heat * 0.5), color.b * (1.0 - heat * 0.6), a)
		draw_circle(Vector2.ZERO, radius, c)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0, 0, 0, 0.35 * a), 2.0)
	if heat > 0.15:
		# boze streepjes rondom, drukker naarmate de rage oploopt
		for i in 6:
			var ang: float = TAU * float(i) / 6.0
			var d: Vector2 = Vector2(cos(ang), sin(ang))
			draw_line(d * (radius + 2.0), d * (radius + 2.0 + heat * 6.0),
				Color(1.0, 0.4, 0.25, heat * 0.9), 2.0)
	if invisible and not revealed:
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 20, Color(0.6, 1.0, 0.85, 0.5), 1.0)
	if aggro:
		# Taunt: gele belletjes-ring zodat je ziet dat torens éérst op hem mikken.
		draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.3, 0.7), 2.0)
	if installing:
		# 'Installing...': dikke cyaan ring = nu onkwetsbaar.
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 24, Color(0.4, 0.85, 1.0, 0.95), 3.0)
	if shield > 0.0:
		# Schild = een dossiermap die je eerst kapot moet krijgen: een boog vóór de vijand
		# in plaats van een volle ring, zodat je ziet dat het een laag ervoor is.
		draw_arc(Vector2.ZERO, radius + 4.0, PI * 0.15, PI * 0.85, 20, Color(0.55, 0.72, 1.0, 0.95), 3.5)
	if stun_time > 0.0:
		# zzz boven het hoofd in plaats van een gele ring
		var f: Font = ThemeDB.fallback_font
		for i in 3:
			var t: float = fmod(Time.get_ticks_msec() * 0.002 + float(i) * 0.33, 1.0)
			draw_string(f, Vector2(radius * 0.3 + t * 6.0, -radius - 6.0 - t * 10.0), "z",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11 - i * 2, Color(1.0, 0.95, 0.5, 1.0 - t))
	if slow_time > 0.0:
		# koffiekring op de vloer: je staat vast in de wachtrij
		draw_arc(Vector2.ZERO, radius * 0.85, 0.0, TAU, 22, Color(0.55, 0.38, 0.22, 0.85), 3.0)
		draw_arc(Vector2.ZERO, radius * 0.6, 0.0, TAU, 18, Color(0.62, 0.44, 0.26, 0.5), 2.0)
	if disrupt_radius > 0.0 and stun_time <= 0.0:
		# spraakbelletjes in plaats van een paarse cirkel: hij kletst je towers stil
		draw_arc(Vector2.ZERO, disrupt_radius, 0.0, TAU, 40, Color(0.8, 0.5, 0.9, 0.10), 1.0)
		var ph: float = Time.get_ticks_msec() * 0.003
		for i in 3:
			var a2: float = ph + float(i) * TAU / 3.0
			var c2: Vector2 = Vector2(cos(a2), sin(a2) * 0.5) * (radius + 9.0)
			draw_circle(c2, 3.5 - float(i) * 0.6, Color(0.85, 0.6, 0.95, 0.75))
	# Balkbreedte schaalt mee met max HP (wortel-schaal), zodat je in één oogopslag
	# ziet welke vijand taai is. Schild krijgt een eigen blauw balkje erboven.
	var w: float = clampf(14.0 + sqrt(max_hp) * 3.0, 14.0, 70.0)
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
	var bar_pos: Vector2 = Vector2(-w * 0.5, -radius - 10.0)
	draw_rect(Rect2(bar_pos, Vector2(w, 4.0)), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(bar_pos, Vector2(w * ratio, 4.0)), Color(0.3, 0.9, 0.4))
	if max_shield > 0.0:
		var sratio: float = clampf(shield / max_shield, 0.0, 1.0)
		var spos: Vector2 = Vector2(-w * 0.5, -radius - 15.0)
		draw_rect(Rect2(spos, Vector2(w, 3.0)), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(spos, Vector2(w * sratio, 3.0)), Color(0.45, 0.7, 1.0))
