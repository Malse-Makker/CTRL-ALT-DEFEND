# Mijn game: context voor de reviewer

Ingevuld op 2026-07-26, geldig voor **v0.78.0**.
Bron van waarheid voor de details: `HANDOFF.md` (stand van zaken + valkuilen),
`Office_TD_GDD.md` (ontwerp), `MAP_DESIGN_REVIEW.md` (levelontwerp).

---

## 1. Identiteit

**Werktitel:** CTRL-ALT-DEFEND (was "Office Tower Defense"; die naam staat nog in oudere
documenten). Ondertitel: *"I'll put this with the rest of the focus."*

**Thema en setting in twee zinnen:** Je verdedigt je werkdag tegen kantoorergernissen die door de
gangen naar je bureau lopen — vergaderingen die een mailtje hadden kunnen zijn, reply-all-stormen,
consultants en de printer. Je houdt ze tegen met koffiezetapparaten, koptelefoons, een
papierversnipperaar en kantoorartillerie.

**Toon:** Droge, cynische kantoorhumor. De grap zit in het bloedserieus behandelen van compleet
stomme dingen — een HR-formulier van vijf pagina's dat je moet tekenen terwijl er een zwerm op je
bureau afkomt, en een brandalarm dat het noodnummer uit The IT Crowd roept.

**Wat is de grap of de hook die deze game uniek maakt:** Elke toren is een manier om je Focus te
behouden en elke vijand is iets dat Focus kost. Dat is geen thema-laagje over een generieke TD
heen: de counters volgen uit het kantoorverhaal. Een Board Member is immuun voor artillerie omdat
hij er nooit fysiek is. De Oude Garde is immuun voor de versnipperaar omdat er bewaarplicht op
dat archief zit. De Kletskous legt je torens stil zolang hij in de buurt staat, en alleen
noise-cancelling koptelefoons snoeren hem de mond. Daarnaast zijn de hazards echte mini-games in
plaats van passieve pieken: een beamer aansluiten, een pizza opeten, een dino-runner spelen omdat
het internet eruit ligt, een telefoontje wegdrukken.

**Wat zou een speler na tien minuten moeten kunnen navertellen aan een vriend:** "Het is een tower
defense waarin je je concentratie verdedigt tegen je collega's, en de counters zijn kantoorgrappen
die kloppen — je moet de vent die altijd remote is platmailen omdat je hem niet kunt vastnieten."

---

## 2. Naamgeving en flavour

**Hoe heten mijn torens generiek:** "towers" in de UI. Het zijn **voorwerpen** van je bureau, geen
mensen. *Open ontwerpvraag:* een tester stelde voor om alle vijanden om te bouwen naar
**collega's** (mensen) met hetzelfde gedrag, terwijl de torens voorwerpen blijven. Dat staat als
stem-item in de in-game feedbackpagina, met een invullijst per vijand.

**Hoe heten mijn vijanden generiek:** "enemies" in de UI; in het ontwerp "kantoorergernissen".
Ze hebben rollen: basic, swarm, tank, disruptor, splitter, stealth, rage, spawner.

**Hoe heet mijn valuta:** **Coffee** (in-level). Meta-valuta tussen levels: **Recognition**
("we kunnen je niet meer betalen, maar hier is wat Recognition").

**Hoe heten levens:** **Focus**. Start op 100 per level. Elke vijand doet bij doorbraak zijn eigen
**vaste** schade, onafhankelijk van resterende HP. 0 Focus = burn-out = game over.

**Bestaande torennamen (14):** Coffee Machine, Auto-Reply, Headphones, Office Artillery,
The Shredder, Motivational Poster, Thumbtacks, Delegation, Quick Reply, Self-Service,
Pomodoro Timer, Reply All — plus twee **specials**: Keyboard Smash en Ctrl+Alt+Del.
Elke core-toren heeft drie upgrade-levels met een eigen naam en flavour-tekst
(Auto-Reply → Out of Office → Inbox Zero; Rubber Band → Stapler → Industrial Tacker).

