# Overdracht — Office Tower Defense

Start een nieuwe chat **in de map `/Users/nijntje/Documents/projecten`** (daar staat
`.mcp.json` met de godot-, blender- en retro-diffusion-servers) en plak het blok hieronder.

---

## PLAK DIT IN DE NIEUWE CHAT

We werken samen aan **Office Tower Defense**, een top-down tower defense in Godot 4.7
(map: `/Users/nijntje/Documents/projecten/game`). Lees eerst deze bestanden, in deze volgorde:

1. `game/README.md` — wat er werkt en hoe je het start
2. `game/Office_TD_GDD.md` — het ontwerpdocument (bron van waarheid)
3. `game/HANDOFF.md` — deze overdracht: werkwijze, valkuilen en de volledige takenlijst
4. `game/art/STYLE_GUIDE.md` — hoe sprites gemaakt en verwerkt worden
5. `game/MAP_DESIGN_REVIEW.md` — de volledige map-/level-design-review (curve, gimmicks, bosses,
   hazards én de ruimtelijke pad-layouts). De data-laag is doorgevoerd (v0.55.0); bovenaan staat
   wat nog openstaat. Bevat ook §9 open ontwerp-vragen.
   (Ter referentie ook: `FABLE5_MAP_REVIEW_PROMPT.md` + `FABLE5_LAYOUT_REVIEW_FOLLOWUP.md` — de prompts
   waarmee die review is opgehaald.)

> **De game heet sinds v0.66.0 CTRL-ALT-DEFEND** (was werktitel "Office Tower Defense").
> Projectmap: `/Users/nijntje/Documents/projecten/CTRL-ALT-DEFEND` — een **publieke git-repo**
> op `git@github.com:Malse-Makker/CTRL-ALT-DEFEND.git`. De oude map `projecten/game` is een
> kopie van vóór de verhuizing en mag weg zodra de gebruiker het zegt; **werk daar niet meer in**.
> Commits gaan als `malse-makker <games@makkers.net>` — die identiteit en de SSH-sleutel
> (`~/.ssh/makkersgames`) staan **lokaal in deze repo**, zodat andere projecten hun eigen
> instellingen houden. Dus: **na elke wijziging committen én pushen.**

**Releasen — vaste werkwijze sinds v0.64.0 (LEES DIT VOOR JE IETS WIJZIGT):**
- **Na elke aanpassing uitbrengen.** Testers draaien de alpha; een wijziging die niet geüpload
  is, bestaat voor hen niet.
- **Altijd via `tools/make_release.sh`** — nooit handmatig exporteren/uploaden. Het script doet:
  changelog valideren → headless check → exporteren → zippen → sha256 → `changelog.json`,
  `version.json` en `changelog.html` genereren → downloadknop bijwerken → **GitHub Release
  aanmaken + zip en version.json uploaden** → site naar OVH → controleren. `--dry-run` bouwt
  alles zonder te publiceren.
- **We leveren een KALE .exe uit, geen zip** (v0.67.0, wens gebruiker): niets uitpakken, en de
  downloadknop kan rechtstreeks naar het bestand wijzen. De assetnaam is bewust **vast**
  (`CTRL-ALT-DEFEND.exe`, zonder versienummer), want alleen dan werkt
  `releases/latest/download/<naam>` — en dat adres gebruiken zowel de knop als de updater, dus
  per release hoeft er niets aan URL's bijgewerkt te worden. *Kosten:* ~105 MB per download in
  plaats van ~37 MB ingepakt. Wordt dat vervelend, dan kan de zip terug voor de updater alleen.
- **VALKUIL: zet een release NIET op `prerelease`.** GitHub's `releases/latest` slaat
  pre-releases over, dus dan geeft `latest/download/...` een 404 — precies het adres waar de
  knop en de updater op leunen. Dit is één keer misgegaan en door de controlestap in het
  script gevangen. Dat het een alpha is, staat in de titel, de notes en op de site.
- **De binary staat op GitHub Releases, niet op de eigen server** (sinds v0.66.0, na feedback
  dat zelf-hosten van een zichzelf-updatende .exe onveilig is). Redenering: wie de webserver
  overneemt bepaalt wat er bij elke tester geïnstalleerd wordt, en een checksum die op diezelfde
  server staat bewijst dan niets. De OVH-server serveert alleen nog de pagina's.
  `scripts/updater.gd` leest `releases/latest/download/version.json` — dat adres wijst vanzelf
  naar de nieuwste release, dus er hoeft per release niets aan URL's bijgewerkt te worden.
  *Nog niet gedaan (de eigenlijke bescherming):* **handtekeningverificatie** — release
  ondertekenen met een privésleutel die alleen lokaal staat, publieke sleutel in de game
  (Godot `Crypto`). Dan maakt het niet meer uit wie welke server overneemt.
- **Publiceren vraagt een GitHub-token** met *Contents: read and write* op deze repo, in
  `~/.config/makkers/github_token` (chmod 600) of `$GITHUB_TOKEN`. Zonder token stopt
  `tools/github_release.py` met uitleg. De gebruiker maakt dat token zelf aan.
- **Stappen:** `CHANGELOG.md` bovenaan een `## v<nieuwe versie> — <datum>`-sectie zetten (Engels,
  speler-gericht), `VERSION` bumpen, `./tools/make_release.sh` draaien. Het script **weigert** als
  de bovenste changelog-sectie niet gelijk is aan `VERSION` — dat is expres.
