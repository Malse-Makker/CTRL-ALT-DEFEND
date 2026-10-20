# CTRL-ALT-DEFEND: de remake

Opgesteld 2026-10-20. Dit bestand heeft twee delen:

1. **De prompt** om in een nieuwe chat te plakken (direct hieronder).
2. **De ontwerpbijbel**: alles wat in de Godot-versie is bedacht, besloten en geleerd, zodat de
   remake daar niets van kwijtraakt.

---

## 1. De prompt (kopieer alles tussen de lijnen)

```
We gaan CTRL-ALT-DEFEND opnieuw bouwen: een tower defense over het verdedigen van je werkdag
tegen collega's. Er bestaat al een speelbare Godot-versie (v0.89.0, alpha). Die gebruiken we als
basis voor ALLE ideeën: torens, collega's, bosses, levels, economie, mini-games, toon. We bouwen
hem opnieuw in een andere engine, met echte modellen, en als browsergame.

WAT ER ANDERS WORDT
- Engine: Unity (Unity 6, build target Web), met een Unity MCP-server.
- Modellen, maps en alle assets maken we met Blender (via de Blender MCP-server) en Unity.
- Het wordt een BROWSERGAME op game.makkers.net. Geen .exe meer, geen updater, geen
  SmartScreen-gedoe: een tester opent een link en speelt.
- Alles wat inhoudelijk is (torens, collega's, bosses, levels, economie) blijft zoals beschreven
  in de ontwerpbijbel, tenzij ik iets anders besluit.

LEES EERST, in deze volgorde (oude repo: /home/mick/projecten/CTRL-ALT-DEFEND):
1. 07_REMAKE_PROMPT.md, deel 2: de ontwerpbijbel. Dit is de bron van waarheid voor de remake.
2. 05_MIJN_GAME_CONTEXT.md: identiteit, toon, wat ik NIET wil.
3. 06_SYSTEEM_AUDIT.md: de systeemanalyse tegen Bloons TD 6, met meetgetallen en wat er nog open
   staat.
4. 01_TD_DESIGN_REFERENCE.md: de benchmark (waarom BTD6 werkt).
5. HANDOFF.md, alleen de blokken "PLAYTEST-DATA LEZEN" en "Valkuilen".
De oude code (scripts/*.gd) is naslag voor exacte getallen. LET OP: de collega's en bosses in
scripts/enemy.gd en de wave-tabellen in scripts/game_state.gd zijn VEROUDERD (v0.88). De versie
in de ontwerpbijbel wint altijd.

OMGEVING
- Deze pc draait NixOS. Unity Hub en Blender zijn nog NIET geinstalleerd, en er zijn nog geen
  MCP-servers voor Unity of Blender ingesteld. Dat is de eerste klus.
- Unity op NixOS is een bekend lastig punt (het editor-binaire verwacht een gewone Linux-
  omgeving). Zoek eerst uit wat er nu werkt (nixpkgs unityhub, FHS-env, of anders) voordat je
  iets installeert, en leg het me voor.
- Server: game.makkers.net draait op de OVH-server (ssh ubuntu@makkers.net, nginx achter Nginx
  Proxy Manager). Bundel SSH-verbindingen: poort 22 gaat dicht bij te veel losse connecties.

EERSTE STAPPEN (stel dit als keuzevragen, met je aanrader erbij, en wacht op mijn antwoord)
1. Unity op NixOS: welke installatieroute, en werkt een Web-build vanaf deze machine? Lukt het
   niet binnen redelijke tijd, stel dan een plan B voor (bijvoorbeeld een web-native engine)
   met eerlijke voor- en nadelen. Kies niet zelf.
2. Stijl: 3D low-poly met een vaste top-down/isometrische camera, of 2D-sprites die we in
   Blender renderen? Laat van allebei zien wat het betekent voor werk en uitstraling.
3. Feedback naar Discord: in een browser is een webhook-URL voor iedereen zichtbaar in de
   devtools. Stel opties voor (accepteren en roteren, een kleine relay met rate limit, of via
   mijn bestaande Discord-bot my-makker op makkers.net) en adviseer.
4. Nieuwe repo: naam, publiek of privé, en waar de map komt.
Pas daarna: een bouwplan in fases, waarbij fase 1 één speelbaar level is met twee torens en
drie collega's, in de browser, op game.makkers.net.

WERKWIJZE (belangrijk)
- Overleg in het Nederlands. Alle in-game tekst is Engels.
- Stap voor stap. Korte keuzevragen met de keuzeknoppen-tool, met je aanrader erbij. Vul geen
  ontwerpkeuzes zelf in.
- Na elke wijziging testen (Unity batchmode / play mode tests) EN visueel controleren met een
  screenshot uit de browser. Overlappende tekst ziet geen enkele automatische test; dat is in de
  vorige versie meermaals misgegaan.
- Elke afgeronde wijziging uitbrengen naar game.makkers.net en committen + pushen. Een wijziging
  die niet live staat, bestaat niet voor de testers.
- VERSION bijwerken (SemVer) en bovenaan CHANGELOG.md een sectie toevoegen (Engels, speler-
  gericht). Meld aan het eind van elk bericht de volgende versie. De remake begint op 0.1.0.
- Commits als malse-makker <games@makkers.net>.
- Meet balans met cijfers (HP-equivalent per wave, schade per Coffee), niet op gevoel. De oude
  repo heeft scripts in tools/ die dat doen; bouw daar het equivalent van.
- Teksten voor spelers: natuurlijk en droog, geen AI-toon, geen em-dashes.

Begin met de vier vragen hierboven.
```

