# Balans-rapport — meet wat een level oplevert en wat towers kosten.
#
# Dit is GEEN autoload en draait niet vanzelf. Plak de aanroep tijdelijk in
# App._ready() (scripts/app.gd) wanneer je aan de balans werkt, en haal 'm er
# daarna weer uit:
#
#     const BalanceReport = preload("res://tools/balance_report.gd")
#     func _ready() -> void:
#         BalanceReport.run()          # TIJDELIJK
#         show_main_menu()
#
# Draai daarna: Godot --headless --path . --quit-after 30
#
# Waar je op let (stand v0.17.0):
#  - Coffee uit kills per level: 467-674. Een volledig uitgebouwde toren kost 47-110,
#    dus je kunt 5-8 torens bouwen. Loopt dit boven de ~800, dan kan de speler alles
#    kopen en is er geen keuze meer.
#  - Coffee Machine lvl 3 levert 256 per run. Blijft dat onder wat kills opleveren,
#    dan is economie een keuze en geen verplichting.
#  - Opbrengst per Coffee moet per upgrade-level STIJGEN (GDD §11), anders is een
#    tweede toren kopen slimmer dan upgraden.

const TowerScript = preload("res://scripts/tower.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

static func run() -> void:
	var edefs: Dictionary = EnemyScript.defs()
	var tdefs: Dictionary = TowerScript.defs()

	var full := {}
	for id in tdefs.keys():
		var c := 0
		for lv in tdefs[id]["levels"]:
			c += int(lv["cost"])
		full[id] = c
	print("volle toren (lvl 1+2+3): ", full)

	for lvl in range(1, GameState.LEVEL_COUNT + 1):
		var data: Dictionary = GameState.get_level(lvl)
		var coffee := float(data["start_coffee"])
		var focus_dmg := 0
		var count := 0
		var per_type := {}
		for w in data["waves"]:
			for g in w:
				var t: String = String(g["type"])
				if not edefs.has(t):
					print("  FOUT: onbekend enemy-type '%s' in level %d" % [t, lvl])
					continue
				var n: int = int(g["count"])
				count += n
				coffee += float(n) * float(edefs[t]["reward"])
				focus_dmg += n * int(edefs[t].get("damage", 1))
				per_type[t] = float(per_type.get(t, 0.0)) + float(n) * float(edefs[t]["reward"])
		var line := ""
		for k in per_type.keys():
			line += "%s=%d " % [k, int(per_type[k])]
		print("L%d %-16s enemies=%-4d Coffee=%-5d focus-als-alles-doorkomt=%-5d towers=%d" % [
			lvl, data["name"], count, int(coffee), focus_dmg, data["towers"].size()])
		print("     bronnen: " + line)

	# Passief inkomen van één Coffee Machine over een run zonder early calls.
	var secs: float = 20.0 * 16.0
	for lv in range(3):
		var s: Dictionary = tdefs["coffee"]["levels"][lv]
		var per_sec: float = float(s["coffee_amount"]) / float(s["coffee_interval"])
		var cost := 0
		for i in range(lv + 1):
			cost += int(tdefs["coffee"]["levels"][i]["cost"])
		print("  Coffee Machine lvl %d: %.2f/s -> %d per run, kost %d, dus %.1fx terug" % [
			lv + 1, per_sec, int(per_sec * secs), cost, (per_sec * secs) / float(cost)])
