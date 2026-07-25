# Art Style Guide — Office Tower Defense

Zo lever je sprites aan zodat ze automatisch in het spel vallen. Zolang een PNG er nog niet is,
gebruikt het spel de huidige gekleurde vorm als fallback — je kunt dus stap voor stap toevoegen.

## Technisch
- **Formaat:** PNG met transparante achtergrond.
- **Stijl:** pixel-art, **top-down** (recht van boven, of lichte 3/4). Neutraal georiënteerd
  (vijanden roteren niet mee met het pad), dus teken ze "naar de kijker / naar beneden".
- **Grootte (vierkant):**
  - Enemies: **32×32 px** (grote types zoals tank/boss mogen 48×48).
  - Towers: **40×40 px** (past in één grid-vak van 40).
- **Geen anti-aliasing / geen blur** — het spel toont ze met nearest-neighbor (crisp).
- Houd een **consistent palet** aan over alles (zie hieronder). Eén lichtbron (bijv. links-boven),
  1px donkere outline werkt fijn voor leesbaarheid.

## Suggestie-palet (office, mag je aanpassen — houd het beperkt, ~16 kleuren)
- Achtergrond/tapijt: `#1f2126`, `#2a2d34`
- Huid: `#e8b796`, `#c98d6b`
- Blauw (mail/IT): `#4a8fe7`, `#2c5aa0`
- Rood (urgent/CEO): `#d95c5c`, `#a53a3a`
- Groen (spam/filter): `#5fb98f`, `#3a7d5c`
- Paars (scrum/kletskous): `#a97fd0`, `#7a55a3`
- Geel (notificatie/nudge): `#e7c84a`, `#b89a2c`
- Grijs (tank/board): `#8a8d96`, `#585b64`

## Bestandsnamen (exact — kleine letters)

> **Upgrade-levels:** towers gebruiken `<naam>_1.png`, `<naam>_2.png`, `<naam>_3.png`
> (level 1/2/3). Het spel valt terug op `<naam>.png` als een level-sprite ontbreekt.

### Towers → `art/towers/<naam>_<level>.png`

**LADDER-REGEL (vastgelegd 2026-07-21).** Een upgrade-reeks hoeft niet drie keer hetzelfde
voorwerp te zijn — het moet een **ladder** zijn waarvan je in één blik ziet dat 3 beter is
dan 2 beter dan 1. IJkpunt: Coffee Machine en Headphones. Dat zijn per level andere
voorwerpen, maar iedereen snapt meteen welke de beste is.

Wat het níét moet zijn: drie verschillende apparaten zonder rangorde (router → switch →
server), alleen een kleurverschil (grijze → rode → gouden megafoon), of drie keer exact
hetzelfde plaatje (envelop → envelop → envelop).

| Bestand | Tower | Ladder (L1 → L2 → L3) |
|---|---|---|
| `auto.png` | Auto-Reply | envelop / mailpijl |
| `coffee.png` | Coffee Machine | koffieautomaat → espressomachine → barista-station ✅ |
| `phones.png` | Headphones | oordopjes → koptelefoon → grote ANC-koptelefoon ✅ |
| `ceo.png` | Office Artillery | liniaal-elastiekschieter → nietmachine → industriële tacker ✅ |
| `filter.png` | The Shredder | prullenbak → papierversnipperaar → industriële shredder ✅ |
| `scrum.png` | Motivational Poster | kat-poster op statief → ingelijst beeld → LED-scherm ✅ |
| `trap.png` | Thumbtacks | blikje punaises → omgekiepte doos → industriële dispenser ✅ |
| `chain_1..3.png` | Delegation | sticky note → klembord met pijl → verzegeld document ✅ |
| `machinegun_1..3.png` | Quick Reply | chat-bubbel → "OK"-bubbel → duim omhoog ✅ |
| `multishot_1..3.png` | Self-Service | FAQ-blad → handboek → service-belletje ✅ |
| `keyboard_1.png` | Keyboard Smash (special) | mechanisch toetsenbord (1 level) ✅ |

**QTE-sprites** staan in `art/ui/`: `qte_projector.png` (grote gedetailleerde projector met
rooster + poorten, 96px), `qte_vga.png` + `qte_power.png` (sleepbare kabels), `qte_xp_wall.png`
(Bliss-landschap, `rd_plus__environment` 192×144 — vol beeld, NIET topdown_item), en
`qte_xp_popup.png` (XP-venster-chrome, `rd_plus__ui_element`, strak uitgesneden tot alleen het
venster). De pop-up-chrome is een sprite; de titel/vraag/knoppen liggen er als echte klikbare
tekst bovenop. *In-game heet het een "projector" (Engels), niet "beamer".*

**Mini-game-sprites** (`art/ui/`): `mg_pizza.png` (top-down pizza, `topdown_item` — Eat the Pizza,
het opgegeten deel wordt met een donkere taartpunt overdekt), en `mg_runner.png` + `mg_cup.png` +
`mg_plane.png` (zij-aanzicht, `rd_plus__classic` — de No Internet-dino: rennende medewerker,
koffiebeker-obstakel op de grond, papieren vliegtuigje in de lucht).

**Les:** voor een vol beeld (achtergrond/landschap) gebruik je `rd_plus__environment` of
`rd_plus__default` (geen achtergrond weghalen); `rd_plus__topdown_item` snijdt het uit tot een
los object en werkt dus NIET voor wallpapers. Voor UI-vensters: `rd_plus__ui_element`.

✅ = voldoet aan de ladder-regel. De oorspronkelijke zes reeksen zijn compleet sinds v0.29.0,
de drie nieuwe torens (Delegation/Quick Reply/Self-Service) sinds v0.38.2. De
tower-namen en flavour-teksten in `scripts/tower.gd` zijn meeveranderd; interne def_id's
(`ceo`, `filter`, `scrum`) blijven ongewijzigd, anders breken de save en de
`immune_to`-verwijzing in `scripts/enemy.gd`.