---

## 2. De ontwerpbijbel

### 2.1 Wat de game is

**CTRL-ALT-DEFEND.** Ondertitel: *"I'll put this with the rest of the focus."* (The IT Crowd).

Je verdedigt je werkdag tegen collega's die door de gangen naar je bureau lopen. Je houdt ze
tegen met voorwerpen van je bureau: koffiezetapparaat, koptelefoon, nietmachine, versnipperaar.

- **Torens zijn voorwerpen. Vijanden zijn mensen.** Dat is de scheidslijn en die is besloten.
- **Toon:** droge kantoorhumor. De grap zit in het bloedserieus behandelen van compleet stomme
  dingen. Referenties: The IT Crowd, Office Space, Papers Please, Not For Broadcast.
- **De kern die je nooit mag slopen:** de counters volgen uit het kantoorverhaal. The Board Member
  is immuun voor alles wat in persoon gebeurt, want hij is er nooit. The Cold Caller leest geen
  mail. De versnipperaar mag niet aan de archiefdoos van The Old Guard, want daar zit
  bewaarplicht op.
- **Niet doen:** fantasy, sci-fi, letterlijk geweld, microtransacties, procedurele maps, mobiele
  free-to-play-trucs (wachttijden, gacha, energie), cartoon-stijl à la Bloons.
- **Wel overnemen van Bloons TD 6:** de systeemdiepte. Elke toren een eigen werkwoord, upgraden
  is een keuze en geen prijskaartje, economie met een greed curve.

### 2.2 Valuta en meta

| Ding | Wat het is | Waarde |
|---|---|---|
| **Focus** | je levens | 100 per level (level 14: 10). Elke collega die je bureau haalt kost een vaste hoeveelheid |
| **Coffee** | geld binnen een level | start `40 + 5 × (level − 1)`, dus 40 op L1 tot 110 op L15 |
| **Recognition** | meta-valuta tussen levels | 12 per level via sterren (3 sterren = alles), +8 eenmalig voor een ronde zonder Focus-verlies |
| **Sterren** | 3 / 2 / 1 | 3 bij ≥90% Focus over **of** max 3 verloren; 2 bij ≥50% **of** max 6 verloren |

**Meta-shop (Recognition):** Startup Budget 30 (+15 Coffee per level), Extra Caffeine 30 (+10
Focus), Bulk Discount 55 (alle torens −10%), Smoke Break 12 per stuk (+15 Focus, verbruiksitem).

**Carrière:** blok 1 junior (L1-5), blok 2 medior (L6-10), blok 3 senior (L11-15). Promotie na
L5 en L10, "specialist" na L15. Boss Rush en Endless pas zichtbaar vanaf specialist.

