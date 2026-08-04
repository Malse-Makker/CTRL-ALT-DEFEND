#!/usr/bin/env python3
"""Economie-analyse. Zet per level de beschikbare Coffee af tegen de verdediging
die de waves eisen, en test een paar strategieen."""
import json
from pathlib import Path

HERE = Path(__file__).parent
rows = json.loads((HERE / "wave_metrics.json").read_text())

WAVE_INTERVAL = 16.0
# Deze formules moeten gelijk blijven aan de game: start_coffee in game_state.gd en
# WAVE_INCOME_BASE / KILL_DAMP_* in level.gd. Lopen ze uiteen, dan meet je iets dat niet bestaat.
def start_coffee(level):
    return 40 + 5 * (level - 1)
WAVE_INCOME_BASE = 4.0
def damp(w):
    return max(0.40, 1.0 - 0.04 * max(0, w - 5))
# DPS per Coffee bij volledig uitgebouwde torens (uit tower_metrics.py):
#   Auto-Reply 0.266, Quick Reply 0.292, Artillery 0.340. Realistisch mengsel: 0.30.
DPS_PER_COFFEE = 0.30
# Een toren schiet niet 100% van de tijd op de juiste vijand: dekking, targeting,
# reistijd van projectielen. Factor 2 is een milde aanname.
COVERAGE = 2.0

print("=" * 96)
print("1. BESCHIKBARE COFFEE TEGENOVER BENODIGDE VERDEDIGING")
print("=" * 96)
print(f"{'Lv':>3} {'zwaarste wave':>14} {'DPS nodig':>10} {'Coffee nodig':>13} "
      f"{'Coffee beschikbaar':>19} {'overschot':>10}")
for lv in sorted(rows, key=int):
    r = rows[lv]
    pw = r["per_wave"]
    peak = max(w[0] for w in pw)
    dps_needed = peak / WAVE_INTERVAL * COVERAGE
    coffee_needed = dps_needed / DPS_PER_COFFEE
    kills = sum(w[1] * damp(i + 1) for i, w in enumerate(pw))
    wage = sum(WAVE_INCOME_BASE + i for i in range(1, r["waves"]))
    total_coffee = start_coffee(int(lv)) + kills + wage
    print(f"{lv:>3} {peak:>14.0f} {dps_needed:>10.1f} {coffee_needed:>13.0f} "
          f"{total_coffee:>19.0f} {total_coffee/coffee_needed:>9.1f}x")

print()
print("=" * 96)
print("2. WANNEER HEB JE GENOEG? (level 1 en level 15, per wave)")
print("=" * 96)
for lv in ["1", "15"]:
    r = rows[lv]
    cum = start_coffee(int(lv))
    print(f"\nLevel {lv}:")
    print(f"{'wave':>5}{'HP':>7}{'DPS nodig':>11}{'C nodig':>9}{'C in kas':>10}{'ratio':>8}")
    for i, w in enumerate(r["per_wave"]):
        if i > 0:
            cum += WAVE_INCOME_BASE + i
        cum += w[1] * damp(i + 1)
        need = w[0] / WAVE_INTERVAL * COVERAGE / DPS_PER_COFFEE
        print(f"{i+1:>5}{w[0]:>7.0f}{w[0]/WAVE_INTERVAL*COVERAGE:>11.1f}"
              f"{need:>9.0f}{cum:>10.0f}{cum/need:>7.1f}x")

print()
print("=" * 96)
print("3. DEFLATION-TEST: geen kill-inkomen, geen wave-salaris, alleen 45 startkoffie")
print("=" * 96)
# 45 Coffee = 1 volledig uitgebouwde Auto-Reply (47) net niet; 3x lv1 (37) = 6.6 dps
# Beste 45-Coffee build: Auto-Reply lv1+lv2 (22) + Auto-Reply lv1 (12) = 34 -> 5.0+2.2 = 7.2
for lv in ["1", "5", "15"]:
    r = rows[lv]
    best_dps = start_coffee(int(lv)) * DPS_PER_COFFEE
    dead = None
    for i, w in enumerate(r["per_wave"]):
        need = w[0] / WAVE_INTERVAL * COVERAGE
        if need > best_dps and dead is None:
            dead = i + 1
    print(f"Level {lv}: {start_coffee(int(lv))} Coffee = {best_dps:.1f} DPS. Eerste wave die dat overschrijdt: "
          f"wave {dead} van {r['waves']}")

