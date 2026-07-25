# Game Design Document — Office Tower Defense

> Werktitel: nog te bepalen. In-game taal: Engels. Ontwikkeling: Nederlands.
> Laatst bijgewerkt: 2026-07-20. **Towers & enemies worden op dit moment herzien** (zie §12).

## 1. Pitch
Een 2D top-down pixel-art tower defense waarin je de werkdag verdedigt tegen kantoorergernissen die door de gangen naar je bureau lopen. Vergaderingen die een mailtje hadden kunnen zijn, reply-all stormen, consultants en stagiairs proberen je **Focus** te slopen. Jij houdt ze tegen met koffiezetapparaten, HR en de conciërge.

Toon: droge, cynische kantoorhumor. De grap zit in het bloedserieus behandelen van compleet stomme dingen.

Titel-suggesties: *Out of Office (defense)*, *Focus Time*, *Do Not Disturb*, *9 to 5: Last Stand*, *This Meeting Could Have Been an Email*.

## 2. Core gameplay loop
1. **Plan-fase** aan het begin: tijd staat stil, je plaatst torens met je startbudget. Druk Start → geen weg terug.
2. Vanaf Start lopen de **~20 waves automatisch** (elke ~20s de volgende; board leeg → volgende na 5s).
3. Je kunt een wave **eerder oproepen** voor **bonuspunten** (waves kunnen overlappen). Pauze + snelheid 1×/2×/3× beschikbaar.
4. Vijanden lopen het pad af; bereiken ze het bureau → je verliest Focus (= levens; **vaste schade per vijandtype**).
5. Vijanden verslaan levert Coffee op (in-level valuta) + score.
6. Met Coffee plaats/upgrade je towers (vrije plaatsing). Economie: startbudget + kills + Coffee Machine.
7. Overleef alle waves → level gehaald → sterren + score → Recognition (meta-valuta) voor perks + consumables.
8. Bij 0 Focus: burn-out → game over (level opnieuw).

> Menu verlaten tijdens een run vraagt eerst bevestiging (run stopt).

## 3. Resources & economie
Drie lagen: **Focus** (levens), **Coffee** (in-game valuta), **Recognition** (meta-valuta).

### Focus (levens)
- Start op **100** per level.
- **Kernregel (herzien v0.11): elke vijand doet bij doorbraak zijn eigen VASTE schade**,
  onafhankelijk van resterende HP. Zwakste = 1, oplopend tot 8 voor tanks en 50 voor de eindbaas.
  (De oude regel "schade = resterende HP" is vervallen: die maakte bijna-dode vijanden gratis.)
- Geen automatische regeneratie tijdens een ronde. Wél terug via consumables (bv. Rookpauze).
- 0 Focus = burn-out = game over.

### Coffee (in-game valuta)
- Verdiend per kill, reset elk level.
- Uitgegeven aan towers plaatsen + upgraden.
- Ook passief te genereren met de Coffee Machine-tower.
- Sommige vijanden geven bewust weinig (bv. "Quick Win") als running gag.

### Recognition (meta-valuta)
- "We kunnen je niet meer betalen, maar hier is wat Recognition."
- Verdiend door levels te halen; bonus bij hoge sterren-rating.
- Twee bestedingen: **permanente upgrades** (perk-menu tussen levels) + **consumables/noodknoppen** (vooraf kopen, mee in je "tas", 1x gebruiken per ronde).

### Permanente upgrades (perk-menu) — nog uit te werken
Voorbeeld-richtingen: Opstartbudget (+X start-Coffee), Bulk-inkoop (towers goedkoper), Extra cafeïne (meer start-Focus), Aanwervingsstop (extra tower/tas-slot unlock), Loyaliteitsbonus (meer Coffee per kill).

### Consumables/noodknoppen — nog uit te werken
Defensieve redmiddelen. Voorbeelden: Rookpauze (geeft X Focus terug), Pizza-avond (effect t.b.d.). Aantal tas-slots t.b.d.

### Sterren-rating per level
- 1 ster: gehaald. 2 sterren: < helft Focus verloren. 3 sterren: < 10% verloren (of geen).
- Sterren bepalen Recognition-bonus en ontgrendelen latere levels/perks.

## 4. Levels
Los te kiezen via level-select (kantoorplattegrond). Elk level: eigen pad-layout + wave-set. Twee levels hebben een hazard.

Ontgrendel-/lescurve: elk level introduceert een paar nieuwe towers + enemies, zodat het spel zichzelf uitlegt en counters op tijd beschikbaar zijn.