### 2.3 Economie (gemeten en besloten)

| Regel | Waarde | Waarom |
|---|---|---|
| Kill-beloning | **0,12 Coffee per HP**, zwermen 0,09, alles wat specifiek gereedschap vraagt 0,15 | Daarvoor varieerde het een factor 3,4 en betaalde de moeilijkste vijand het slechtst |
| Demping op kills | volle opbrengst t/m wave 5, daarna −4% per wave, bodem 40% | Zonder demping liep het overschot binnen een level op van 3x naar 8x |
| Wave-salaris | `4 + wavenummer` per overleefde wave | "De wave halen" moet een eigen inkomen zijn naast "veel doodmaken" |
| Verkopen | 60% van wat erin zit | Tijdelijk in economie stappen en uitverkopen loont al (2,4x na 10 waves) |
| Duplicaat-opslag | +25% per bestaand exemplaar van hetzelfde type, max +100%, alleen bij plaatsen | Anders wint spammen altijd van upgraden |
| Coffee Machine | 20/20/30 Coffee, levert 1/2/4 per 5 seconden | De veilige economie-keuze |

**Balansregel:** schade per Coffee moet STIJGEN per upgrade-level, zodat upgraden altijd beter is
dan een tweede exemplaar. Bereik groeit juist nauwelijks, zodat een tweede toren nodig blijft om
een tweede stuk map te dekken.

**Nog open, staat klaar om te bouwen:** **The Expense Claim**, de tweede economische filosofie.
Verzamelt Coffee in een pot met rente in plaats van uit te keren; klikken claimt hem. Petty Cash
(25) +3/wave 10% plafond 60, Expense Report (30) +5/wave 15% plafond 140, Corporate Card (45)
+8/wave 20% plafond 300. *"Submit by the end of the quarter. Finance does not do exceptions."*
Te vroeg claimen is verlies, te laat ook (pot vol = groei stopt). Details in 06_SYSTEEM_AUDIT.md.

### 2.4 Torens (14)

Twee **schadesoorten**. Immuniteiten richten zich op een soort, niet op een toren, zodat ze een
bouwstijl straffen en geen slot met één sleutel zijn.

- **WRITTEN** (je schrijft terug): Auto-Reply, Quick Reply, Reply All, Self-Service, Delegation
- **IN PERSON** (werkt alleen als hij er echt is): Office Artillery, The Shredder, Thumbtacks,
  Pomodoro Timer, Keyboard Smash
- Geen soort: Coffee Machine, Headphones, Motivational Poster (doen geen schade), Ctrl+Alt+Del

Elke toren heeft een **eigen werkwoord**. Dat was de belangrijkste les uit de speeltest: "de
torens voelen hetzelfde" kwam doordat bijna alles "schiet op een vijand in bereik" deed.