**Bestaande vijandnamen (32, inclusief 15 bosses):** The Notification, The Question, User Story,
The Old Guard, The Nudge, The Thread, The Change, Task, The Micro-manager, The Chatterbox,
Feedback, The Printer, Error Message, Suspicious Link, The Board Member, The Cold Caller,
The Phone Caller, System Update. Bosses: The All-Hands Meeting, The Broken Projector, Out of
Order, The Reorganisation, The Cleaner, The Smoking Colleague, The Baby, The Floater, The HR
Manager, The Legacy System, The Consultant, The Deadline, The Performance Review (drie rangen)
en de finale-variant met 360°-cameo's van eerdere bosses.

**Woorden of concepten die absoluut NIET in mijn game passen:** fantasy en sci-fi (geen magie,
geen ridders, geen aliens), geweld en wapens in letterlijke zin (de "artillerie" is een
nietmachine), alles wat de kantoormetafoor breekt. Ook: geen emoji of geometrische
Unicode-tekens in de UI — het standaardfont rendert die niet en op Linux/Proton worden het lege
blokjes. Symbolen worden getekend.

---

## 3. Scope en grenzen

**Godot-versie:** 4.7.1 stable. GDScript, alles in code (geen .tscn per object).

**2D of 3D, en perspectief:** 2D pixel-art, top-down. Basisresolutie **960×540** (exact 2× naar
1080p, 4× naar 4K — cruciaal voor scherpe pixels).

**Solo project of team:** solo, gebouwd samen met een AI-assistent (Claude Code). Sprites komen
van Retro Diffusion; ik teken zelf geen pixel-art.

**Hoeveel uur per week kan ik eraan werken:** hobbyproject, in vlagen — soms een hele dag, soms
een week niets.

