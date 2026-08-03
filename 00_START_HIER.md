# Start hier

Vijf bestanden, twee gebruiksscenario's.

## Scenario 1: mijn bestaande game verbeteren (dit is waar het je om ging)

1. Vul `05_MIJN_GAME_CONTEXT.md` in. Doe dit serieus, dit bepaalt of de suggesties
   in jouw game passen of dat je een Bloons-kloon terugkrijgt.
2. Open een nieuwe chat.
3. Upload: `01_TD_DESIGN_REFERENCE.md`, je ingevulde `05_MIJN_GAME_CONTEXT.md`, en
   je game-bestanden (de lijst staat onderaan `04_AUDIT_PROMPT.md`).
4. Plak de prompt uit `04_AUDIT_PROMPT.md`.
5. Je krijgt: inventarisatie, scorecard, vijf systeemanalyses, een
   prioriteitentabel op impact-per-uur, en de bovenste drie uitgewerkt tot code.

---

## Wat elk bestand is

| Bestand | Wat het is | Wanneer gebruiken |
|---|---|---|
| `01_TD_DESIGN_REFERENCE.md` | De systeemanalyse van BTD6, thema-neutraal gemaakt. Torens, vijanden, maps, economie, en hoe het samenhangt. Eindigt met een checklist. | Altijd meesturen. Dit is de benchmark. |
| `02_GAME_DESIGN_DOCUMENT.md` | Een compleet GDD met datamodellen, tabellen en Godot-architectuur. | Bij nieuwbouw, of als naslag bij herontwerp. |
| `04_AUDIT_PROMPT.md` | De verbeterprompt met vijf analyseblokken en een prioriteitentabel. | Bij je bestaande game. |
| `05_MIJN_GAME_CONTEXT.md` | Invulformulier over jouw thema, scope en grenzen. | Altijd meesturen bij de audit. |

---

## De drie dingen die je meeneemt als je verder niks leest

1. **Diepte komt niet uit meer torens.** Het komt uit vier assen die
   vermenigvuldigen: wat je raakt (weerstanden), hoe je raakt (damage / pierce /
   rate), waar je staat (terrein en zicht), en wat het kost over tijd (economie).
   Een toren die op alle vier gelijk scoort aan een bestaande toren voegt niks toe.

2. **De economie is het spel.** De spanning tussen "nu verdedigen" en "nu
   investeren" is de motor. Twee inkomstenstromen die verschillend gedrag belonen,
   een investeringslaag met een timing-mechanic, en een dempingscurve zodat het
   niet ontploft. Zonder die spanning is er na tien minuten geen beslissing meer.

3. **Weerstanden straffen strategieen, niet torens.** Een weerstand die maar door
   één toren te counteren is, is een slot met één sleutel. Een goede weerstand
   straft *te veel van hetzelfde*, en komt precies op het moment dat de speler in
   die richting doorbouwt.