| Toren | Werkwoord | Archetype | Upgrade-ladder (kosten) |
|---|---|---|---|
| **Coffee Machine** | levert Coffee, geen schade | Banana Farm | Coffee Machine 20 · Espresso Machine 20 · Barista Station 30 |
| **Auto-Reply** | schiet op de voorste, het ijkpunt | Dart Monkey | Auto-Reply 14 · Out of Office 12 · Inbox Zero 25 |
| **Quick Reply** | bouwt op zolang hij hetzelfde doel vasthoudt, tot x2; wisselen = opnieuw | ramping DPS | "Got it" 16 · "OK" 20 · Thumbs-Up 35 |
| **Office Artillery** | bereik over de HELE verdieping, trage herlaad, één enorme klap | Sniper | Rubber Band 25 · Stapler 28 · Industrial Tacker 45 |
| **Headphones** | legt iedereen in een straal stil; lvl 3 stunt echt | Ice Monkey | Earbuds 20 · Over-Ear 22 · Noise Cancelling 35 |
| **The Shredder** | zone die vertraagt, onthult onzichtbaren; schade gedeeld over iedereen erin | Glue Gunner | Wastebasket 30 · Paper Shredder 30 · Industrial Shredder 50 |
| **Thumbtacks** | gooit punaises op het pad die blijven liggen | Spike Factory | Loose Tacks 22 · Spilled Box 24 · Tack Carpet 40 (zelf de plek kiezen) |
| **Motivational Poster** | buft automatisch de dichtstbijzijnde torens (schade, snelheid, bereik) | Monkey Village | Hang In There 25 · Framed Print 28 · LED Wall 45 |
| **Delegation** | chain waarbij elke sprong HARDER slaat (escaleren maakt het erger) | chain | Delegate 28 · Escalate 30 · Company Policy 48 |
| **Self-Service** | raakt alles in een kleine ring om zich heen, onbeperkt aantal | Tack Shooter | Send the FAQ 25 · Send the Wiki 28 · Send to Service Desk 45 |
| **Pomodoro Timer** | mortier: speler kiest een TEGEL, hij beukt die tegel, dwars door muren | Mortar | Pomodoro Timer 26 · Focus Sprint 28 · Deep Work 45 |
| **Reply All** | splash die meebeweegt met een doelwit | Bomb Shooter | Reply All 26 · CC the Team 28 · Company-Wide Email 45 |
| **Keyboard Smash** | *special, max 1:* AoE-klap op het pad en daarna een slagboom | blocker | 60 |
| **Ctrl+Alt+Del** | *special, max 1:* laadt op, force-quit de sterkste collega, eenmalig | ability | 60 |

Exacte getallen per level: `scripts/tower.gd` in de oude repo (actueel).

**Zijsporen (crosspath).** Naast de ladder heeft elke toren (behalve Coffee Machine en de
specials) twee sporen van twee stappen. Je kiest er één; de eerste stap zet het andere op slot.
Stap 1 kost 50% van de instapprijs, stap 2 100%.

| Spoor | Stap 1 | Stap 2 |
|---|---|---|
| **OVERTIME** *"Just one more thing before I log off."* | 20% sneller | +20% bereik |
| **ESCALATION** *"I'm going to have to loop in a few more people."* | meer doelen (per rol anders) | +25% schade |

**Ontgrendeling:** één toren per level, zodat elke toren een eigen introductie krijgt. L1 Coffee
Machine + Auto-Reply · L2 + Headphones, Office Artillery, The Shredder · L3 + Quick Reply · L4 +
Thumbtacks, Self-Service · L5 + Keyboard Smash · L6 + Reply All · L7 + Delegation · L8 + Pomodoro
· L9 + Motivational Poster · L10 + Ctrl+Alt+Del. Daarna is de toolkit compleet. De shop toont bij
vergrendelde torens op welk level ze komen.

**Targeting** per toren instelbaar: First (standaard), Last, Closest, Farthest, Least HP, Most HP.

**Nog open, uit de werkwoorden-ronde:**
- The Shredder: schade blijft **plakken**, wie de zone verlaat bloedt door
- Thumbtacks: punaises **negeren zicht** en raken meerdere vijanden
- Motivational Poster: lvl 3 geeft ook **korting** op torens in de straal
- Keyboard Smash: schade eruit, blokkade langer
- Ctrl+Alt+Del: wordt een **knop met cooldown** in plaats van een toren (besloten)
- **The Whiteboard:** nieuwe support die onzichtbaren in een straal onthult (detectie-rol)

### 2.5 Collega's (10): VERVANGT de versie in de oude code

