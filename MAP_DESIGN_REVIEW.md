# Office Tower Defense — Map & Level Design Review (integraal advies)

> **Status:** DATA-LAAG DOORGEVOERD in v0.55.0 (2026-07-25). Alle layout-/pad-/obstakel-/muur-/
> pay-zone-/nobuild-/reveal-/corridor-wijzigingen, de volgorde-wissels 6↔7 en 12↔13, de
> hazard-verhuizingen (brandalarm 2→10, QTE→15), de modifier-aanpassingen, de banned-fix
> (auto+machinegun i.p.v. phones) en de code-fix (ontgrendelde pay-zone overrulet obstakel) zitten
> erin en zijn headless + visueel getest. **NOG NIET gedaan** (groter code/art-werk): de boss-cameo-
> fase van L15 ("360° feedback"), spawn-deur-sprites voor reveals/spawns achter de shopbalk, en het
> aankleden van de dode zone boven de boardroom-tafel. De optionele L15-zijdeur wacht op playtests.
>
> Oorspronkelijke samenvoeging van twee reviews (2026-07-25):
> de gameplay-review (curve, gimmicks, bosses, hazards) en de ruimtelijke layout-review
> (padvormen, dekking, bouwruimte — gebaseerd op de échte coördinaten uit
> `scripts/game_state.gd`, toren-ranges uit `scripts/tower.gd` en de corridor-breedte uit
> `scripts/level.gd`).
>
> Veld-conventies: basis 960×540, grid 40 px, padpunten op vak-middens (40k+20),
> bouwbaar tot x ≤ 780 (shopbalk rechts), bureau vrijwel altijd aan de rechterrand.
> Elk level heeft 20 waves.

---

## 1. Samenvatting — de tien belangrijkste beslissingen