**Waar wil ik uiteindelijk uitkomen:** nu een alpha voor vrienden op
[game.makkers.net](https://game.makkers.net), broncode publiek op GitHub. Verder dan dat is open;
Steam is overwogen (vooral omdat het de SmartScreen-waarschuwing van de ongesigneerde .exe
oplost), maar er is geen commercieel plan. Niet-commercieel, onderdeel van de makkers-collectie.

**Aantal torens nu / geplande maximum:** 14 nu (12 core + 2 specials). Geen hard maximum, maar de
shop is fysiek vol — meer torens vraagt een scrollende of gepagineerde shop.

**Aantal vijandtypes nu / geplande maximum:** 32 inclusief bosses (18 gewone types + 14
boss-varianten). Voldoende; nieuwe types alleen als ze een nieuwe rol invullen.

**Aantal maps nu / geplande maximum:** 15 levels in drie carrièreblokken (junior 1-5, medior 6-10,
senior 11-15), plus drie extra modi: Tutorial, Boss Rush en Endless. 15 is het eindpunt.

**Aantal rondes per potje:** 20-22 waves per level. Een wave start automatisch elke 16 seconden,
of eerder als je hem oproept (bonuspunten, gecapt op 40 per wave). Een rustig gespeeld level duurt
zo'n 5-7 minuten.

**Wat ik expliciet NIET wil:**  geen microtransacties, geen procedurele maps
(elk van de 15 levels heeft een handgemaakte layout met eigen mechanieken), geen 3D. Meta-progressie
tussen levels (Recognition, sterren, perks) wil ik juist wél — dat is de carrièrelaag.

---

## 4. Wat werkt er al goed

1. **De counter-logica die uit het thema volgt.** Immuniteiten en zwaktes zijn geen willekeurige
   getallen maar kantoorgrappen die kloppen (Board Member immuun voor burst, Oude Garde immuun voor
   de versnipperaar wegens bewaarplicht, papier gaat er juist extra hard doorheen). Dit is de kern
   van de game — hier niet aan zitten.
2. **De hazards als echte mini-games.** Vijf stuks, allemaal interactief, met auto-skip zodat je
   nooit vastzit: beamer aansluiten, pizza-timingbalk, dino-runner, telefoon wegdrukken en een
   compliance-document van vijf pagina's tekenen. Het spel loopt gedimd door terwijl je ze doet.
3. **De feedback- en release-infrastructuur.** Playtest-telemetrie per ronde, een in-game
   feedbackpagina met stem-items, een SEND-knop die alles rechtstreeks naar Discord stuurt, een
   changelog die op drie plekken uit één bron komt, en een self-updater. Eén commando brengt een
   release uit. Dit hoeft niet "verbeterd" te worden.

---

## 5. Wat voelt nu niet goed

1. **De Auto-Reply-meta.** Uit de playtest-CSV: van de 14 torens werden er in vier rondes maar
   vijf gebouwd, en Auto-Reply domineerde alles. Pomodoro Timer, Reply All, Delegation,
   Self-Service, Quick Reply, Thumbtacks en beide specials werden **nul keer** gekocht. Per Coffee
   is Office Artillery op hoog niveau sterker, maar hij is te traag tegen zwermen — en de levels
   zitten vol zwermen. Ik weet niet of dit een getallenprobleem is of een rolprobleem.
2. **Bosses zijn te makkelijk.** Tester over Out of Order: "sure je krijgt geen coffee, maar je
   hebt al heel veel torens staan dus je overleeft het wel." De boss-mechanieken zijn er allemaal,
   maar ze veranderen te weinig aan wat je moet doen.
3. **De moeilijkheidscurve springt.** Level 1 is te makkelijk (fun 8/10 maar "net iets te
   makkelijk"), level 2 was drie keer op rij onhaalbaar (fun 2/10). Ik wil dat élk level haalbaar
   is **zonder Focus te verliezen** als je het goed doet, en dat weet ik nu niet te bouwen.

---

## 6. Technische staat

**Staat balans in Resources of hardcoded in scripts:** hardcoded in GDScript-dictionaries, niet in
`.tres`-Resources. `tower.gd defs()` en `enemy.gd defs()` bevatten alle stats; `game_state.gd`
bevat de wave-tabellen (`WAVES`), levellayouts (paden, obstakels, muren, pay-zones, reveals),
`TOWERS_PER_LEVEL` en de modifiers. Data-driven van opzet, alleen niet via Resources.

**Heb ik object pooling:** nee. Vijanden en projectielen worden aangemaakt en `queue_free()`'d.
Bij 8× snelheid met ~150 vijanden is dat nog geen probleem gebleken.

**Hoe bewegen vijanden:** waypoints. Geen Path2D/PathFollow2D — elke vijand krijgt bij spawn een
**eigen kopie** van het pad (`PackedVector2Array`) en loopt de punten af. Dat is bewust: op
multi-path-levels rouleert het level per wave door meerdere ingangen, en met een gedeelde
Path2D zou dat misgaan.

**Hoe werkt targeting nu:** per toren instelbaar via `target_mode`, zes standen (first, last,
closest, farthest, least_hp, most_hp) plus een losse "hidden first"-optie voor torens die
onzichtbare vijanden kunnen zien. Standaard staat alles op **first**. `tower.gd _find_target()`
scoort kandidaten; taunt (The Phone Caller) telt daar als een enorme bonus in mee. Er is
line-of-sight: zicht-muren blokkeren schoten (`_los_clear`).

**Hoe werkt schade nu:** verspreid. Elke rol in `tower.gd _process()` heeft zijn eigen tak
(damage, multi, chain, splash, burst, area, trap, stun, smash, forcequit) en roept
`enemy.take_damage(amt)` aan. Er is één centraal punt aan de ontvangende kant (`take_damage` op de
vijand, die schild vóór HP afhandelt en immuniteiten kent), maar **niet** aan de zendende kant.
Gevolg: er is geen bron bij een treffer, dus "kills per toren" is niet bij te houden zonder een
verbouwing. Schade **per toren** wordt wel geteld (`stat_damage`).

**Grootste technische schuld die ik ken:** `level.gd` is ~2900 regels en doet alles — plaatsen,
waves, hazards, HUD, mini-game-timing, win/lose, tutorial-lessen. Verder: balansgetallen staan
verspreid over drie bestanden, en de UI wordt volledig in code opgebouwd met absolute posities,
waardoor elke tekstwijziging iets kan laten overlappen (dat is deze week drie keer gebeurd).

**Wat mag NIET herschreven worden:** de release- en feedback-keten (`tools/make_release.sh`,
`gen_release_files.py`, `github_release.py`, `updater.gd`, `feedback_send.gd`, `playtest.gd`) —
die werkt, is getest tot in de checksums, en staat los van de gameplay. Ook de mini-games
(`qte_*.gd`) zijn af en zelfstandig testbaar in de Art Room.

---

## 7. Speeltest-observaties

Uit één serieuze speeltest (7 rondes, v0.71.0, twee testers eerder). De cijfers komen uit de
playtest-CSV die de game per ronde wegschrijft.

**Waar haakten spelers af:** level 2 (Coffee Corner). Drie keer op rij verloren, fun 2/10, en de
opmerking "eigenlijk kan je ook helemaal niets met 1 auto reply". Level 1 daarvoor: fun 8/10.
Dat is de scherpste rand in de curve.

**Welke toren kocht iedereen altijd:** Auto-Reply, en daarna Office Artillery en Coffee Machine.
In de winnende ronde: 4 Auto-Replies met 8 upgrades.

**Welke toren kocht niemand ooit:** Pomodoro Timer, Reply All, Delegation, Quick Reply,
Self-Service, Thumbtacks, Motivational Poster, Keyboard Smash en Ctrl+Alt+Del — allemaal
**nul keer gebouwd** in vier rondes. Dat is meer dan de helft van de toolkit.

**Op welke ronde verloren de meeste spelers:** in level 2 rond wave 11, of ze haalden wave 22 met
0 Focus over. De oorzaak stond in de kolommen: **69, 88 en 98 doorgelaten Nudges**. Het level bevatte
312 Nudges, tot 50 in één wave, met de eerste zwerm al op wave 2. Dat is in v0.76.0 gehalveerd.

**Wat deden spelers dat je niet verwacht had:** waves spammen om een verloren ronde af te raffelen
— 21 van de 22 waves vroeg opgeroepen, hele level uit in 61 seconden. Ik las dat eerst als de
oorzaak van het verlies, maar het was het gevolg: die rondes verdienden 1 en 14 Coffee, er ging dus
allang niets meer dood. De echte fout was van mij: **doodgaan was de enige route naar het
eindscherm** met cijfers en het feedbackformulier, want "Quit run" gooide je zonder iets terug naar
het menu. Sinds v0.77.0 is er een Give up-knop. Les die ik daaruit meeneem: als een speler iets
geks doet, eerst kijken welke uitgangen het spel hem gaf.

---

## 8. Referenties

**Games die ik als voorbeeld gebruik:** Bloons TD 6 (systeemdiepte, de shop-UI, upgradeladders),
Kingdom Rush (leesbaarheid van een druk scherm), en qua humor Papers Please en Not For Broadcast —
alledaagse bureaucratie die je serieus moet nemen. De mini-games zijn geïnspireerd op de taakjes
uit Among Us en de Chrome-offline-dino. Verder wil ik referenties uit tv series en films zo als it crowd en officepace

**Games waar ik juist NIET op wil lijken:** de mobiele free-to-play tower defense met
wachttimers, gacha en energie. Ook geen generieke fantasy-TD met torentjes en goblins — dat is
precies het decor dat ik wilde vermijden.

**Wat ik uit Bloons TD 6 wel wil:** de systeemdiepte en het gevoel dat elke toren een echte rol
heeft in plaats van een sterker getal; de spanning tussen investeren in economie en investeren in
verdediging; upgraden dat altijd beter moet zijn dan nóg een kopie neerzetten (die regel staat in
mijn GDD en heb ik met een prijsopslag op duplicaten afgedwongen).

**Wat ik uit Bloons TD 6 niet wil:**  de
monetisatie, en de cartoon-art style. Mijn art is pixel-art in een kantoorpalet.
