# Systeemaudit CTRL-ALT-DEFEND

Opgesteld 2026-08-03, tegen **v0.78.0**. Benchmark: `01_TD_DESIGN_REFERENCE.md`.
Randvoorwaarde bij elk voorstel: het past binnen het thema, de toon en de scope uit
`05_MIJN_GAME_CONTEXT.md`. Waar iets die scope overschrijdt, staat dat er expliciet bij.

Dit is een **werkdocument**. Vink af wat af is; de meetgetallen bovenaan zijn de dure
kant van dit werk en hoeven niet opnieuw uitgerekend te worden.

**Meetgereedschap dat hierbij hoort (nieuw, in `tools/`):**

```bash
python3 tools/wave_metrics.py    # HP-equivalent, Coffee en Focus-dreiging per level en per wave
python3 tools/tower_metrics.py   # DPS, doelen per aanval, DPS per Coffee, openingsopties
python3 tools/economy.py         # inkomen tegenover benodigde verdediging, ROI, deflation-test
```

`wave_metrics.py` moet als eerste draaien: `economy.py` leest de JSON die het wegschrijft.
Alle drie lezen rechtstreeks uit `enemy.gd`, `tower.gd` en `game_state.gd`, dus ze kunnen
niet uit de pas lopen met de code.

---

## 0. Beslissingen die al genomen zijn