| # | Locatie | Pad | Nieuwe towers | Nieuwe enemies | Test / les | Hazard |
|---|---|---|---|---|---|---|
| 1 | Kantoortuin (open-plan) | Enkel, breed | Coffee Machine, Auto-Reply | Basic-familie (Notificatie, Hulpvraag) | Basis: economie + schade + focus | — |
| 2 | Vergaderzaal | Gesplitst (lange tafel) | Spam Filter | The Thread (tros), Oude Garde (tank) | Area vs zwerm; tank = sustained | Brandalarm |
| 3 | Koffiehoek | Kort, druk, snel | Headphones, CEO-mail | The Nudge (sprinter), Micro-manager, De Kletskous | Crowd control + burst + snelheid | — |
| 4 | Kantine | Convergerend | Scrum Master | De Change (splitter), stealth-trio (Suspicious Link, Board Member, Cold Caller) | Volledige diversiteit + chokepoints | Lunchpauze |
| 5 | Directiekamer | Finale | — (alles beschikbaar) | The Performance Review (boss) | Alles samen, moeilijkheidspiek | Eindbaas |

Counter-timing klopt: het stealth-trio (L4) heeft Spam Filter (L2), Auto-Reply (L1) én CEO-mail (L3) al beschikbaar.

**Hazards.**
- **Brandalarm** (Vergaderzaal) — "iedereen naar buiten": op vaste, aangekondigde momenten versnellen alle vijanden kort richting je bureau (de uitgang) terwijl je towers stilliggen. Dubbelzijdige piek; je moet marge houden.
- **Lunchpauze** (Kantine) — **herzien v0.30.0.** Was een harde stop waarbij ook de towers stillagen; dat maakte het een passieve hazard waarin je alleen kon toekijken. Nu: je **towers vuren gewoon door**, maar de hele afdeling loopt tegelijk de gang op — een dichte swarm van snelle, zwakke types die met de wave-index meegroeit. **Bouwen, upgraden en verkopen liggen wél stil** (jij zit zelf ook te lunchen), dus de timing van je opstelling vóór de pauze blijft alles. De druk komt nu van doorvoer in plaats van van stilstand. Aangekondigd met een bureauwekker en het geroezemoes van een opstaande afdeling.

**Quick-time events / mini-games (idee gebruiker 2026-07-23).**
Om de game uniek te maken: hazards deels vervangen door korte interactieve mini-games (Among
Us-taak-achtig). Terwijl je de mini-game doet **loopt het spel gewoon door** — je ziet het
gedimd en kunt niets bouwen tot je klaar bent.
- **Vergaderzaal → "Connect the beamer".** ✅ *Gebouwd v0.35.0, herzien naar drag-and-drop
  v0.35.1* (hazard `"beamer"`, `_build_qte`/`_show_qte`/`_qte_input`/`_qte_check_cables`/
  `_finish_qte`). Among Us-taak: **fase 1** — sleep de VGA-kabel (grappig-oud) én de power-kabel
  naar de juiste poort op de beamer (snapt binnen 46px, kabels hebben een meelopend snoer).
  **Fase 2** — een pixel-art Windows-XP-scherm (Bliss-lucht + heuvel + taakbalk) met een
  "Display Settings"-pop-up: twee opties, klik de 2e ("Duplicate desktop to the projector").
  **Auto-skip na ~10s.** Bouwen ligt stil, het spel loopt gedimd door. *Nog uit te breiden:
  echte pixel-art sprites voor beamer/kabels, geluid, evt. decoy-poorten.*
- **Brandalarm verhuisd naar de Koffiehoek** (level 3, magnetron) ✅ *v0.35.0.* De vergaderzaal
  (level 2) heeft nu de beamer-QTE i.p.v. het brandalarm. **Balans: level 3 heeft er nu een
  hazard bij — toetsen.**
- **Flow (bevestigd 2026-07-23):** snel oplossen (< ~5s) geeft je meteen de controle terug —
  dat is de beloning. Na ~10s **skipt de mini-game automatisch** zodat je nooit vastzit. Doen
  wordt beloond, niks-doen wordt niet bestraft met blijven hangen. Eventueel een skip-knop.
- *Nog te bouwen; eerst een simpele proef-mini-game om te voelen of het werkt.*

## 5. Towers
Zeven towers (was zes), elk 3 levels (koop lvl 1, twee upgrades). Lineaire upgrades, geen split-paths.

Targeting-opties per single-target tower: **First** (verst op het pad), **Last** (net binnen),
**Closest**, **Farthest**, **Least HP**, **Most HP** — per tower instelbaar.

