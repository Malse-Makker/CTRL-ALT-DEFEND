# TD Design Reference: waarom Bloons TD 6 werkt

Dit document is geen beschrijving van BTD6, maar een uitgeklede analyse van de
onderliggende systemen, zodat je ze kunt toepassen op je eigen thema. Overal waar
"apen" en "ballonnen" stonden, staan hier generieke termen: **toren** en **vijand**.

Gebruik dit bestand als benchmark. Als je eigen game een van deze systemen mist of
plat heeft geimplementeerd, is dat een concrete verbeterrichting.

---

## 0. De kernstelling

BTD6 heeft ongeveer 24 torens, maar de speelruimte komt niet uit het aantal torens.
Die komt uit **vier orthogonale assen die met elkaar vermenigvuldigen**:

1. Wat een toren *raakt* (damage type versus immuniteiten)
2. Hoeveel een toren *raakt* (pierce) versus hoe *hard* (damage) versus hoe *vaak* (rate)
3. *Waar* een toren kan staan en *wat* hij kan zien (placement en line of sight)
4. Wat een toren *kost* nu, versus wat hij *oplevert* over 20 rondes (economie)

Elke andere ontwerpbeslissing in de game dient een van deze vier assen. Een toren
toevoegen die op alle vier de assen hetzelfde scoort als een bestaande toren voegt
niets toe, hoe leuk de art ook is. Dat is de belangrijkste les.

---

## 1. Vijanden: gelaagde HP, geen healthbars

### 1.1 Lagen in plaats van HP
Een normale vijand heeft geen healthbar. Hij heeft een *laag*, en als die kapot gaat
spawnt hij zijn kinderen. Rood > niets. Blauw > 1x rood. Groen > 1x blauw. Geel >
1x groen. Roze > 1x geel. Zwart > 2x roze. Regenboog > 2x zebra. Enzovoort.

Waarom dit sterk is:
- **Leesbaarheid**: je ziet aan de kleur meteen de dreiging, zonder UI.
- **Ruimtelijke druk**: een enkele grote vijand die doorbreekt wordt onderweg
  exponentieel breder. Eén lek wordt vier lekken. Dat maakt "diepte" van je
  verdediging een echte resource, niet alleen DPS.
- **Meetbaarheid**: de totale kosten van een ronde is uit te drukken in één getal,
  het aantal basisprikken dat nodig is om alles volledig af te breken (in BTD6:
  RBE, Red Bloon Equivalent). Ceramic = 104. MOAB = 616. BFB = 3164. ZOMG = 16656.
  BAD = 55760. Dit is de belangrijkste balansmetriek in de hele game.

### 1.2 Snelheid is een aparte as
Rood loopt op 1.0, geel op 3.2, roze op 3.5. Zwart heeft 11 lagen maar loopt op 1.8.
De grote luchtschepen zijn juist traag (BFB 0.25, ZOMG 0.18) behalve de DDT, die op
2.64 vliegt en juist daarom eng is. **Taai en traag** versus **zwak en snel** zijn
twee compleet verschillende bedreigingen die twee verschillende torens vragen.

### 1.3 Immuniteiten als design tool, niet als straf
Dit is het scherpste stuk BTD6 design en meestal het zwakst gekopieerd:

| Vijandtype | Immuun voor | Effect op de speler |
|---|---|---|
| Zwart | explosies | Straft mono-bomb builds |
| Wit | freeze/ice | Straft mono-control builds |
| Paars | vuur, plasma, energie | Straft mono-magic builds |
| Lood | scherp/darts | Straft de standaard starter toren |
| Zebra | explosies en freeze | Combineert twee straffen |
| Camo | alles zonder detectie | Vraagt een support-investering |

Let op wat hier gebeurt. Elke immuniteit is gericht op *precies de toren die op dat
moment het efficientst zou zijn als je erin doorbouwde*. De immuniteit is geen
willekeurige muur, het is een timer op mono-strategieen. En de introductierondes
staan zo dat je nog net kunt bijsturen: lood op 28, paars op 25, camo op 24.

Regel: **een immuniteit hoort een straf te zijn op te veel van hetzelfde, niet op
een specifieke toren.** Als je immuniteit maar door één toren gecounterd wordt, heb
je een sleutel-en-slot puzzel gebouwd in plaats van een keuze.