- **`CHANGELOG.md` is de enige bron van waarheid** voor de changelog. Daaruit worden gegenereerd:
  `changelog.json` (gaat mee in de build, voedt de **What's New**-pagina in het hoofdmenu),
  de `changes` in `version.json` (het update-scherm) en `changelog.html` (de site).
  *Valkuil:* `CHANGELOG.md` zélf meeleveren kán niet — het export-preset sluit `*.md` uit en dat
  exclude-filter wint van het include-filter. Vandaar de gegenereerde `.json`.
- **Checksums horen erbij.** `version.json` en `changelog.html` publiceren de sha256 van de zip
  én van de .exe; de game toont de eerste 12 tekens van zijn eigen exe-hash rechtsonder in het
  hoofdmenu (`scripts/build_info.gd`, in een thread zodat het opstarten niet hapert). Zo kan een
  tester controleren dat hij de build speelt die op de site staat.

**Werkwijze (belangrijk):**
- We overleggen in het **Nederlands**, alle **in-game tekst is Engels**.
- Stap voor stap. Stel korte keuzevragen met de keuzeknoppen-tool, geef bij elke vraag aan
  wat je zelf aanraadt, en vul niets zelf in zonder dat ik beslis.
- Na elke wijziging **headless testen**:
  `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --quit-after 120`
  (schoon = alleen de engine-versieregel). Tijdelijke autotest-code er daarna weer uithalen.
- Controleer wijzigingen ook **visueel** met een schermafdruk vanuit het spel — er zijn al
  meerdere fouten zo gevonden die de headless test niet ziet.
- **VERSION** bijwerken (SemVer) en aan het eind van je bericht de volgende versie melden.
- Retro Diffusion kost geld — **altijd eerst `estimate_inference_cost`** (gratis) en
  overleggen voordat je genereert.
- Zet de openstaande punten uit dit bestand aan het begin in je takenlijst.

De stand van zaken en alles wat nog moet gebeuren staat onderaan dit bestand.

---

## Structuur

```
scripts/
  app.gd          schermbeheer: menu, level select, settings, shop, art room
  game_state.gd   AUTOLOAD: progressie, settings, save/load, wave-tabellen, lescurve
  level.gd        de gameplay: plaatsen, waves, hazards, HUD, win/lose (~1780 regels)
  tower.gd        data-driven towers (defs() + configure())
  enemy.gd        data-driven vijanden (defs() + configure())
  artroom.gd      showroom + testbank voor sprites, geluiden en effecten
  fx_layer.gd     effecten (projectielen, poef, zwevende tekst, rook) — gedeeld
  sfx.gd          procedureel gegenereerde geluiden, geen audiobestanden
  playtest.gd     telemetrie + CSV-export (uit te zetten met één const)
tools/
  balance_report.gd   meet wat een level oplevert (zie het bestand voor gebruik)
  downscale.py remove_bg.py make_palette.py apply_palette.py
```

## Valkuilen die we tegenkwamen

**Godot / GDScript**
- `const` met een `PackedVector2Array`-literal mag niet → gebruik `var`.
- Cross-script `class_name`-types falen bij de allereerste import → gebruik `preload()`.
- `String(v)` bestaat niet als constructor voor willekeurige waardes → gebruik `str(v)`.
- JSON kent alleen doubles: hele getallen komen terug als `7.0`.
- Het standaardfont rendert **geen emoji**.
- Uitlijnen met spatie-padding (`%-16s`) werkt niet: het font is proportioneel.
- `Engine.time_scale` regelt pauze (0) en snelheid; staat op 0 in de plan-fase en bij
  game-over. `_exit_tree()` zet 'm terug op 1 — niet weghalen. Timers die tóch moeten
  lopen: `create_timer(t, true, false, true)` (laatste parameter negeert time_scale).
- Screenshot vanuit het spel: `get_viewport().get_texture().get_image().save_png(...)` na
  `await RenderingServer.frame_post_draw`. Werkt niet headless.
- **zsh splitst variabelen niet**: `python3 script.py $FILES` werkt niet, gebruik globs.
- Nieuwe PNG's zijn pas zichtbaar na `Godot --headless --path . --import`.

**Resolutie-instellingen (v0.31.0).** Bied géén lijst van willekeurige schermresoluties aan:
de game rendert op 960x540 (16:9), dus een venster met een andere verhouding (ultrawide)
geeft vervorming of loopt van het scherm af — dat was de bug. `available_resolutions()`
biedt nu alleen de **16:9-maten die passen**; beeldvullend op een ultrawide gaat via
Borderless/Fullscreen met integer content-scaling (scherpe pixels + zwarte balken op de
zijkanten). Dit is de gangbare aanpak voor pixel-art Godot-games. Bronnen:
- GDQuest, *Setting up pixel art graphics in Godot 4* — https://www.gdquest.com/library/pixel_art_setup_godot4/
- itch.io, *Godot 4.4 settings for pixel art* — https://itch.io/blog/806788/godot-44-settings-for-pixel-art
- Chickensoft, *Display Scaling in Godot 4* — https://chickensoft.games/blog/display-scaling

**Audiobussen (v0.31.0).** Master → regelt alles (op 0 = stil, verving de mute-knop). Losse
bussen die naar Master sturen: Music (ambient), ShootSFX (schoten + kill), BuySFX
(buy/upgrade/sell), CoffeeSFX (alleen koffie — eigen kanaal zodat je de economie hoort),
EventSFX (alarm/lunch/crowd/focus-verlies). Aangemaakt in `_ensure_buses`, geregeld in
`apply_settings`; de key→bus-toewijzing staat in `level.gd` en `artroom.gd` (houd ze gelijk).

**Na elke geautomatiseerde bewerking van een script:**
```bash
grep -n "^func " scripts/level.gd | awk -F'func ' '{print $2}' | awk -F'(' '{print $1}' | sort | uniq -d
```
Een zoek-en-vervang met twee posities in omgekeerde volgorde dupliceerde ooit 113 regels
inclusief complete functies. **Godot gaf geen enkele fout** — de laatste definitie wint.

**Balans meten:** `tools/balance_report.gd`, draait niet vanzelf (uitleg staat bovenin).
Richtgetallen v0.28: 467-674 Coffee per level uit kills, Coffee Machine lvl 3 op 256 per run,
een volledig uitgebouwde toren kost 47-110.

**Art-pipeline (Retro Diffusion MCP):** genereer op 96×96 met `rd_plus__topdown_item`,
`input_palette` = `art/palette.png`, plus de vaste stijl-zin uit de style guide. Daarna
`tools/downscale.py 48`, `tools/remove_bg.py`, Godot `--import`. ~$0,038 per sprite.
Controleer het resultaat in de **Art Room**.

Bij een harde slagschaduw naast het object: eerst `tools/remove_shadow.py` op de 96×96,
vóór het downscalen — daarna is de schaduw niet meer van het object te onderscheiden.
RD's eigen `background_remover` faalde hierop (serverfout 500).

`rd_plus__topdown_item` **ondersteunt geen `reference_images`** en gaat maar tot 96×96.
Voor consistentie via een referentiesprite (punt 2 hieronder) is `rd_pro__*` dus echt nodig.

**Ladder-regel voor upgrade-art:** elk upgrade-level mag een ander voorwerp zijn, maar je
moet in één blik zien dat 3 beter is dan 2 beter dan 1. IJkpunt: Coffee Machine en
Headphones. Zie `art/STYLE_GUIDE.md`.

---

## Ondertekening & SmartScreen (uitgezocht 2026-07-25)

De waarschuwing komt doordat de .exe **niet ondertekend** is en geen reputatie heeft. Opties,
van goedkoop naar duur:
- **Azure Trusted Signing** — maandabonnement (orde $10/mnd), het gangbare pad voor hobby-devs;
  vraagt identiteitsverificatie en een Azure-abonnement.
- **EV code-signing-certificaat** — enkele honderden euro's per jaar, hardware-token/HSM
  verplicht; geeft de snelste SmartScreen-reputatie.
- **OV-certificaat** — goedkoper, maar SmartScreen blijft in het begin waarschuwen tot er genoeg
  downloads zijn.
- **Via een platform uitbrengen** (Steam/itch-app): de launcher haalt het bestand op, dus geen
  browser-download en geen Mark-of-the-Web → de waarschuwing verdwijnt in de praktijk. Steam
  Direct kost eenmalig $100 per game.
*Let op:* prijzen en voorwaarden wijzigen; controleer ze vóór je iets koopt. **Auto-updates
triggeren SmartScreen niet** — de updater schrijft het bestand zelf weg, dus dat krijgt geen
Mark-of-the-Web. Het speelt dus alleen bij de allereerste handmatige download.

## RD Plus vs RD Pro (uitgezocht 2026-07-25, prijzen via de gratis cost-check)

| | rd_plus__topdown_item | rd_pro__topdown |
|---|---|---|
| Prijs per sprite | **$0,038** | **$0,18** (4,7×) |
| Max resolutie | 96×96 | 256×256 |
| `reference_images` | **nee** | **ja** (tot 9) |
| Batchkorting | geen | geen (4 stuks = 4×) |

**Waarom Pro voor consistentie beter is:** alleen Pro accepteert referentiebeelden, dus je kunt
bestaande sprites meegeven als stijl-ijkpunt. Bij Plus kun je alleen een palet + de vaste
stijl-zin meegeven, en blijft elke generatie een losse gok. Dat is precies waar de huidige set
op wringt.

**Kosten van een volledige overstap** (110 PNG's in `art/`: 31 towers, 29 enemies, 9 UI):
60 gameplay-sprites × $0,18 ≈ **$11**, alles inclusief UI ≈ **$20** — reken op ~30% extra voor
mislukte pogingen, dus **$14–26**. Saldo nu: **$0,92** (50 credits), dus eerst opwaarderen.
**Eerst één sprite testen:** `rd_pro__*` gaf op dit account eerder HTTP 400 "inference_failed"
(zie v0.32.0-notitie); de gratis cost-check zegt niets over of genereren zelf lukt.

## Stand van zaken (v0.69.0)

**Eerste tester-feedback verwerkt (v0.69.0).** Bron: `feedback/2026-07-25_tester1.md`.
- **Shredder deelt zijn schade nu.** `tower.gd` "area": eerst iedereen in de zone verzamelen,
  dan `share = 1/aantal` -- het schadebudget (`dot`) is vast en wordt verdeeld. Gemeten: 1 vijand
  = 11/s, 8 vijanden = 1,4 per stuk, totaal altijd 11. Was 11 **per vijand**, dus 88/s tegen een
  zwerm; daarmee was hij de swarm-verdelger die de rest overbodig maakte (2× genoemd, sterkste
  signaal van de playtest). Zijn rol is nu vertragen. `desc` + tooltip aangepast, anders klopt
  wat er in het spel staat niet meer met wat hij doet. **Meteen ook de "Shredder en Headphones
  lijken op elkaar"-klacht:** area-controle vs. één doel hard stilzetten is nu een echt verschil.
- **Prijsopslag op duplicaten** (`DUPLICATE_SURCHARGE` 25% per exemplaar, max +100%, alleen bij
  plaatsen). Reden: een rekensom over alle torens liet zien dat upgraden bij Auto-Reply maar 4%
  beter was dan een tweede exemplaar en bij Coffee Machine **exact gelijk** -- en een tweede toren
  geeft óók nog dekking, dus spammen won altijd. Dit lost de hele klasse in één keer op **zonder
  de torens sterker te maken** (buffen zou het spel makkelijker maken, en L1 is al te makkelijk).
  Gemeten: Auto-Reply 10 → 13 → 15 → 18, upgraden blijft 12. `_update_bar` schrijft de prijs nu
  live op de knop, anders staat er een bedrag dat niet klopt met wat er afgeschreven wordt.
- **Salaris per overleefde wave** (`WAVE_INCOME` = 4, via `_add_coffee` zodat half_coffee en de
  Out of Order-boss gelden). Tegen "verkeerde openingskeuze = ronde verloren". Gemeten: +4
  normaal, +2 met half_coffee.
- **Enemy-paneel blijft dicht** als de speler het zelf dichtdeed (`_left_user_closed`). Het
  klapte terug open bij elk nieuw vijandtype.
- **Volumes fors omlaag** (master 0.9 → 0.55, schoten 0.8 → 0.45, rest navenant): "je kan snel
  doof worden".
- **Tutorial bovenaan in het midden** van de level-select, los van de blokken.
- **Boss Rush + Endless pas zichtbaar bij rang specialist** -- de gate die al als polish-punt
  openstond.
- **Colleagues-vraag is een invullijst** (`FB_COLLEAGUES` + `_fb_colleague_list`): per vijand wat
  hij doet, met een veld ernaast. De Kletskous staat als voorbeeld in de intro. Komt als eigen
  blok in de export.
- **Site:** links waren donkerblauw op zwart (browserstandaard, er stond geen kleurregel). Nu een
  eigen `--link`-kleur op beide pagina's.
- **Niet gedaan:** "onduidelijk wat elke vijand doet" (de uitleg zit nu in tooltips + het
  enemy-paneel; vraagt een eigen ontwerpronde) en L1 die na wave 10 makkelijk wordt (tester noemde
  dat zelf acceptabel voor een eerste level).

## Stand van zaken (v0.68.0)

**HUD-iconen, shop met namen, snelheden 1/2/4/8 (v0.68.0) — allemaal uit tester-feedback.**
- **`scripts/hud_icon.gd`** (nieuw): getekende HUD-iconen, een **bliksem** bij Focus en een
  **kopje** bij Coffee. Getekend en niet als emoji, want het standaardfont rendert die niet.
  De bliksem kleurt mee met de Focus-balk (groen → oranje → rood). *Let op de volgorde:* de
  bliksem staat vóór de balk — stond hij erachter, dan leek hij bij Coffee te horen.
- **Shop toont nu de naam onder elk icoon** (`_shop_cell`) en staat **in de volgorde waarin je
  ze vrijspeelt**. `_buildable()` leidt die volgorde af uit `GameState.TOWERS_PER_LEVEL` in
  plaats van uit de vaste `BAR_ORDER`, dus de sneltoetsnummers en de tegels kunnen niet uit
  elkaar lopen. `BAR_ORDER`/`SPECIALS` bepalen nog wél wie core is en wie special.
  *Valkuil:* het 48px-icoon rekte elke knop op tot ~60px per rij en dan viel de SPECIALS-sectie
  onder de paneelrand. Opgelost met `add_theme_constant_override("icon_max_width", 15)` plus
  compactere rijen; alle 12 core + 2 specials passen nu met naam binnen de 410px van het paneel.
  Komt er een toren bij, dan moet dit opnieuw gemeten worden (of het paneel scrollbaar).
- **Snelheden `SPEEDS := [1, 2, 4, 8]`** in plaats van 1/2/3 (verdubbelen leest lekkerder en is
  een binaire knipoog). +/- lopen via `_speed_step()` door de reeks. Getest: een level draait op
  8× zonder fouten — 4 waves in 6 echte seconden — en schakelt netjes terug naar 1×.
- **Valkuil bij het testen:** een autotest die op een level wacht met `create_timer(t)` hangt,
  want de plan-fase zet `time_scale` op 0. Gebruik `create_timer(t, true, false, true)`.

## Stand van zaken (v0.67.0)

**Kale .exe in plaats van een zip (v0.67.0).** Testers downloaden nu één bestand en spelen;
er valt niets meer uit te pakken.
- `tools/make_release.sh` maakt geen zip meer en publiceert `build/windows/CTRL-ALT-DEFEND.exe`
  als asset met een **vaste naam** — nodig voor het `latest/download`-adres (zie het releaseblok
  bovenaan). De downloadknop op de site wijst daarheen en hoeft dus nooit meer bijgewerkt te
  worden; de sed daarvoor is geankerd op `<a class="dl" href=` en niet op de bestandsnaam
  (die matchte niet meer toen de extensie veranderde).
- `scripts/updater.gd` haalt de .exe rechtstreeks op (`exe_url` in version.json), controleert de
  sha256 en wisselt 'm om — de ZIPReader-stap is weg. Route 2 zet de nieuwe .exe in Downloads.
- `deploy/player_readme.txt` is vervallen (die zat in de zip); de speluitleg staat nu in de
  GitHub-release-notes en op de site.
- **Eerste echte publicatie gedaan.** Geverifieerd: de .exe van `latest/download` matcht exact
  de sha256 in de gepubliceerde `version.json`, site en changelogpagina staan live op de nieuwe
  naam, en de release-notes komen uit CHANGELOG.md.
- **Nog steeds ongetest: de zelf-vervangende update op Windows.** Draai die één keer door
  (v0.67.0 → volgende versie) voordat de rest automatisch update.

## Stand van zaken (v0.66.0)

**Hernoemd naar CTRL-ALT-DEFEND + releases naar GitHub (v0.66.0).**
- **Naam.** Overal waar een speler het ziet: titelscherm (ondertitel is nu de IT Crowd-knipoog
  *"I'll put this with the rest of the focus."*), venstertitel, `CTRL-ALT-DEFEND.exe`, de zip,
  de site, de feedback-header en de mail-onderwerpregel. Feedbackbestanden heten nu
  `ctrl_alt_defend_*`. Interne def_id's zijn **niet** aangeraakt (breekt saves).
- **Publieke repo** `Malse-Makker/CTRL-ALT-DEFEND`. `feedback/` staat bewust in `.gitignore`:
  daar staan opmerkingen en speler-id's van testers in en de repo is openbaar. `build/` en
  `.godot/` ook. De spelers-README voor in de zip is daarom verhuisd naar
  `deploy/player_readme.txt` (stond in `build/`, dat niet meer meegaat).
- **Nieuw:** `tools/github_release.py` (alleen stdlib, geen `gh` nodig): maakt de release aan
  of hergebruikt 'm, verwijdert een gelijknamig asset vóór het uploaden (anders plakt GitHub er
  "-1" achter), en haalt de release-notes uit `CHANGELOG.md` zodat GitHub, de site en het
  update-scherm hetzelfde vertellen. Releases zijn `prerelease: true` (alpha).
- Getest: dry-run bouwt de hernoemde zip + exe ✓, `version.json` wijst naar het GitHub-asset ✓,
  downloadknop op de site wijst naar dezelfde URL ✓, headless schoon ✓, broncode gepusht ✓.
- **Nog niet gedraaid: de echte publicatie** — daarvoor is het GitHub-token nodig (zie boven).

## Stand van zaken (v0.65.0)

**Leuk-schaal, changelog overal, checksums, mailen (v0.65.0).**
- **De vraag na een ronde gaat nu over LEUK, niet over moeilijk.** "How much FUN was this level?
  0 = no fun, barely playable · 10 = loved it". Reden: de eerste tester gaf L1 een 9 en L2 een 2
  terwijl zijn tekst het omgekeerde zei — onduidelijk welke kant van de schaal wat betekende.
  CSV-kolom heet nu **`fun_0_10`**; de oude kolom **`difficulty_0_10` blijft bestaan** zodat
  rondes van vóór de wissel hun antwoord houden (twee verschillende vragen mag je niet optellen).
- **Changelog op drie plekken, één bron.** Zie het releaseblok bovenaan dit bestand.
  Nieuw: `CHANGELOG.md`, `scripts/changelog.gd`, `tools/gen_release_files.py`, de **What's
  New**-knop in het hoofdmenu (`app.gd show_changelog`, huidige versie groen opgelicht) en
  **https://game.makkers.net/changelog.html**.
- **Checksums.** `build_info.gd` rekent de sha256 van de draaiende .exe in een thread uit; het
  hoofdmenu toont `v0.65.0   build 9ad448463dfd`. De site publiceert de volledige hashes van zip
  én exe. Geverifieerd: de gepubliceerde waarden matchen de live artefacten exact.
- **Feedback terugsturen kan nu op drie manieren:** COPY ALL TO CLIPBOARD (Discord, tekstbestand,
  pastebin), **Email it to games@makkers.net** (`_email_feedback`: zet alles op het klembord en
  opent een mailto met adres + onderwerp — een mailto-*body* kan de feedback niet dragen, veel te
  lang), en de oude bestands-export als achtervang.
- **Per ronde staat nu de versie erbij** (`_fb_run_line`), in de lijst op het scherm én in de
  export: `[v0.64.0] Canteen: win (2 stars, wave 20/20, fun 8/10)`. Zo is te zien of een klacht
  gaat over iets dat al gerepareerd is. Oude rondes tonen `difficulty x/10 (old scale)`.
- Getest: changelog-pagina rendert 5 versies met de huidige groen ✓, feedbackpagina toont de
  versie per ronde ✓, changelog.json zit in de build ✓, site + checksums live geverifieerd ✓,
  headless schoon ✓. Autotest-code weer verwijderd.

## Stand van zaken (v0.64.0)

**Update-check + zelf-updatende game (v0.64.0).** Vrienden hoeven niet meer zelf te controleren of
er een nieuwe build is. `scripts/updater.gd` (losstaand component op een eigen `CanvasLayer`, net
als de QTE-componenten; toegevoegd in `app.gd _ready`):
- **Bij elke start** wordt `https://game.makkers.net/version.json` opgehaald (timeout 6s). Server
  plat of geen internet = stilzwijgend doorspelen. Is de versie daar nieuwer dan `res://VERSION`,
  dan verschijnt **UPDATE AVAILABLE** met de changelog en Update/Cancel.
- **Achter Update zitten twee routes** (bewuste keuze gebruiker — de speler kiest zelf):
  1. **AUTOMATIC** (alleen Windows): download → sha256 controleren → .exe uit de zip halen →
     huidige exe hernoemen naar `*_old.exe` → nieuwe op die plek → `OS.create_process` → afsluiten.
     **De hele truc rust erop dat Windows een dráaiende .exe wel laat hernoemen maar niet
     overschrijven of verwijderen.** De `*_old.exe` wordt bij de volgende start opgeruimd
     (`_cleanup_leftovers`). Het scherm waarschuwt expliciet dat antivirus dit gedrag wantrouwt
     én legt uit hoe je het herstelt (Windows Security → Protection history → Allow/Restore).
  2. **SAFE**: zip naar Downloads + tonen in de verkenner, speler wisselt zelf. Werkt overal.
- **Faalt de automatische route** (geen schrijfrechten, hernoemen geweigerd), dan wordt alles
  teruggedraaid en krijgt de speler de veilige route aangeboden — nooit een half vervangen
  installatie. Checksum-mismatch = download weggegooid.
- **Bewust géén upload-endpoint** voor feedback (keuze gebruiker: geen open POST-adres dat
  port-/websitescanners kunnen vinden). Alleen deze GET van een statisch JSON-bestand.
- **`tools/make_release.sh`** doet nu de hele release in één klap: headless check → exporteren →
  zippen (README-versie meeschrijven) → sha256 → `version.json` genereren uit
  **`CHANGELOG_NEXT.md`** → downloadpagina bijwerken → rsync + `docker compose up -d` → controle.
  `--dry-run` bouwt alles zonder te uploaden. **Zo kunnen versie, checksum en changelog niet meer
  uit de pas lopen met de zip die er echt staat** — handmatig bijwerken ging daar gegarandeerd een
  keer mis. *Valkuil:* BSD `sed`/`grep` op macOS kennen `\s` niet → POSIX-klassen gebruiken
  (`[[:space:]]`), anders blijft het streepje in de changelog-regels staan.
- Getest (end-to-end, lokaal VERSION tijdelijk op 0.63.0 gezet tegen de echte server): check ziet
  0.64.0 ✓, dialoog met changelog ✓, keuzescherm in beide varianten ✓ (Windows-tak via een
  tijdelijke env-hook gerenderd), veilige download inclusief **sha256-verificatie** ✓, live
  `version.json` matcht de live zip op size én sha256 ✓, `updater.gdc` + `VERSION` zitten in de
  gepubliceerde build ✓, headless schoon ✓. Testcode weer verwijderd.
- ✅ **De zelf-vervangende route is op een échte Windows-machine getest en werkt** (gebruiker,
  2026-07-25). De hernoem-truc op een draaiende .exe doet wat hij moet doen. Daarmee is het
  laatste ongeteste stuk van de updater dicht.
- **SmartScreen blijft waarschuwen** bij de eerste handmatige download: de build is niet
  ondertekend. Dat is geen bug maar het ontbreken van een code-signing-certificaat; zie de
  notitie hieronder bij v0.69.0.
- *Let op:* de v0.63.0 die eventueel al rondgaat heeft nog geen updater; die moet één keer
  handmatig. Vanaf v0.64.0 gaat het vanzelf.

## Stand van zaken (v0.63.0)

**Feedback-tool gerepareerd na de eerste externe playtest (v0.63.0).** De eerste tester kon zijn
export niet via Discord versturen (Discord zag de bestanden als leeg) en meldde dat de duimpjes
niet werkten. Drie fixes:
- **COPY ALL TO CLIPBOARD** is nu de hoofdroute (`app.gd _copy_feedback`): zet de feedback **plus**
  de playtest-CSV als één tekstblok op het klembord (`DisplayServer.clipboard_set`), zodat testers
  het direct in Discord plakken en er geen bestand meer aan te pas komt. De oude bestands-export
  staat er als tweede knop naast ("Save as files"). Bewust géén upload-endpoint: de gebruiker wil
  geen open POST-adres dat port-/website-scanners kunnen vinden.
- **`version: ?` gefixt.** `PlaytestScript.version()` leest `res://VERSION`, maar dat bestand zat
  niet in de export. `export_presets.cfg` heeft nu `include_filter="VERSION"` (de excludes gooiden
  het eruit). Geldt ook voor de `version`-kolom in de CSV.
- **Stemknoppen zichtbaar gemaakt.** De gekozen stem kreeg alleen een `modulate`-tint — op het
  donkere thema vrijwel onzichtbaar, dus testers denken dat er niets gebeurt. Nu een gevulde
  StyleBoxFlat (groen ▲ / rood ▼) met donkere pijl via `_fb_paint_vote`. **Gevolg: de stemmen uit
  de eerste playtest zijn onbruikbaar** (alles kwam als `[+UP]` binnen).
- Refactor: `_fb_compose()` bouwt de tekst (gedeeld door copy + save), `playtest.gd csv_text()`
  levert de CSV als string los van het wegschrijven.
- Getest: version=0.63.0 in de export ✓, stemmen groen/rood zichtbaar op schermafdruk ✓, klembord
  gevuld (7102 tekens incl. CSV) ✓, headless schoon ✓. Autotest-code er weer uitgehaald.
- **Eerste playtest-feedback staat in [`feedback/2026-07-25_tester1.md`](feedback/2026-07-25_tester1.md)**
  — samengevat: Shredder te sterk (2×), upgraden loont niet t.o.v. bijkopen (Coffee Machine +
  eerste toren), enemy-overzicht klapt vanzelf open, geluid te hard, tutorial hoort bovenaan in
  het midden, fun-maps pas zichtbaar bij Specialist, en het colleagues-idee moet een invullijst
  worden i.p.v. een open vraag. Nog niet uitgewerkt — dat is de volgende fase.

## Stand van zaken (v0.62.0)

**Alpha-export + hosting (v0.62.0).** De game is als Windows-alpha uitgerold voor vrienden.
- **Target: alleen Windows** (besluit gebruiker; Linux-vrienden draaien de .exe via Proton/Wine,
  mac + web bewust overgeslagen). Playtest-telemetrie staat AAN (`playtest.gd ENABLED = true`).
- **Export:** `export_presets.cfg` preset **"Windows"** (x86_64, `embed_pck=true` → één .exe,
  excludes: `*.md, tools/*, _shop4.png`). Bouwen:
  `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --export-release "Windows" build/windows/OfficeTowerDefense.exe`
  Export-templates 4.7.1 geïnstalleerd in `~/Library/Application Support/Godot/export_templates/4.7.1.stable/`
  (alleen de windows-bestanden uitgepakt uit de officiële .tpz).
- **Distributie:** `build/OfficeTowerDefense_v0.61.0_alpha_windows.zip` (37 MB) = .exe +
  `build/windows/README.txt` (Engels: SmartScreen-uitleg, Proton-tip, besturing, feedback-instructie).
- **Hosting:** `game/deploy/` (docker-compose + nginx.conf met security-headers + `public/` met
  downloadpagina en zip) → ge-rsynct naar **`ubuntu@makkers.net:/home/ubuntu/office-td/`** (OVH),
  daar `docker compose up -d` → nginx:alpine op **poort 8090**. Publieke URL **https://game.makkers.net**
  via Nginx Proxy Manager (proxy host → 51.75.118.72:8090 + Let's Encrypt, patroon van de andere
  makkers-projecten; de NPM-UI-stap doet de gebruiker).
- **Nieuwe build uitrollen:** exporteren → nieuwe versie-zip maken → naar `deploy/public/` →
  link + versie in `deploy/public/index.html` bijwerken → rsync → klaar (container herstart niet nodig).
- **Feedback-lus:** vrienden spelen, menu → Feedback → export, en sturen
  `office_td_feedback_*.txt` + `office_td_playtest_*.csv` uit hun Downloads terug. Volgende stap
  (aparte chat): die bestanden inlezen en er een vragenlijst van maken — niet direct uitwerken.

## Stand van zaken (v0.61.0)

**Feedback-/"Help me"-pagina (v0.61.0).** Pre-release feedback-scherm in `app.gd` (`show_feedback`),
bereikbaar via de nieuwe **Feedback**-knop in het hoofdmenu (alleen als `PlaytestScript.ENABLED`; de oude
`_add_playtest_export` is vervangen — de playtest-export is hierheen verhuisd).
- **Scrollbaar** (ScrollContainer + VBox). Secties: **YOUR PLAYTESTS** (lijstje uit `PlaytestScript.all_runs()`),
  **PLANS & IDEAS** (16 stem-items met ▲/▼-knoppen + comment-veld per item; `_fb_plan_list()`), **TELL US
  MORE** (5 vrije velden: towers, enemies, maps, colleagues, ideas), **SEND IT BACK** (export).
- **Colleague-idee** verwerkt: als prominent stem-item (object-enemies → collega's, torens blijven
  voorwerpen) én als eigen invulveld dat om collega-namen vraagt die bij het gedrag passen.
- **Export** (`_export_feedback`): schrijft een leesbaar `office_td_feedback_<stamp>.txt` naar Downloads
  (versie, player_id, votes met `[+UP]`/`[-DOWN]` + comments, de 5 velden) **én** roept de playtest-CSV-
  export aan. Toont beide paden. Parseerbaar voor latere verwerking.
- Getest: pagina rendert + scrollt ✓, stemmen (groene ▲) ✓, export schrijft feedback-txt + CSV ✓,
  headless schoon ✓.
- *Let op:* geen emoji (font kan het niet) — vote-knoppen zijn ▲/▼.

## Stand van zaken (v0.60.0)

**3 extra spelmodi — functioneel (v0.60.0) — cluster 5.** Via speciale level-ids (`level_id >= 100`);
`game_state.gd` `_special_level()` levert de configs, `app.gd` level-select heeft een **SPECIAL MODES**-
rij met 3 knoppen (nu altijd beschikbaar; specialist-gate = polish). `level.gd` `special_mode` slaat
géén sterren/Recognition op (`_win`-guard).
- **Tutorial (101):** recht pad, 5 lessen. Per les: `tutorial_lessons[i]` = {towers, spec, text}. Bord
  reset tussen lessen (`_tutorial_reset`), torens beperkt tot de les (`available_towers` + `_rebuild_shop`),
  plan-fase per les (`_tutorial_advance` in `_process` zodra de les-vijanden weg zijn). Les-tekst in de
  msg-balk. Lessen: 1) Auto-Reply vs Notification, 2) economie, 3) Shredder vs Thread, 4) Headphones vs
  Nudge, 5) Artillery vs Old Guard.