Onzichtbare vijanden staan hier los van: dat is een **aparte aanvinkoptie** ("Hidden enemies
first"), zodat je kunt kiezen "richt op de sterkste, maar pak onzichtbare eerst" in plaats van
te moeten kiezen tussen slim targeten óf onzichtbaren zien. De optie verschijnt alleen bij
towers die onzichtbare vijanden kúnnen zien (`sees_hidden` in de defs). Besloten 2026-07-22:
**geen enkele schiet-tower ziet ze** — alleen de Versnipperaar-zone onthult ze, daarna zijn ze
voor iedereen zichtbaar. De optie ligt klaar voor een eventuele latere detector-tower.

1. **Coffee Machine** — economie. Passief Coffee. Koffieautomaat → Espressomachine → Barista-station.
2. **Auto-Reply** — basic damage. -1 dmg, hoge snelheid. Auto-Reply → Out of Office → Inbox Zero.
3. **Headphones** — crowd control op één doel; weinig/geen schade, targeting instelbaar
   (standaard Most HP). Je filtert één distractie weg. Earbuds → Over-Ear → Active Noise
   Cancelling. **Herzien 2026-07-22:** lvl 1 en 2 *vertragen* (tot 65% resp. 45%), pas lvl 3
   *stunt* — en die stunt én vertraagt, omdat een herhaalde stun op hetzelfde doel steeds
   korter wordt (zie de stun-weerstand hieronder) en lvl 3 anders minder zou ophouden dan lvl 2.
   Alleen lvl 3 snoert de Kletskous de mond.

> **Stun-weerstand.** Elke volgende stun op hetzelfde doelwit duurt de helft van de vorige,
> met een ondergrens, en herstelt na een paar seconden rust. Zonder dat hield één Headphones
> lvl 3 elk doelwit permanent stil, inclusief de eindbaas. Bosses hebben daarbovenop een
> eigen weerstand.
4. **Office Artillery** (was: De CEO-mail) — single-target burst / sniper. Hoge schade, traag.
   Rubber Band → Stapler → Industrial Tacker. "Geniet, afgehandeld, klaar": één klap
   sluit een afleiding definitief af. ✅ *Doorgevoerd in code + art v0.29.0.*
5. **Motivational Poster** (was: De Scrum Master) — support/buff. Buft zelf-gekozen towers
   (dmg+speed+range), aantal groeit per level. Hang In There (katposter op een wankel
   statief) → Framed Print → LED Wall. ✅ *Doorgevoerd in code + art v0.29.0.*
6. **The Shredder** (was: Spam Filter) — area/splash. Legt een aanhoudende zone op het pad:
   vijanden erin nemen damage-over-time én worden vertraagd ("in de wachtrij"). Upgrades
   vergroten de zone; DoT en vertraging per level gelijk. Sterk tegen zwermen.
   Wastebasket → Paper Shredder → Industrial Shredder. ✅ *Doorgevoerd in code + art v0.29.0.*
7. **Thumbtacks** (strooier, nieuw v0.32.0 — herzien v0.33.1). De tower staat naast het pad en
   **gooit punaises** (met een worp-projectiel) op **willekeurige tegels** op de baan binnen zijn
   ronde bereik. **Mechaniek (gebruiker, def.):** begint op 0 en blijft gooien — elke
   `throw_interval` een punaise. Elke punaise heeft een **leeftijd** (`lifetime`): wordt hij te
   oud en niet gebruikt, dan roest hij weg. Zo liggen er bij lvl 1 gemiddeld ~3, bij lvl 2 ~5
   tegelijk (lifetime ÷ interval). Een vijand die over een punaise loopt krijgt `damage` en
   verbruikt 'm; meerdere punaises op één tegel raken hem meerdere keren. **lvl 3 (Tack Carpet):
   je kiest zelf de doeltegel** (klik op het pad) waar hij ze naartoe gooit — concentreert de
   punaises. Fysiek, dus de Kletskous-silence raakt 'm niet.
   Loose Tacks → Spilled Box → Tack Carpet. Shop van level 4-5.
   ✅ *Code v0.33.1; sprite-ladder nog te maken (valt nu terug op de basisvorm).*

### Specials (aparte categorie, besloten 2026-07-23)
Naast de 7 core-towers komt er een **Specials-sectie** onderin de shop (Bloons-achtige
2-koloms UI: core boven, specials onder). **Gedeelde regels voor élke special**, zodat ze
onderhoudbaar blijven ondanks unieke effecten:
- **max 1 per level** (van elk type),
- **geen upgrade-levels**,
- **één krachtig, uniek effect**.
Binnen die regels mag een special van alles doen (andere plaatsing, tijdelijke effecten, enz.).
Ruimte voor 2-4 specials. De eerste:

- **Keyboard Smash** (special #1). ✅ *Gebouwd v0.33.0.* Een toetsenbord dat op het pad
  neerslaat. **Alleen direct op/aan het pad te plaatsen.** Slaat toe zodra er een vijand in
  bereik komt: **AoE-schade** rondom (meerdere vijanden tegelijk) + letters vliegen weg als
  explosie. Daarna **ligt het als een slagboom**: vijanden staan stil tot het weer weg is.
  Sterk tegen veel vijanden met weinig HP. Waarden nu: 14 AoE-schade, straal 90, barrière 2,5s,
  cooldown 6s, kost 60, level 3-5. Nog geen sprite (fallback-vorm).

> **Ladder-regel voor de art (2026-07-21):** elk upgrade-level is een ander voorwerp, maar je
> moet in één blik zien dat 3 beter is dan 2 beter dan 1. IJkpunt: Coffee Machine en Headphones.
> Zie `art/STYLE_GUIDE.md`. Definitieve namen per level worden bij de implementatie vastgesteld.

Open punten: stapelen meerdere Scrum Masters op dezelfde toren? Spam Filter-synergie met digitale/spam-vijanden?

## 6. Enemies
Doel: 10+ types, deels families met varianten. Rollen: basic, swarm/snel, tank, disruptor, splitter, stealth/ontwijk (+varianten), rage. Buffer en healer vallen bewust af.

**Kernregel: vaste Focus-schade per vijandtype.** **Schild** (herbruikbare bouwsteen) = extra HP-laag vóór de echte HP, telt niet mee voor doorbraak-schade.

### Klaar (functioneel)
- **Basic-familie** (oplopend HP): De Notificatie → De Hulpvraag → De User Story.
- **De Oude Garde** (tank): traag, veel HP, schild-laag eerst dan HP. Counter: burst van de kantoor-artillerie. **Immuun voor de Versnipperaar-zone: op dat archief zit bewaarplicht** — dat mág wettelijk niet vernietigd worden. (Variant: hij bewaart alles in drievoud, dus versnipper er één en hij heeft er nog twee.)
- **De Change** (splitter, 3 generaties): Change → 2 goedkeuringsformulieren → taakjes (zwak/snel). Dwingt towercombinatie af.
- **De Micro-manager** (rage): versnelt lineair met opgelopen schade. Counter: burst vóór versnelling, of stun.

- **De Printer** (spawner, nieuw v0.30.0) = het apparaat waar het altijd gezeik mee is. Drivers doen het niet, papier is op, inkt is op. Traag en taai, maar het echte probleem is wat er uit komt: elke paar seconden loopt hij vast en spuwt hij een paar **Error Messages** uit, die zelfstandig doorlopen. Laat je hem leven, dan sta je tegen een file foutmeldingen te vechten in plaats van tegen de printer.
  - *Counter 1:* hem vroeg neerhalen — elke seconde dat hij leeft kost je errors.
  - *Counter 2:* **stun**. Een stilgezette printer print niet, dus de Headphones onderbreken de stroom. Dat geeft die tower een tweede duidelijke reden van bestaan naast de Kletskous.
  - *Counter 3:* area-schade tegen de errors zelf, want die komen in groepjes.
  - Staat in **level 3** (Koffiehoek), niet in level 4: daar levert de lunchpauze al een swarm en wordt het onleesbaar druk. Level 3 heeft daarom 21 waves in plaats van 20 — de Printer krijgt een eigen rustige introductiewave, omdat elke andere wave daar al iets anders introduceert.

- **De Kletskous** (verhuisd van tower → enemy) = **de Disruptor**. Die collega die je klemzet.
  - *Aura-silence:* towers binnen een straal vallen stil zolang de Kletskous in bereik is; ze vuren meteen weer zodra hij voorbij is. Raakt alle tower-types die in bereik komen. Je kunt towers bewust buiten zijn route plaatsen.
  - *Immuun voor crowd control, behalve top-tier:* Headphones lvl 1 & 2 doen niets tegen hem. Alleen **Headphones lvl 3 (Active Noise Cancelling)** stunt hem én zet zijn aura uit — de harde counter.
  - *Overige counter:* gewoon neerschieten (bv. CEO-mail-burst vanaf een plek buiten zijn route).
  - Doet bij doorbraak normale Focus-schade (= resterende HP), net als andere enemies.
  - *Spam Filter:* vertraagt hem normaal, maar de aura blijft aan — hem vertragen bij je towers is juist link (hij blijft langer kletsen). Regel: alleen Headphones lvl 3 snoert hem; al het andere raakt hem puur fysiek.

- **Swarm-familie** (individueel triviaal, gevaar zit in aantallen). Papier = extra gevoelig voor de Versnipperaar (tegenpool van de Oude Garde, die er door bewaarplicht juist immuun voor is).
  - **The Thread** (tros): spawnt als één grote groep tegelijk; elk bijna geen HP, normale snelheid. Overweldigt single-target towers (die pakken er één per keer) → counter = area/Versnipperaar. **De collega die de hele reply-all-mailwisseling uitprint** en rondstuurt — dus papier, en dat gaat prachtig door een shredder.
  - **The Nudge** (sprinter): rent over het pad, elk triviaal, komt als snelle sliert. Ontloopt trage towers (de artillerie mist ze) → counter = snelle towers (Auto-Reply) of vertraging (Versnipperaar).

- **Stealth/ontwijk-familie** (ontwijken via onzichtbaarheid/immuniteit; dwingt tower-diversiteit af).
  - **Suspicious Link** (onzichtbaar): niet targetbaar door single-target towers tot 'ie de Versnipperaar-zone raakt. **De snippers plakken aan 'm vast** — als meel over een onzichtbare man — waardoor hij een zichtbare vorm krijgt. De zone doet area-schade én markeert 'm permanent → daarna zichtbaar voor álle towers. Zonder Versnipperaar op het level glipt 'ie ongestraft door.
  - **The Board Member** (immuun voor de kantoor-artillerie): burst doet 0, want **hij is er nooit fysiek** — altijd remote, altijd in een andere meeting. Je kunt niemand vastnieten die er niet is. Alleen plat te slijten met aanhoudende schade (Auto-Reply): geduldig blijven mailen tot hij wel reageert. Spiegelbeeld van de Oude Garde (die juist door burst wordt gecounterd).
  - **The Cold Caller** (immuun voor Auto-Reply): chip-schade ketst af → alleen te stoppen met burst (de artillerie).
  - Board Member + Cold Caller = gekoppeld paar: samen dwingen ze béide schade-towers af (sustained + burst).
  - *Open (later):* eventueel een dodge-variant (kans om treffers te ontwijken).

### Eindbazen per level (✅ gebouwd v0.34.0, gele fallback-vorm)
Elk level sluit af met een eigen thematische boss in de slotwave. Gegeneraliseerd via
`boss_kind` in `enemy.gd` (HP-fases op 66%/33%; per-boss mechaniek gedispatcht).
- **L1 The All-Hands Meeting** — "This could have been an email." Traag, veel HP, roept
  doorlopend Notificaties erbij (spawnt adds). Zachte intro-boss (alleen Auto-Reply + economie
  nodig).
- **L2 The Broken Projector** — schild-laag ("loading…") die eerst gebroken moet worden
  (beloont burst); beamt periodiek een zwerm slide-adds naar je bureau (test area/Shredder).
- **L3 Out of Order** — de "monteur" van het koffieapparaat: **geen Coffee-inkomsten** (kills
  én machines) zolang hij leeft. Snel neerhalen of gespaard hebben.
- **L4 The Reorganisation** — "We're restructuring." Bij elke HP-fase splitst hij een Manager
  (Change-splitters) af die naar je bureau rent (test burst + area).
- **Kandidaat: De Schoonmaker** (nog te bouwen) — speed-aura + veegt zones/vallen weg.

### Eindbaas: The Performance Review (Het Functioneringsgesprek) — level 5
Eén entiteit, **HP-gated** (fase-wissel op ~66% en ~33% HP). Loopt continu over het pad; bereikt 'ie je bureau → vrijwel game-over (enorme resterende-HP-schade). Elke fase examineert een andere tower-rol.
- **Fase 1 — Self-Assessment** ("vertel eens over jezelf"): traag, hoge HP, gewikkeld in een **Schild-laag** (defensief over feedback). Eerst schild kapot (beloont burst / CEO-mail), dan pas HP.
- **Fase 2 — Peer Feedback**: stopt periodiek en spawnt een **mini-swarm feedback-adds** die naar je bureau rennen → test je area (Spam Filter). Boss is even kwetsbaar tijdens het "ophalen van feedback".
- **Fase 3 — Improvement Plan**: versnelt sterk en sprint naar je bureau; towers in bereik **vuren half zo snel** (fire-rate slow) i.p.v. volledige silence. Finale DPS-race: krijg je 'm neer vóór 'ie er is?

### Enemies — nog te doen
- Structuur/aantal is nu compleet (~12 types + eindbaas, ruim over doel 10+). Optioneel later: dodge-variant in de stealth-familie.
- Balansgetallen (HP, snelheid, reward, spawn-timing) → balancing-fase.

## 7. Visuele stijl
2D top-down pixel-art. Kantoor-tileset. Vijanden/towers als herkenbare kantoor-archetypes. Start met programmer-art/placeholders. UI: strak "corporate dashboard" (Focus-meter, Coffee-teller, wave-indicator).

## 8. Structuur & modi
Campagne via level-select op een kantoorplattegrond, met sterren. Ontgrendelen via voortgang + sterren.

**Nu gebouwd:** 5 levels (blok 1).

**Richting — carrièrepad (idee gebruiker 2026-07-23, nog te bouwen).** De campagne groeit uit
tot een carrière in blokken van vijf levels. Haal je een heel blok met **3 sterren**, dan volgt
een schermvullende promotie:
- Level 1–5 → **PROMOTED! You are now a medior**
- Level 6–10 (flink moeilijker) → **PROMOTED! You are now senior!**
- Level 11–15 → **PROMOTED! You are now specialist**

De impliciete startrang is *junior*.

**Specialist-bonuslevels.** Zodra je specialist bent, zijn de bonuslevels **allemaal tegelijk
ontgrendeld** (geen onderlinge sterren-eis) — puur extra, tellen niet mee voor progressie.
Ideeën:
- **Boss Rush:** alléén bosses achter elkaar.
- **Endless:** een oneindig aantal waves die telkens zwaarder worden; geen einde, je speelt
  voor een highscore. Vraagt een oplopende-moeilijkheidsgenerator (HP/aantal/tempo schalen met
  het wave-nummer) in plaats van een handgeschreven wave-tabel. (Dit is de plek waar de
  eerder als "out of scope" geparkeerde Endless-mode terugkomt.)

De moeilijkheid loopt door de hele carrière op via **sterkere vijanden én eigenwijze
map-mechanics** — niet zomaar een schuifknop. Voorbeelden van map-modifiers:
- **Verhuizend kantoor:** slechts een handjevol bouwplekken (zie ook §11, plekken beperken).
- **Geen koffie:** geen Coffee Machine én geen Coffee per kill; je begint met één grote berg
  Coffee en moet het daar de hele ronde mee doen.
- ruimte voor meer van dat soort "gekke" regels.

**Tutorial-level (nog te bouwen).** Kort en snel, **altijd beschikbaar maar niet verplicht**
voor level 1 — staat los van de rang-progressie en telt niet mee voor sterren. Eén recht pad;
**per wave één les**: introduceer één tower plus de enemy waar die tegen bedoeld is, laat de
speler alléén die relevante tower(s) kopen, en **reset na elke wave** (towers en enemies
verdwijnen) zodat elke wave een schone mini-demo is.

(Endless-mode was eerder "out of scope v1"; die komt nu terug als een specialist-bonuslevel,
zie hierboven.)

### Carrière-levelkaart (uitgewerkt 2026-07-24)

**Drie soorten moeilijkheid.** Als ruggengraat wisselen **hazard** en **event** elkaar af;
vanaf level 9 mogen meerdere prikkels samen, en in blok 3 heeft elk level er minstens twee.
- **🔥 Hazard** (passief): brandalarm (torens stil + vijanden sprinten), lunch-swarm (bouwen
  stil), rook (toren-range omlaag), oververhitting (torens pauzeren periodiek).
- **🎮 Event** (interactief onderbreken; spel gedimd + bouwen stil, auto-skip ~10s):
  projector-QTE, telefoon-ophangen, "teken het formulier", **Eat the Pizza**, **No Internet**.
- **🧩 Modifier** (hele ronde): multi-path, verboden torens, 50% koffie, weinig bouwplekken,
  start met laag Focus (10).

De **Boardroom** is de finale van elk blok (5/10/15) met **The Performance Review** als boss;
die wordt per rang netter én zwaarder (je bent immers gepromoveerd).

| Lvl | Blok | Locatie | Prikkels | Boss |
|---|---|---|---|---|
| 1 | junior | Open-Plan Office | — (alleen boss) | All-Hands Meeting |
| 2 | junior | Coffee Corner | 🔥 brandalarm | Out of Order |
| 3 | junior | Meeting Room | 🎮 projector-QTE | Broken Projector |
| 4 | junior | Canteen | 🔥 lunchpauze | **The Cleaner** |
| 5 | junior | Boardroom | — finale | Performance Review (jr) |
| 6 | medior | The Parking | 🔥 rook → range↓ | Smoking Colleague |
| 7 | medior | Work From Home | 🎮 No Internet (dino) | The Baby |
| 8 | medior | The Flexplek | 🧩 multi-path | The Floater |
| 9 | medior | Town Hall | 🎮 telefoon-ophangen + 🧩 50% koffie | The Reorganisation |
| 10 | medior | Boardroom | 🧩 weinig bouwplekken | Performance Review (md) |
| 11 | senior | HR Room | 🧩 geen Headphones + geen Quick Reply + 🎮 teken het formulier | The HR Manager |
| 12 | senior | Server Room | 🧩 weinig bouwplekken + 🔥 oververhitting | The Legacy System |
| 13 | senior | The Merger | 🧩 multi-path + 🔥 herstructurering blokkeert bouwzone | The Consultant |
| 14 | senior | Release Night | 🧩 start 10 Focus + 🎮 Eat the Pizza | The Deadline |
| 15 | senior | Boardroom | 🧩 weinig bouwplekken + 🧩 50% koffie | Performance Review (sr) |

**Nieuwe boss-mechanieken (nog te bouwen, tenzij anders vermeld):**
- **The Cleaner** (L4) — speed-aura (vijanden bij hem versnellen) + veegt Shredder-zones
  (onderdrukt ze zolang hij ernaast is) en punaisenvallen weg die hij passeert. Eerlijke
  counter op area/trap. *(In aanbouw v0.39.)*
- **The Floater** (L8) — verschijnt elke fase uit een andere ingang en trekt adds door álle lanes.
- **The Reorganisation** (L9, verhuisd van L4) — splitst bij elke HP-fase een Manager af (bestaat al).
- **The HR Manager** (L11) — "audit": schakelt periodiek één toren-type een paar sec uit.
- **The Legacy System** (L12) — tanky mainframe, spuwt continu Error-adds.
- **The Consultant** (L13) — buft alle andere vijanden (speed/schild-aura); doden verzwakt de wave.
- **The Deadline** (L14) — hoe langer hij leeft, hoe sneller álle vijanden lopen (bord-brede rage).
- **The Baby** (L7) en **Smoking Colleague** (L6) — trekken/afleiden; mechaniek nog te verfijnen.

**Mini-game — Eat the Pizza (event, L14).** Timing-balk (Abiotic-Factor-stijl): een pijltje sweept
heen-en-weer over een balk met een **klein groen vak** (beste) en een **groter geel vak**. Spatie
stopt het pijltje → hap: groen = **50%**, geel = **25%**, rest = **5%** van de pizza. De
pizza-sprite krimpt tot 0% (klaar). **Cooldown ~0,5s per druk** zodat rammen (5%-happen) ~20 happen
≈ 10s kost — even lang als gewoon wachten; skill (2× groen) is klaar in ~1s. Het pijltje
**versnelt** naarmate de pizza slinkt. Auto-skip ~10s, spel gedimd + bouwen stil.

**Mini-game — No Internet (event, L7).** Endless-runner in Chrome-offline-stijl (mono), kantoor-thema:
een figuurtje rent automatisch, **spatie = springen / omlaag = bukken**, obstakels (koffiebeker of
nietmachine op de grond, papieren vliegtuigje in de lucht), snelheid loopt op. Je wacht ~10s tot
"de verbinding terug is", **maar elk ontweken obstakel haalt er seconden af** → spelen maakt het
korter. Vergevingsgezind: een botsing is geen game-over, je struikelt en mist alleen die tijdsbonus.

**Status (v0.45.0):** alle **15 levels bestaan, zijn speelbaar en compleet uitgewerkt**. Rang/promotie
+ level-select in 3 blokken werken. **Alle** bosses (blok 1/2/3) hebben mechaniek **én sprite**; alle
torens en vijanden hebben art. Alle mechanieken werken: rook, oververhitting, 50% koffie, weinig
bouwplekken (torencap 8), laag Focus, verboden torens, zone-block, baby-aura, consultant-buff,
deadline-speed-up, HR-audit, **multi-path** (3 samenkomende ingangen op Flexplek/Merger, per wave
een andere ingang). Alle events zijn echte mini-games: projector-QTE, **Eat the Pizza** (timing-balk),
**No Internet** (dino-runner), telefoon (Hang up) en formulier (Sign here) — allemaal met sprites waar
nodig. **Nog te doen richting alpha:** eigen/mooiere maps (blok 2/3 hergebruiken nu blok-1-padvormen —
puur cosmetisch), en de **balans uitspelen** (alles is doorgerekend, niet gespeeld — dáár is de alpha voor).

## 9. Technische opzet (Godot 4.x)
Godot 4.x, GDScript. Data-driven via custom Resources (.tres): towers, enemies, waves als Resource-classes.

Scene-architectuur (voorstel):
```
Main (autoload GameState: Recognition, unlocks, settings)
├── LevelSelect (scene)
└── Level (scene, per locatie)
    ├── Path2D            # het vaste pad
    ├── BuildSpots        # vaste plekken voor towers
    ├── WaveSpawner       # leest WaveData-resource, spawnt enemies
    ├── Towers (container)
    ├── Enemies (container)
    └── HUD (CanvasLayer: Focus, Coffee, wave, build-menu)
```

Patronen: Path2D + PathFollow2D voor beweging. Enemy/Tower base scene + Resource met stats. Signals voor losse koppeling (enemy_died, enemy_reached_base, focus_changed, coffee_changed, wave_completed, level_completed). GameState autoload voor meta-progressie + save/load.

Resource-classes: `EnemyData`, `TowerLevel`, `TowerData` (met `archetype` + `can_target`), `WaveSpawn`, `WaveData`. (Zie originele schets voor velden.)

## 10. Scope & faseplan
- **Fase 1 — Speelbaar prototype:** ✅ **GEBOUWD** (2026-07-20). 1 level (Kantoortuin), 1 pad, 2 towers (Coffee Machine + Auto-Reply, lvl 1), 2 enemies (De Notificatie + De Hulpvraag), Focus + Coffee werkend, 3 waves, win/lose-scherm. Placeholder-graphics, alles in code (geen .tscn per object). Zie `README.md`. NB: de eerdere placeholder-namen "Office Plant / Quick Question / The Intern" zijn vervangen door de definitieve towers/enemies.
- **Fase 2 — Systemen compleet:** ✅ vrijwel af (v0.5.0). Alle 6 towers (incl. Spam Filter zone+slow, Scrum Master buff-aura), upgrade/sell, vrije plaatsing + range-preview + max-afstand-tot-pad. Enemies: Basic-trio, Oude Garde (tank+schild), The Nudge (sprinter), De Change (splitter), Micro-manager (rage), De Kletskous (disruptor/silence), stealth-trio (Suspicious Link onzichtbaar/Spam-Filter-reveal, Board Member immuun-CEO, Cold Caller immuun-Auto-Reply), + eindbaas The Performance Review (3 fases). ✅ Per-toren targeting (closest/farthest/least-hp/most-hp/hidden-first), Scrum Master selectie-UI (klik torens om te buffen), grid-plaatsing. Nog: resource-driven waves (nu code-driven).
- **Fase 3 — Content & progressie:** 🚧 grotendeels (v0.6.0). ✅ 5 levels met eigen paden, level-select + unlock-progressie + sterren + Recognition + Shop (tech tree + consumables) + save/load, **beide hazards** (brandalarm level 2, lunchpauze level 4), eindbaas. Nog: fijnere level-layouts/pixel-art.
- **Fase 4 — Polish:** pixel-art, animaties, geluid, flavour, balancing.

## 11. Open punten / later beslissen
Economie & meta: definitieve Recognition-upgrades; consumables-lijst + effecten; aantal tas-slots; permanent vs. per-run perks. Towers: Scrum Master stapelen; Firewall-synergie; selectie-UI Scrum Master; alle balansgetallen. Algemeen: titel, geluid/muziek-stijl.

**Balans-regel (v0.12, opgelost):** *kracht per Coffee moet stijgen bij elk upgrade-level*,
zodat upgraden altijd efficiënter is dan een tweede exemplaar kopen. Tegelijk groeit **bereik
nauwelijks** (~+5% per level), zodat een tweede toren nodig blijft om een tweede stuk van de
map te dekken. Zo wint upgraden op kracht en spreiden op dekking. (Aantal waves per level = ~20, vastgelegd v0.3.0.)

## 12. Actieve herziening (deze sessie)
Nieuw ontwerpprincipe (2026-07-20): **elke tower = een manier om Focus te behouden; elke enemy = iets dat Focus kost.**

Vastgelegd deze sessie:
- ✅ Nieuwe stun-tower **Headphones** vult de crowd-control-rol (§5.3).
- ✅ De Firewall wordt de **Spam Filter**: DoT-zone + vertraging (§5.6).
- ✅ Overige towers getoetst — Coffee Machine, Auto-Reply, CEO-mail, Scrum Master blijven ongewijzigd.
- ✅ De Kletskous verhuisd naar enemy én **absorbeert de Disruptor-rol** — volledig uitgewerkt in §6 (aura-silence, immuun voor CC behalve Headphones lvl 3).

**Herziening afgerond.** Definitieve 6 towers: Coffee Machine, Auto-Reply, Headphones, CEO-mail, Scrum Master, Spam Filter. De aparte Disruptor-enemy is geschrapt (opgegaan in De Kletskous).

## 13. Pop-culture referenties (idee gebruiker 2026-07-23)
Subtiele knipogen naar **Office Space** en **The IT Crowd**, verwerkt in flavour-teksten,
tooltips, enemy-abilities of easter eggs — waar het natuurlijk past, nooit geforceerd.
Verzamellijst (aanvullen wanneer er meer opkomen):
- ✅ **De rode nietmachine** (Office Space, Miltons rode Swingline) → GEPLAATST v0.32.2: Office
  Artillery lvl 2 (Stapler) heeft flavour "It's a Swingline."
- **"Is it good for the company?"** (The IT Crowd) — bv. flavour of een boss-lijn.
- **"Did you see that ludicrous display last night?"** (The IT Crowd, voetbalpraat) — de **Sports
  Guy**-enemy (zie ideeënlijst) opent hiermee.
- **"Do you feel stressed?"** (The IT Crowd) — openingslijn van de **Peer Review**-boss.
- ✅ **"Have you tried turning it off and on again?"** (The IT Crowd) → GEPLAATST v0.32.2 als de
  ability-tekst van Error Message (komt uit de Printer).
- **"The Internet"** (The IT Crowd, het zwarte doosje) — enemy, easter egg of shop-item.
- ✅ **"0118 999 881 999 119 725 3"** (The IT Crowd noodnummer) → GEPLAATST v0.32.2: het
  brandalarm roept "FIRE ALARM! Quick, call 0118 999 881 999 119 725 3!"
- **"I'll put this with the rest of the fire."** (The IT Crowd) — past ook bij het brandalarm.
- *Meer volgt; de gebruiker vindt dit soort details belangrijk. Bij het schrijven van nieuwe
  flavour-teksten en boss-lijnen actief kansen zoeken om er een te plaatsen.*