Besloten 2026-08-06. Van 33 vijandtypes naar 21 (10 collega's + 11 boss-defs). Elke collega vult
één rol. Waar een counter erop leunt dat er een voorwerp is, **draagt de collega dat voorwerp**.

| Collega | Rol | HP | Snelheid | Focus | Wat hij doet | Counter |
|---|---|---|---|---|---|---|
| **The Intern** | normaal, licht | 4 | 105 | 1 | Er gewoon. En er zijn er veel. Ook wat bosses erbij roepen | Elke goedkope schadetoren |
| **The New Hire** | normaal, zwaar | 12 | 80 | 2 | *"Sorry, where do I find...?"* Houdt langer aan | Upgrade je basistoren |
| **The Chaser** | snel, zwak, veel | 3 | 190 | 1 | *"Just bumping this up your inbox."* Nooit alleen | Area-schade, of eerst afremmen |
| **The Requester** | splitter | 16 | 80 | 3 | *"Can we just tweak one thing?"* Splitst bij dood in 2 Chasers | Area-schade, klaar zijn voor de helften |
| **The Old Guard** | tank | 46 + schild 30 | 50 | 8 | Sleept de archiefdoos mee. Klappen onder 10 ketsen af; de Shredder mag er niet aan | Office Artillery, opgewaardeerde Pomodoro, Keyboard Smash |
| **The Impersonator** | onzichtbaar | 10 | 100 | 3 | *"It is me, the CEO. I need gift cards."* Onzichtbaar tot een Shredder-zone hem onthult | Shredder-zone, daarna alles |
| **The Board Member** | immuun voor IN PERSON | 40 | 60 | 8 | Nooit fysiek aanwezig | Alles wat WRITTEN is |
| **The Cold Caller** | immuun voor WRITTEN | 24 | 92 | 4 | Leest geen mail. Hij belt | Alles wat IN PERSON is |
| **The Chatterbox** | verstoorder | 22 | 75 | 5 | Legt torens in de buurt stil. Alleen Headphones lvl 3 snoert hem de mond | Headphones lvl 3, of torens buiten zijn route |
| **The Phone Caller** | taunt | 34 | 86 | 5 | Single-target torens schieten EERST op hem, en hij kan het hebben | Area-schade, of single-target buiten zijn bereik |

Kill-beloning volgens §2.3 (0,12 per HP, zwermen 0,09, Old Guard / Impersonator / Board Member /
Cold Caller / Chatterbox / Phone Caller 0,15).

**Geschrapt bij het snoeien:** User Story, The Thread, Task, Feedback, The Printer, Error Message,
System Update, The Micro-manager, **The Steering Committee**. Die laatste was de klasse-breuk op
L6 (schil die burst vraagt, met vier Board Members erin die immuun zijn voor burst). Het is een
goed idee dat bij het snoeien sneuvelde; vraag of hij terug moet als boss of klasse-breuk.

### 2.6 Bosses (10 mensen, 11 defs)

Vier komen terug in een zwaardere versie (HP-vermenigvuldiger) in plaats van dat er elk level een
nieuw gezicht verschijnt.

| Level | Boss | Wat hij doet |
|---|---|---|
| 1 | **The Head of Comms** | *"This could have been an email."* Roept doorlopend Interns erbij |
| 2 | **The Repair Guy** | Komt de koffiemachine "maken". Geen Coffee-inkomen zolang hij leeft |
| 3 | **The Presenter** | *"Can everyone see my screen?"* Schild als laadscherm, beamt zwermen naar je bureau |
| 4 | **The Cleaner** | Versnelt collega's in de buurt, veegt Shredder-zones en punaises weg |
| 5 | **Your Line Manager** | Drie fases: schild, roept peer reviewers, wordt sneller en remt je torens |
| 6 | **The Baby** | Eist alle aandacht. Torens in de buurt vuren trager |
| 7 | **The Smoking Colleague** | De rook verkort het bereik van al je torens |
| 8 | The Head of Comms, x1,8 HP | Terugkeer, op de Flexplek met vier deuren |
| 9 | The Repair Guy, x1,8 HP | Terugkeer, op Town Hall waar je al maar halve Coffee krijgt |
| 10 | Your Line Manager, x1,4 HP | Terugkeer, medior-finale |
| 11 | **The HR Manager** | Doet audits: legt telkens één heel torentype stil |
| 12 | **The Consultant** | Buft elke andere collega. Dood hem en de wave zakt in |
| 13 | The Cleaner, x1,9 HP | Terugkeer, in de Server Room waar hij je gekochte zones wegveegt |
| 14 | **The Project Manager** | *"Where are we on this?"* Hoe langer hij leeft, hoe sneller ALLES beweegt |
| 15 | **Your Line Manager, 360** | Finale. Eerdere bosses keren terug als peer reviewers. *"Do you feel stressed?"* |

Alle bosses hebben fases op 66% en 33% HP en verminderde stun-gevoeligheid. Speeltest-klacht die
nog open staat: **bosses veranderen te weinig aan wat je moet doen.** Ontwerp ze zo dat elke boss
een andere aanpak afdwingt.

### 2.7 Levels (15)

| # | Blok | Naam | Gimmick | Hazard / modifier |
|---|---|---|---|---|
| 1 | junior | Open-Plan Office | eenvoudige S-bocht, intro | geen |
| 2 | junior | Coffee Corner | snelheid en crowd control, lange rechte stukken | geen |
| 3 | junior | Meeting Room | kam (zwerm tegen area) | projector-mini-game |
| 4 | junior | Canteen | lange lus, natte-vloer-vakken (niet bouwen) | lunchpauze-zwerm |
| 5 | junior | Boardroom | lus om de vergadertafel | geen |
| 6 | medior | Work From Home | spiraal met zichtmuren | No Internet (dino-mini-game) |
| 7 | medior | The Parking | gespreide switchback, rand-banen, geparkeerde auto's | rook verkort bereik |
| 8 | medior | The Flexplek | 4 deuren die per wave rouleren | geen |
| 9 | medior | Town Hall | bureau in het MIDDEN, 3 fronten | telefoon-mini-game + halve Coffee |
| 10 | medior | Boardroom II | zelfde arena + pilaren | brandalarm + max 8 torens |
| 11 | senior | HR Room | kam met muur in je oude pocket | formulier-mini-game + Auto-Reply en Quick Reply verboden |
| 12 | senior | The Merger | haakpad, rond wave 12 voegt een tweede pad in | halve Coffee |
| 13 | senior | Server Room | gangpaden tussen racks, bouwplekken op de racks kopen | oververhitting |
| 14 | senior | Release Night | alleen bouwen langs het pad, tweede front vanaf wave 10 | pizza-mini-game + start met 10 Focus |
| 15 | senior | Boardroom III | zelfde arena, alleen bouwen langs het pad | projector-mini-game |

Blok 1: 20 tot 22 waves per level, blok 2 en 3: 15. Elk level eindigt op zijn boss. Exacte
padcoördinaten, muren, zones en de ontwerpregels (lane-afstanden, softlock-checks) staan in
MAP_DESIGN_REVIEW.md en scripts/game_state.gd.

**Softlock-regels die altijd moeten gelden:** Headphones beschikbaar vóór de eerste Chatterbox
(L2). Shredder vóór de eerste Impersonator (L4). Thumbtacks vóór The Cleaner (L4). Area-schade
vóór de eerste Phone Caller. Headphones mag NOOIT verboden worden op een level met een Chatterbox.

**Wave-tabellen** moeten opnieuw: de oude zijn op de geschrapte vijanden gebouwd. Startpunt is de
v0.88-tabel met deze vertaling: User Story en Micro-manager → The Requester, Thread en Task → The
Chaser, Feedback en Error Message → The Intern, Printer → The Board Member, System Update → The
Cold Caller. Meet daarna het HP-equivalent per wave en houd de curve vloeiend: in de oude versie
zaagde hij (L5 lichter dan L2-4, L6 30% lichter dan L5).

**Speeltest-doel:** elk level haalbaar zonder Focus te verliezen als je het goed speelt.

### 2.8 Mini-games en hazards

Hazards zijn **interactieve mini-games**, het spel loopt gedimd door terwijl je ze doet, en er is
altijd een auto-skip zodat je nooit vastzit. Dit is een van de sterkste punten van de game.

- **Projector:** beamer aansluiten (L3, L15)
- **Eat the Pizza:** timingbalk, klik of spatie (L14)
- **No Internet:** dino-runner met een voortgangsbalk "Reconnecting..." (L6)
- **Telefoon:** telefoon schuift in en trilt; rood ophangen, groen opnemen helpt niet (*"Hi, do you
  have a minute?"*) (L9)
- **Formulier:** compliance-document van 5 pagina's met handtekeningregels (L11)
- Overige hazards: lunchpauze-zwerm (L4), rook (L7), brandalarm waarbij iedereen sprint (L10),
  oververhitting (L13)

### 2.9 Modi

Tutorial (7 lessen met hint-pijl), Boss Rush, Endless.

### 2.10 UI-beslissingen die werkten

- Shop rechts met naam onder elk icoon, in ontgrendelvolgorde; vergrendelde torens tonen hun level.
- Collega-overzicht links: wie er nu op de vloer staat, met NEW-badge.
- Snelheden 1x / 2x / 4x / 8x, pauze, wave vroeg oproepen voor punten.
- Torenpaneel: upgrade, zijsporen, targeting, verkopen, en per toren de schade per Coffee.
- Eindscherm: **WHAT HURT YOU**, de doorbraken gesorteerd op Focus-schade (niet op aantal), met per
  collega wat je ertegen bouwt. Scrollbaar.
- **Give up** naast Quit: dan kom je op het eindscherm met je cijfers. Zonder die knop gingen
  spelers waves spammen om een verloren ronde af te raffelen.
- Na elke ronde: "How much FUN was this level? 0-10" plus opmerking, met één knop naar Discord.
- What's New-pagina in de game, gevoed door CHANGELOG.md.

### 2.11 Lessen uit de Godot-versie (niet opnieuw leren)

**Ontwerp**
1. Torens moeten een ander **werkwoord** hebben, geen ander getal.
2. Een immuniteit straft een **bouwstijl**, nooit één specifieke toren.
3. Een economische aankoop moet **fout kunnen zijn**, anders is het geen keuze.
4. Een tekst die de speler iets belooft (bijv. "light hits bounce off") moet in de code waar zijn.
   Het schild was ooit gewoon 30 extra HP terwijl de tutorial het tegendeel leerde.
5. Waarschuwingen nooit tonen aan iemand die al verliest.
6. Een verborgen tweede handeling maakt een toren onzichtbaar. De Poster deed niets tot je
   torens aanklikte, en werd daardoor nul keer gekocht terwijl hij per Coffee de sterkste was.

**Playtest-data lezen**
- Vroeg waves oproepen correleert met verliezen maar veroorzaakt het niet: spelers raffelen een
  verloren ronde af. Kijk naar verdiende Coffee en kills.
- Kijk naar wie er doorheen kwam vóór je aan torens sleutelt. "Te zwaar" bleek een wave-tabel.
- Vergelijk met de winnende ronde van dezelfde speler, en let op welke versie gespeeld werd.

**Techniek**
- UI nooit met vaste posities en handmatig berekende hoogtes: gebruik layout-containers en meet.
  Drie keer viel er iets van het scherm (meldingsregel achter een paneel, Sell-knop onder de rand,
  feedbackformulier onbereikbaar).
- Lange teksten afbreken op woordgrens; een label zonder wrap loopt gewoon het scherm uit.
- Let op stille parse-fouten: `float("2.00*1.8")` gaf in GDScript 2.0 zonder klacht.
- Geen emoji of speciale Unicode in UI-tekst tenzij het font ze aantoonbaar heeft; anders worden
  het lege blokjes. Symbolen tekenen.
- Releases via één script, zodat versie, changelog en build nooit uit de pas lopen.
- Eén bron voor de changelog.

### 2.12 Nog open uit de laatste speeltest (2026-08-05)

De tester (de maker zelf) vond de game "niet te moeilijk" maar:
1. **Torens voelen hetzelfde**: aangepakt met de werkwoorden in §2.4, nog niet gespeeld.
2. **Onduidelijk wat er gebeurt**: waarom landt schade niet, wat weert deze collega af, wat doet
   mijn toren eigenlijk. Bouw dit in vanaf het begin: zichtbare feedback op elke treffer.
3. **Te weinig te doen tijdens een ronde**: de Pomodoro richten was een begin. Abilities
   (Ctrl+Alt+Del als knop) en meer momenten om in te grijpen.

### 2.13 Staat van de oude repo

- Laatste gepushte versie: **v0.88.0** (`e1e94e3`).
- **v0.89.0** (de collega-rework) staat live als Windows-release, maar de broncode is nooit
  gepusht: die commit staat alleen op de oude Mac. Voor de remake maakt dat niet uit, want alles
  daaruit staat in §2.5 en §2.6.