- **Boss Rush (102):** windend pad, volle toolkit, veel start-focus/coffee; 15 waves = alle per-level
  bosses in volgorde (allhands → … → boss360), elk met kleine escorte.
- **Endless (103):** serpentine, volle toolkit, `endless: true`. `game_state._endless_spec(n)` genereert
  oplopende waves (pool groeit, aantal omhoog, tempo omlaag); `level.gd _start_next_wave` houdt een buffer
  klaar zodat `wave_index` `total_waves` nooit inhaalt → geen win, speel tot je Focus op is. Highscore = score.
- Getest: configs (5/15/3 waves, towers) ✓; endless schaalt (wave1 20 → wave20 132 vijanden) ✓; tutorial
  laadt met les-tekst + beperkte shop (alleen Auto-Reply/Coffee) ✓; les-overgang reset+plan zonder fouten ✓.
- **Nog te doen (art/tuning):** sprites/decor, balans van de modi, specialist-unlock-gate voor Rush/Endless.

## Stand van zaken (v0.59.0)

**Functionele gaten gedicht (v0.59.0) — cluster 4.**
- **Consultant buft nu ook schilden.** `level.gd _apply_buffs_and_disrupt` "consultant"-tak geeft elke
  andere vijand naast de speed-buff (×1.3) éénmalig +8 schild (`enemy._consultant_shielded` voorkomt
  onsterfelijk toppen). Kill de Consultant om nieuwe buffs te stoppen.
