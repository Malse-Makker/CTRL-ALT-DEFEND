# Office Tower Defense — brief voor een map-design review

Je bent een ervaren game-designer die gespecialiseerd is in tower-defense. Ik bouw een game
(**Office Tower Defense**) en wil dat je **heel kritisch naar het map-design kijkt** en concrete,
goed onderbouwde verbeteringen voorstelt. Lees eerst de hele brief. Aan het eind staat precies wat ik
van je wil. Stel gerust verhelderende vragen voordat je begint als iets onduidelijk is.

> In-game tekst is Engels; met mij overleg je in het Nederlands.

---

## 1. De game in het kort

Top-down tower defense in kantoor-thema (Godot 4.7). Je speelt een kantoormedewerker; **vijanden zijn
kantoor-afleidingen** (notificaties, vergaderingen, deadlines) die over een pad naar **jouw bureau**
lopen. Bereiken ze het bureau, dan verlies je **Focus** (= levens). Je bouwt **torens** (kantoor-tools)
langs het pad om ze tegen te houden. Toon: luchtig, veel kantoorhumor en pop-culture (Office Space,
The IT Crowd).

**Carrière-structuur:** 15 levels in 3 blokken van 5 — **junior (1-5)**, **medior (6-10)**,
**senior (11-15)**. Je verdient sterren per level. Aan het eind van elk blok (level 5, 10, 15) staat
**The Performance Review** als eindbaas: versla je die, dan word je gepromoveerd (junior → medior →
senior → specialist).

## 2. Kernsystemen

- **Coffee** = geld. Je krijgt het van **Coffee Machine**-torens en van kills. Hiermee bouw en upgrade
  je torens.
- **Focus** = levens (meestal 100). Elke vijand die je bureau bereikt kost Focus. 0 = verloren.
- **Plan-fase → waves.** Voor elke ronde plaats je in rust torens (tijd staat stil). Dan start je de
  waves. Je kunt een wave **vroeg oproepen** voor bonuspunten.
- **Torens upgraden** naar level 1→2→3 (elk sterker, eigen sprite). **Specials** zijn los: max 1 per
  level, geen upgrades, staan óp het pad.
- **Targeting:** per toren instelbaar (first / last / closest / farthest / least-hp / most-hp, plus
  "hidden first").
- **Snelheid** 1×/2×/3× en pauze.

## 3. Torens (rol + waar ze goed tegen zijn)

| Toren | Rol | Bijzonder / counter |
|---|---|---|
| **Coffee Machine** | Economie | Genereert Coffee. Geen schade. |
| **Auto-Reply** | Basis-schade | Goedkoop, betrouwbaar. (Cold Caller is er immuun voor.) |
| **Headphones** | Crowd control | Slow → slow → **stun**. Lv3 "Active Noise Cancelling" is het enige dat de Chatterbox stillegt. |
| **Office Artillery** | Zware single-target / sniper | Hoge schade, traag. (Board Member is er immuun voor.) |
| **The Shredder** | Zone / area | Legt een versnipper-zone op het pad. Eet "papieren" vijanden (The Thread) en **onthult onzichtbare** Suspicious Links. (Old Guard is immuun.) |
| **Motivational Poster** | Support | Buft nabije torens (schade/tempo). |
| **Thumbtacks** | Val | Gooit punaises op willekeurige pad-tegels; vijand die erover loopt krijgt schade. Lv3: richtbaar. |
| **Keyboard Smash** | Special (op pad) | AoE-klap + slagboom die vijanden even stilzet. |
| **Delegation** | Chain | Schot springt door naar volgende vijanden (schade valt af per sprong). |
| **Quick Reply** | Snelvuur | Heel snel, minieme schade. Goed tegen zwakke zwermen. |
| **Self-Service** | Multi-shot | Raakt meerdere doelen tegelijk (2/5/8). |

Niet elk level heeft alle torens beschikbaar — een lescurve introduceert ze geleidelijk (blok 1),
daarna is de volle set beschikbaar.

## 4. Vijanden (en hun counter)

- **The Notification** — snel, simpel basis-doel.
- **The Question** — stevigere basis.
- **User Story** — zware basis.
- **The Old Guard** — schild, immuun voor de Shredder → burst nodig.
- **The Nudge** — heel snelle zwerm → area / slows.
- **The Thread** — grote papier-tros → Shredder eet 'm.
- **The Change** — splitst bij dood in twee Tasks → area/burst.
- **The Micro-manager** — versnelt hoe meer schade hij krijgt → in één keer wegblazen.
- **The Chatterbox** — legt nabije torens het zwijgen op; alleen Headphones lv3 stopt 'm.
- **The Printer** — hapert en spuwt Error Messages → snel doden.
- **Suspicious Link** — onzichtbaar tot een Shredder-zone 'm onthult.
- **The Board Member** — immuun voor Office Artillery.
- **The Cold Caller** — immuun voor Auto-Reply → burst.

## 5. Map-mechanieken (het gereedschap voor map-design)

Dit zijn de bouwstenen die ik voor maps kan inzetten:

- **Pad-vormen** (bochten, lussen, serpentine). *Belangrijk designprincipe:* **paden die dicht bij
  elkaar of samen lopen zijn makkelijker**, want één toren dekt dan meerdere baan-stukken tegelijk.
  Ver uit elkaar = moeilijker.
- **Multi-ingang** — meerdere deuren waar vijanden uit komen (rouleren per wave).
- **Bureau-in-het-midden** — het doel staat centraal, vijanden komen van meerdere kanten.
- **Obstakels** — massieve blokken (vergadertafel, serverracks): pad loopt eromheen, niet bebouwbaar.
- **Geen-bouw-zones** — vakken waar je niet mag bouwen (wel doorloopbaar).
- **Zicht-muren** — schotten die het **schootzicht** blokkeren (line-of-sight): een toren raakt geen
  vijand áchter een muur, dus dekt maar een klein gebied.
- **Betaal-om-te-bouwen-zones** — vergrendelde bouwvakken die je eerst met Coffee ontgrendelt.
- **Corridor-bouwen** — de hele map is geen-bouw, behálve een smalle strook (~2-3 tegels) rond een
  actief pad.
- **Onthul-paden** — extra pad(en) die pas bij een bepaalde wave opengaan (met een eigen bouwstrook in
  corridor-levels). De speler ziet vooraf niet dat er een pad komt.
- **Modifiers (hele ronde):** `few_spots` (weinig torens toegestaan), `banned` (bepaalde torens
  verboden), `half_coffee` (50% koffie-inkomen), `low_focus` (start met weinig Focus).
- **Hazards / events / mini-games (tijdens de ronde):** brandalarm, projector-QTE (kabels aansluiten),
  lunch-swarm, rook (bereik omlaag), "No Internet" dino-mini-game, telefoon-event, formulier-event,
  oververhitting (torens tijdelijk stil), "Eat the Pizza"-timing-mini-game.

## 6. Carrière & promotie (VAST)

- Blokken van 5. **Level 5, 10 en 15 zijn de Performance-Review-eindbazen** die je promotie bepalen.
- **Alleen deze drie mogen dezelfde layout delen** (het is telkens "dezelfde" review-arena), maar ze
  moeten **oplopen in moeilijkheid via gimmicks / events / hazards**, niet via de vorm.
- De thema-volgorde van de **overige levels ligt NIET vast** — die mag herschikt worden als dat de
  opbouw verbetert. Alleen 5/10/15 staan vast.

## 7. Overzicht — alle 15 maps (huidige staat)

Legenda: **Gimmick** = het bouw/pad-mechaniek dat de map uniek maakt. Bureau = het doel.