1. **Level 15 wordt weer de Boardroom.** De 4-lane-corridor-finale vervalt; 5/10/15 delen
   exact dezelfde arena en lopen op via restricties (vrij → pilaren + few_spots → corridor),
   events en de boss. De epiek komt uit de finale-boss ("360° feedback": eerdere bosses
   keren terug als mini-cameo's), niet uit een nieuwe padvorm.
2. **Corridor-bouwen alleen nog op 14 en 15** (leren → examineren). De Merger verliest
   corridor en krijgt er een écht merge-mechaniek voor terug (invoegend onthul-pad).
3. **Softlock opgelost in HR Room:** niet Headphones bannen (enige Chatterbox-counter),
   maar **Auto-Reply + Quick Reply** ("informal communication violates our tone-of-voice
   policy").
4. **Brandalarm verhuist van level 2 naar level 10** — een fire drill midden in je
   Performance Review. Level 2 houdt zo één les; de eerste hazard van het spel wordt de
   projector-QTE in level 3.
5. **Volgorde-wissels:** Work From Home vóór The Parking (6 ↔ 7) en The Merger vóór de
   Server Room (12 ↔ 13). Zachte introductie vóór de zware toepassing, plus een senior-
   verhaallijn: HR-audit → fusie → legacy erven → release night → eindreview.
6. **The Parking wordt écht gespreid:** banen van 160 px (= geometrisch identiek aan de
   Canteen én triviaal te dubbel-dekken) naar 240/200 px met twee rand-banen.
7. **Canteen krijgt wet-floor geen-bouw-vakken** in de dominante binnenband: dicht de
   curve-dip, introduceert geen-bouw zacht, en past bij The Cleaner.
8. **Server Room wordt gangpaden-slinger met pay-zones bóvenop de racks** ("root access"):
   de enige dubbel-dek-plekken zijn de plekken die je moet vrijkopen.
9. **Town Hall-spaken krijgen ellebogen** en gebruiken de rechterhelft van de map; Flexplek
   krijgt een zuid-deur die de merge-staart halverwege binnenvalt.
10. **Expliciet modifier-budget:** junior 0–1, medior 1, senior 2 gelijktijdige extra's.
    Server Room levert daarvoor few_spots in (dubbelde met de pay-zones).

---

## 2. Systeem-inzichten — de getallen waar alle layout-keuzes op rusten

### 2.1 Lane-afstand heeft drie harde drempels

Standaard toren-range is ~115–165 px (Artillery 220–236, Shredder 95–125). Een toren
tussen twee evenwijdige banen staat op de **halve baanafstand** van beide:

| Baanafstand | Halve afstand | Effect |
|---|---|---|
| **160 px** | 80 | *Elke* toren dekt beide banen. Dit is "samenkomend", niet gespreid. |
| **200 px** | 100 | Shredder valt af; de rest dekt nog dubbel. |
| **240 px** | 120 | Basis-torens (115–125) halen het niet meer; midden-torens (135–165) nét. Half-gespreid. |
| **280+ px** | 140+ | Alleen **Office Artillery** (220–236) dekt nog twee banen. Echt gespreid. |

Gevolgen: (a) gebruik 160 px in junior, 240 in medior, 280+ in senior als je "gespreid"
bedoelt; (b) Artillery wordt vanzelf "de sniper die spreiding oplost" — een mooie
speler-ontdekking, showcase in The Parking.

### 2.2 In corridor-levels zijn bochten de énige bron van keuzes

De bouwstrook is 100 px (~2,5 tegel, `CORRIDOR_BUILD_DIST` in `level.gd`). Op een recht
stuk is elke bouwplek gelijkwaardig — nul beslissingen. Alleen bij een 90°-bocht bestaan
cellen die twee pad-benen tegelijk bereiken. **Corridor-levels hebben dus méér bochten
nodig dan gewone levels, niet minder.** (De oude L13/14/15 waren vrijwel kaarsrecht —
zwaarste restrictie op de armste geometrie.)

### 2.3 Rand-banen zijn een gratis moeilijkheids-knop

Een baan op de maprand (y ≈ 20 of y ≈ 500) heeft maar aan één kant bouwruimte — halveert
de dekking zonder extra mechaniek. Ingezet in de nieuwe Parking.

### 2.4 Onthul-paden: zacht vs. hard

- **Invoegend** (nieuw pad sluit aan op je bestaande route): je verdediging dekt al de
  helft → de zachte versie. → The Merger (L12).
- **Gescheiden** (volledig eigen route tot vlak voor het bureau): tweede front → de harde
  versie. → Release Night (L14).
  Zelfde verrassing, oplopende prijs.

### 2.5 Merge-afstand als tuning-knop (multi-ingang)

Hoe verder het merge-punt van het bureau ligt, hoe langer de gedeelde staart en hoe
sterker één AoE-fort → makkelijker. Dichter bij het bureau = zwaarder. Flexplek staat nu
op 280 px staart; dat is de knop bij het balanceren.

### 2.6 Modifier-budget per blok

Maximaal aantal gelijktijdige extra's (hazard/event/modifier bovenop de gimmick):
**junior 0–1 · medior 1 · senior 2.** De stapeling zelf wordt zo een leesbare
moeilijkheids-knop.

---

## 3. Herzien overzicht — alle 15 levels

Wijzigingen t.o.v. de oude opzet zijn **vetgedrukt**. Volgorde-wissels: 6↔7 en 12↔13;
level 5/10/15 liggen vast.

| # | Blok | Thema | Gimmick | Layout (kort) | Boss — wat 'ie doet | Hazard / Event / Modifier |
|---|---|---|---|---|---|---|
| 1 | junior | Open-Plan Office | Simpele intro | S-bocht, 1 pad, bureau rechtsboven | The All-Hands Meeting — spawnt Notifications | — |
| 2 | junior | Coffee Corner | Snelheid / crowd-control | Piek-S, lange rechten | Out of Order — blokkeert Coffee-inkomen zolang hij leeft | **—** (brandalarm → L10) |
| 3 | junior | Meeting Room | Zwerm vs. area | Kam (tanden 240 px uit elkaar) | The Broken Projector — schild, beamt slides | Projector-QTE (**eerste hazard van het spel**) |
| 4 | junior | Canteen | Diversiteit + **zachte intro geen-bouw ("wet floor")** | Grote omtrek-lus, exit dwars door het midden | The Cleaner — versnelt vijanden, veegt zones/vallen weg | Lunch-swarm + **wet-floor-vakken** |
| 5 | junior | **Boardroom Ⅰ** | Review-arena, vrij bouwen | ¾-ring rond de vergadertafel | The Performance Review — 3 fases | — |
| 6 | medior | **Work From Home** *(was 7)* | Zicht-muren in vergevingsgezinde lus | Compacte spiraal-lus | The Baby — nabije torens vuren trager | "No Internet" dino-mini-game |
| 7 | medior | **The Parking** *(was 6)* | Écht gespreide switchback + geen-bouw (auto's) | **Banen op 240/200 px, twee rand-banen** | The Smoking Colleague — rook verkort bereik | Rook (bereik ↓) |
| 8 | medior | The Flexplek | Multi-ingang (4 deuren, rouleren) | W/W/N-deuren mergen; **zuid-deur valt de staart halverwege binnen** | The Floater — trekt van alle kanten menigtes aan | — (rouleren ís de druk) |
| 9 | medior | Town Hall | Bureau-in-het-midden (3 fronten, géén merge) | **Elleboog-spaken** i.p.v. rechte spaken | The Reorganisation — splitst Managers af per fase | Telefoon-event + half_coffee |
| 10 | medior | **Boardroom Ⅱ** | Zelfde arena + pilaren + few_spots | Identieke padvorm als L5 | The Performance Review — zwaarder | **Brandalarm ("fire drill mid-review")** + few_spots |
| 11 | senior | HR Room | Kam-subversie: muur in de aangeleerde pocket + banned | Kam (240 px) + 3 zicht-muren | The HR Manager — legt telkens één torentype stil | Formulier-event + **Auto-Reply & Quick Reply verboden** |
| 12 | senior | **The Merger** *(was 13)* | **Invoegend onthul-pad** (geen corridor meer) | Haak-pad van links; wave ~12 voegt pad van rechtsonder in | The Consultant — buft alle vijanden; dood hem = wave breekt | **half_coffee ("consultancy fees")** |
| 13 | senior | **Server Room** *(was 12)* | **Gangpaden tussen rack-rijen + pay-zones óp de racks** | Slinger door smalle aisles | The Legacy System — vrijwel onkillbaar, spuwt Error Messages | Oververhitting (**few_spots geschrapt**) |
| 14 | senior | Release Night | Corridor-bouwen (leert het) + **gescheiden** onthul-front | **Twee zigzag-corridors**, alleen de laatste kolom gedeeld | The Deadline — alles versnelt zolang hij leeft | "Eat the Pizza" + low_focus (10) |
| 15 | senior | **Boardroom Ⅲ** | Zelfde arena + **corridor-bouwen** | **Identieke padvorm als L5/L10** | The Performance Review, finale — **"360° feedback": eerdere bosses keren terug als mini-cameo's** | Corridor + projector-QTE ("your final presentation") |

---

## 4. De Performance-Review-arena (level 5 / 10 / 15)

### 4.1 De gedeelde layout (blijft zoals gebouwd)

```
pad:    (-60,100) → (140,100) → (140,420) → (700,420) → (700,100) → (780,100)
tafel:  Rect2(360,180, 240,160)          bureau: rechtsboven (780,100)
```

Een **¾-ring** rond de tafel: linksom naar beneden, onderlangs, rechts omhoog, exit
rechtsboven. ±1480 px pad. Drie gelijkwaardige zones (links / onder / rechts), elk met een
eigen premium-plek — precies genoeg vet om in twee stappen weg te snijden.

**Hoe de arena speelt (dekkingskaart):**

| Plek | Positie (±) | Dekt | Kwaliteit |
|---|---|---|---|
| Binnenhoek links-onder | (200,360) | linkerbeen + onderbeen (60/60 px) | ★★★ premium |
| Binnenhoek rechts-onder | (640,360) | onderbeen + rechterbeen (60/60 px) | ★★★ premium |
| Binnenband links | x 180–260 | linkerbeen | ★★ |
| Binnenrij onder | y = 380 | onderbeen (40 px — Shredder-rij) | ★★ |
| Binnenkolom rechts | x = 640 | rechterbeen | ★★ |
| Buitenring | rondom | het aangrenzende been | ★ |
| Boven de tafel | x 360–600, y 100–160 | **niets** (240+ px van elk been) | dode zone |

> De dode zone boven de tafel expliciet als **decor** stylen (whiteboard, planten), anders
> leest de speler het als "kapotte" bouwruimte.

### 4.2 De ladder — zelfde kamer, drie keer vijandiger

| | Restricties | Events | Boss | Wat het geometrisch doet |
|---|---|---|---|---|
| **L5** | geen | — | 3 fases (schild → spawnt Feedback → versnelt + vertraagt torens) | Alles open; speler ontdekt de binnenhoeken en de Shredder-rij. |
| **L10** | pilaren `(260,150,18,90)` + `(650,300,18,90)`, few_spots | brandalarm (fire drill mid-review) | idem, zwaarder | Pilaar 1 halveert de linkerband, pilaar 2 snijdt de binnenkolom af. **Binnenhoeken blijven bewust vrij** — few_spots dwingt je schaarse torens dáárheen; de arena toetst wat L5 leerde. |
| **L15** | pilaren blijven staan + **corridor** (100 px strook) | projector-QTE ("your final presentation") | finale + **cameo-fase**: mini-versies van eerdere bosses (All-Hands, Cleaner, Consultant…) als "peer reviewers" | Corridor snijdt de buitenring af: linkerband 4→2 kolommen, onder nog 2 rijen, dode zone sowieso weg. Wat overblijft is exact de kennis-route van L5/L10, onder de zwaarste waves. |

Padvorm identiek in alle drie; alleen wat eromheen mag verandert. Het speelveld-verval
(vrij → gesnoeid → strook) vertelt zelf het verhaal "elke review wordt de kamer
vijandiger". Bijvangst van de cameo's: hergebruik van bestaande boss-code en -sprites.

**Achtervang (alleen als playtests erom vragen):** een zijdeur `(140,600) → (140,420)` die
vanaf ~wave 15 vijanden halverwege de bestaande lus laat instappen. Wijzigt de padvorm
niet — het is een extra spawn óp de lus. Niet vooraf inbouwen.

**Waarom de oude 4-lane-finale vervalt:** hij ruilt de sterkste narratieve beat (terug in
dezelfde review-kamer) in voor een generieke map; vier lanes die bij het bureau samenkomen
zijn per het samenkomend-is-makkelijker-principe zwakker dan ze ogen; gespiegelde lanes
delen dezelfde tegelrij in tegengestelde richting (vijanden kruisen elkaar frontaal —
onleesbaar); en vier réchte lanes is per §2.2 de armste corridor-vorm die er is.

---

## 5. Per level — diagnose, layout en onderbouwing

### Blok 1 · junior — gebouwd en gebalanceerd; alleen chirurgische ingrepen

#### Level 1 — Open-Plan Office
- **Pad:** `(-60,100)→(300,100)→(300,300)→(580,300)→(580,140)→(780,140)` · ±1140 px
- **Diagnose:** prima intro. Eén duidelijke binnenpocket rond (440,220) die de onderrun en
  beide verticalen deels dekt — de speler ontdekt vanzelf "in de bocht bouwen is beter".
  Leesbaarheid perfect (links in, rechts bureau).
- **Wijziging: geen.**

#### Level 2 — Coffee Corner
- **Pad:** `(-60,260)→(340,260)→(340,100)→(620,100)→(620,420)→(780,420)` · ±1320 px
- **Diagnose:** goed voor de snelheids-les: twee lange rechten (400/320 px) waar sprinters
  uitrekken; pockets rond (380,180) (drie benen) en (680,340) (afdaling + bureaurun).
  Boss Out of Order is een stiekem briljante targeting-les ("dood de boss éérst").
- **Wijziging: brandalarm eruit** (→ L10). Level 2 introduceerde anders twee lessen
  tegelijk (economie-boss én hazard). Eerste hazard van het spel wordt de projector-QTE
  in L3, die zichzelf uitlegt. De bestaande brandalarm-code verhuist alleen van koppeling.

#### Level 3 — Meeting Room
- **Pad:** `(-60,420)→(180,420)→(180,140)→(420,140)→(420,420)→(660,420)→(660,140)→(780,140)` · ±1680 px
- **Diagnose:** kam met tanden op 240 px — precies de drempel waar dubbel-dekken nét kan
  (120 ≤ 135): belonend zonder gratis te zijn. De U-bocht-binnenhoeken (bv. (220,380),
  40 px van beide benen) zijn perfecte Shredder-plekken — de area-les werkt geometrisch.
- **Wijziging: geen** (behalve dat de QTE nu de éérste hazard is — geen inhoudelijke
  verandering voor dit level zelf).

#### Level 4 — Canteen
- **Pad:** `(-60,100)→(700,100)→(700,420)→(180,420)→(180,260)→(780,260)` · ±2300 px (langste van het spel)
- **Diagnose:** het enige junior-probleem. De drie horizontale banen liggen 160 px uit
  elkaar, dus de binnenband rond (440,180) dubbel-dekt met élke toren; samen met de
  extreme padlengte is L4 layout-technisch makkelijker dan L3 — een dip in de curve.
- **Wijziging:** pad laten staan (gebalanceerd), maar **wet-floor geen-bouw-vakken** in de
  dominante band: `Rect2(340,140,80,80)` en `Rect2(500,140,80,80)`. Laat één pocket-cel
  over (±(460,180)) zodat dubbel-dekken een schaarse vondst wordt. Drie vliegen: de dip is
  weg, geen-bouw is zacht geïntroduceerd vóór The Parking erop leunt, en de bordjes zijn
  thematisch van The Cleaner (die hier boss is en zones/vallen wegveegt).
- **Let op (vraag 1, §9):** de Cleaner veegt Shredder-zones en punaises — check dat die
  torens op dit punt in het unlock-schema al beschikbaar zijn.

#### Level 5 — Boardroom Ⅰ
- Zie §4. Vrij bouwen, geen events; boss met 3 fases. De speler leert de arena kennen.

### Blok 2 · medior — wissel 6↔7; zachte introductie vóór zware toepassing

#### Level 6 — Work From Home *(was level 7)*
- **Pad:** `(-60,260)→(220,260)→(220,140)→(580,140)→(580,420)→(340,420)→(340,260)→(780,260)` · ±1880 px
- **Muren:** `Rect2(400,180,20,130)` en `Rect2(180,330,130,20)`
- **Diagnose:** sterkste medior-layout. De exit-run snijdt door het lus-binnenste,
  waardoor rond (460,200) een *triple*-dip-pocket ligt (60/60/120 px van drie runs) — en
  de zicht-muren staan er precies in om hem te splitsen. Exact hoe je LOS moet
  introduceren: de speler ziet de perfecte plek, ontdekt dat de muur hem halveert, en
  leert om de muur héén te denken. Lang pad = vergevingsgezind.
- **Wijziging: alleen de positie in de volgorde** (nu direct ná de promotie). Nieuw
  concept (LOS) in een vergevingsgezinde layout vóór de zware combinatie van The Parking.

#### Level 7 — The Parking *(was level 6)*
- **Oud pad:** banen op y=100/260/420 — 160 px uit elkaar. Per §2.1 is dat geen spreiding,
  en het is exact dezelfde rijen-set als de Canteen (visuele herhaling).
- **Nieuw pad:** `(-60,60)→(700,60)→(700,300)→(100,300)→(100,500)→(780,500)` · ±2420 px
  — banen op y=60/300/500 (240/200 px uit elkaar), buitenste twee zijn **rand-banen** met
  maar één bouwkant. Bureau rechtsonder. Geen-bouw-auto's verschuiven mee naar de nieuwe
  tussenbanden.
- **Waarom:** zonder rook is dubbel-dekken nu al schaars (120+ px), mét rook onmogelijk —
  de hazard krijgt eindelijk geometrische tanden in plaats van een pad dat hem tegenwerkt.
  Artillery (220–236) dekt wél nog twee banen: dit level is de showcase voor "sniper lost
  spreiding op". Lang pad compenseert; de moeilijkheid zit in dekking, niet in tijd.

#### Level 8 — The Flexplek
- **Huidig:** 4 deuren mergen op (500,260), staart van 280 px naar bureau (780,260).
  Deuren: links-boven, links-onder, boven (x=260), boven (x=500).
- **Diagnose:** (1) deuren zitten W/W/N/N — leest niet als "van alle kanten"; (2) deur 4
  bereikt de merge al na 320 px; (3) de 280-px-staart is zó lang dat één AoE-fort op de
  staart de rotatie-gimmick platslaat.
- **Wijziging:** houd deuren 1–3; vervang deur 4 door een **zuid-deur die de staart
  halverwege binnenvalt**: `(620,600)→(620,260)→(780,260)`.
- **Waarom:** windrichtingen kloppen (W/W/N/Z), en de zuid-deur slaat 120 px van het
  staart-fort over — het fort blijft de juiste les ("merge = choke") maar dekt niet langer
  álles, dus per-deur-dekking houdt waarde. **Merge-afstand (280 px) is de tuning-knop**
  bij het balanceren (§2.5).

#### Level 9 — Town Hall
- **Huidig:** drie kaarsrechte spaken naar het centrale bureau (460,260); geen enkele
  bocht; de complete rechterhelft van de map is dood terrein.
- **Diagnose:** keuze-arme donut — de enige strategie is een ring pal om het bureau.
  Rechte spaken zijn per §2.2 het armste wat je kunt tekenen.
- **Nieuwe spaken:**
  - West (hoofdingang, blijft recht): `(-60,260)→(460,260)`
  - Noord met elleboog: `(220,-60)→(220,140)→(460,140)→(460,260)`
  - Zuidoost met elleboog: `(700,600)→(700,380)→(460,380)→(460,260)`
- **Waarom:** twee kwaliteits-pockets ontstaan — (340,200) dekt west + noord (60/60 px),
  (580,320) dekt west + zuidoost — zodat mid-field bouwen een echt alternatief wordt voor
  de donut. Spaken krijgen eigen karakter en vergelijkbare lengte (±460–520 px); de
  rechterhelft doet mee. Leesbaarheid blijft: alles eindigt zichtbaar in het midden.
- **Bewust zo laten:** AoE-specials dekken maar één spaak (spaken delen geen tegel vóór
  het bureau) — dat ís de moeilijkheid van center-desk. Samen met half_coffee en het
  telefoon-event de terechte piek vóór de blok-boss.

#### Level 10 — Boardroom Ⅱ
- Zie §4. Zelfde padvorm; pilaren + few_spots; **brandalarm als "fire drill mid-review"**
  (verhuisd uit L2 — comedy én escalatie); boss zwaarder.

### Blok 3 · senior — wissel 12↔13; verhaallijn: audit → fusie → legacy → release → review

#### Level 11 — HR Room
- **Pad:** `(-60,100)→(300,100)→(300,420)→(540,420)→(540,100)→(780,100)` · ±1480 px
- **Muren:** `(150,210,18,150)`, `(420,170,18,170)`, `(640,240,18,150)` · geen-bouw `(620,420,120,80)`
- **Diagnose — zo houden:** dit is stiekem heel slim. Geometrisch een L3-kam (zelfde
  240-spacing, dus de speler herkent de dubbel-dek-pocket)… en de middelste muur staat er
  *precies* in. "De plek die je in blok 1 leerde, is hier afgepakt" — subversie van
  aangeleerde kennis, precies wat senior moet doen. De flankmuren nerfen de linkerbeen-
  aanloop en de bureau-hoek. De kam-gelijkenis met L3 is hier een feature.
- **Wijziging (kritiek): banned-lijst.** Headphones bannen creëert een **softlock** — het
  is per ontwerp de enige Chatterbox-counter, en een wave-afspraak ("geen Chatterbox in
  L11") breekt bij elke wave-tabel-wijziging. Ban in plaats daarvan **Auto-Reply +
  Quick Reply**: "informal communication violates our tone-of-voice policy". Grappiger,
  dwingt net zo goed tot adaptatie, en de Cold Caller (immuun voor Auto-Reply) wordt er
  niet per ongeluk irrelevant door. In code: `banned = {11: ["auto", "machinegun"]}`
  i.p.v. `["phones", "machinegun"]`.

#### Level 12 — The Merger *(was level 13)*
- **Oud:** één rechte horizontale lijn met bureau in het midden + rechte tegenlijn op
  wave 10, in corridor-modus. De armste map van het spel: nul bochten, nul keuzes, en
  on-thematisch — er "merget" niets, de paden botsen alleen.
- **Nieuw** (corridor gaat eraf; open bouwen):
  - Hoofdpad (jouw bedrijf, van links): `(-60,140)→(300,140)→(300,380)→(620,380)→(620,220)→(780,220)` · ±1240 px, bureau rechts-midden
  - Onthul-pad (het overgenomen bedrijf, **wave ~12**, van rechtsonder buiten beeld):
    `(840,460)→(460,460)→(460,380)` — **voegt in** op de bestaande onderrun en volgt de
    rest van jouw route naar het bureau
  - Modifier: **half_coffee** ("consultancy fees" — de Consultant kost je letterlijk de
    helft van je budget)
- **Waarom:** nu merget er letterlijk een route in — het thema ís de mechaniek. Bestaande
  torens langs de onderrun en de (620,380)-hoek krijgen meteen waarde tegen het nieuwe
  pad: de zachte versie van het onthul-principe (§2.4), die L14 daarna verzwaart. Eerder
  in het blok dan de Server Room omdat één gimmick + één modifier lichter is dan de
  hazard-stapeling daar — én de verhaallijn klopt (na de fusie erf je hun legacy-systeem).
- **Leesbaarheid:** de spawn op x=840 ligt achter de shopbalk — teken een deur-sprite op
  de rand (x=780), anders lijken vijanden uit de UI te komen (vraag in §9).

#### Level 13 — Server Room *(was level 12)*
- **Oud:** alwéér een kam (derde van het spel) met racks in de pockets, plus few_spots
  bóvenop pay-zones en oververhitting — de zwaarste stapeling van het spel, verstopt.
- **Nieuw — gangpaden-slinger:**
  - Racks: `Rect2(140,120,520,80)` (A) en `Rect2(300,280,480,80)` (B)
  - Pad: `(-60,60)→(700,60)→(700,240)→(220,240)→(220,420)→(780,420)` · ±2100 px, bureau rechtsonder
  - De gangpaden zelf zijn te smal om in te bouwen; vrije bouwruimte alleen aan de
    marges en in de hoeken
  - **Pay-zones bovenop de racks** ("root access"): `Rect2(300,120,160,80)` en
    `Rect2(460,280,160,80)` — een toren op rack A staat op ~80–100 px van twee gangpaden
  - Modifiers: oververhitting; **few_spots geschrapt** (de pay-zones beperken je
    bouwplekken al — dubbel dekkend, en het modifier-budget van §2.6 staat op 2)
- **Waarom:** een serverruimte ís smalle gangpaden — claustrofobie als thema én
  mechaniek. De pay-zone wordt eindelijk de kern-beslissing van het level in plaats van
  een hoekje: de enige dubbel-dek-plekken zijn de plekken die je moet vrijkopen, onder
  druk van oververhitting. Lang pad, maar bijna geen gratis bouwruimte — lengte en
  bouwdruk in balans.
- **Code-notitie:** pay-zone moet het obstakel-bouwverbod kunnen overrulen (nu sluiten
  die elkaar uit) — zie §8.

#### Level 14 — Release Night
- **Oud:** twee kaarsrechte parallelle lanes (680 px recht) die bij het bureau
  samenkomen. Rechte corridors = nul beslissingen (§2.2).
- **Nieuw** (corridor blijft — dit level leert corridor-bouwen voor de finale):
  - Hoofdpad: `(-60,60)→(300,60)→(300,180)→(580,180)→(580,60)→(740,60)→(740,260)` · ±1180 px, bureau (740,260)
  - Onthul-pad **wave 10, volledig gescheiden front**:
    `(-60,460)→(220,460)→(220,340)→(500,340)→(500,460)→(740,460)→(740,260)` · ±1220 px
  - Hazards/modifiers: "Eat the Pizza"-mini-game + low_focus (start 10 Focus)
- **Waarom:** elk pad heeft vier bochten — in corridor-modus acht hoek-pockets, dus de
  smalle strook zit vol echte keuzes. De fronten delen alleen de laatste kolom (x=740,
  van boven én onder het bureau in): één klein nood-choke, maar met low_focus moet de
  speler wél twee volwaardige verdedigingen runnen. De harde versie van het
  onthul-principe, ná L12's zachte versie. Terechte piek vóór de finale.

#### Level 15 — Boardroom Ⅲ
- Zie §4. Zelfde padvorm als L5/L10; pilaren blijven staan; **corridor-bouwen** als grote
  knijp; projector-QTE ("your final presentation"); boss-finale met **cameo-fase**.

---

## 6. Rode draad — de curve in één tabel

Padlengte lees je samen met bouwtoegang: lang pad + vrije bouw = makkelijk; kort of recht
pad + restricties = zwaar.

| # | Map | Vorm | ±Lengte | Dekkings-karakter | Layout-druk |
|---|---|---|---|---|---|
| 1 | Open-Plan | S | 1140 | 1 duidelijke pocket | geen |
| 2 | Coffee Corner | piek-S | 1320 | 2 pockets, lange rechten | geen |
| 3 | Meeting Room | kam (240) | 1680 | dubbel-dek nét haalbaar | geen |
| 4 | Canteen | omtrek-lus | 2300 | banden 160 → wet-floor snoeit | wet-floor |
| 5 | Boardroom Ⅰ | ¾-ring | 1480 | 3 zones, 2 binnenhoeken | geen |
| 6 | WFH | spiraal-lus | 1880 | triple-pocket, door muren gesplitst | 2 muren |
| 7 | Parking | switchback | 2420 | banen 240/200 + rand-banen; alleen sniper dubbelt | auto's + rook |
| 8 | Flexplek | 4-ster met staart | 560–680/deur | staart-choke; zuid-deur omzeilt de helft | rotatie |
| 9 | Town Hall | elleboog-spaken | 460–520/spaak | 2 pockets tussen spaken, geen gedeelde choke | 3 fronten + half_coffee |
| 10 | Boardroom Ⅱ | ¾-ring | 1480 | hoeken vrij, banden gesnoeid | pilaren + few_spots |
| 11 | HR Room | kam (240) + muren | 1480 | "je oude pocket is afgepakt" | muren + banned |
| 12 | Merger | haak + invoeg-pad | 1240 (+460) | invoegend front; bestaande dekking telt | half_coffee |
| 13 | Server Room | gangpad-slinger | 2100 | dubbel-dek alléén op gekochte racks | pay + overheat |
| 14 | Release Night | 2× zigzag-corridor | 1180+1220 | 8 hoek-pockets in smalle strook | corridor + low_focus |
| 15 | Boardroom Ⅲ | ¾-ring | 1480 | bekende plekken, strook-versie | corridor + pilaren |

**De curve per blok:** junior geeft steeds langere, zelf-aangrenzende paden met vrije
bouw (vergevingsgezindheid groeit mee met de wave-druk); medior spreidt de geometrie
(spacing 160→240, rotatie, fronten zonder choke); senior houdt paden kort of knijpt de
bouwruimte (muren → betaald → strook), eindigend in de arena die je al twee keer kende.

**Vorm-variatie-audit:** alle 15 vormen zijn nu uniek behalve de bedoelde herhalingen —
de Boardroom-trilogie (het ritueel) en de kam van L3/L11 (bewuste subversie). De oude
duplicaten (Parking = Canteen-rijen; drie kammen; drie rechte corridors) zijn opgelost.

---

## 7. Ontwerpregels & softlock-checks (bewaken bij elke wave-tabel-wijziging)

1. **Chatterbox nooit in een level waar Headphones gebannen of onbereikbaar (lv3) is.**
   Opgelost voor L11 via de nieuwe banned-lijst, maar blijft een regel.
2. **Suspicious Link (onzichtbaar) nooit vóór de Shredder-unlock** — reveal is er de enige
   counter voor.
3. **The Cleaner (L4) veegt Shredder-zones en punaises** — die torens moeten dan al
   beschikbaar zijn in het unlock-schema, anders is de boss-mechaniek onzichtbaar.
4. **Modifier-budget:** junior 0–1, medior 1, senior 2 gelijktijdige extra's (§2.6).
5. **Samenkomend = makkelijker:** lane-afstanden bewust kiezen op de drempels van §2.1
   (junior ≤160, medior ±240, senior ≥280 waar spreiding bedoeld is).
6. **Corridor-levels hebben bochten nodig** — nooit een recht corridor-pad (§2.2).
7. **5/10/15: padvorm heilig.** Escalatie alleen via restricties, events, hazards en de
   boss. (Pilaren, few_spots en corridor wijzigen de padvorm niet en zijn dus legaal.)

---

## 8. Implementatie-notities (`scripts/game_state.gd` tenzij anders vermeld)

- **`paths`:** nieuwe waypoints voor 7 (Parking), 12 (Merger), 13 (Server Room),
  14 (Release Night); 15 → `boardroom`. Volgorde-wissels 6↔7 en 12↔13 betekenen dat
  thema-gebonden data (namen, waves, hazards, bosses) mee-verhuist met het thema, niet
  met het nummer.
- **`multi`:** L8 deur 4 vervangen door `(620,600)→(620,260)→(780,260)`; L9 de drie
  elleboog-spaken.
- **`reveals`:** 12 (invoegend, trigger ~12), 14 (gescheiden, trigger 10); 15 leegmaken
  (de oude 4-lane-reveals vervallen). Optionele L15-zijdeur pas na playtests.
- **`obstacles`:** 13 → rack A/B; 15 → `boardroom_table` toevoegen (deelt met 5/10).
- **`walls`:** 10 → ook aan 15 koppelen (pilaren blijven staan in de finale).
- **`pay_zones`:** 13 → de twee rack-top-zones. **Code-wijziging:** pay-zone moet het
  obstakel-bouwverbod overrulen (volgorde van de checks in `level.gd` omdraaien:
  eerst betaalde zone, dan obstakel).
- **`nobuild`:** 4 → wet-floor-rects toevoegen; 7 → auto's naar de nieuwe tussenbanden.
- **`corridor`:** `{14: true, 15: true}` — 13 (Merger-oud) eruit.
- **`hazards`:** brandalarm van 2 naar 10; QTE naar 15 toevoegen; verder mee-verhuizen
  met de thema's.
- **`modifiers`:** 12 → `["half_coffee"]`; 13 → few_spots eruit; 15 → geen extra
  economy-modifier (corridor is de knijp).
- **`banned`:** `{11: ["auto", "machinegun"]}`.
- **Boss-cameo's (L15):** nieuwe fase in de boss-logica die bestaande boss-`type_id`'s
  als verkleinde adds spawnt — hergebruik van bestaande code en sprites.
- **Spawn-deuren:** deur-sprites op de spawn-randen, zeker voor reveals en voor spawns
  achter de shopbalk (x > 780).
- **Decor:** dode zone boven de boardroom-tafel aankleden (whiteboard/planten).

---

## 9. Open vragen

1. **Toren-unlock-schema blok 1:** welke torens zijn per level beschikbaar? Bepalend voor
   L4 (Cleaner-mechaniek) en de Chatterbox/Headphones-regel.
2. **Vijand-debuut-schema:** wanneer verschijnen Suspicious Link en Chatterbox voor het
   eerst? (Regels 1–2 uit §7.)
3. **Spawns achter de shopbalk** (Merger x=840): is de shopbalk transparant genoeg dat een
   deur-sprite op x=780 volstaat, of reveal-spawns van rechts vermijden?
4. **Onthul-fairness:** vooraf een subtiele hint (dichte deur zichtbaar, zonder pad), of
   volledige verrassing zoals de code-comment nu zegt?
5. **Sterren-criteria:** waar hangen de sterren aan? Bepalend voor of half_coffee /
   low_focus een 3-sterren-run onredelijk maken.
6. **Onthul-timing:** reveals op wave 10 van 20 is precies halverwege; wave 12–14 zou
   spannender zijn (minder hersteltijd). Voorkeur?
