#!/usr/bin/env python3
"""Torenprofielen: damage, doelen per aanval (pierce-equivalent), rate, DPS tegen
groepen van 1/5/10, en DPS per geinvesteerde Coffee. Getallen komen uit tower.gd."""
import re
from pathlib import Path

ROOT = Path("/Users/nijntje/Documents/projecten/CTRL-ALT-DEFEND")
src = (ROOT / "scripts/tower.gd").read_text()
block = src.split("static func defs()")[1].split("\nfunc configure")[0]

towers = {}
for m in re.finditer(r'\n\t\t"(\w+)": \{(.*?)\n\t\t\},', block, re.S):
    tid, body = m.group(1), m.group(2)
    role = re.search(r'"role": "(\w+)"', body).group(1)
    name = re.search(r'"name": "([^"]+)"', body).group(1)
    lvls = []
    for lm in re.finditer(r'\{"name": .*?\}', body):
        d = {}
        for k, v in re.findall(r'"(\w+)":\s*([0-9.]+)', lm.group(0)):
            d[k] = float(v)
        lvls.append(d)
    towers[tid] = {"name": name, "role": role, "levels": lvls}


def profile(tid, lv):
    """returns (damage_per_hit, targets_per_hit, interval, dps_vs_1, dps_vs_5, dps_vs_10)"""
    t = towers[tid]
    s = t["levels"][lv]
    role = t["role"]
    dmg = s.get("damage", 0.0)
    rate = s.get("rate", 1.0)
    if role in ("damage",):
        return dmg, 1, rate, dmg / rate, dmg / rate, dmg / rate
    if role == "multi":
        n = int(s.get("shots", 1))
        d = dmg / rate
        return dmg, n, rate, d, d * min(5, n), d * min(10, n)
    if role == "chain":
        j = int(s.get("jumps", 0)); fo = s.get("falloff", 0.75)
        def tot(n):
            hits = min(n, j + 1)
            return sum(dmg * fo ** i for i in range(hits)) / rate
        return dmg, j + 1, rate, tot(1), tot(5), tot(10)
    if role == "splash":
        fo = s.get("splash_falloff", 0.6)
        # aanname: bij 5 in bereik staan er ~2 in de splash, bij 10 ~4
        return dmg, "1+aoe", rate, dmg / rate, (dmg + 2 * dmg * fo) / rate, (dmg + 4 * dmg * fo) / rate
    if role == "burst":
        return dmg, "alles", rate, dmg / rate, dmg * 5 / rate, dmg * 10 / rate
    if role == "area":
        dot = s.get("dot", 0.0)
        return dot, "alles (gedeeld)", 1.0, dot, dot, dot
    if role == "trap":
        # 1 punaise per throw_interval, elke punaise raakt 1 vijand
        ti = s.get("throw_interval", 1.5)
        return dmg, 1, ti, dmg / ti, dmg / ti, dmg / ti
    if role == "smash":
        sd = s.get("smash_damage", 0.0); cd = s.get("smash_cooldown", 6.0)
        return sd, "alles", cd, sd / cd, sd * 5 / cd, sd * 10 / cd
    return 0.0, 0, 0.0, 0.0, 0.0, 0.0


print(f"{'toren':<22}{'rol':<10}{'lv':<3}{'kost':>5}{'cum':>5}{'dmg':>7}{'doelen':>16}{'int':>7}"
      f"{'dps1':>7}{'dps5':>7}{'dps10':>7}{'dps1/C':>8}{'dps10/C':>9}")
order = ["auto", "machinegun", "ceo", "pomodoro", "splash", "multishot", "chain",
         "filter", "trap", "phones", "scrum", "coffee", "keyboard", "ctrlaltdel"]
for tid in order:
    t = towers[tid]
    cum = 0
    for lv in range(len(t["levels"])):
        s = t["levels"][lv]
        cost = int(s.get("cost", 0)); cum += cost
        dmg, tg, itv, d1, d5, d10 = profile(tid, lv)
        if t["role"] == "economy":
            per_sec = s.get("coffee_amount", 0) / s.get("coffee_interval", 1)
            print(f"{t['name']:<22}{t['role']:<10}{lv+1:<3}{cost:>5}{cum:>5}"
                  f"{'':>7}{'-':>16}{'':>7}{'':>7}{'':>7}{'':>7}"
                  f"  {per_sec:.2f} C/s  ROI {cum/per_sec:.0f}s")
            continue
        if t["role"] in ("stun", "support"):
            print(f"{t['name']:<22}{t['role']:<10}{lv+1:<3}{cost:>5}{cum:>5}"
                  f"{'0':>7}{'-':>16}{s.get('rate',0):>7.2f}{'':>7}{'':>7}{'':>7}")
            continue
        print(f"{t['name']:<22}{t['role']:<10}{lv+1:<3}{cost:>5}{cum:>5}{dmg:>7.1f}{str(tg):>16}"
              f"{itv:>7.2f}{d1:>7.1f}{d5:>7.1f}{d10:>7.1f}{d1/cum:>8.3f}{d10/cum:>9.3f}")
    print()

print("\n--- Openingsvraag: wat kun je kopen voor 45 startkoffie? ---")
for tid in order:
    c = towers[tid]["levels"][0].get("cost", 0)
    # duplicaatopslag +25% per exemplaar
    n, spent, prices = 0, 0.0, []
    while True:
        p = round(c * (1 + min(0.25 * n, 1.0)))
        if spent + p > 45:
            break
        spent += p; prices.append(int(p)); n += 1
    print(f"{towers[tid]['name']:<22} lv1 kost {int(c):>3}C -> {n}x voor {int(spent)}C  {prices}")