| # | Blok | Thema (naam) | Gimmick | Layout | Boss — wat 'ie doet | Hazard / Event / Modifier |
|---|---|---|---|---|---|---|
| 1 | junior | **Open-Plan Office** | Simpele intro | Rustige S-bocht, 1 pad, bureau rechts | **The All-Hands Meeting** — "this could have been an email"; blijft iedereen erbij roepen (spawnt Notifications) | — |
| 2 | junior | **Coffee Corner** | Snelheid/crowd-control | Hoge piek-S, 1 pad | **Out of Order** — komt het koffieapparaat "repareren"; zolang hij leeft **geen Coffee-inkomen** | Brandalarm (hazard) |
| 3 | junior | **Meeting Room** | Zwerm vs. area | Kam/serpentine (3 tanden) | **The Broken Projector** — schild ("loading"), eerst breken; beamt slides naar je bureau | Projector-QTE (kabels aansluiten, mini-game) |
| 4 | junior | **Canteen** | Diversiteit | Grote lus, 1 pad | **The Cleaner** — de conciërge; versnelt nabije vijanden + **veegt Shredder-zones en punaisevallen weg** | Lunch-swarm (hazard) |
| 5 | junior | **Boardroom ①** | Boardroom-layout + centrale tafel (obstakel) | Lus rond de vergadertafel, bureau rechtsboven | **The Performance Review** (promotie) — 3 fases: schild → spawnt Feedback → versnelt + vertraagt jouw torens; nauwelijks te stunnen | — |
| 6 | medior | **The Parking** | Brede switchback + geen-bouw-zones (auto's) | 3 banen ver uit elkaar, haarspeldbochten | **The Smoking Colleague** — rookpauze; de haze **verkort het bereik van elke toren** | Rook (hazard: bereik↓) |
| 7 | medior | **Work From Home** | Compact + zicht-muren (meubels) | Knusse lus rond een kamer | **The Baby** — eist alle aandacht; nabije torens raken afgeleid en **vuren trager** | "No Internet" dino-mini-game (event) |
| 8 | medior | **The Flexplek** | Multi-ingang (4 deuren) | 4 deuren mergen bij het bureau | **The Floater** — geen vaste plek; blijft van alle kanten een menigte erbij trekken | — |
| 9 | medior | **Town Hall** | Bureau-in-het-midden (3 deuren) | Doel centraal, vijanden van 3 kanten | **The Reorganisation** — "we herstructureren"; splitst bij elke fase een Manager af | Telefoon-event + 50% Coffee (modifier) |
| 10 | medior | **Boardroom ②** | Boardroom-layout + tafel + zicht-pilaren | Zelfde lus als L5 + minder bouwplekken | **The Performance Review** (promotie) — idem, zwaarder | Weinig bouwplekken (modifier) |
| 11 | senior | **HR Room** | Brede lanes + zicht-muren (cubicles) + verboden torens | ⊓-vorm, banen ver uit elkaar | **The HR Manager** — houdt audits; legt telkens **één van jouw torentypes** een paar sec stil | Formulier-event + Headphones & Quick Reply **verboden** (modifier) |
| 12 | senior | **Server Room** | Obstakels (racks) + betaal-om-te-bouwen-zones | Pad slingert tussen serverkasten | **The Legacy System** — oeroud, vrijwel onkillbaar; **spuwt de hele tijd Error Messages** | Oververhitting (torens stil, hazard) + weinig bouwplekken |
| 13 | senior | **The Merger** | Corridor-bouwen + onthul-pad | Bureau midden; start 1 pad van **links**, wave 10 opent een pad van **rechts** (bedrijven mergen) | **The Consultant** — buft alle andere vijanden (snelheid + schilden); dood 'm om de wave te verzwakken | Corridor-bouwen (gimmick) |
| 14 | senior | **Release Night** | Corridor-bouwen + onthul-pad | Bureau rechts-van-midden; 1 pad van links-boven, wave 10 een 2e van links-onder | **The Deadline** — hoe langer hij leeft, hoe sneller **ALLES** beweegt; snel wegbursten | "Eat the Pizza"-mini-game + start met 10 Focus (low_focus) |
| 15 | senior | **Boardroom ③ / finale** | Corridor-bouwen + **gespiegelde 4-lane** (elke ~4 waves opent een lane) | Bureau midden; 2 paden van links + 2 van rechts komen samen — alles komt op je af | **The Performance Review** (promotie, finale) — idem, zwaarst | Corridor-bouwen (gimmick) |

**Kanttekeningen bij de huidige staat (waar ik twijfel over heb):**
- Level 5/10/15 delen nu **niet** allemaal exact dezelfde layout meer: 5 en 10 zijn de boardroom-lus
  met tafel, maar 15 is een 4-lane corridor-finale geworden. Ik wil eigenlijk dat **5/10/15 dezelfde
  layout hebben** en alleen via gimmicks/events/hazards moeilijker worden. Hier wil ik jouw advies.
- De **moeilijkheids-opbouw** is niet uitgespeeld; ik weet niet of de curve lekker oploopt.
- Sommige gimmicks zitten misschien op de "verkeerde" plek qua thema of moeilijkheid.

## 8. Ontwerp-randvoorwaarden (waar je voorstel aan moet voldoen)

1. **Elk level iets moeilijker** dan het vorige — een lekkere, voelbare opbouw over de 15 heen.
2. **Samenkomende / dicht bijeen lopende paden = makkelijker** (één toren dekt meerdere lanes). Gebruik
   dit bewust als moeilijkheids-knop: makkelijker vroeg, meer gespreide/aparte lanes later.
3. **Thema-passend** — de gimmick, boss en hazard/event van een level moeten bij het kantoor-thema van
   die map passen en samen kloppen.
4. **Volgorde van thema's mag herschikt** worden (dat mag je voorstellen) — **behalve level 5, 10 en 15**,
   dat zijn de vaste Performance-Review-promotie-momenten.
5. **5/10/15 mogen als enige dezelfde layout delen**, maar moeten oplopen in moeilijkheid via
   gimmicks/events/hazards, niet via de padvorm.
6. Gebruik alleen de bouwstenen uit §5 (of stel gemotiveerd een nieuwe voor, met uitleg waarom).

## 9. Wat ik van je wil

Kijk **heel kritisch** naar het map-design en lever:

1. **Een beoordeling** van de huidige 15 maps: wat werkt, wat niet, en waarom (met nadruk op de
   moeilijkheids-curve en of gimmick/boss/hazard per level goed samen kloppen en bij het thema passen).
2. **Een concreet herzien overzicht** van alle 15 maps in dezelfde tabel-vorm als §7 (thema, gimmick,
   layout, boss + wat 'ie doet, hazard/event/modifier), waarin:
   - de moeilijkheid duidelijk en gelijkmatig oploopt;
   - je waar nuttig de thema-volgorde herschikt (met korte reden);
   - 5/10/15 dezelfde layout delen en alleen via gimmicks/events/hazards zwaarder worden;
   - je het "samenkomende lijnen = makkelijker"-principe bewust inzet.
3. **Per wijziging een korte onderbouwing** (waarom dit beter is voor de curve / het thema / de fun).
4. Markeer waar je **twijfelt of een aanname mist**, en stel me daar een gerichte vraag over.

Denk hardop en wees eigenwijs waar dat het ontwerp beter maakt — ik wil juist een frisse, kritische blik.