print()
print("=" * 96)
print("4. COFFEE MACHINE: ROI EN NETTO-OPBRENGST")
print("=" * 96)
tiers = [(20, 1 / 5), (20, 2 / 5), (30, 4 / 5)]
cum_cost = 0
for i, (cost, per_sec) in enumerate(tiers):
    cum_cost += cost
    print(f"lv{i+1}: kost {cost:>2} (cumulatief {cum_cost:>2}), {per_sec:.2f} C/s, "
          f"terugverdiend na {cum_cost/per_sec:>5.0f}s")
print()
for waves, label in [(15, "blok 2/3 (15 waves)"), (21, "blok 1 (21 waves)")]:
    dur = waves * WAVE_INTERVAL
    for lvl, (cc, ps) in enumerate([(20, .2), (40, .4), (70, .8)], 1):
        gross = dur * ps
        print(f"{label}: {dur:.0f}s. Machine lv{lvl} (cum {cc}C) levert {gross:.0f}C bruto, "
              f"netto {gross-cc:+.0f}C   [terugverdiend op t={cc/ps:.0f}s = wave {cc/ps/WAVE_INTERVAL:.0f}]")
    print()

print("=" * 96)
print("5. TIJDELIJK IN ECONOMIE STAPPEN EN UITVERKOPEN (verkoop = 60% van invested)")
print("=" * 96)
for claim_wave in [5, 8, 10, 12]:
    t = claim_wave * WAVE_INTERVAL
    gross = t * 0.8
    sell = 70 * 0.6
    print(f"Machine lv3 (70C) gekocht op t=0, verkocht na wave {claim_wave} ({t:.0f}s): "
          f"verdiend {gross:.0f} + verkoop {sell:.0f} = {gross+sell:.0f}C terug op 70C "
          f"= {(gross+sell)/70:.2f}x")

print()
print("=" * 96)
print("6. VOORSTEL: DEMPING OP KILL-INKOMEN + OPLOPEND WAVE-SALARIS")
print("=" * 96)


print("dempingscurve:", "  ".join(f"w{w}:{damp(w):.2f}" for w in [1, 5, 8, 10, 12, 15, 18, 21]))
print()
print(f"{'Lv':>3}{'nu totaal':>11}{'nieuw totaal':>14}{'verschil':>10}"
      f"{'nu kills':>10}{'nieuw kills':>13}{'nu salaris':>12}{'nieuw salaris':>15}")
for lv in sorted(rows, key=int):
    r = rows[lv]
    old_kill = r["coffee"]
    old_wage = 4.0 * (r["waves"] - 1)
    new_kill = sum(w[1] * damp(i + 1) for i, w in enumerate(r["per_wave"]))
    new_wage = sum(4 + i for i in range(1, r["waves"]))
    old_tot = 45 + old_kill + old_wage
    new_tot = start_coffee(int(lv)) + new_kill + new_wage
    print(f"{lv:>3}{old_tot:>11.0f}{new_tot:>14.0f}{new_tot-old_tot:>+10.0f}"
          f"{old_kill:>10.0f}{new_kill:>13.0f}{old_wage:>12.0f}{new_wage:>15.0f}")

print()
print("=" * 96)
print("7. VOORSTEL: THE EXPENSE CLAIM (rente met timingrisico)")
print("=" * 96)
for name, cost, per_wave, rate, cap in [
        ("Petty Cash    ", 25, 3, 0.10, 60),
        ("Expense Report", 30, 5, 0.15, 140),
        ("Corporate Card", 45, 8, 0.20, 300)]:
    pot = 0.0
    hist = []
    for w in range(1, 16):
        pot = min(cap, (pot + per_wave) * (1 + rate))
        hist.append(pot)
    print(f"{name} (cum {cost}C): " + " ".join(f"{h:.0f}" for h in hist))
print()
print("Vergelijking over 15 waves (240s):")
print(f"  Coffee Machine lv3 (70C):  {240*0.8:.0f}C, doorlopend beschikbaar")
print(f"  Corporate Card  lv3 (100C): {min(300,0):.0f} ... zie rij hierboven, "
      f"alles pas beschikbaar op het moment dat je claimt")
