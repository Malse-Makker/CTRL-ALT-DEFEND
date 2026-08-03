#!/usr/bin/env python3
"""Rekent per level het HP-equivalent, de Coffee-opbrengst en de Focus-dreiging uit.
Leest de defs rechtstreeks uit enemy.gd en game_state.gd, zodat de getallen niet
kunnen afwijken van de code."""
import re, sys, json
from pathlib import Path

ROOT = Path("/Users/nijntje/Documents/projecten/CTRL-ALT-DEFEND")

# ---- vijand-defs uit enemy.gd ----
enemy_src = (ROOT / "scripts/enemy.gd").read_text()
block = enemy_src.split("static func defs()")[1].split("\nfunc configure")[0]
enemies = {}
for m in re.finditer(r'"(\w+)":\s*\{(.*?)\n', block):
    pass
# defs staan verspreid over meerdere regels per entry; pak per entry alles tot de sluitende }
entries = re.findall(r'"(\w+)":\s*\{(.*?)\},\n', block, re.S)
for eid, body in entries:
    def num(key, default=0.0):
        mm = re.search(r'"%s":\s*([0-9.]+)' % key, body)
        return float(mm.group(1)) if mm else default
    if '"hp"' not in body:
        continue
    enemies[eid] = {
        "hp": num("hp"), "shield": num("shield"), "speed": num("speed"),
        "reward": num("reward"), "damage": num("damage"),
        "boss": '"boss": true' in body,
        "split": int(num("split_count")), "split_type": (re.search(r'"split_type":\s*"(\w+)"', body).group(1) if '"split_type"' in body else ""),
        "spawner": num("spawner"), "spawn_type": (re.search(r'"spawn_type":\s*"(\w+)"', body).group(1) if '"spawn_type"' in body else ""),
        "spawn_count": int(num("spawn_count")),
    }

# ---- WAVES uit game_state.gd ----
gs = (ROOT / "scripts/game_state.gd").read_text()
wblock = gs.split("const WAVES := {")[1].split("\n}\n")[0]
levels = {}
cur = None
for line in wblock.splitlines():
    s = line.strip()
    m = re.match(r"^(\d+):\s*\[", s)
    if m:
        cur = int(m.group(1)); levels[cur] = []; continue
    if s.startswith('"') and cur is not None:
        levels[cur].append(s.strip('",').strip('"'))

def wave_stats(spec):
    """HP-equivalent = som van hp+shield van alles wat je moet stukmaken,
    inclusief kinderen van splitters (Change -> 2x Task)."""
    hp = coffee = focus = 0.0
    cnt = 0
    for part in spec.split("+"):
        part = part.strip()
        if not part:
            continue
        typ, rest = part.split(":")
        n = int(rest.split("@")[0])
        e = enemies.get(typ)
        if e is None:
            print("ONBEKEND TYPE:", typ, file=sys.stderr); continue
        hp += n * (e["hp"] + e["shield"])
        coffee += n * e["reward"]
        focus += n * e["damage"]
        cnt += n
        if e["split"] and e["split_type"] in enemies:
            c = enemies[e["split_type"]]
            hp += n * e["split"] * (c["hp"] + c["shield"])
            coffee += n * e["split"] * c["reward"]
            focus += n * e["split"] * c["damage"]
            cnt += n * e["split"]
    return hp, coffee, focus, cnt

print(f"{'Lv':>3} {'waves':>5} {'HP-eq':>8} {'Coffee':>7} {'Focus':>7} {'aantal':>7} {'HP w1':>6} {'HP wLast':>9} {'HPmax/w':>8}")
rows = {}
for lv in sorted(levels):
    tot_hp = tot_c = tot_f = tot_n = 0.0
    per_wave = []
    for spec in levels[lv]:
        h, c, f, n = wave_stats(spec)
        tot_hp += h; tot_c += c; tot_f += f; tot_n += n
        per_wave.append((h, c, f, n))
    rows[lv] = {"waves": len(levels[lv]), "hp": tot_hp, "coffee": tot_c, "focus": tot_f,
                "count": tot_n, "per_wave": per_wave}
    print(f"{lv:>3} {len(levels[lv]):>5} {tot_hp:>8.0f} {tot_c:>7.0f} {tot_f:>7.0f} {tot_n:>7.0f} "
          f"{per_wave[0][0]:>6.0f} {per_wave[-1][0]:>9.0f} {max(w[0] for w in per_wave):>8.0f}")

print()
print("--- per wave, HP-equivalent (curve per level) ---")
for lv in sorted(rows):
    print(f"L{lv:>2}: " + " ".join(f"{w[0]:.0f}" for w in rows[lv]["per_wave"]))

print()
print("--- per wave, cumulatieve Coffee uit kills + wave-salaris (4/wave vanaf wave 2) ---")
for lv in sorted(rows):
    cum = 45.0
    out = []
    for i, w in enumerate(rows[lv]["per_wave"]):
        if i > 0:
            cum += 4
        cum += w[1]
        out.append(f"{cum:.0f}")
    print(f"L{lv:>2}: " + " ".join(out))

Path(__file__).with_name("wave_metrics.json").write_text(json.dumps(rows, indent=1))