### 1.4 Properties als orthogonale modifiers
Camo, Regrow en Fortified zijn *geen* vijandtypes maar vlaggen die je op bestaande
types plakt. Ze erven over naar kinderen. Effect:

- **Camo**: onzichtbaar tenzij een toren detectie heeft. Straft "ik zet gewoon meer
  DPS neer" en beloont support-torens.
- **Regrow**: groeit lagen terug als hij niet snel genoeg sterft. Straft *lekken*
  in plaats van *doorlaten*. Chip damage werkt niet meer, je moet af kunnen maken.
- **Fortified**: verdubbelt HP (lood x4). Puur een schaalknop, geen nieuwe mechanic.

Drie vlaggen op twaalf types geven je effectief tientallen dreigingsprofielen zonder
één nieuwe asset. Dit is de goedkoopste contentvermenigvuldiger in het hele ontwerp.

### 1.5 De klasse-breuk
Vanaf ronde 40 komen luchtschepen: een aparte klasse met echte HP (200 / 700 / 4000 /
20000), die bij kapotgaan een vaste hoeveelheid normale vijanden dumpt. De MOAB
splitst in 4 ceramics, de BFB in 4 MOABs, de ZOMG in 4 BFBs.

Belangrijk: dit is een **paradigmawissel halverwege de game**. De verdediging die
ronde 1 tot 39 perfect werkte (veel pierce, breed, goedkoop) is precies de verkeerde
verdediging voor ronde 40+ (single target burst). Zonder zo'n breuk wordt je game
na twintig minuten een grafiek in plaats van een spel.

De DDT is het slimste ontwerp in de hele lijst: camo + lood + snel + 400 HP. Hij
combineert drie eerder geleerde lessen in één vijand. Dat is hoe een late-game
vijand hoort te werken, als examen over eerder materiaal.

---

## 2. Torens: drie paden, twee keuzes, oneindig veel builds

### 2.1 De 5/2 regel
Elke toren heeft 3 paden van 5 upgrades. Je mag **één pad naar tier 5, en één ander
pad naar maximaal tier 2**. Het derde pad gaat op slot.

Dit is de belangrijkste single design decision in de game. Waarom:
- Je hebt per toren 3 x 2 = 6 hoofdrichtingen en binnen elke richting 3 crosspath
  varianten. Dus ruwweg 18 zinnige eindconfiguraties per toren.
- Elke upgrade die je koopt is een **onherroepelijke keuze**. Dat maakt de beslissing
  spannend en de build persoonlijk.
- Je hoeft geen 18 torens te ontwerpen, je ontwerpt er één met 15 upgrades.

De crosspath (die tier 1 of tier 2 in het zijpad) is meestal geen nieuwe mechanic
maar een statknop: +pierce, +rate, +range, of camo-detectie. Precies daardoor is het
een echte keuze: "meer schoten of meer doorboring" is contextafhankelijk, en de
context is de map en de ronde.

### 2.2 De drie stat-assen
Bijna alle balans in BTD6 is een driehoek:

- **Damage**: hoeveel lagen per raak. Telt tegen taaie enkelvoudige doelen.
- **Pierce**: hoeveel vijanden één projectiel raakt voor hij verdwijnt. Telt tegen
  dichte groepen.
- **Attack rate**: hoe vaak. Vermenigvuldigt de andere twee, en is daarom altijd de
  gevaarlijkste stat om te buffen.

Een toren die hoog scoort op alle drie is kapot. Elke toren hoort in het profiel te
passen: "hoog pierce, laag damage" (tack shooter), "hoog damage, geen pierce"
(sniper), "extreem hoge rate, matige rest" (super monkey).

### 2.3 Tier 5 schaarste
Er mag maar **één tier 5 per pad per torentype tegelijk op het veld staan**. Dat
betekent: geen spam van de beste optie. Je wordt gedwongen te diversifieren op het
moment dat je genoeg geld hebt om niet meer te hoeven kiezen. Dit is de enige rem op
de late game die niet aan geld gekoppeld is, en daarom werkt hij.

### 2.4 Torenklassen
Vier klassen (Primary, Military, Magic, Support) doen drie dingen tegelijk:
- ze structureren de UI,
- ze zijn een aanhakingspunt voor buffs (village buft alles in radius),
- ze zijn de basis voor game modes (Primary Only, Military Only, Magic Only) die
  bestaande content hergebruiken als volledig nieuwe puzzel. Nul extra assets.