- **Trap dekt alle lanes.** `tower.gd` heeft nu `trap_paths` (alle lanes); `_closest_path_point` en
  `_random_path_point_in_range` lopen via `_trap_lanes()` over álle banen. `level.gd` zet
  `t.trap_paths = paths_all`. Op multi-path-levels strooit de val nu over elke lane.
- **Sneltoetsen dekken alle torens.** `level.gd _handle_key`: 1-9 → toren 1-9, **0 → toren 10**,
  **shift+1..4 → toren 11/12 + de twee specials**.
- Getest: consultant-schild +8 ✓, trap raakt 14 y-banden op L8 ✓, hotkeys 0/shift+1/shift+4 ✓.

## Stand van zaken (v0.58.0)

**Finale-boss met 360°-cameo-fase = Peer Review (v0.58.0).** De twee boss-TODO's (L15-cameo + Peer
Review "Do you feel stressed?") samengevoegd in één finale-boss:
- **`boss360`** (enemy.gd) — finale-variant van The Performance Review (hp 520, shield 140, reward 60),
  `boss_kind: "review"` (zelfde 3-fasen + feedback-adds) + `cameo: true` met `cameo_pool`
  [allhands, cleaner, consultant, smoking, baby, reorg]. Spawnt vanaf **fase 2** elke ~6s een
  **mini-"peer reviewer"**: een eerdere boss, maar gedegradeerd (`is_boss=false`, `boss_kind=""`, hp 26,
  55% radius) → puur cosmetisch, geen boss-mechaniek. Flavour bij spawn: *"360-degree feedback — past
  managers return as peer reviewers. Do you feel stressed?"*
- Code: `enemy.gd` `cameo`/`cameo_pool`/`on_spawn_cameo` + cameo-timer in de `review`-tak van
  `_boss_update`; `level.gd` `_spawn_cameo()` (mini-add) + wiring/flash in `_spawn_enemy_at`;
  `game_state.gd` L15 laatste wave `boss:1` → `boss360:1`.
- Getest: cameo vuurt niet in fase 1, wél in fase 2 (pool-boss) ✓; `_spawn_cameo` maakt live een
  niet-boss mini-add ✓; headless schoon ✓.
- Peer Review is hiermee de finale-cameo (review §4.2 concept); geen aparte boss nodig.

## Stand van zaken (v0.57.0)

**2 nieuwe vijanden — functioneel (v0.57.0).** (Sports Guy bewust geschrapt door gebruiker.)
- **The Phone Caller** (`caller`, `aggro: true`): TAUNT — single-target torens richten éérst op hem
  (`tower.gd _target_score` +500000 bij `e.aggro`). Wat taai, dus torens verspillen schoten aan hem
  terwijl de rest erlangs glipt. Gele taunt-ring in `_draw`.