**Slagschaduwen weghalen.** Retro Diffusion zet er soms een harde slagschaduw naast het
object, en na het downscalen deelt die schaduw zijn kleur met het object zelf — op kleur
filteren beschadigt dan de sprite. Wat wél werkt: flood-fill vanaf de rand op de 96×96
*vóór* het downscalen, waarbij je zowel de achtergrondkleur als de schaduwtint accepteert.
De verplichte donkere outline uit het stijl-recept houdt de fill buiten het object.
Retro Diffusion's eigen `background_remover` faalde hierop met een serverfout.

### Enemies → `art/enemies/<naam>.png`
| Bestand | Enemy |
|---|---|
| `noti.png` | De Notificatie |
| `hulp.png` | De Hulpvraag |
| `story.png` | User Story |
| `tank.png` | De Oude Garde (tank, met "schild"-look) |
| `nudge.png` | The Nudge (snelle chat-ping) |
| `thread.png` | The Thread — dikke stapel geniete printjes (de uitgeprinte reply-all-mailwisseling). Komt als tros; papier, dus de versnipperaar vreet 'm ✅ |
| `change.png` | De Change (formulier) |
| `task.png` | taakje (splitst uit Change) |
| `micro.png` | De Micro-manager |
| `kletskous.png` | De Kletskous |
| `feedback.png` | feedback-add (boss) |
| `printer.png` | De Printer — kantoorprinter met vastgelopen papier ✅ |
| `error.png` | Error Message — foutmelding-dialoogje, komt uit de Printer ✅ |
| `beamer.png` | The Broken Projector (L2-boss) — plafond-beamer met lens ✅ |
| `outoforder.png` | Out of Order (L3-boss) — monteur met gereedschapskist ✅ |
| `reorg.png` | The Reorganisation (verhuisd naar medior/Town Hall) — manager met organigram-klembord ✅ |
| `allhands.png` | The All-Hands Meeting (L1-boss) — manager op podium met microfoon ✅ |
| `cleaner.png` | The Cleaner (L4-boss) — conciërge met dweil en schoonmaakkar ✅ |
| `smoking.png` | The Smoking Colleague (L6-boss) — collega op rookpauze ✅ |
| `baby.png` | The Baby (L7-boss) — huilende baby in een romper ✅ |
| `floater.png` | The Floater (L8-boss) — dwalende medewerker met laptop ✅ |
| `hrmanager.png` | The HR Manager (L11-boss) — strenge HR'er met klembord + rode map ✅ |
| `legacy.png` | The Legacy System (L12-boss) — oude beige servertoren ✅ |
| `consultant.png` | The Consultant (L13-boss) — consultant met aanwijsstok ✅ |
| `deadline.png` | The Deadline (L14-boss) — boze rode wekker ✅ |
| `phish.png` | Suspicious Link (onzichtbaar-thema) |
| `board.png` | The Board Member |
| `cold.png` | The Cold Caller |
| `boss.png` | The Performance Review (eindbaas, groot) |

## Zo krijg je een sprite in het spel
1. Zet de PNG in de juiste map met de juiste naam.
2. **Achtergrond transparant maken** (AI-sprites komen met een effen achtergrond):
   `python3 tools/remove_bg.py art/towers/coffee.png`
   Flood-fillt vanaf de rand, dus grijstinten *ín* de sprite blijven staan.
3. **Importeren in Godot** — anders ziet het spel de PNG niet:
   `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --import`
   (of gewoon de Godot-editor openen, die importeert automatisch)
4. Start het spel — de sprite vervangt automatisch de gekleurde vorm.

HP-balk, schild/stun-ringen en range-cirkels blijft het spel er zelf overheen tekenen.

## HUISSTIJL-RECEPT (getest, nog niet toegepast op de set)

Uitkomst van de stijl-tests. IJkpunt = de eerste `coffee.png` (stevig object, donkere
outline, zachte shading met highlights).

1. **Genereer op 96×96** (niet 48 — figuren worden dan papperig), style `rd_plus__topdown_item`,
   kosten **$0.038** per sprite.
2. **`input_palette`** = `art/palette.png` (te herbouwen met `tools/make_palette.py`).
   Dit geeft de kleur-samenhang over de hele set.
3. **Vaste stijl-zin achter elke prompt**:
   `chunky solid object/character with a bold dark outline, smooth soft shading with subtle
   highlights, clean readable silhouette, muted colors`
   (gebruik "object" voor dingen, "character" voor figuren)
4. **Terugschalen naar 48**: `python3 tools/downscale.py 48 <png>` — pixel-perfect
   (meest voorkomende kleur per blok), gelijkwaardig aan RD's k_centroid maar gratis en lokaal.
5. **Achtergrond weg**: `python3 tools/remove_bg.py <png>`
6. **Importeren**: `Godot --headless --path . --import`

Wat níét werkt: alleen een palet zonder stijl-zin (wordt vlak), en direct op 48 genereren
(te weinig detail voor figuren).

## Gekozen generatie-instellingen (Retro Diffusion)
- Style: **`rd_plus__topdown_item`** (3/4 top-down, losse assets) — ~$0.027 per sprite bij 48×48.
- Grootte: **48×48** (32×32 is iets goedkoper, ~$0.025).
- Prompt: beschrijf **alleen het onderwerp**, nooit "pixel art" — de style regelt de rendering.
- Geen batchkorting: 4 stuks kost gewoon 4×.
- `rd_pro__topdown` is mooier maar kost **$0.18** per sprite — te duur voor een set van 20.