Als jouw game geen torenklassen heeft, mis je vooral dat derde punt.

### 2.5 Targeting priority
Elke toren heeft First / Last / Close / Strong, en soms een extra toggle. Dit is
gratis speler-agency: geen micromanagement, wel echte tactische diepte. Een sniper
op Strong versus op First is een compleet andere toren.

### 2.6 Abilities
Tier 4 en 5 upgrades geven vaak een handmatige ability met cooldown. Dat geeft de
speler iets te *doen* tijdens een ronde in een genre dat verder passief is, en
maakt een enkele piekronde overleefbaar zonder de baseline te verhogen.

### 2.7 Support als eigen categorie
Support-torens schalen niet met eigen DPS maar met de *rest van je bord*:
- radius-buff op range, rate, damage, of camo-detectie
- korting op aankopen binnen radius
- tijdelijke buffs die je op een specifieke toren richt
- economie (zie hoofdstuk 4)

Dit zorgt voor **clustering**: torens willen bij elkaar staan, maar de map wil dat je
spreidt. Die spanning is gratis level design.

### 2.8 Hero
Eén held per potje, levelt automatisch mee per ronde, tot level 20. Kernidee:
- Je koopt hem één keer en hij wordt de rest van het potje gratis sterker.
- Vroeg plaatsen betekent meer levels maar minder geld voor je basisdefensie.
- Elke held herschrijft één regel van de game (eentje verdient geld in plaats van
  schade te doen, eentje schiet door muren heen, eentje is een frontline melee).

Een held is dus een **strategische identiteit**, geen sterkere toren.

---

## 3. Maps: de map is een torenpuzzel, niet een pad

Dit onderschatten de meeste TD clones. In BTD6 is de map minstens zo belangrijk als
de toren. Ontwerpassen:

### 3.1 Plaatsbaarheid
Land, water en "verhoogd" zijn aparte terreintypes. Sommige torens *moeten* in het
water. Een map zonder water schrapt in één klap een hele torenklasse uit je build.
Dat is geen bug, dat is de map-identiteit.

### 3.2 Line of sight
Obstakels blokkeren zicht, niet alleen plaatsing. Gevolg: een toren met enorme range
kan waardeloos zijn achter een heuvel, terwijl een mortier (die op een vast punt
schiet) juist bloeit. Dit maakt elke map een andere metagame met dezelfde torens.

### 3.3 Betaalbare terreinverandering
Obstakels zijn vaak te verwijderen voor geld (van 250 tot 2000 per stuk, één map
kost 12550 om helemaal vrij te maken). Dit is briljant omdat het **map design en
economie aan elkaar knoopt**: ruimte kopen concurreert direct met torens kopen.

Varianten die ze gebruiken:
- pad verlengen of vijanden vertragen tegen een oplopende prijs per gebruik
- platformen die alleen een bepaalde torenklasse mogen dragen
- verborgen water dat pas vrijkomt na het opruimen van iets

### 3.4 Padtopologie
Assen die ze varieren, elk met een eigen strategische consequentie:

| Variant | Gevolg voor de speler |
|---|---|
| Eén lang kronkelend pad | Chokepoint-optimalisatie, hoge waarde per toren |
| Kort pad | Weinig tijd om schade te doen, DPS-dichtheid telt |
| Meerdere lanes tegelijk | Je verdediging moet gesplitst, geen mega-cluster |
| Alternerende ingangen per ronde | Je kunt niet alles op één punt zetten |
| Aparte lane alleen voor luchtschepen | Late game verandert de map, niet alleen de vijand |
| Pad dat pas na ronde 39 opengaat | Ingebouwde midgame twist |
| Bewegende platformen / roterende map | Je build moet elke ronde opnieuw kloppen |
| Terrein dat instort en torens vernietigt | Plaatsing wordt een risico-afweging |

### 3.5 Moeilijkheidsgraden van maps
Beginner / Intermediate / Advanced / Expert. De moeilijkheid zit in *ruimte en zicht*,
niet in sterkere vijanden. Expert maps hebben vier ingangen, korte paden, weinig
plaatsingsruimte. Dezelfde vijanden, andere puzzel. Ook dit is contentvermenigvuldiging.

---

