# Game Design Document: Tower Defense (Godot 4)

Dit GDD is thema-neutraal opgeschreven. Vul je eigen setting in bij `[THEMA]` en
vervang de plaatsnamen van torens en vijanden. De *systemen* zijn het product,
de skin is inwisselbaar.

---

## 1. Pillars

1. **Elke aankoop is een onherroepelijke keuze.** Geen respec, geen "beste build".
2. **Verdediging tegen groei.** Elke munt in economie is een munt niet in defensie.
3. **De map is de puzzel.** Dezelfde torens spelen anders per map.
4. **Rondes zijn leerbaar.** Handgemaakte waves, geen procedurele soep.
5. **Late game breekt je vroege oplossing.** Wat op ronde 20 werkte, faalt op 40.

---

## 2. Core loop

```
ronde starten -> vijanden spawnen -> torens vuren -> munten verdienen
   -> tussen rondes: kopen / upgraden / verkopen / terrein vrijmaken
   -> volgende ronde
```

Speler heeft `levens`. Een vijand die de exit haalt kost levens gelijk aan zijn
resterende laag-equivalent. Levens op nul = verloren.

---

## 3. Vijandsysteem

### 3.1 Datamodel

```gdscript
class_name EnemyType
extends Resource

@export var id: StringName
@export var tier: int                  # positie in de splitsketen
@export var speed: float               # basis 1.0
@export var children: Array[Dictionary] # [{type: &"blue", count: 1}]
@export var immunities: Array[StringName] # [&"explosive", &"ice"]
@export var hp: int = 1                # alleen voor "boss"-klasse, anders 1 laag
@export var is_heavy: bool = false     # aparte klasse (luchtschip-equivalent)
@export var reward: int = 1
```

### 3.2 Splitsketen (voorbeeldopzet)
Ontwerp minstens 8 lagen. Richtwaarde voor totaal-equivalent (TE, het aantal
basisprikken om volledig af te breken):

| Laag | Splitst in | TE | Snelheid | Immuun voor |
|---|---|---|---|---|
| T1 | niets | 1 | 1.0 | - |
| T2 | 1x T1 | 2 | 1.4 | - |
| T3 | 1x T2 | 3 | 1.8 | - |
| T4 | 1x T3 | 4 | 3.2 | - |
| T5 | 1x T4 | 5 | 3.5 | - |
| Zwaar-A | 2x T5 | 11 | 1.8 | explosies |
| Zwaar-B | 2x T5 | 11 | 2.0 | vertraging/vries |
| Zwaar-C | 2x T5 | 11 | 3.0 | energie/vuur |
| Gepantserd | 2x Zwaar-A | 23 | 1.0 | scherp |
| Gemengd | 1x Zwaar-A + 1x Zwaar-B | 23 | 1.8 | explosies + vries |
| Elite | 2x Gemengd | 47 | 2.2 | - |
| Kern | 2x Elite | ~104 | 2.5 | - |

Regel: **elke immuniteit richt zich op de goedkoopste dominante strategie op dat
moment in de rondecurve.** Introduceer ze in de volgorde waarin de speler die
strategieen ontdekt.

### 3.3 Properties (vlaggen, erven over naar kinderen)

| Vlag | Effect | Vroegste ronde |
|---|---|---|
| `hidden` | alleen targetbaar door torens met detectie | ~24 |
| `regen` | wint elke N seconden een laag terug tot origineel | ~17 |
| `reinforced` | x2 TE (x4 op gepantserd) | ~45 |

Combinaties zijn geldig en vormen vanzelf de zwaarste normale rondes.

### 3.4 Zware klasse
Vanaf ronde ~40. Echte HP-pool in plaats van lagen, dumpt bij vernietiging een vaste
lading normale vijanden. Suggestie voor de schaal, met elke stap ongeveer een factor
4 tot 5 in TE:

