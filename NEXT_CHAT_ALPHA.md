# Prompt voor de volgende chat — Alpha maken & speelbaar voor vrienden

Start een nieuwe chat **in de map `/Users/nijntje/Documents/projecten`** (daar staat `.mcp.json` met
de godot-, blender- en retro-diffusion-servers) en plak het blok hieronder.

---

## PLAK DIT IN DE NIEUWE CHAT

We werken samen aan **Office Tower Defense**, een top-down tower defense in Godot 4.7
(map: `/Users/nijntje/Documents/projecten/game`). Lees eerst deze bestanden, in deze volgorde:

1. `game/README.md` — wat er werkt en hoe je het start
2. `game/Office_TD_GDD.md` — het ontwerpdocument (bron van waarheid)
3. `game/HANDOFF.md` — overdracht: werkwijze, valkuilen, stand van zaken en de volledige takenlijst
4. `game/art/STYLE_GUIDE.md` — hoe sprites gemaakt en verwerkt worden
5. `game/MAP_DESIGN_REVIEW.md` — de map-/level-design-review (curve, gimmicks, bosses, hazards én de
   ruimtelijke pad-layouts); data-laag is doorgevoerd, bovenaan staat wat nog openstaat

**Stand van zaken (v0.61.0):** de game is **functioneel compleet**. 15 levels in 3 blokken met
promotie (junior/medior/senior), alle torens/vijanden/bosses/mechanieken, 3 extra modi
(Tutorial · Boss Rush · Endless), en een in-game **feedback-pagina** (menu → Feedback) met een export.
De map-design-review is qua data doorgevoerd. **Nog niet gedaan** (bewust uitgesteld): de hele
**art-pass** (de maps zijn nog greybox — grijze vlaktes en gekleurde blokjes), audio-uitbreiding, en
**balans uitspelen**. Dat is de "feedback- & art-fase" die ná deze stap komt.

**Doel van deze chat: de game speelbaar maken voor vrienden.** Dus: een **alpha-export** maken en een
**download-/speel-link** opzetten. De gebruiker heeft een **OVH-server** waar de build gehost kan worden.
> Let op: dit game-project is **geen git-repo**, dus er is géén CI/CD-deploy zoals bij de andere
> projecten (Codeberg-runner). Exporteren en uploaden gaat handmatig.

**Werkwijze (belangrijk):**
- We overleggen in het **Nederlands**, alle **in-game tekst is Engels**.
- Stap voor stap. Stel korte keuzevragen met de keuzeknoppen-tool, geef bij elke vraag je aanrader,
  en vul niets zelf in zonder dat ik beslis.
- Na elke code-wijziging **headless testen**:
  `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --quit-after 120`
  (schoon = alleen de engine-versieregel). Tijdelijke autotest-code er daarna weer uithalen.
- Controleer wijzigingen ook **visueel** met een schermafdruk vanuit het spel.
- **VERSION** bijwerken (SemVer) en aan het eind van je bericht de volgende versie melden. We staan op
  **v0.61.0**.
- Retro Diffusion kost geld — **altijd eerst `estimate_inference_cost`** (gratis) en overleggen.

**Concrete eerste stappen voor de alpha (overleg per stap, geef je aanrader):**
1. Check of de **Godot export templates** voor v4.7.1 geïnstalleerd zijn. Zo niet: installeren.
2. Kies de **targets**. Aanrader: **Web (HTML5)** — één URL, speelt in de browser, werkt op elke
   computer, geen installatie. Eventueel daarnaast **native** builds (Windows `.exe` + `.pck` in een zip,
   macOS `.app` in een zip) als echte download.
3. **Export-presets** aanmaken (`export_presets.cfg`) en een build maken. CLI-export kan met
   `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --export-release "<preset>" <uitvoerpad>`.
4. De build **testen** (web lokaal serveren en spelen; native starten).
5. **Hosten op OVH**: de web-build-map uploaden (speel-URL) of de zip als download-link. Samen bepalen
   hoe (SSH/scp, welke map, welke URL).
6. **Playtest-telemetrie aan laten**: `ENABLED` in `scripts/playtest.gd` op `true` zodat vrienden-data
   logt. Vrienden gebruiken de **Feedback**-knop in het menu en sturen de geëxporteerde bestanden terug
   (`office_td_feedback_*.txt` + `office_td_playtest_*.csv`).

**Belangrijk om te weten:**
- Greybox-art is oké voor een speel-alpha; de art-pass komt ná de feedback.
- Web-export vraagt vaak specifieke instellingen voor pixel-art/audio en cross-origin headers op de
  server (SharedArrayBuffer) — daar op letten bij het hosten.

**Feedback-lus (na deze chat):** zodra de gebruiker en vrienden hebben gespeeld, leveren ze de
feedback-`.txt` + playtest-`.csv` in. De volgende stap is die **inlezen en er een vragenlijst van maken**
(wat we wél en niet willen aanpassen) — **niet direct uitwerken**.