- **System Update** (`update`, `update_interval`/`update_dur`): wisselt in `enemy.gd _process` tussen
  normaal en **'installing'** (onkwetsbaar — `take_damage` returnt vroeg zolang `installing`); blijft
  doorlopen. Cyaan ring als hij updatet. Burst 'm tussen de updates.
- **In waves:** `caller` in Town Hall (L9), `update` in Server Room (L13) — thematisch, ruwe plaatsing
  (fijn afstemmen in de tuning-fase).
- Getest: taunt kiest de caller ook naast een sterker doel ✓; update onkwetsbaar tijdens installing,
  raakbaar erbuiten ✓; ringen visueel ✓; headless schoon ✓.
- **Nog te doen (art/tuning-fase):** sprites (nu fallback-cirkels), balans + wave-plaatsing.

## Stand van zaken (v0.56.0)

**3 nieuwe torens — functioneel (v0.56.0).** Start van de "eerst alles functioneel af, dán pas
feedback-tuning + art"-fase (beslissing gebruiker). Nieuwe rollen in `tower.gd` + shop-registratie:
- **Pomodoro Timer** (`pomodoro`, rol **`burst`**): laadt op (`rate` = laadtijd) en lost dan één
  AoE-klap op alles in bereik (`damage`). Nieuwe burst-rol. Levels: 4s/6dmg → 3.5s/12 → 3s/22.
- **Reply All** (`splash`, rol **`splash`**): raakt één doel + splash-schade (`splash_falloff`) op alles
  binnen `splash_radius` van dat doel — beweegt mee met het doel (anders dan de Shredder-zone).
- **Ctrl+Alt+Del** (`ctrlaltdel`, rol **`forcequit`**, SPECIAL): laadt op (`charge` sec), force-quit dan
  de vijand met de meeste HP (instakill), daarna **verbruikt** (`_spent`). Wacht op een doel als er nog
  geen is. Laad-ring + verbruikt-kruisje in `_draw`.
- **Registratie:** `level.gd` `BAR_ORDER` += pomodoro/splash, `SPECIALS` += ctrlaltdel;
  `game_state.gd` `TOWERS_PER_LEVEL` L4-15 += de drie ids. Shop toont nu 12 core + 2 specials.
- Getest: unit-test (burst raakt alleen in-bereik, splash direct+omstander, force-quit sterkste + spent)
  ✓ headless schoon ✓ shop visueel ✓.
- **Nog te doen (feedback/art-fase):** sprites (nu lege iconen), balans, audio (nu rol-fallback), en
  evt. de beschikbaarheids-curve (nu al vanaf L4).

## Stand van zaken (v0.55.0)

**Map-design-review doorgevoerd (v0.55.0).** De volledige **data-laag** van `MAP_DESIGN_REVIEW.md` (een
externe review, samengevoegd in de repo) is geïmplementeerd in `game_state.gd` + één code-fix in
`level.gd`:
- **Volgorde-wissels 6↔7** (Work From Home vóór The Parking) en **12↔13** (The Merger vóór Server Room):
  themadata (naam, WAVES-sleutel, hazard, paden, muren) mee-verhuisd.
- **Nieuwe/aangepaste layouts:** L4 wet-floor geen-bouw · L7 Parking écht gespreid (banen 240/200 +
  rand-banen) · L8 zuid-deur · L9 Town Hall elleboog-spaken · L10 pilaren-muren · L12 Merger =
  haak-pad + **invoegend** onthul-pad (trigger 12) + half_coffee, géén corridor meer · L13 Server Room =
  gangpaden-slinger met racks-obstakels + **pay-zones bóvenop de racks** · L14 Release = zigzag-corridor
  + **gescheiden** onthul-front (trigger 10) · L15 = **terug naar de boardroom-arena** (tafel + pilaren +
  corridor), 4-lane-finale vervalt.
- **Hazards:** brandalarm 2→10 ("fire drill mid-review"); projector-QTE nu eerste hazard (L3) + terug op
  L15. **Modifiers:** L12 half_coffee, L13 few_spots geschrapt. **Softlock-fix:** `banned = {11:
  ["auto","machinegun"]}` (níet phones — enige Chatterbox-counter).
- **Code-fix `level.gd`:** in `_can_place_at` staat de betaal-zone-check nu vóór obstakel/nobuild → een
  **ontgrendelde** pay-zone overrulet het obstakel-verbod ("root access" op de racks).
- Headless schoon + visueel per herwerkt level gecontroleerd.