| Naam | HP | Splitst in | Snelheid | Ronde |
|---|---|---|---|---|
| Zwaar I | 200 | 4x Kern | 1.0 | 40 |
| Zwaar II | 700 | 4x Zwaar I | 0.25 | 60 |
| Zwaar III | 4000 | 4x Zwaar II | 0.18 | 80 |
| Sluiper | 400 | 4x hidden+regen Kern | 2.64 | 90 |
| Eindbaas | 20000 | 2x Zwaar III + 3x Sluiper | 0.18 | 100 |

De Sluiper is het examen: snel, onzichtbaar, immuun voor je twee standaard
damage-types. Als de speler daar geen antwoord op heeft, heeft hij eerder te smal
gebouwd.

---

## 4. Torensysteem

### 4.1 Datamodel

```gdscript
class_name TowerType
extends Resource

@export var id: StringName
@export var tower_class: StringName      # &"primary" / &"tactical" / &"exotic" / &"support"
@export var base_cost: int
@export var placement: StringName        # &"land" / &"water" / &"any" / &"elevated"
@export var footprint: float
@export var base_range: float
@export var needs_line_of_sight: bool = true
@export var paths: Array[UpgradePath]    # exact 3
```

```gdscript
class_name UpgradeTier
extends Resource

@export var cost: int
@export var damage_delta: int
@export var pierce_delta: int
@export var rate_multiplier: float
@export var range_delta: float
@export var grants_damage_types: Array[StringName]
@export var grants_detection: bool
@export var ability: AbilityDef          # null bij tier 1 t/m 3
@export var replaces_attack: bool        # tier 4/5 mag het attackprofiel vervangen
```

### 4.2 Upgraderegels (hard afdwingen in code)
- Precies 3 paden, 5 tiers per pad.
- Zodra pad A tier 3 bereikt: pad B mag maximaal tier 2, pad C gaat op slot.
- Maximaal 2 paden ooit beschikbaar per toren-instantie.
- Maximaal **één tier 5 per (torentype, pad)** op het veld tegelijk.
- Verkoopwaarde 70% van totale investering (globale constante, per mode aanpasbaar).

### 4.3 Torenklassen
Vier klassen, elk met een eigen rol en elk bruikbaar als mode-restrictie:

- **Primary**: goedkoop, betrouwbaar, veel pierce, weinig speciale damage types.
- **Tactical**: duur, lange range of vaste-punt-schoten, sterk tegen zware klasse,
  vaak minder afhankelijk van line of sight.
- **Exotic**: speciale damage types (vuur, energie, gif), sterke effecten,
  slechte matchup tegen minstens één immuniteit.
- **Support**: nul of lage eigen DPS, buft radius, geeft detectie, korting,
  of genereert inkomen.

### 4.4 Damage types
Minimaal: `sharp`, `explosive`, `energy`, `cold`, `arcane`, `normal`.
`normal` negeert alle immuniteiten en hoort alleen op dure tier 5 upgrades te zitten.

### 4.5 Targeting
Per toren instelbaar: `first`, `last`, `close`, `strong`. Torens met detectie krijgen
een extra toggle `prioritize_hidden`. Torens met vaste-punt-schoten krijgen in plaats
daarvan een handmatige richtmarker.

### 4.6 Abilities
Tier 4 en tier 5 geven een handmatige ability met cooldown (30 tot 90 seconden).
Regel: een ability mag een piekronde redden maar mag geen baseline DPS zijn.

### 4.7 Held
Eén per potje. Kost geld bij plaatsen, levelt daarna gratis mee (vaste XP per ronde,
20 levels). Elke held herschrijft één regel:
- eentje genereert geld in plaats van schade
- eentje negeert line of sight
- eentje vecht in melee op het pad zelf
- eentje geeft globale detectie

---

## 5. Mapsysteem

### 5.1 Datamodel

```gdscript
class_name MapDef
extends Resource

@export var id: StringName
@export var difficulty: StringName        # beginner / intermediate / advanced / expert
@export var lanes: Array[LaneDef]         # elk met eigen spawn, exit, curve
@export var lane_schedule: StringName     # &"all" / &"alternate" / &"heavy_only_after_39"
@export var terrain_mask: Texture2D       # land / water / verboden / verhoogd
@export var sight_blockers: Array[BlockerDef]
@export var purchasables: Array[PurchasableDef]  # {kosten, effect, herhaalbaar}
@export var round_events: Array[MapEventDef]     # rotatie, instorting, opening
```