| Datum | Beslissing |
|---|---|
| 2026-08-03 | **Ctrl+Alt+Del wordt geen toren maar een ability** met knop en cooldown |
| 2026-08-03 | **Delegation draait om**: elke sprong slaat harder in plaats van zwakker |
| 2026-08-03 | **Splitsketen alleen op User Story**, The Question blijft plat (entiteiten-risico) |
| 2026-08-03 | **Recurring is de eerste vlag**, BCC'd pas nadat er een detectie-toren bestaat |
| 2026-08-04 | **Alle vijanden worden mensen (collega's).** Namen nog niet bepaald. Zie §4.6 |
| 2026-08-04 | **Uitgebracht in v0.79.0:** D1 (start_coffee schalen) en D2 (demping + oplopend salaris) |
| 2026-08-04 | **Uitgebracht in v0.80.0:** Z1, een toren per level tot en met L10 (volgorde in `TOWERS_PER_LEVEL`) |

---

## 1. De meetgetallen

### 1.1 HP-equivalent per level

Berekend uit `WAVES` en `enemy.gd`, inclusief de kinderen van The Change. Adds die
tijdens een wave uit een Printer of boss komen zitten er **niet** in.

| Level | Waves | HP-eq totaal | Zwaarste wave | Coffee uit kills | Focus-dreiging |
|---|---|---|---|---|---|
| 1 | 21 | 3.400 | 462 | 515 | 649 |
| 2 | 22 | 4.385 | 698 | 501 | 859 |
| 3 | 21 | 4.836 | 728 | 508 | 858 |
| 4 | 21 | 5.320 | 900 | 594 | 1.052 |
| 5 | 20 | 6.320 | 632 | 679 | 1.230 |
| 6 | 15 | 4.446 | 536 | 499 | 868 |
| 7 | 15 | 4.648 | 566 | 489 | 881 |
| 8 | 15 | 5.028 | 702 | 541 | 963 |
| 9 | 15 | 5.648 | 670 | 598 | 1.056 |
| 10 | 15 | 5.786 | 702 | 614 | 1.095 |
| 11 | 15 | 6.300 | 760 | 676 | 1.173 |
| 12 | 15 | 7.982 | 1.056 | 809 | 1.434 |
| 13 | 15 | 7.110 | 896 | 736 | 1.276 |
| 14 | 15 | 6.638 | 808 | 703 | 1.217 |
| 15 | 15 | 8.292 | 1.136 | 841 | 1.446 |

**De curve zaagt.** Level 5 (blok-finale) heeft een lichtere piek dan level 2, 3 en 4.
Level 6 valt 30% terug na level 5, met dezelfde volledige toolkit.

### 1.2 Torenprofielen op maximaal niveau

| Toren | Damage | Doelen | Interval | DPS vs 1 | DPS vs 10 | Volle kosten | DPS/C vs 1 | DPS/C vs 10 |
|---|---|---|---|---|---|---|---|---|
| Auto-Reply | 4,0 | 1 | 0,32 | 12,5 | 12,5 | 47 | 0,266 | 0,266 |
| Quick Reply | 1,6 | 1 | 0,075 | 21,3 | 21,3 | 73 | 0,292 | 0,292 |
| Office Artillery | 80 | 1 | 2,40 | 33,3 | 33,3 | 98 | 0,340 | 0,340 |
| Pomodoro Timer | 22 | alles | 3,00 | 7,3 | 73,3 | 99 | 0,074 | **0,741** |
| Reply All | 6,0 | 1 + splash | 0,90 | 6,7 | 25,3 | 99 | 0,067 | 0,256 |
| Self-Service | 4,0 | 8 | 0,70 | 5,7 | 45,7 | 98 | 0,058 | 0,466 |
| Delegation | 8,0 | 5 | 0,80 | 10,0 | 33,6 | 106 | 0,094 | 0,317 |
| The Shredder | 11/s gedeeld | alles | doorlopend | 11,0 | 11,0 | 110 | 0,100 | 0,100 |
| Thumbtacks | 4,0 | 1 | 1,30 | 3,1 | 3,1 | 86 | 0,036 | **0,036** |
| Keyboard Smash | 14 | alles | 6,00 | 2,3 | 23,3 | 60 | 0,039 | 0,389 |
| Motivational Poster | buff | 3 torens | doorlopend | +56 dps* | +56 dps* | 98 | **0,574** | 0,574 |

\* op drie Auto-Replies lvl 3: x1,8 damage en x1,39 rate is samen x2,5.

### 1.3 Wat je kunt kopen voor 45 startkoffie

| Opening | Kosten | DPS |
|---|---|---|
| Auto-Reply x3 (10 + 12 + 15 met duplicaat-opslag) | 37 | 6,6 |
| Quick Reply x2 | 40 | 7,7 |
| Office Artillery x1 | 25 | 5,8 |
| Headphones x2 of Coffee Machine x2 | 45 | 0 |

Auto-Reply kost 10, de op één na goedkoopste schadetoren kost 18.

### 1.4 Coffee tegenover benodigde verdediging

Model: DPS nodig = HP van de wave / 16s, maal 2 voor dekking en targeting-verlies.
Coffee nodig bij 0,30 DPS per Coffee.

| Level | Zwaarste wave | Coffee nodig | Coffee beschikbaar | Overschot |
|---|---|---|---|---|
| 1 | 462 | 192 | 640 | 3,3x |
| 4 | 900 | 375 | 720 | 1,9x |
| 5 | 632 | 263 | 800 | 3,0x |
| 10 | 702 | 292 | 715 | 2,4x |
| 15 | 1136 | 473 | 942 | 2,0x |

Op de gewone waves van level 1 zweeft de ratio tussen **3,2x en 8,3x**.
Op level 15 slaat het om: **wave 2 vraagt 177 Coffee en je hebt er 104.**

### 1.5 Reward per HP verschilt een factor 3,4

| Vijand | Reward per HP |
|---|---|
| The Notification, Suspicious Link | 0,200 |
| The Thread | 0,150 |
| The Chatterbox | 0,136 |
| The Question, Cold Caller, Micro-manager | 0,125 - 0,133 |
| The Printer, The Nudge | 0,117 |
| User Story, System Update, Phone Caller | 0,103 - 0,108 |
| The Board Member | 0,088 |
| Error Message | 0,080 |
| **The Old Guard** | **0,059** |

De moeilijkste vijand van het spel betaalt het slechtst.

---

## 2. Scorecard tegen hoofdstuk 7 van de reference

| Systeem | Score | Kern |
|---|---|---|
| Vijanden | **3/5** | Thematisch sterk, mechanisch smal: één healthbar, geen overerfbare vlaggen, snel is altijd zwak |
| Torens | **2/5** | Lineaire ladder zonder pierce-as en zonder crosspath: de speler kiest wélke toren, nooit welke kant op |
| Maps | **3/5** | Goede assen, maar allemaal in blok 2 en 3; blok 1 is kaal en L5/L10/L15 zijn dezelfde map |
| Economie | **2/5** | Eén passieve investeringstoren, geen demping, geen timing, geen greed curve |
| Structuur | **3/5** | Handgemaakte waves zijn een kracht; moeilijkheid zit alleen in de wave-tabel en de curve zaagt |

**Afwezig volgens de checklist:** meetgetal per ronde (nu opgelost met `wave_metrics.py`),
overerfbare vlaggen, klasse-breuk, crosspath, torenklassen voor modes, handmatige abilities,
terreintypes, demping op kill-inkomen, investeringstoren met twee filosofieën, timing-mechanic.

---

## 3. Fouten in de huidige code

Dingen die niet doen wat het spel de speler vertelt. Deze eerst, want ze maken bestaande
teksten waar in plaats van nieuwe systemen te bouwen.

### 3.1 Het schild heeft geen drempel

`take_damage` in `enemy.gd` trekt elke schade van het schild af, ook 1 punt tegelijk.
Het schild is dus 30 extra HP, meer niet. Maar het spel zegt op drie plekken iets anders:

- Old Guard-omschrijving: *"Shielded: break the shield first. Burst it down."*
- Counter-tekst: *"Only burst breaks the shield; chip damage bounces off."*
- Tutorial les 5: *"Only Office Artillery hits hard enough to break through."*

**Fix:** veld `shield_min_hit` op de vijand-def; schade daaronder raakt het schild niet.
Old Guard op **10**: Artillery (15/35/80), Pomodoro lvl 2+ (12/22) en Keyboard Smash (14)
breken het, Auto-Reply (4), Quick Reply (1,6), Self-Service (4), Reply All (6) en
Delegation (8) niet. Drie torens uit drie hoeken, dus een straf op een build en niet op
één toren.

### 3.2 start_coffee is 45 voor alle vijftien levels

`game_state.gd` regel 168. Level 1 opent met 45 Coffee tegen een wave van 20 HP,
level 15 met 45 Coffee tegen 150 en daarna 424 HP.

### 3.3 De toren-ontgrendelcurve dumpt acht torens tegelijk

`TOWERS_PER_LEVEL`: L1 twee torens, L2 vijf, L3 zes, **L4 alle veertien**, en daarna elf
levels lang niets nieuws. Dit verklaart het playtest-cijfer "negen torens nul keer gekocht"
grotendeels: acht van die negen waren in de gespeelde levels niet te koop.

### 3.4 Ctrl+Alt+Del negeert zijn eigen bereik

De UI tekent een cirkel van 180, maar de code zoekt over álle vijanden op het bord
(`tower.gd` regel ~250). Hij vuurt bovendien zodra hij geladen is, dus wie hem in wave 3
koopt betaalt 60 Coffee om één Question van 12 HP te doden.

### 3.5 LOS wordt inconsistent gecontroleerd

| Wat | LOS? | Terecht? |
|---|---|---|
| Gewone schade-torens, Self-Service, Pomodoro | ja | ja |
| Shredder-zone, Thumbtacks, Reply All-splash | nee | verdedigbaar |
| **Keyboard Smash, Delegation-sprongen** | **nee** | **nee, dat is toeval** |

### 3.6 modifiers-tabel klopt niet met het commentaar

Het commentaar boven level 15 zegt "weinig bouwplekken + 50% koffie", maar `modifiers`
heeft geen entry voor 15. Level 13 en 15 hebben er nul, terwijl de map-review senior op
twee per level zet. Ook L6, L7 en L8 hebben er geen.

### 3.7 low_focus op L14 maakt drie sterren bijna onmogelijk

`_stars()` geeft 3 sterren bij 90% Focus over. Level 14 start met 10 Focus, dus je marge
is **1 Focus**. Eén Notification kost je de derde ster.

### 3.8 `sees_hidden` is dode code

Volledig geïmplementeerd in targeting, opslag en de UI-knop, maar geen enkele toren-def
zet hem aan. De detectie-rol bestaat als code zonder inhoud.

---

## 4. Voorstellen per systeem

### 4.1 Torens

**A1. Crosspath: twee zijsporen per toren.** Elke core-toren houdt zijn ladder van drie
en krijgt twee zijstappen. Maximaal twee zijstappen, en ze moeten in hetzelfde spoor.
Koop je de eerste stap van het ene spoor, dan gaat het andere op slot.

| Spoor | Stap 1 | Stap 2 | Waarom |
|---|---|---|---|
| **OVERTIME** *"Just one more thing before I log off."* | interval x0,80 | range x1,20 | Rate vermenigvuldigt alles: de veilige keuze. Range is de map-afhankelijke keuze. |
| **ESCALATION** *"I'm going to have to loop in a few more people."* | +1 doel per aanval | damage x1,25 | Doelen is de pierce-as die volledig ontbreekt. Damage is de tank-as. |

Prijs: stap 1 kost 50% van de level-1-prijs van die toren, stap 2 kost 100%.
Auto-Reply 5 en 10, Artillery 13 en 25, Shredder 15 en 30.

Effect op Auto-Reply lvl 3 (47C, 12,5 dps):

| Configuratie | Kosten | vs 1 vijand | vs groep | Range |
|---|---|---|---|---|
| kaal | 47 | 12,5 | 12,5 | 150 |
| + Overtime x2 | 62 | 15,6 | 15,6 | 180 |
| + Escalation x2 | 62 | 15,6 | 31,3 | 150 |

Per rol wat de knoppen betekenen:

| Rol | Overtime 1 | Overtime 2 | Escalation 1 | Escalation 2 |
|---|---|---|---|---|
| damage, multi, chain, splash, burst, trap | interval x0,80 | range x1,20 | +1 doel | damage x1,25 |
| area (Shredder) | radius x1,15 | radius x1,20 | slow 0,05 sterker | dot x1,25 |
| stun (Headphones) | cooldown x0,80 | range x1,20 | stunt 2 doelen | stunduur x1,25 |
| support (Poster) | radius x1,20 | +1 doeltoren | buff_dmg +0,2 | buff_rate x0,92 |
| economy, specials | geen zijpaden | | | |

**A2. Ctrl+Alt+Del wordt een ability** met knop en cooldown in plaats van een toren.
(Besloten.)

**A3. Delegation omdraaien:** `falloff` boven 1,0, dus elke sprong slaat harder omdat de
mail hoger in de organisatie komt. Delegate → Escalate → Company Policy klopt al.
(Besloten.)

**A4. Thumbtacks herprofileren** naar de ontbrekende rol: punaises negeren zicht en raken
meerdere vijanden voor ze op zijn. Dan is hij op de LOS-levels (6, 10, 11, 15) het beste
wat je hebt en elders het slechtste. Hangt af van C1.

**A5. Keyboard Smash naar pure blokkade.** Zijn schade verliest sowieso van een goedkopere
Pomodoro lvl 2 (23,3 tegen 34,3 dps). Zijn unieke eigenschap is de slagboom.

**A6. Reply All herprofileren of goedkoper maken.** Kost exact evenveel als Pomodoro (99)
met bijna dezelfde range, en doet 2,9x minder tegen een groep.

**A7. Motivational Poster wordt een straalbuff.** Nu buft hij alleen torens die je
handmatig hebt aangeklikt (`level.gd` regel 1207), dus wie hem koopt zonder die verborgen
tweede handeling krijgt niets. Vervang de lus over `buff_targets` door een lus over alle
torens binnen `range_radius`. Hij is met 0,574 DPS per Coffee de efficiëntste aankoop in
het spel en werd nul keer gekocht.

**A8. De prijsladder aan de onderkant rechttrekken.** Auto-Reply domineert niet omdat hij
sterk is (0,222 DPS/C op lvl 1, midden in het veld) maar omdat hij 10 kost terwijl de
volgende 18 kost. Drie goedkope torens dekken meer pad dan één dure, en dekking wint vroeg.

### 4.2 Vijanden

**B1. `shield_min_hit`** (zie 3.1). Old Guard op 10.

**B2. Splitsketen op User Story.** Machinerie bestaat al en is recursief
(`level.gd` regel 1107). Alleen data:

| Vijand | Schil-HP | Splitst in | HP-equivalent |
|---|---|---|---|
| The Notification | 4 | niets | 4 |
| The Question | 12 | niets (bewust plat gelaten) | 12 |
| User Story | 4 | 2x The Question | 28 |

Meeteenheid: **1 NE (Notification Equivalent) = 4 HP.**
Risico: de zwaarste wave van level 1 gaat van 7 naar 21 entiteiten. Meten voor je uitbrengt.

**B3. Schadeklassen in plaats van `immune_to` op toren-id.** Nu is een immuniteit een slot
met één sleutel; de speler die toevallig die toren niet koos merkt er niets van.

| Klasse | Torens | Immune vijand | Flavour |
|---|---|---|---|
| **written** | Auto-Reply, Quick Reply, Reply All, Self-Service, Delegation | The Cold Caller | *"He does not read email. He calls."* |
| **physical** | Office Artillery, Thumbtacks, The Shredder, Keyboard Smash | The Board Member | *"He is never actually in the building."* |
| **ambient** | Pomodoro Timer, Headphones, Motivational Poster | The Micro-manager | *"He does not care what your calendar says."* |

`immune_to` staat op drie plekken in `tower.gd` (633, 679, 726).

**B4. Drie orthogonale vlaggen die overerven naar kinderen.**

| Vlag | Naam | Effect | Straft |
|---|---|---|---|
| regeneratie | **Recurring** *"It repeats every Tuesday."* | herstelt 15% max HP per 3s | lekken; chip damage dat niet afmaakt |
| onzichtbaar | **BCC'd** *"You were not on the original thread."* | niet targetbaar tot onthuld | "ik zet gewoon meer DPS neer" |
| versterkt | **Signed Off** *"Approved by management."* | HP x2 | niets, puur een schaalknop |

Notatie in de wave-tabel: `"story:4@1.20#recurring"`, meerdere met `+`.
`_parse_wave` krijgt er één split bij. **Recurring eerst** (besloten): geen afhankelijkheden
en hij raakt precies de Auto-Reply-muur. BCC'd pas als er een detectie-toren is.

**B5. The Walk-and-Talk.** Het kwadrant "snel én taai" is leeg: Pearson r tussen snelheid
en HP is **-0,67**, de snelste helft heeft gemiddeld 9,9 HP tegen 30,7 voor de traagste.

> HP 34, speed 110, Focus-schade 5, reward 3,5.
> *"He is already late for the next one. He will talk to you on the way."*
> Counter: *"Fast and tough at once. Slow towers cannot track him: use rate, not damage per hit."*

Introductie: level 7. Hij is de eerste vijand waar Artillery (2,4s per schot) niets tegen kan.

**B6. De klasse-breuk: The Steering Committee, level 6 wave 5.**
Blok 2 gebruikt exact dezelfde vijandtypes als blok 1; in de hele game komt er na level 5
precies één nieuw type bij (System Update op L13).

> Schil-HP 120, `shield_min_hit` 12, speed 40, Focus-schade 20, reward 18.
> Bij dood: **4x The Board Member**.
> *"A decision will be made about your decision."*
> Counter: *"Artillery cracks it open. Artillery cannot touch what comes out."*

De schil vraagt burst, de inhoud is immuun voor physical. De oplossing voor de buitenkant
is het verkeerde gereedschap voor de binnenkant. HP-equivalent 280, ongeveer de helft van
een gemiddelde L6-wave. Hangt af van B1 en B3.

**B7. Het late-game examen: The Quick Question, level 12 wave 6.**

> HP 45, speed 150, Focus-schade 6, reward 4,0. Vlaggen: BCC'd + silence radius 70.
> *"Got a sec?"*
> Counter: *"You never see it coming, it is fast, and your towers stop working while it is
> next to you. Detection first, then rate. Slow towers will never land a shot."*

Combineert drie eerder geleerde lessen (onzichtbaar van Suspicious Link, snel van The Nudge
maar met 45 HP, silence van The Chatterbox) en is de eindexamenversie van The Question,
de tweede vijand die de speler ooit tegenkwam. Hangt af van B4 en de detectie-toren.

### 4.3 Maps

**C1. `ignores_los` als expliciete eigenschap** in plaats van als toeval (zie 3.5).
Dit is meteen de ontbrekende "vaste-punt-schutter" uit de reference en de basis onder A4.

**C2. `pay_zones` uitbreiden.** Werkt al volledig, staat op één level, waar je 90 van de
836 Coffee aan ruimte kunt uitgeven (11%). Nul code, alleen data.

**C3. Terreintypes.** De enige as uit hoofdstuk 3 die helemaal ontbreekt.

- **Stopcontacten (`power_zones`)**: stroken langs muren en pilaren. Coffee Machine,
  Pomodoro, Motivational Poster en Headphones mogen alleen daar staan.
  *"Building services will not run an extension lead to the middle of the floor."*
- **Stiltezones (`quiet_zones`)**: Keyboard Smash, Office Artillery en Reply All verboden.
  *"This is a quiet zone. Please take calls elsewhere."*

`_can_place_at` werkt al met lijsten van `Rect2`; er komt één lijst bij plus een veld op de
toren-def. Tooltip die uitlegt waaróm je daar niet mag bouwen is verplicht.

**C4. Geboekte ruimtes (dynamiek binnen een ronde).** Eén rechthoek is per wave geboekt:
torens erin zijn `silenced`, bouwen kan niet, en elke drie waves verspringt hij. Twee waves
vooruit zichtbaar. *"Room booked 14:00 - 15:00. Please vacate."* `silenced` bestaat al.

**C5. L14-sterrencriterium nakijken** (zie 3.7).

**C6. Drie map-concepten.** *Let op: dit overschrijdt de scope in je contextdocument,
waar staat dat 15 levels het eindpunt is.* In te zetten als vervanging van een van de drie
Boardroom-herhalingen, of als losse modus.

- **The Renovation** — ruimte kopen is de hele puzzel. Zes zones van 25/35/45/60/75/90
  Coffee (samen 330 van de ~640 die je verdient). *"Facilities apologises for the noise.
  And the dust. And the fact that you cannot sit anywhere."*
- **The Cubicle Farm** — zicht boven bereik. Raster van schotten van 18 px op 160x160.
  Artillery is er waardeloos, de geherprofileerde Thumbtacks is er koning.
  *"You have been allocated a workstation with excellent proximity to the printer."*
  Wel eerst prestaties meten: 20 muren tegen 40 vijanden is 800 segment-checks per poging.
- **The Hot Desk Floor** — je eigen posities worden je afgepakt (zie C4).
  *"We have moved to activity-based working. Please clear your desk at the end of each day."*

### 4.4 Economie

**D1. `start_coffee` schalen per level** (zie 3.2):

```gdscript
"start_coffee": 40 + 5 * (level_id - 1)
```
L1 = 40, L5 = 60, L8 = 75, L10 = 85, L12 = 95, L15 = 110.

**D2. Demping op kills plus een oplopend wave-salaris.**

```gdscript
func kill_income_mult(wave: int) -> float:
    return maxf(0.40, 1.0 - 0.04 * float(maxi(0, wave - 5)))
```
Wave 1-5: 1,00 · wave 8: 0,88 · wave 10: 0,80 · wave 15: 0,60 · wave 21: 0,40.

```gdscript
const WAVE_INCOME_BASE := 4   # uitbetaling = WAVE_INCOME_BASE + wave_index
```
Wave 2 betaalt 6, wave 10 betaalt 14, wave 15 betaalt 19.

| Level | Nu totaal | Nieuw totaal | Kills nu → nieuw | Salaris nu → nieuw |
|---|---|---|---|---|
| 1 | 640 | 657 | 515 → 322 | 80 → 290 |
| 5 | 800 | 767 | 679 → 456 | 76 → 266 |
| 10 | 715 | 695 | 614 → 489 | 56 → 161 |
| 15 | 942 | 879 | 841 → 673 | 56 → 161 |

Het totaal blijft gelijk, maar de samenstelling kantelt van 88% kills naar 55% kills.

**D3. Reward normaliseren op 0,12 Coffee per HP-equivalent**, met een bewuste band van
±25%: zwermen 0,09 (makkelijk met AoE te raken), tanks en immune types 0,15 (vragen
specifiek gereedschap). Vervangt de huidige spreiding van 0,059 tot 0,200 (zie 1.5).

**D4. The Expense Claim: de tweede economische filosofie.**

> **Petty Cash** → **Expense Report** → **Corporate Card**
> *"Submit by the end of the quarter. Finance does not do exceptions."*

Verzamelt Coffee in een pot in plaats van uit te keren. Klikken claimt de pot en zet hem
op nul. Vol = groei stopt.

| Tier | Kosten | Per wave | Rente | Plafond |
|---|---|---|---|---|
| Petty Cash | 25 | +3 | 10% | 60 |
| Expense Report | 30 (cum 55) | +5 | 15% | 140 |
| Corporate Card | 45 (cum 100) | +8 | 20% | 300 |

Pot bij Corporate Card per wave: 10, 21, 35, 52, 71, 95, 124, 158, 200, 249, **300 (vol op wave 11)**.

Tegenover de Coffee Machine (70C, 192C over 15 waves, doorlopend beschikbaar, terugverdiend
op wave 5): te vroeg claimen is verlies, te laat claimen is verlies, en ondertussen verdedig
je met 100 Coffee minder in een level waar wave 10 om 338 Coffee aan verdediging vraagt.

Optioneel derde spoor, later: **The Bulk Order** (support, -15% op torens binnen de straal,
niet-extrapolerend dus toegestaan in een modus zonder inkomen).

**D5. `SELL_RATIO := 0.6` als constante.** Nu drie losse `0.6` in `level.gd` (816, 924, 2362).
Het percentage zelf blijft: uitverkopen levert nu al 2,43x op als je na wave 10 verkoopt,
dus de 70-80% uit de reference is hier niet nodig.

### 4.5 Koppelingen

**E1. Een vijand die Coffee kost in plaats van Focus.**

> **The Subscription Renewal**
> HP 28, speed 84, Focus-schade **0**, kosten bij doorbraak **15 Coffee**, reward 3,4.
> *"Auto-renewed. Non-refundable. You agreed to this in 2019."*
> Counter: *"It does not hurt your Focus. It empties your wallet. Let it through and you
> cannot afford the next wave."*

Dit is wat The Expense Claim gevaarlijk maakt: je hebt 100 Coffee in een pot zitten en de
wave die erdoorheen breekt kost je precies het geld waarmee je de verdediging had gerepareerd.

### 4.6 Alle vijanden worden collega's (besloten 2026-08-04)

Stond als open ontwerpvraag in `05_MIJN_GAME_CONTEXT.md` §2 en is nu een besluit: elke vijand
wordt een **mens**, de torens blijven **voorwerpen**. Namen zijn nog niet gekozen.

**Waarom dit de identiteit versterkt:** het geeft een schone scheidslijn die je nu niet hebt.
Voorwerpen van je bureau verdedigen je, mensen leiden je af. Dat is in één zin uit te leggen
en het klopt met elke grap in de game.

**De helft is al mens.** Van de 32 defs zijn er 12 al een persoon:

| Al een persoon (12) | Nog om te bouwen (20) |
|---|---|
| The Old Guard, The Micro-manager, The Chatterbox, The Board Member, The Cold Caller, The Phone Caller | The Notification, The Question, User Story, The Nudge, The Thread, The Change, Task, Feedback, The Printer, Error Message, Suspicious Link, System Update |
| The Cleaner, The Smoking Colleague, The Baby, The Floater, The HR Manager, The Consultant | The All-Hands Meeting, The Broken Projector, Out of Order, The Reorganisation, The Legacy System, The Deadline, The Performance Review (x2) |

**De valkuil, en die is echt.** Je noemt de counter-logica zelf de kern van de game
(`05_MIJN_GAME_CONTEXT.md` §4.1), en een deel daarvan leunt erop dat de vijand een **ding** is:

- The Thread is papier, dus de Shredder eet hem (`zone_mult` 1.6).
- The Old Guard is een archief met bewaarplicht, dus de Shredder mag er niet aan (`zone_mult` 0.0).
- The Board Member is nooit fysiek aanwezig, dus Artillery raakt hem niet.

Wordt The Thread een mens, dan slaat "de versnipperaar eet hem" nergens meer op.

**De uitweg: de persoon draagt het ding.** Een collega die met een enorme stapel printjes
aan komt lopen kan nog steeds door de versnipperaar, want wat de versnipperaar pakt is de
stapel. Zo blijft elke bestaande counter kloppen én is elke vijand een mens. Dat is de regel
om aan te houden bij het bedenken van de namen: **de mens is de vijand, het voorwerp dat hij
bij zich draagt is de counter.**

**Wat het raakt:**

| Wat | Omvang |
|---|---|
| `name`, `ability` en `counter` in `enemy.gd` | 20 defs, 60 teksten |
| Tutorial-lesteksten in `game_state.gd` | 4 van de 7 lessen noemen een vijand |
| De invullijst `FB_COLLEAGUES` in `app.gd` | bestaat al, is precies hiervoor gemaakt |
| Sprites in `art/enemies/` | 29 stuks: dit is de art-pass, en die is bewust als laatste gepland |
| `def_id`'s | **niet aanraken.** `seen_enemies` in de save gebruikt ze als sleutel |

**Volgorde:** eerst de namen en de teksten (dat is een schrijfronde, geen code), daarna pas
de sprites in de art-pass. De game is dan meteen consistent in taal, ook al ziet een Thread
er nog uit als een stapel papier.

**De drie sterkste ontbrekende koppelingen, op volgorde:**

1. **Schadeklassen (B3).** Vijf van je zes weerstanden zijn nu te negeren door meer DPS neer
   te zetten; alleen de Chatterbox dwingt een echte switch af. Dit is de koppeling die de
   Auto-Reply-meta breekt zonder Auto-Reply te verzwakken.
2. **Ruimte kopen als serieuze uitgave (C2, C6).** Een tweede bestemming voor Coffee,
   precies in de fase waar het overschot naar 3x tot 8x loopt.
3. **The Subscription Renewal (E1).** Maakt lekken duur op het moment dat je investeert.

---

## 5. Prioriteitenlijst

Impact 1-5, werk in uren. **Geen enkel voorstel breekt saves**: `save_game()` bewaart alleen
progressie en instellingen, geen torens of levelstaat.

| # | Voorstel | Systeem | Impact | Werk | Afhankelijk van |
|---|---|---|---|---|---|
| D1 | `start_coffee` schalen per level | economie | 5 | 0,1 | - |
| Z1 | Ontgrendelcurve uitsmeren (L4-dump) | structuur | 5 | 1 | - |
| D2 | Demping op kills + oplopend salaris | economie | 5 | 1 | - |
| B1 | `shield_min_hit` | vijanden | 4 | 1 | - |
| A7 | Poster wordt straalbuff | torens | 4 | 1 | - |
| A8 | Prijsladder onderkant rechttrekken | torens | 4 | 0,5 | - |
| D3 | Reward normaliseren op 0,12/HP | economie | 4 | 1 | - |
| A3 | Delegation omdraaien | torens | 2 | 0,5 | - |
| C5 | L14-sterrencriterium | structuur | 2 | 0,25 | - |
| D5 | `SELL_RATIO` als constante | economie | 1 | 0,2 | - |
| Z2 | modifiers-tabel opschonen | structuur | 2 | 0,5 | - |
| B3 | Schadeklassen | vijanden | 5 | 2 | - |
| A1 | Crosspath Overtime/Escalation | torens | 5 | 6 | - |
| D4 | The Expense Claim | economie | 5 | 8 | D1, D2 |
| B4 | Vlaggen (Recurring eerst) | vijanden | 4 | 5 | - |
| C1 | `ignores_los` expliciet | maps | 3 | 1 | - |
| A4 | Thumbtacks herprofileren | torens | 3 | 2 | C1 |
| B6 | The Steering Committee (L6) | vijanden | 4 | 1 | B1, B3 |
| E1 | The Subscription Renewal | koppeling | 4 | 1 | D4 |
| A2 | Ctrl+Alt+Del wordt ability | torens | 3 | 3 | - |
| C2 | `pay_zones` uitbreiden | maps | 3 | 1 | - |
| B2 | Splitsketen User Story | vijanden | 3 | 2 | - |
| A5 | Keyboard Smash naar blokkade | torens | 2 | 1 | - |
| A6 | Reply All herprofileren | torens | 2 | 1 | - |
| B5 | The Walk-and-Talk | vijanden | 2 | 0,5 | - |
| C3 | Stopcontacten en stiltezones | maps | 3 | 3 | - |
| C4 | Geboekte ruimtes | maps | 3 | 3 | - |
| B7 | The Quick Question (L12) | vijanden | 3 | 1 | B4, A4 |
| C6 | Drie map-concepten | maps | 3 | 8+ | buiten scope |
| N1 | Alle vijanden omschrijven naar collega's (namen + teksten) | vijanden | 4 | 3 | - |
| N2 | Vijand-sprites naar mensen | art | 3 | art-pass | N1 |

### NU (hoge impact, laag werk, geen afhankelijkheden)

- [x] **D1** `start_coffee` schalen  *(v0.79.0)*
- [x] **Z1** ontgrendelcurve uitsmeren over L4 tot L10  *(v0.80.0)*
- [x] **D2** demping plus oplopend wave-salaris  *(v0.79.0)*
- [ ] **B1** `shield_min_hit`
- [ ] **A8** prijsladder onderkant
- [ ] **A7** Poster als straalbuff
- [ ] **D3** reward normaliseren
- [ ] **A3** Delegation omdraaien
- [ ] **C5** L14-sterren, **D5** SELL_RATIO, **Z2** modifiers opschonen

### DAARNA (hoge impact, hoog werk, of afhankelijk van NU)

- [ ] **B3** schadeklassen
- [ ] **A1** crosspath
- [ ] **D4** The Expense Claim
- [ ] **B4** vlaggen, Recurring eerst
- [ ] **C1** `ignores_los` → **A4** Thumbtacks
- [ ] **B6** The Steering Committee
- [ ] **E1** The Subscription Renewal
- [ ] **A2** Ctrl+Alt+Del als ability
- [ ] **C2** pay_zones uitbreiden
- [ ] **B2** splitsketen User Story
- [ ] **N1** alle vijanden omschrijven naar collega's (namen + `ability` + `counter`)

### LATER (nice to have)

- [ ] **C3** stopcontacten en stiltezones
- [ ] **C4** geboekte ruimtes
- [ ] **B7** The Quick Question
- [ ] **A5** Keyboard Smash, **A6** Reply All, **B5** The Walk-and-Talk
- [ ] **C6** map-concepten (buiten de huidige scope van 15 levels)
- [ ] **N2** vijand-sprites naar mensen (hoort bij de art-pass, na N1)

---

## 6. Regels om te bewaken

1. **Elk nieuw voorstel moet op minstens één van de vier assen uit de reference iets
   toevoegen**: wat het raakt, hoeveel het raakt, waar het mag staan, of wat het kost
   tegenover wat het oplevert. Een toren die op alle vier hetzelfde scoort als een bestaande
   voegt niets toe.
2. **Een immuniteit hoort een build te straffen, niet een toren.** Daarom schadeklassen.
3. **Een economische aankoop moet fout kunnen zijn.** De Coffee Machine verdient zich terug
   op wave 5 van 15 en is daarmee geen beslissing.
4. **Na elke wijziging opnieuw meten** met de drie scripts in `tools/`, want de balansgetallen
   in dit document zijn een momentopname van v0.78.0.