## 4. Economie: het beste deel, en het minst gekopieerde

### 4.1 De twee basisstromen
1. **Per pop**: ongeveer 1 per gepopte laag. Dit schaalt bewust *omlaag* in latere
   rondes (0.5 na ronde 50, 0.2 na 60, 0.1 na 85, 0.05 na 100, 0.02 na 120), want
   het aantal lagen per ronde schiet omhoog. Zonder die demping explodeert je
   economie vanzelf.
2. **Einde ronde**: 100 + rondenummer. Lineair, voorspelbaar, en het maakt "overleven"
   op zich al winstgevend.

Merk op: bron 1 beloont *veel raken*, bron 2 beloont *de ronde halen*. Dat zijn twee
verschillende speelstijlen die allebei betaald worden.

### 4.2 De investeringslaag
Een aparte economie-toren die niets doodt maar geld genereert. Drie paden, drie
economische filosofieen:

| Pad | Mechanic | Speelgevoel |
|---|---|---|
| Productie | Meer waarde per oogst, tot 5 kratten van 1200 per ronde | Simpel, lineair, hoge cap |
| Bank | Slaat op met 15% samengestelde rente per ronde, cap 7000, moet je legen | Timing, geduld, snowball |
| Markt | Automatisch, lager per ronde, buft andere geldbronnen | Passief, synergie |

Die middelste is de interessantste. Rente op een opgeslagen saldo betekent: te vroeg
innen is verlies, te laat innen is verlies (want vol = productie stopt). Dat is een
**actief economisch minigame** binnen een tower defense.

Het tier 4 van dat pad geeft je een lening van 10000 direct, waarbij 50% van je
toekomstige inkomen naar de schuld gaat. Dat is een echte financiele beslissing:
liquiditeit nu tegen rendement later.

### 4.3 De spanning die het hele spel draagt
Elke euro die je in economie stopt, staat niet in verdediging. Elke ronde die je
overleeft met te weinig verdediging, was een gratis rentepercentage. Dat is de
**greed curve**, en die is de motor van het hele spel. Speel je te veilig, dan haal
je de late game niet omdat je te arm bent. Speel je te gulzig, dan lek je op ronde 40.

Als je game deze spanning niet heeft, is er geen interessante beslissing meer over.

### 4.4 Return on investment als balansmetriek
Elke economische aankoop moet je kunnen uitdrukken als:

```
ROI in rondes = kosten / (inkomen per ronde)
```

en afzetten tegen de resterende rondes. Een investering die zich pas terugverdient
na ronde 80 in een potje van 60 rondes is per definitie slecht. Dit is de check die
je op *elke* eco-upgrade moet doen, en het is de reden dat verkoopwaarde (rond de
70 tot 80% terug) belangrijk is: je kunt tijdelijk in economie zitten en op tijd
uitstappen naar verdediging.

### 4.5 Kosten aan de andere kant
- Kortingsbronnen (support-toren die alles in radius goedkoper maakt) zijn *ook*
  economie, maar niet-extrapolerend: ze geven een vast bedrag terug, geen groei.
  Daarom mogen ze in modes bestaan waar echt inkomen verboden is.
- Prijsmodifiers per moeilijkheid: makkelijk -15%, normaal 0%, moeilijk +8%,
  extreem +20%. Eén getal dat de hele economie herschaalt, zonder één tabel aan te
  raken.

### 4.6 Modes die de economie testen
- **Half Cash**: alle inkomen gehalveerd. Test of je economie te vlak is.
- **Deflation**: vast startbedrag, geen inkomen ooit. Test of je torens op zichzelf
  interessant zijn.
- **CHIMPS**: geen extra inkomen, geen verkopen, geen powers, één leven. De ultieme
  test, en meteen de reden dat verkoopwaarde en eco-torens niet te sterk mogen zijn.

Als je in je eigen game een "geen economie" mode kunt aanzetten en het spel valt
volledig uit elkaar, weet je dat je economie een pleister is voor zwakke torens.

---

## 5. Rondestructuur en moeilijkheid

- Rondes zijn **vast en handgemaakt**, niet procedureel. Speler leert ze uit het
  hoofd, en dat leren is de progressie.