### 5.2 Verplichte varianten in je maplijst
Bouw minstens één map per rij:

| Type | Kernidee |
|---|---|
| Tutorial | Eén lang pad, geen blokkers, geen water |
| Water | Groot wateroppervlak, watertorens verplicht relevant |
| Zicht | Zware sight blockers, mortier-achtige torens bloeien |
| Kort pad | Weinig tijd, DPS-dichtheid is alles |
| Multi-lane | Twee of meer gelijktijdige lanes |
| Alternerend | Ingang wisselt per ronde |
| Zware lane | Extra pad dat pas na ronde 39 opent, alleen zware klasse |
| Dynamisch | Roterend of bewegend terrein, of terrein dat instort |
| Verdiend terrein | Bijna alles begint geblokkeerd, ruimte moet gekocht |
| Interactief | Machine op de map die vijanden vertraagt tegen oplopende kosten |

### 5.3 Purchasables
Terrein vrijmaken kost geld, oplopend per map (richtwaarde 250 tot 2000 per stuk).
Herhaalbare map-effecten (vertragingsmachine, knockback) horen een **oplopende prijs
per gebruik** te hebben, zodat ze een tijdelijke redding zijn en geen strategie.

---

## 6. Economie

### 6.1 Basisstromen

```
inkomen_per_laag = base_pop_value * pop_scaling(ronde)
einde_ronde_bonus = 100 + ronde
```

`pop_scaling`: 1.0 tot ronde 50, dan 0.5, na 60 -> 0.2, na 85 -> 0.1, na 100 -> 0.05.

Kalibreer `base_pop_value` zo dat een speler die *precies* genoeg verdediging heeft
en niets in economie stopt, het net haalt tot de laatste ronde op normaal. Alles
daarboven moet uit economie of uit efficientere plaatsing komen.

### 6.2 Investeringstoren
Eén toren, drie paden, drie filosofieen:

| Pad | Mechanic | Sleutelspanning |
|---|---|---|
| Productie | Vaste opbrengst per ronde, handmatig ophalen | Aandacht kost tijd |
| Reserve | Saldo groeit met 15% rente per ronde, cap, moet geleegd | Timing: te vroeg of te laat is verlies |
| Netwerk | Automatisch, lager, buft alle andere geldbronnen | Schaalt pas bij meerdere |

Tier 4 van het reserve-pad: directe lening (bijvoorbeeld 10.000), waarbij 50% van
toekomstig inkomen afgaat tot afbetaald. Tier 5: dezelfde injectie zonder schuld,
maar met cooldown.

### 6.3 Balansregels
- Elke eco-aankoop moet een berekenbare ROI in rondes hebben. Documenteer die in de
  Resource zelf als `@export var expected_roi_rounds: float` en test die.
- Een eco-aankoop die zich pas terugverdient na de eindronde van de standaardmode is
  per definitie fout geprijsd.
- Verkoopwaarde (70%) moet hoog genoeg zijn dat "tijdelijk in economie stappen en
  uitverkopen voor een grote aankoop" werkt, en laag genoeg dat het niet gratis is.
- Kortingsbronnen zijn geen inkomen: ze schalen niet, en mogen daarom in modes
  bestaan waar inkomen uit staat.

### 6.4 Prijsmodifiers per moeilijkheid
Eén globale multiplier, geen aparte tabellen:

| Moeilijkheid | Levens | Startgeld | Kosten | Vijandsnelheid | Rondes |
|---|---|---|---|---|---|
| Makkelijk | 200 | 650 | -15% | -9% | 1-40 |
| Normaal | 150 | 650 | 0% | 0% | 1-60 |
| Moeilijk | 100 | 650 | +8% | +13% | 3-80 |
| Extreem | 1 | 650 | +20% | +13% | 6-100 |

---

## 7. Rondes en modes

### 7.1 Rondedefinitie

