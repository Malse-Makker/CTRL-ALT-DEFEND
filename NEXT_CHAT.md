# Prompt voor een nieuwe chat

Start een nieuwe chat **in de map `/Users/nijntje/Documents/projecten`** (daar staat `.mcp.json`
met de godot-, blender- en retro-diffusion-servers) en plak het blok hieronder.

Werk dit bestand bij zodra de stand van zaken verandert; `HANDOFF.md` blijft de uitgebreide bron.

---

## PLAK DIT IN DE NIEUWE CHAT

We werken samen aan **CTRL-ALT-DEFEND**, een top-down pixel-art tower defense in Godot 4.7.1 over
het verdedigen van je werkdag tegen kantoorergernissen.
Map: `/Users/nijntje/Documents/projecten/CTRL-ALT-DEFEND` — dit is een **publieke git-repo**
(`git@github.com:Malse-Makker/CTRL-ALT-DEFEND.git`). *Let op: de oude map `projecten/game` is een
kopie van vóór de verhuizing; daar niet in werken.*

**Lees eerst, in deze volgorde:**
1. `HANDOFF.md` — werkwijze, valkuilen, releaseproces en de stand van zaken per versie. Bovenaan
   staan drie blokken die je écht moet lezen vóór je iets doet: **playtest-data lezen**, de
   **release-checklist** en het **releaseproces**.
2. `05_MIJN_GAME_CONTEXT.md` — wat de game is, wat werkt, wat niet, en de speeltest-observaties.
3. `Office_TD_GDD.md` — het ontwerpdocument (torens, vijanden, economie, levelkaart).
4. `MAP_DESIGN_REVIEW.md` — het levelontwerp per map.
5. `art/STYLE_GUIDE.md` — hoe sprites gemaakt en verwerkt worden.

**Stand van zaken: v0.78.0, alpha, speelbaar en uitgebracht.**
15 levels in drie carrièreblokken met promotie, 14 torens, 32 vijanden inclusief bosses, vijf
interactieve mini-games, drie extra modi (Tutorial, Boss Rush, Endless). De game **update
zichzelf**, staat op https://game.makkers.net en wordt via GitHub Releases verspreid. Testers
sturen feedback met één klik vanuit de game naar Discord.
**Nog niet gedaan:** de art-pass (maps zijn greybox), audio-uitbreiding, en de balans écht
uitspelen.

**Werkwijze (belangrijk):**
- We overleggen in het **Nederlands**, alle **in-game tekst is Engels**.
- Stap voor stap, met korte keuzevragen en jouw aanrader erbij. Vul geen ontwerpkeuzes zelf in.
- Na elke wijziging **headless testen**:
  `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --quit-after 120`
  (schoon = alleen de engine-versieregel). Controleer UI-werk ook **visueel met een schermafdruk** —
  de headless test ziet geen overlappende tekst, en dat is deze week meermaals misgegaan.
  Tijdelijke autotest-code er daarna weer uithalen.
- **Na elke afgeronde wijziging uitbrengen** met `./tools/make_release.sh` (bouwt, checksumt,
  publiceert op GitHub, werkt de site bij) en **committen + pushen**. Een wijziging die niet
  uitgebracht is, bestaat niet voor de testers.
- **VERSION** bijwerken (SemVer) en bovenaan in `CHANGELOG.md` een sectie toevoegen; het
  releasescript weigert als die twee niet overeenkomen. Meld aan het eind van je bericht de
  volgende versie.
- Commits gaan als `malse-makker <games@makkers.net>` (staat lokaal in de repo ingesteld).
- Retro Diffusion kost geld — **altijd eerst `estimate_inference_cost`** (gratis) en overleggen.

**Waar we het laatst mee bezig waren:** de eerste serieuze speeltest verwerken. Level 2 bleek
onhaalbaar door 312 Nudges (nu gehalveerd), de startkoffie stond te laag, de tutorial klopte niet,
en het eindscherm vertelt nu welke vijanden je pijn deden en wat je ertegen bouwt.

**Wat er nu op tafel ligt** (mijn voorkeur eerst, maar overleg het):
1. **De balans uitspelen en de Auto-Reply-meta aanpakken.** Van de 14 torens werden er in de
   speeltest **negen nul keer gekocht**. Dat is het grootste inhoudelijke probleem: meer dan de
   helft van de toolkit doet niet mee. Dit vraagt eerst analyse (waarom wint Auto-Reply altijd?),
   dan een ontwerpkeuze, niet meteen getallen schuiven.
2. **Bosses interessanter maken.** Ze hebben allemaal een mechaniek, maar veranderen te weinig aan
   wat je moet doen; een tester haalde Out of Order zonder het te merken.
3. **De moeilijkheidscurve gladstrijken.** Level 1 is te makkelijk, level 2 was drie keer op rij
   onhaalbaar. Doel van de gebruiker: elk level moet haalbaar zijn **zonder Focus te verliezen**.
4. **De art-pass** (maps zijn nog greybox) — maar dat is bewust de láátste stap, zie de
   release-checklist in HANDOFF.

Vraag me waar we mee beginnen voordat je aan de slag gaat.