**Nog te doen uit de review** (groter code/art-werk, bewust uitgesteld): boss-**cameo-fase** L15 ("360°
feedback": mini-versies van eerdere bosses als adds — nieuwe fase in de boss-logica), **spawn-deur-
sprites** voor reveals en spawns achter de shopbalk (x>780), **decor** voor de dode zone boven de
boardroom-tafel, en de optionele L15-zijdeur (pas na playtests). Zie ook de open vragen §9 in de review.

## Stand van zaken (v0.53.0)

**Corridor-bouwen + onthul-paden op 3 maps (v0.52.0–0.53.0).**
- **Corridor-bouwen** (`corridor_build`, `game_state.gd` `corridor`-dict): de hele map is geen-bouw,
  behalve binnen `CORRIDOR_BUILD_DIST` (100px ≈ 2,5 tegel) van een ACTIEF pad — check in `_can_place_at`
  (`_min_path_dist(p) > CORRIDOR_BUILD_DIST`, telt alle `paths_all`). Bouwstrook wordt in `_draw` groen
  opgelicht langs elk pad.
- **Onthul-paden** (`reveals`-dict → lijst `[{trigger_wave, path}]` per level; in `level.gd` als
  `[{trigger_wave, path, done}]`): in `_start_next_wave` (na `wave_index += 1`, vóór de rotatie) worden
  alle reveals waarvan de trigger-wave bereikt is aan `paths_all` toegevoegd. Elk pad moet op hetzelfde
  bureau eindigen als het basispad (desk = `path[laatste]`). In corridor-levels wordt de strook rond het
  nieuwe pad meteen bouwbaar. De speler ziet vooraf niet dat er een pad komt.
- **De 3 corridor-maps** (bureau-positie = eindpunt basispad):
  - **L14 Release Night** — bureau rechts-van-midden (620,260); start 1 pad van links-boven (op y140 →
    ruimte om erboven te bouwen); wave 10 een 2e pad van links-onder.
  - **L13 The Merger** — bureau in het MIDDEN (420,260); start 1 pad van LINKS; wave 10 een pad van
    RECHTS (twee bedrijven mergen). `zone_block`-modifier verwijderd (nu corridor).
  - **L15 senior FINALE (v0.54.0)** — de 4-lane map is hierheen verplaatst (moest ná L13/L14 komen).
    Bureau in het MIDDEN (380,260), **gespiegeld**: 2 lanes van links + 2 van rechts (rechter-ingangen
    op x=1020, komen achter de shop-balk vandaan). Start links-boven; reveals wave 5=rechts-boven,
    9=links-onder, 13=rechts-onder → alles komt van beide kanten. `corridor_build`. **Boardroom-tafel,
    zicht-muren, betaal-zones én few_spots/half_coffee zijn van L15 verwijderd** — de 4-lane corridor is
    de uitdaging. *Gevolg:* de "3 boardrooms zelfde layout"-trio (L5/L10/L15) is nu een **paar**
    (L5/L10); L15 heet nog "Boardroom" maar is de convergentie-finale (naam evt. nog te wijzigen).
  - **L9 Town Hall** — teruggezet naar de gewone **3-deurs center-desk** (multi, `half_coffee`), géén
    corridor meer.
- *Let op:* L13/L14/L15 hebben 15 waves; L15-triggers op 5/9/13 zodat alle lanes vóór het einde open
  zijn (niet 5/10/15, want 15 = laatste wave). Wil de gebruiker écht "elke 5", dan meer waves nodig.
- L8 blijft de multi-ingang-merge-map. Getest: reveals voegen paden toe (L15 1→4 lanes) ✓, corridor
  blokkeert bouwen buiten de strook ✓, L9 teruggezet ✓, visueel per map ✓.

**Geen-bouw-hatch-zones (v0.51.0):** statische rode "niet bouwen"-vlakken op **L6** (auto's) en **L11**
(HR-rode-draad) — `nobuild`-dict, geblokkeerd in `_can_place_at`, getekend in `_draw`.

**Betaal-om-te-bouwen-zones (v0.50.0).** Vergrendelde bouwvlakken die je met koffie ontgrendelt
vóór je er torens kunt zetten. Data: `game_state.gd` `pay_zones`-dict (`[{rect, cost}]`) → `"pay_zones"`.
`level.gd`: ingelezen in `_ready` als `[{rect, cost, unlocked=false}]`; klik op een vergrendelde zone
(mouse-handler, vóór de tower-loop) trekt de kosten af (`coffee -= cost` + `_update_labels`) en zet
`unlocked=true`; `_can_place_at` blokkeert bouwen in een nog-vergrendelde zone; getekend als amber vlak
met de prijs (`ThemeDB.fallback_font`, "%dC"). Getest: locked → niet bouwen ✓, unlocked → bouwen ✓.
Ingezet: **L12** (2×40C), **L15** (2×50C). (L14 had betaal-zones maar is v0.52.0 herzien naar
corridor-bouwen.) *Let op:* een zone moet binnen toren-bereik van een pad liggen, anders is
ontgrendelen nutteloos — bij balans checken.

**Alle vier de map-mechanieken zijn nu gebouwd** (obstakels, zicht-muren, betaal-zones — plus de
bestaande few_spots/banned/zone_block/multi-path). Enige rest van de sketch-mechanieken: losse
geen-bouw-**hatch**-zones (L6 auto's, L11 rode draad) — puur cosmetisch bovenop wat er al is.

**Zicht-muren / line-of-sight (v0.49.0).** Dunne schotten (`Rect2`) die het SCHOOTZICHT blokkeren:
een toren kan een vijand niet raken als er een muur tussen zit → torens dekken maar een klein
gebied. Data: `game_state.gd` `walls`-dict → `"walls"` in de level-return. `level.gd`: `walls`
ingelezen, `t.get_walls` bedraad (net als `get_enemies`), bouwen erop geblokkeerd, getekend in
paars (eigen kleur zodat de speler ze herkent). `tower.gd`: `_los_clear(target)` +
`_seg_hits_rect(a,b,r)` (via `Geometry2D.segment_intersects_segment` op de 4 randen); toegepast in
`_find_target` (single-target) en `_valid_targets` (multi/chain). Getest: LOS-wiskunde ✓
(doel achter muur = niet zichtbaar). Ingezet: **L7** (meubels), **L10/L15** (pilaren), **L11** (cubicles).
*Polish-restje:* de range-preview-cirkel bij het plaatsen toont nog de vólle cirkel, ook waar een muur
het zicht knipt (schaduw in de preview zou fijner zijn).

**Obstakels: tafel + serverracks (v0.48.0).** Massieve blokken waar het pad omheen loopt en waar je
NIET op kunt bouwen. Data: `game_state.gd` `obstacles`-dict (Array van `Rect2` per level) → in de
level-return als `"obstacles"`. `level.gd`: `obstacles` ingelezen in `_ready`, geblokkeerd in
`_can_place_at` (`r.grow(14).has_point(p)`), getekend in `_draw` (massief blok + rand) net na de paden.
Ingezet: **L5/L10/L15** delen de centrale vergadertafel `Rect2(360,180,240,160)` (boardrooms nu écht
compleet), **L12** twee serverracks. De paden waren al zo ontworpen dat ze eromheen lopen.
**Nog te bouwen van de map-mechanieken:** geen-bouw-hatch-zones (los van massieve obstakels),
zicht-muren (klein schootbereik), betaal-om-te-bouwen-zones.

**Richting-pijltjes (v0.47.0).** Bewegende, in-/uitfadende groene chevrons langs elke ingang tonen
welke kant de vijanden op lopen — alleen in de **plan-fase** of **tijdens het plaatsen van een toren**.
`level.gd`: `_draw_path_arrows()` + `_sample_path()` (punt+richting langs de polyline), aangeroepen in
`_draw`; `_process` zet `queue_redraw` aan zolang ze zichtbaar zijn. **Valkuil:** `time_scale` is 0 in
de plan-fase (delta = 0), dus de animatietijd komt uit `Time.get_ticks_msec()`, niet uit opgetelde delta.
Op center-desk-maps (L9/L13) convergeren de pijltjes mooi naar het midden.

**Eigen greybox-layouts voor alle 15 levels (v0.46.0).** Blok 2/3 hergebruiken géén blok-1-paden
meer; elk level heeft nu z'n eigen padvorm in `game_state.gd` (`get_level`, dicts `paths` +
`multi`). Ontwerpprincipes (samen met gebruiker vastgesteld): banen **ver uit elkaar** waar het
moeilijk moet zijn (één toren dekt niet twee lanes), meer **variatie**, en de drie **Boardrooms
(L5/L10/L15) delen exact dezelfde layout** (lus rond een centrale vergadertafel, bureau
rechtsboven) maar lopen op in restricties.
- **Multi-ingang & bureau-in-het-midden werken puur via data**: `level.gd` rouleert per wave door
  `paths_all` en tekent het bureau op `path[laatste]`. Elke vijand krijgt bij spawn een eigen
  padkopie (`enemy.setup`), dus rotatie is veilig. **L8** = 4 deuren mergen (bureau rechts);
  **L9** (3 deuren) en **L13** (5 deuren) = bureau in het MÍDDEN, vijanden van alle kanten.
- `level.gd` `_near_path`/`_min_path_dist` kijken nu over **alle** lanes (`paths_all`), zodat je op
  multi-ingang-maps geen toren op een inactieve baan kunt zetten.
- **Nog te bouwen (mechanieken uit het ontwerp, nu alleen als concept ingetekend):** de centrale
  **tafel-obstakels** (L5/L10/L15 vlak 360,180..600,340) + serverracks (L12) — "pad loopt eromheen,
  niet bouwen"; **geen-bouw-zones**; **zicht-muren** (toren naast muur = klein schootbereik);
  **betaal-om-te-bouwen-zones** (koffie betalen om tegels te ontgrendelen). Zonder deze zijn de
  boardrooms nu nog een lege lus. Daarna: art-pass (tileset/bureau/deur). Balans via playtest.

## Stand van zaken (v0.45.0)

**Carrièresysteem + blok 2 & 3 compleet (v0.39–0.45).** Het spel is nu **feature-compleet voor een alpha**.
- **15 levels in 3 blokken** (junior 1-5 / medior 6-10 / senior 11-15). `LEVEL_COUNT=15`. Rang +
  promotie (`GameState.current_rank()`, promotie-melding op het win-scherm bij level 5/10/15).
  Level-select in 3 blok-rijen (`app.gd show_level_select`).
- **Alle bosses hebben mechaniek + sprite.** Nieuw: The Cleaner (L4, speed-aura + veegt zones/vallen weg),
  Smoking Colleague (L6), The Baby (L7, afleidingsaura), The Floater (L8), The Reorganisation (verhuisd
  naar L9), HR Manager (L11, audit), Legacy System (L12, error-spam), The Consultant (L13, buft vijanden),
  The Deadline (L14, bord-brede speed-up via `menace`). Auras/audits in `level.gd _apply_buffs_and_disrupt`.
- **Events zijn echte mini-games** (herbruikbare componenten, patroon van `qte_projector.gd`):
  `qte_pizza.gd` (Eat the Pizza, timing-balk, sprite `art/ui/mg_pizza.png`), `qte_dino.gd` (No Internet,
  dino-runner, sprites `mg_runner/cup/plane`), `qte_click.gd` (telefoon + formulier). Getriggerd als
  `hazard_type` (pizza/no_internet/phone/form) met auto-skip, net als de projector-QTE.
- **Modifiers** (in de leveldata, `level.gd`): `half_coffee`, `few_spots` (torencap `FEW_SPOTS_CAP=8`),
  `low_focus` (start 10), `banned` (verboden torens, tonen "✕"), `zone_block` (pulserende bouwblokkade),
  hazards `smoke` (range↓) en `overheat` (torens stil). **multi_path**: `game_state` levert 3 samenkomende
  ingangen; `level.gd` rouleert per wave (`paths_all`, `_start_next_wave`), tekent alle paden.
- **Data:** alles in `game_state.gd` (`get_level` names/paths/multi/hazards/modifiers/banned,
  `TOWERS_PER_LEVEL`, `WAVES` 1-15). **Eigen padvormen per level sinds v0.46.0** (geen hergebruik meer).

**NOG TE DOEN (backlog — spel is speelbaar zonder dit):**
- **Richting alpha:** map-mechanieken bouwen (tafel/rack-obstakels, geen-bouw-zones, zicht-muren,
  betaal-om-te-bouwen — zie v0.46.0) · art-pass (tileset/bureau/deur, blijft cosmetisch) · **balans uitspelen**
  (alles doorgerekend, niet gespeeld — dáár is de alpha voor) · een **alpha-export** klaarzetten
  (Godot export macOS/Windows/web; playtest-telemetrie staat aan).
- **Open features:** **Pomodoro-toren** (laatste toren, mechaniek nog te bepalen) · Splash-schade-toren ·
  Ctrl+Alt+Delete-special · nieuwe enemies **Phone Callers / System Updates / Sports Guy** (los van het
  telefoon-EVENT) · **audio**: melodie-per-toren, geluid voor de nieuwe torens (nu Auto-fallback),
  mini-game-geluiden · **tutorial-level** (GDD §8) · **specialist-bonuslevels** Boss Rush + Endless ·
  pop-culture flavour-teksten (GDD §13) · Peer Review-boss "Do you feel stressed?".
- **Polish/klein:** Art Room-kolomtitels overlappen (15 kol) · sneltoetsen 1-9 dekken toren 10/11 niet ·
  Consultant geeft nu alleen speed-buff (schilden overgeslagen) · multi-path-vallen dekken maar één lane.
- **Bij afronding:** playtest-telemetrie eruit (`ENABLED := false` in `playtest.gd`).

---

**v0.37–0.38 — QTE-component, XP-pop-up, 3 nieuwe torens (met sprites).**
- **Gedeelde QTE-component (v0.37.0):** de projector-mini-game zit nu in
  `scripts/qte_projector.gd` (herbruikbaar). `level.gd` regelt alleen de timing/auto-skip;
  de **Art Room** heeft een knop **"Projector QTE"** om 'm los te testen. Signalen: `solved`,
  `message(text)`; geluid via een `play_cb`-callback.
  **Valkuil:** een Control onder een CanvasLayer krijgt géén grootte van `PRESET_FULL_RECT`
  (anchors gelden alleen t.o.v. een parent-Control) → zet `size` expliciet, anders vangt
  `gui_input` niks en werkt het slepen niet.
- **XP-pop-up herbouwd (v0.37.1):** fase 2 is nu een **geclipt** monitor-scherm (Bliss + taakbalk)
  met een échte XP-dialoog (blauwe titelbalk, rode kruisknop, twee knoppen) die **klein→groot
  in-ploept** (`_pop_in`, TRANS_BACK, <1s). Blijft binnen het scherm. De rode kruisknop is een
  grapje: "You can't escape a meeting like that." `art/ui/qte_xp_popup.png` wordt niet meer gebruikt.
- **3 nieuwe torens (v0.38.0–0.38.2), met sprites.** Normale torens, def_id's
  `chain`/`machinegun`/`multishot`, beschikbaar in level 4-5, sprites in `art/towers/<id>_1..3.png`:
  - **Delegation** (`chain`, rol `"chain"`): schot springt naar dichtstbijzijnde vijanden
    (`chain_range`), schade × `falloff` per sprong. Delegate → Escalate → Company Policy.
  - **Quick Reply** (`machinegun`, rol `"damage"`): heel snel, minieme schade. "Got it" → "OK" → Thumbs-Up.
  - **Self-Service** (`multishot`, rol `"multi"`): raakt tot `shots` doelen per salvo (2/5/8).
    Send the FAQ → Send the Wiki → Send to Service Desk.
  - Nieuwe rollen `"multi"`/`"chain"` in `tower.gd` (`_find_targets`, `_chain_fire`, `_target_score`,
    `_valid_targets`, `_nearest_unhit`). Shop: `expand_icon` + 40px-knoppen zodat 10 core-torens +
    specials passen. Getest (headless-logica): chain 5 raak + falloff ✓, multi = alle doelen in
    bereik ✓, machinegun ~13 schoten/s ✓. **Balans nog niet uitgespeeld.**

**Art-ronde v0.36.0.** Nieuwe sprites (rd_plus, ~$0,46): Thumbtacks-ladder (`trap_1/2/3.png`),
Keyboard Smash (`keyboard_1.png`), 3 boss-sprites (`beamer/outoforder/reorg.png`), en 3
QTE-sprites in `art/ui/` (`qte_beamer/qte_vga/qte_power.png`) die in de sleepfase zitten +
een schuif-animatie naar het XP-scherm. **All-Hands-boss overgeslagen** (concept afgekeurd,
gele fallback). XP-wallpaper en pop-up bewust getekend gehouden. Bug gefixt: `Tower.configure`
clampt nu naar het aantal levels (specials hebben er één). Art Room: trap+keyboard toegevoegd,
11 kolommen voor 21 vijanden. Saldo ~$1,83. **Nog te doen:** All-Hands (ver naar achteren geschoven; concept nog niet af).

**v0.36.2:** XP-scherm + pop-up zijn nu sprites. `qte_xp_wall.png` (Bliss-landschap via
`rd_plus__environment`) vult het monitor-scherm; `qte_xp_popup.png` (XP-venster via
`rd_plus__ui_element`, strak uitgesneden) is de pop-up-chrome met echte klikbare knoppen erop.

**v0.36.1:** QTE-projector vervangen door een grote, gedetailleerde sprite (`qte_projector.png`,
96px met rooster + poortenrij) getoond op 2,6x; VGA/PWR-sleepdoelen uitgelijnd op de poorten van
de sprite. **In-game hernoemd "beamer" → "projector"** (Engels; interne keys `hazard_type`/
`boss_kind` = `"beamer"` blijven). Oude kleine `qte_beamer.png` verwijderd.

**Nieuw in v0.30.0.** De lunchpauze legt je towers niet meer stil maar stuurt een swarm die
met de wave-index meegroeit (bouwen blijft wél geblokkeerd) — zie GDD §4. Nieuwe vijand
**De Printer** (level 3): loopt vast en spuwt Error Messages uit; stun onderbreekt hem.
Nieuwe geluiden: lunchwekker, geroezemoes en een eigen sell-geluid. Vierde audiobus
`EventSFX` plus een Mute all in Settings. De resolutielijst komt nu uit je eigen scherm.

> **Let op bij nieuwe geluiden die uit veel opgetelde stemmen bestaan** (zoals `crowd`):
> die heffen elkaar deels op, dus de piek is niet te voorspellen uit het opgegeven volume.
> Eerste versie kwam op 8% uit terwijl de wekker op 28% zat. Gebruik `Sfx._normalize()`.

**Af:** wave-tabellen per level met eigen karakter, tower-lescurve, The Thread, de
economie-herbalancering, de bekende exploits dicht (perma-stun, Scrum-stacking, wave-spam),
CEO als sniper, Kletskous als echte disruptor, Headphones-ladder (slow → slow → stun),
targeting met zes standen plus losse "hidden first"-optie, boss-fases met eigen HP-balk,
projectielen en trefferfeedback, statuseffecten in kantoorstijl, loopanimaties,
koffiebubbels, het complete UI-blok, procedurele audio, en het playtest-systeem.

**Niet uitgespeeld:** alle balansgetallen zijn doorgerekend, niet gespeeld. De playtest-build
is er juist om dat te toetsen — laat testers meerdere levels spelen en exporteer de CSV.

## Openstaande punten

Neem deze over in je takenlijst.

**Grote richting — carrièresysteem + tutorial (idee gebruiker 2026-07-23, voor later)**

Dit verandert de fundamentele structuur van 5 losse levels naar een carrièrepad. Vastgelegd
in GDD §8. Groot; opknippen wanneer eraan begonnen wordt.

- **A. Carrière/promotie-progressie.** Levels in blokken van vijf. Haal je alle vijf van een
  blok met **3 sterren**, dan word je gepromoveerd met een schermvullende melding:
  - Level 1–5 → **"PROMOTED! You are now a medior"**
  - Level 6–10 (flink moeilijker) → **"PROMOTED! You are now senior!"**
  - Level 11–15 → **"PROMOTED! You are now specialist"**
  - Startrang is impliciet "junior" (bevestigd door gebruiker: je wordt "now a medior").
  - Nu bestaan alleen level 1–5. Blok 2 en 3 zijn dus 10 nieuwe levels.
  - **Specialist-bonuslevels (bevestigd 2026-07-23).** Zodra je specialist bent, zijn ze
    **allemaal tegelijk ontgrendeld** — geen onderlinge sterren-eis, puur extra/lol. Ze
    tellen niet mee voor verdere progressie (specialist is de top). Voorbeelden:
    - **Boss Rush:** alléén bosses achter elkaar.
    - **Endless:** oneindig veel waves die telkens zwaarder worden — geen einde, je speelt
      voor een highscore (hoe ver kom je). Dit vervangt het oude "Endless out of scope"-punt
      uit GDD §8/§10; het komt terug als specialist-bonus. Vraagt een oplopende-moeilijkheid-
      generator (schaal HP/aantal/tempo met het wave-nummer) i.p.v. een vaste wave-tabel.
  - Raakt: `game_state.gd` (LEVEL_COUNT=5, `highest_unlocked`, sterren-opslag,
    promotie-detectie), `app.gd` level-select + een promotie-scherm, en de bonus-modi.
  - *Open:* toont level-select alle vijftien tegelijk of per rang-blok? Vrijgave van blok 2:
    na promotie of na simpelweg blok 1 uitspelen (los van 3 sterren)?

- **B. Moeilijkheid via map-mechanics, niet alleen sterkere enemies.** De hogere blokken
  krijgen sterkere vijanden **plus** eigenwijze map-regels. Ideeën van de gebruiker:
  - **Verhuizend kantoor:** maar een handjevol bouwplekken (koppelt aan openpunt 11 hieronder,
    "bouwbare plekken beperken").
  - **Geen koffie:** geen Coffee Machine te bouwen én geen Coffee per kill; je krijgt aan het
    begin één grote berg Coffee en daar moet je het de hele ronde mee doen.
  - "En meer van dat soort gekke dingen" — ruimte voor nog een paar map-modifiers.
  - *Open:* is een map-modifier een veld op de leveldata (schaalbaar) of per level hardcoded?

- **C. Tutorial-level.** Kort, snel, **altijd beschikbaar maar niet verplicht** om level 1 te
  spelen (staat dus los van de rang-progressie, telt niet mee voor sterren/promotie). Opzet:
  - Eén recht pad, en **per wave precies één les**: introduceer één tower + de enemy waar die
    tegen bedoeld is.
  - Na elke wave **resetten**: de getoonde towers en enemies verdwijnen weer, zodat elke wave
    een schone mini-demo is.
  - De speler kan **alleen de tower(s) kopen die bij die wave horen** — de rest staat uit.
  - *Open:* welke wave-volgorde/lessen precies (waarschijnlijk: Auto-Reply vs Notification →
    Shredder vs Thread-zwerm → Artillery vs tank → Headphones vs een sprinter/printer → …)?
    Eigen scherm of een speciaal leveltype dat `level.gd` hergebruikt met een "tutorial"-vlag?

**Wacht op een beslissing van de gebruiker**

1. **Level-boss per level.** Nu heeft alleen level 5 een boss (The Performance Review).
   Elk level krijgt zijn eigen thematische eindboss in de laatste wave. Zie `_boss_update`
   in `enemy.gd` voor de fase-logica en de nieuwe `spawner`-mechaniek (Printer) voor adds.

   > ✅ **GEBOUWD v0.34.0** (met gele fallback-vorm; sprites volgen in een art-ronde). Het
   > boss-systeem is gegeneraliseerd met `boss_kind` (`enemy.gd`): `_boss_update` dispatcht de
   > mechaniek, `level.gd` `_on_boss_phase`/`_boss_phase_name`/spawn de reacties. Elke boss zit
   > als eigen slotwave in zijn level (`game_state.gd`). Getest: allhands spawnt adds ✓, beamer
   > schild 90 + slides ✓, outoforder blokkeert Coffee ✓, reorg splitst Manager bij fase-wissel ✓.
   > **De Schoonmaker** (kandidaat) is nog NIET gebouwd — mechaniek staat klaar (speed-aura +
   > veegt zones/vallen weg), level nog te kiezen.
   > **All-Hands Meeting (L1 boss): concept afgekeurd 2026-07-23** — de gebruiker was er niet
   > blij mee (speakerphone-idee). Mechaniek (spawnt Notificaties) blijft, maar naam/visueel
   > moeten opnieuw bedacht worden. In de art-ronde v0.36 daarom OVERGESLAGEN (gebruikt nog de
   > fallback-vorm).

   **Voorgestelde concepten (te mergen met de ideeën van de gebruiker):**
   - **L1 Open-Plan Office — *The All-Hands Meeting*** ("This could have been an email").
     Traag, veel HP, lage focus-schade — zachte intro-boss. Mechaniek: roept iedereen erbij,
     spawnt elke paar sec een paar Notifications. Beatable met alleen Auto-Reply + economie.
   - **L2 Meeting Room — *The Broken Projector*** (kapotte beamer, idee gebruiker). Schild-laag
     ("loading…") die eerst gebroken moet worden → beloont burst. Mechaniek: "No Signal" —
     flikkert periodiek en spawnt een zwermpje slide-adds richting bureau → test area/Shredder.
   - **L3 Coffee Corner — *Out of Order*** ("the coffee machine is broken"). ✅ Door gebruiker
     bevestigd + verfijnd: het is **een monteur die het koffieapparaat komt "repareren"**.
     Mechaniek: zolang hij leeft krijg je **geen Coffee erbij** (Coffee Machines leveren niets
     en/of geen Coffee-per-kill). Past bij de aura-familie (Kletskous) van dit level.
   - **L4 Canteen — *The Reorganisation*** ("we're restructuring"). Mechaniek: bij elke HP-fase
     splitst hij een kleinere Manager af die naar je bureau sprint (splitter op boss-schaal,
     echoot The Change). Test burst + area.
   - **De Schoonmaker / The Cleaner** (boss, mechaniek besloten 2026-07-23). De conciërge die
     "opruimt". Mechaniek: **speed-aura** (vijanden bij hem versnellen) **+ wist Shredder-zones
     en punaisenvallen** die hij passeert. Eerlijke, gerichte counter tegen area/trap-towers,
     zonder de RNG-frustratie van torens verplaatsen (dat is bewust afgewezen). Level nog te
     kiezen (kan een van de bovenstaande vervangen of een extra worden).

**Kosten geld (eerst `estimate_inference_cost` en overleggen)**

2. ~~**Board Member en Nudge opnieuw**~~ ✅ **AF (v0.32.0).** Beide opnieuw met `rd_plus` +
   het verfijnde recept ($0,076 samen). Board is nu een stevige directeur met gekruiste armen,
   Nudge een chat-notificatie met bliksem. **Let op:** `rd_pro__*` gaf consequent HTTP 400
   "inference_failed" op dit account, ondanks globale status "ok" — waarschijnlijk niet op het
   plan. Voor betrouwbaar figuur-werk dus voorlopig `rd_plus` + het recept uit de style guide.
3. ~~**Upgrade-ladders voor filter, scrum en ceo**~~ ✅ **AF (v0.29.0).** Alle negen sprites
   staan in het spel, de towers heten nu The Shredder, Motivational Poster en Office
   Artillery, en de mechanic-teksten in `tower.gd`, `enemy.gd` en `level.gd` zijn mee
   veranderd. Def_id's (`filter`, `scrum`, `ceo`) zijn ongewijzigd gebleven. Kosten $0,42
   (11 generaties: twee sprites moesten opnieuw). Zie `art/STYLE_GUIDE.md` voor de nieuwe
   `tools/remove_shadow.py`-stap tegen slagschaduwen.

**Level-designfase (samen doen)**

4. **Kantoor-tileset** voor het speelveld — nu een egale grijze vlakte met een lijn.
   Retro Diffusion heeft `rd_tile__*`-styles; check eerst `get_style_usage`.
5. **Bureau-sprite** als einddoel (nu een rood rechthoekje in `level.gd`), passend bij het
   level. Optioneel: rommeliger naarmate je Focus zakt.
6. **Deur op het spawnpunt** waar vijanden uit komen. Let op: paden beginnen nu buiten
   beeld (x = -60), dus voor een zichtbare deur moeten de paden in `game_state.gd` mee.
7. **Nieuwe maps** voor alle vijf levels — het oorspronkelijke openstaande punt.

**Balans nakijken (v0.30.0, nog niet gespeeld)**

- **Lunch-swarm in level 4.** Bijgesteld v0.32.0 na balans-analyse: rustperiode 30→55s
  (~4-5 lunches per level i.p.v. 8-9), rush iets groter (12 Nudge + 6 Noti + 4 Question,
  groeiend met `wave_index/3`). Zie `_spawn_lunch_rush` in `level.gd`. Nog niet gespeeld.
- **Balans-analyse v0.32.0 (via `tools/balance_report.gd`):** economie gezond — Coffee uit
  kills 508-685 (richtlijn 467-674), volle toren 47-110, Coffee Machine opbrengst/Coffee
  stijgt (3.2→3.2→3.7x). Let op: het rapport telt runtime-spawns (lunch-swarm, printer-errors)
  NIET mee, dus L3 en L4 zijn effectief zwaarder dan hun basisgetal.
  Draaien: aanroep `BalanceReport.run()` tijdelijk in `App._ready()` (env-vars komen niet door
  de sandbox), dan `Godot --headless --path . --quit-after 90`.
- **De Printer in level 3.** 34 HP, spawnt elke 3,4s twee Errors. Level 3 heeft nu 21 waves.
  Vraag: is hij vroeg genoeg te doden, en zijn de Errors niet te veel bovenop de Nudges?

**Nieuwe towers (ontwerpkeuzes eerst)**

8. **Splash-schade rondom de treffer.** Anders dan de zone van de Versnipperaar: beweegt
   mee met het doelwit. Thema en balans nog open.
9. **Chain shot** — schot springt door naar volgende vijanden. Aantal sprongen, schade per
   sprong en maximale afstand nog open.
10. ~~**Vallen op het pad**~~ ✅ **AF (v0.32.0) → herzien naar STROOIER-model (v0.33.1).**
    7e tower **Thumbtacks** (def_id `trap`, rol `"trap"`). Staat naast het pad en **gooit**
    punaises (worp-projectiel `fx.toss`) op **willekeurige tegels** binnen bereik. Begint op 0,
    elke `throw_interval` één worp; elke punaise heeft een `lifetime` en roest weg als hij te oud
    is (→ ~3 tegelijk bij lvl 1, ~5 bij lvl 2). Vijand die er overheen loopt krijgt `damage` en
    verbruikt de punaise. **lvl 3 (`pick_spot`):** klik een pad-tegel om de worpen te richten
    (`trap_selecting` + `set_trap_spot`). Data: `_tacks_list` = `[{pos, age}]`. Getest: gooit
    naar verschillende tegels ✓, binnen bereik ✓, veroudert ✓, vijand verbruikt ✓. Silence raakt
    'm niet. Shop level 4-5. **Nog geen sprite** (gele-cirkel-fallback).
11. **Bouwbare plekken beperken + platform-tower** die een geblokkeerde plek vrijmaakt.
    Hoort bij de level-designfase.
12. ~~**Specials-categorie + Keyboard Smash**~~ ✅ **AF (v0.33.0).** Shop is nu een **2-koloms
    grid** met een aparte **SPECIALS**-sectie (`_shop_button` + core_grid/spec_grid in
    `_build_shop`; `SPECIALS`-const + `_buildable()`). Gedeelde special-regels werken:
    `is_special`/`on_path` in de tower-defs, **max 1 per level** (`_can_place_at` + melding),
    **geen upgradeknop** (`_open_upgrade`). **Keyboard Smash** (def_id `keyboard`, rol `smash`):
    op-pad-plaatsing, slaat toe zodra een vijand in bereik komt → AoE-schade + **slagboom** die
    vijanden stilzet (`enemy.blocked` → speed 0, gezet in `_apply_buffs_and_disrupt`), plus
    **letters-fx** (`fx.letters`). Getest: op-pad ✓, 2e weigert ✓, AoE ✓, blocked=true/speed=0 ✓.
    Staat in shop van level 3-5. **Nog geen sprite** (fallback-vorm). Zie **GDD §5 → Specials**.

**Nieuwe richtingen (2026-07-23, eerst bespreken)**

13. ~~**Quick-time events / mini-games**~~ ✅ **AF, drag-and-drop (v0.35.1).** Hazard `"beamer"`.
    Among Us-taak: **fase 1** sleep VGA- + power-kabel naar de poorten op de beamer (snap 46px,
    meelopend snoer via `Line2D`); **fase 2** pixel-art Windows-XP-scherm + "Display Settings"-
    pop-up, klik de 2e optie. Auto-skip na 10s; spel loopt gedimd door, bouwen stil. Code:
    `_build_qte`, `_qte_add_cable`, `_qte_input` (drag), `_qte_check_cables`, `_finish_qte`,
    `"beamer"`-tak in `_update_hazard`. Level 2 = beamer-QTE, **brandalarm verhuisd naar level 3**
    (Koffiehoek). *Uit te breiden: geluid, decoy-poorten.* **Balans:
    level 3 heeft er nu een hazard bij — toetsen.**
    > ✅ **v0.37: uitgehaald naar `scripts/qte_projector.gd`** (gedeeld, ook los testbaar in de
    > Art Room) **+ XP-pop-up herbouwd** als echte XP-dialoog met klein→groot-animatie. Zie
    > Stand van zaken bovenaan. Functies heten nu `_build`/`show_qte`/`_check_cables`/`_on_gui_input`.
14. **Pop-culture referenties** (Office Space / The IT Crowd). ✅ *Eerste lichting geplaatst
    (v0.32.2):* brandalarm roept het IT Crowd-noodnummer, Error Message zegt "Have you tried
    turning it off and on again?", Office Artillery lvl 2 heet "Stapler" met flavour "It's a
    Swingline" (Milton, Office Space). Lopende lijst in **GDD §13** — bij elke nieuwe
    flavour-tekst een kans zoeken om er een te plaatsen.

**Nieuwe ideeën (gebruiker 2026-07-23, nog uit te werken)**

16. **Nieuwe enemies — afleidingen (distractions).**
    - **Phone Callers** (Kantoortuin/level 1) — mensen die lopen te bellen. Optie A: vertraagt
      torens in de buurt, maar **Headphones is er immuun voor**. Optie B (leuker?): trekt juist
      alle aandacht — torens schieten éérst op hem (**overschrijft target-prioriteit** tijdelijk).
      Kiezen welke.
    - **System Updates** — afleiding-monster. Kan ook een **QuickTime** worden ("klik op Later"
      om de update uit te stellen — de eeuwige "Remind me later"-knop).
    - **Sports Guy** — de collega die het altijd over voetbal heeft. Opent met "Did you see that
      ludicrous display last night?" (IT Crowd, GDD §13). Mechaniek nog te bepalen (afleiding).
17. **Nieuwe torens.**
    - **Pomodoro Timer** — mechaniek nog te bepalen (tijd-gebaseerd; evt. burst elke X sec). NOG TE DOEN.
    - ~~**Machine Gun**~~ ✅ **AF + sprite (v0.38.2)** — heet nu **Quick Reply** (`machinegun`).
    - ~~**Multi-shot**~~ ✅ **AF + sprite (v0.38.2)** — heet nu **Self-Service** (`multishot`), 2/5/8 doelen.
    - ~~**Chain Shot**~~ ✅ **AF + sprite (v0.38.2)** — heet nu **Delegation** (`chain`).
18. **Specials — uitbreiding.**
    - **Ctrl+Alt+Delete** (nieuw special-idee, van mij) — laadt op tijdens het spelen; vol =
      **force-quit** de sterkste vijand op het scherm (instakill/enorme schade). Eenmalig, sterk.
    - **Specials pas vanaf medior?** (idee gebruiker) — koppel de SPECIALS-sectie aan de
      carrière-rang (medior = level 6+). **Beslissen zodra de carrièreblokken bestaan**; tot dan
      blijven specials in level 3-5 om te testen.
19. **Audio — melodie per toren.** Elk schietgeluid per toren-type een andere toon, zodat je
    opstelling samen een deuntje speelt. Past bij de procedurele `sfx.gd`. (Nu deelt elke
    tower-shot dezelfde bus/geluiden per rol.)
20. **Peer Review-boss** opent met "Do you feel stressed?" (IT Crowd, GDD §13). Haakt aan op de
    Performance-Review-boss (fase 2 = Peer Feedback) of een eigen boss.

**Pas als het spel af is**

15. **Playtest-telemetrie eruit**: `ENABLED := false` bovenin `scripts/playtest.gd`
    schakelt formulier én exportknop uit. Volledig verwijderen kan ook — let op dat de
    `_stats`-tellers in `level.gd` ook het eindscherm voeden.