```gdscript
class_name RoundDef
extends Resource

@export var index: int
@export var groups: Array[SpawnGroup]  # {type, count, spacing, delay, lane, flags}
@export var comment: String            # optionele hint in UI
```

Rondes zijn handgemaakt tot de eindronde. Daarna procedureel schalen, waarbij
normale vijanden nog maar één kind spawnen zodat het totaal-equivalent beheersbaar
blijft.

### 7.2 Modes (allemaal hergebruik van bestaande content)

| Mode | Regel |
|---|---|
| Standaard | Basisregels per moeilijkheid |
| Klasse-only | Alleen één torenklasse toegestaan |
| Deflatie | Vast startbedrag, nul inkomen ooit |
| Omgekeerd | Vijanden lopen de andere kant op, waves omgekeerd |
| Non-stop | Geen pauze tussen rondes, waves overlappen |
| Dubbele zware HP | Zware klasse x2 HP |
| Half geld | Alle inkomen x0.5 |
| Puur | Geen inkomen, geen verkopen, geen meta-bonussen, 1 leven |
| Zandbak | Vrij testen, alle vijanden spawnbaar |

"Puur" is je balansthermometer. Als die mode onmogelijk of triviaal is, klopt er
iets fundamenteels niet aan je torens of je economie.

---

## 8. Meta-progressie

- **XP per torentype**, apart. Upgrades permanent unlocken in willekeurige volgorde,
  met oplopende kosten dieper in het pad.
- **Zachte valuta** per gewonnen map/mode, sterk verlaagd na de eerste keer.
- **Kennispunten**: kleine globale bonussen (+startgeld, -kosten, +pierce),
  volledig uitgeschakeld in de mode "Puur".
- **Medailles per map per mode**, met een border bij volledige set. Geen power.

---

## 9. Technische architectuur (Godot 4)

```
res://
  data/
    towers/        *.tres  (TowerType)
    upgrades/      *.tres  (UpgradeTier)
    enemies/       *.tres  (EnemyType)
    rounds/        *.tres  (RoundDef, per moeilijkheid)
    maps/          *.tres  (MapDef)
    modes/         *.tres  (ModeDef)
  scenes/
    game/          Game.tscn, RoundManager, EconomyManager, PlacementManager
    towers/        Tower.tscn (één scene, data-driven)
    enemies/       Enemy.tscn (één scene, data-driven)
    ui/
  scripts/
    core/          signals.gd, game_state.gd, damage.gd, targeting.gd
    balance/       roi_calculator.gd, te_calculator.gd
  tools/           balance_sim.gd (headless simulatie)
```

Harde regels:
- **Alle balans in Resources, nul balans in scripts.** Een balanswijziging mag nooit
  een code-edit zijn.
- Eén `Tower.tscn` en één `Enemy.tscn`, gedreven door hun Resource. Geen scene per
  torentype.
- Damage-resolutie centraal in `damage.gd`: één functie die damage type, immuniteit,
  pierce en detectie afhandelt. Nergens anders immuniteitschecks.
- Object pooling voor projectielen en vijanden. Een late ronde heeft honderden
  entiteiten.
- Vijanden bewegen over `Path2D`/`PathFollow2D` met een genormaliseerde `progress`,
  zodat "first/last" targeting een simpele vergelijking is.
- Ruimtelijke index (grid buckets) voor targeting, geen `get_overlapping_bodies`
  per frame per toren.
- Line of sight via een aparte occlusion-laag met een raycast bij target-selectie,
  gecached tot de target wisselt.
- Deterministische simulatie met een seeded RNG, zodat je headless kunt balanceren.

---

## 10. Balanceer-workflow

1. Bereken per ronde het totaal-equivalent (TE) en zet dat in een grafiek.
2. Bereken per toren-eindconfiguratie de DPS tegen drie profielen: enkel taai doel,
   dichte groep, gemengd.
3. Bereken kosten per DPS en kosten per TE-per-seconde.
4. Draai `balance_sim.gd` headless: gegeven een build en een map, haalt hij ronde N?
5. Elke toren moet op minstens één map of minstens één mode de beste keuze zijn.
   Kan je die situatie niet noemen, dan is de toren overbodig.