- Elke ronde introduceert iets, of test iets dat net geintroduceerd is.
- Moeilijkheid wordt niet met andere rondes gemaakt maar met **globale modifiers**:
  levens (200 / 150 / 100 / 1), startrondenummer (1 / 1 / 3 / 6), vijandsnelheid
  (-9% / 0% / +13%), kostenmodifier, en eindronde (40 / 60 / 80 / 100).
- Speciale modi hergebruiken alles: alleen één torenklasse, omgekeerde richting,
  non-stop rondes zonder pauze, dubbele HP op luchtschepen, andere rondenvolgorde.

Elk van die modi is een paar regels code en levert een nieuwe leerervaring op.
Dit is de goedkoopste replay value die er bestaat.

Na de eindronde volgt freeplay met exponentiele schaling, waarbij normale vijanden
nog maar één kind spawnen zodat de RBE niet compleet ontploft.

---

## 6. Meta-progressie (buiten het potje)

- **XP per torentype**, apart per toren, om upgrades permanent te unlocken. Je kunt
  sparen en een pad diep induiken. Je speelt met wat je gebruikt.
- **Zachte valuta** voor helden, powers en cosmetica, met een sterk verlaagde
  uitbetaling na de eerste keer dat je een map/moeilijkheid haalt (anti-grinding).
- **Knowledge points** in een skilltree met kleine globale bonussen, die uitgezet
  worden in de puurste modes zodat competitieve runs eerlijk blijven.
- **Medals en borders** per map per mode: een compleetheidsdoel dat niets aan power
  toevoegt.

Belangrijk principe: **meta-progressie mag nooit de moeilijkste content trivialiseren.**
Daarom is er precies één mode waar alle meta uit staat.

---

## 7. Checklist voor je eigen game

Loop dit af. Elk "nee" is een verbeterpunt.

**Vijanden**
- [ ] Splitsen vijanden in kleinere vijanden, of is het een platte healthbar?
- [ ] Heb ik een meetgetal per ronde (totale HP-equivalent) om te balanceren?
- [ ] Zijn snelheid en taaiheid losgekoppelde assen?
- [ ] Heb ik minstens drie immuniteiten die elk een andere mono-build straffen?
- [ ] Heb ik orthogonale vlaggen (onzichtbaar / regeneratie / versterkt) die overerven?
- [ ] Is er een klasse-breuk halverwege die mijn build ongeldig maakt?
- [ ] Is er een late-game vijand die drie eerdere lessen combineert?

**Torens**
- [ ] Kan een toren maar één pad diep, met een beperkte crosspath?
- [ ] Is elke upgrade onherroepelijk?
- [ ] Zit elke toren in een duidelijk profiel op de as damage/pierce/rate?
- [ ] Is er een limiet op het aantal topupgrades op het veld?
- [ ] Heb ik torenklassen, en gebruik ik ze voor modes en buffs?
- [ ] Kan de speler richtprioriteit instellen?
- [ ] Zijn er handmatige abilities met cooldown?
- [ ] Heb ik supporttorens die schalen met de rest van het bord?

**Maps**
- [ ] Zijn er meerdere terreintypes met eigen torenrestricties?
- [ ] Blokkeren obstakels zicht en niet alleen plaatsing?
- [ ] Kan de speler terrein kopen, en concurreert dat met torens kopen?
- [ ] Varieer ik padtopologie (lanes, splits, alternerende ingangen, latere paden)?
- [ ] Zit map-moeilijkheid in ruimte en zicht, niet in sterkere vijanden?

**Economie**
- [ ] Heb ik twee onafhankelijke inkomstenstromen die verschillend gedrag belonen?
- [ ] Dempt inkomen per kill in latere rondes?
- [ ] Is er een investeringstoren met minstens twee verschillende filosofieen?
- [ ] Is er een timing-mechanic (rente, opslag, lening) en niet alleen passief inkomen?
- [ ] Kan ik van elke eco-aankoop de ROI in rondes uitrekenen?
- [ ] Is verkoopwaarde zo dat tijdelijk investeren een echte strategie is?
- [ ] Werkt mijn spel nog als ik alle extra inkomen uitzet?

**Structuur**
- [ ] Zijn rondes handgemaakt en leerbaar?
- [ ] Maak ik moeilijkheid met globale modifiers in plaats van nieuwe rondes?
- [ ] Heb ik minstens vier modes die bestaande content hergebruiken?
- [ ] Trivialiseert mijn meta-progressie de hardste mode niet?
