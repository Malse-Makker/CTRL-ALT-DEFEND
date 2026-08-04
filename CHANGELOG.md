# Changelog — CTRL-ALT-DEFEND

Dit bestand is de **bron van waarheid** voor de changelog. Hij wordt op drie plekken getoond:
de website (`changelog.html`), het update-scherm in de game (`version.json`) en de
"What's New"-pagina in de game (via het gegenereerde changelog.json).

**Format — niet vrij invullen, er wordt op geparsed:**
- `## v<versie> — <datum>` begint een versie. De bovenste moet gelijk zijn aan `VERSION`.
- Regels die met `- ` beginnen zijn de punten van die versie.
- Schrijf **Engels** (in-game tekst is Engels) en speler-gericht: wat merkt een tester ervan?
  Interne refactors horen in `HANDOFF.md`, niet hier.

`tools/make_release.sh` leest dit bestand en weigert te releasen als de bovenste versie niet
overeenkomt met `VERSION`.

## v0.86.0 — 2026-08-04
- Every tower now has two side tracks on top of its normal 1-2-3 upgrades, and you may only go down one of them. OVERTIME ("just one more thing before I log off") makes it fire faster and then reach further. ESCALATION ("I'm going to have to loop in a few more people") makes it hit an extra target and then hit harder.
- Buying the first step of one track locks the other on that tower forever, so two Auto-Replies on the same floor can now be completely different towers. There is a small coloured marker under each tower showing which way it went.
- Side steps are cheap on purpose: half the tower's starting price for the first, the full price for the second. Auto-Reply is 7 and 14. This is where your spare change goes when you have 14 Coffee and nothing to buy.
- To give a sense of it: a maxed Auto-Reply does 12.5 damage per second. With Overtime it does 15.6 and reaches 180 instead of 150. With Escalation it does 15.6 against one target but 31.2 against a crowd. Same price, completely different answer depending on the floor.
- Coffee Machine, Keyboard Smash and Ctrl+Alt+Del have no side tracks.

## v0.85.0 — 2026-08-04
- New enemy: The Steering Committee. "A decision will be made about your decision." It arrives on level 6 behind a heavy shield that light hits bounce off, and when you finally crack it open it releases four Board Members - who are immune to every single tower that could crack a shield.
- This is deliberate. Up to now level 14 asked for the same defence as level 3, only more of it. From level 6 onwards you need both approaches standing at the same time.
- It shows up three times on Work From Home and once on the medior finale.

## v0.84.0 — 2026-08-04
- Towers now have an approach: WRITTEN (Auto-Reply, Quick Reply, Reply All, Self-Service, Delegation) or IN PERSON (Office Artillery, The Shredder, Thumbtacks, Pomodoro Timer, Keyboard Smash). It is shown in the shop and on the tower panel.
- Immunities target the approach instead of one specific tower. The Board Member is never actually in the building, so nothing in-person touches him at all; The Cold Caller does not read email, so nothing written does. Both used to shrug off exactly one tower, which you could ignore by owning almost any other.
- That also closes some holes: Shredder zones, Pomodoro bursts and Keyboard Smash never checked immunity at all, so they quietly hit enemies that were supposed to be immune.
- Hits that bounce off now flash white on the enemy, so "my tower is firing and nothing is happening" reads as the wrong weapon rather than a bug.
- Fixed: advice on the results screen ran off the right-hand edge of the screen if it was long. It now wraps.

## v0.83.0 — 2026-08-04
- Coffee rewards now scale with how much enemy you actually had to kill. They used to vary wildly: a Notification paid over three times more per point of health than an Old Guard, so which enemies a level happened to contain mattered more than how well you played. Swarms pay a little less per point, anything that demands a specific tool (shields, immunities, invisibility) pays a little more.
- The Old Guard is the big winner: 11 Coffee instead of 4.5, which finally matches what it costs you to bring the right tower.
- Level 15 is no longer unaffordable at the start. Its second wave used to demand more defence than you could possibly own.
- Three stars now also works on Release Night. That level starts you on 10 Focus, and three stars needed 90% of it, so losing a single point cost you the star. You can now lose up to 3. Normal levels are completely unchanged.
- Tidied up: selling always paid 60% but the number lived in three separate places, and five code comments described features as unfinished that have been done since v0.71.

## v0.82.0 — 2026-08-04
- Delegation works the other way round now: every hop hits HARDER than the last, because it keeps going further up the chain. Base damage is lower, so it is nearly useless against a lone target and brutal against a tight crowd. Company Policy goes from 4 to 37 damage per second depending purely on how packed the path is.
- Auto-Reply costs 14 instead of 10, and hits harder to match. Quick Reply costs 16 instead of 18. Auto-Reply used to be the only tower you could afford three of on wave one, which made the opening decision the same every single game.
- Quick Reply's description now warns you that its hits are far too light to dent a shield, which since the last version actually matters.
- Fixed: the tower panel was clamped to a fixed height, so on any tower in the lower half of the floor the Sell button fell off the bottom of the screen. It now measures itself.

## v0.81.0 — 2026-08-04
- The Old Guard's shield now works the way the game always claimed it did: hits under 10 damage bounce straight off it. Auto-Reply, Quick Reply, Self-Service, Reply All and Delegation cannot dent it no matter how many you build. Office Artillery, an upgraded Pomodoro Timer and Keyboard Smash can. Deflected hits flash white on the shield so you can see what is happening.
- Until now that shield was simply 30 extra hit points, so the tutorial was teaching you a rule the game did not actually have.
- The Motivational Poster now buffs the nearest towers automatically the moment you place it. It used to buff only towers you had clicked on afterwards, which was never explained anywhere, so buying one and doing nothing else did literally nothing. You can still click towers to choose your own; the panel shows whether it is on auto.

## v0.80.0 — 2026-08-04
- Towers now unlock one per level up to level 10, instead of two on level 1, three on level 2, one on level 3 and then all eight remaining ones at once on level 4. Every tower gets its own introduction on the floor where it makes the most sense: Quick Reply on the Meeting Room swarms, Thumbtacks in the Canteen where The Cleaner sweeps them away, Delegation in the Parking where the lanes are spread out.
- Because of that, the shop on level 1 now doubles as a roadmap: every locked tower shows the level it arrives on.
- No towers were removed and none were added. If you had already reached the later levels, your full toolkit is still there from level 10 onwards.

## v0.79.0 — 2026-08-04
- Starting Coffee now scales with the level: 40 on the first floor, 110 on the last. It used to be 45 everywhere, which was generous on level 1 and close to unplayable on the later floors, where wave 2 alone is heavier than the finale of level 1.
- Surviving a wave pays more the further you get. Payday used to be a flat 4 Coffee; it now grows with the wave number, so making it through a late wave is worth something on its own.
- Coffee from kills tapers off after wave 5, down to a floor of 40%. Late waves used to hand out far more Coffee than any defence could ever cost, which quietly made the second half of every level a formality.
- Fixed: on-screen messages were hidden behind the enemy panel, so half of every notification was unreadable while that panel was open.

## v0.78.0 — 2026-07-26
- When a run ends you now get a WHAT HURT YOU list: which enemies got through, how much Focus each of them actually cost you, and what to build against them next time.
- It is sorted by Focus lost rather than by headcount, so three Old Guards rank above twenty Notifications -- which is usually the thing you needed to know.

## v0.77.0 — 2026-07-26
- New "Give up" button when you leave a run: it takes you to the results screen with your stats instead of dropping you back at the menu with nothing. If a run is already lost you no longer have to rush waves just to reach the end.
- The early-wave warning now only appears when you are still doing well. Nobody needs a lecture while they are already losing.

## v0.76.0 — 2026-07-26
- You now start every level with 45 Coffee instead of 30. Thirty was exactly one Shredder and nothing else, so picking it meant losing before you began.
- Coffee Corner had 312 Nudges in it, up to 50 in a single wave, and the first swarm arrived on wave 2 while you still had one tower. That is 167 now, spread out, and the first swarm comes later.
- Calling a wave early now warns you when the board is already full. It still pays points, but waves stack, and it was cheerfully saying "nice" while burying you.

## v0.75.0 — 2026-07-25
- Click any tower you have placed and it now tells you what that particular tower has actually done: total damage dealt, and how much damage it earned per Coffee you put into it. Coffee Machines show what they have made.

## v0.74.0 — 2026-07-25
- The tutorial is meant to be beatable without losing any Focus now: smaller groups, more starting Coffee, and a fresh purse for every lesson.
- A pulsing arrow points at whatever the lesson is talking about -- the shop, the path, the speed buttons or a tower you placed.
- Fixed the Headphones lesson: it used to throw twenty Nudges at a tower that can only slow one thing at a time. It is six now, and the lesson says to pair it with Auto-Reply.
- The Old Guard lesson sends one tank instead of three, so you can actually watch the Artillery break the shield.
- Two new lessons: one for START, pause and the 1x-8x speeds, and one for opening a tower to upgrade it and set its targeting.

## v0.73.0 — 2026-07-25
- Feedback now has a SEND button: one click and it arrives with me, no copying, no files, no chasing.
- Copy and email still work exactly as before, in case sending fails or you would rather not.

## v0.72.0 — 2026-07-25
- Fixed the empty boxes for good: every symbol in the interface is now plain text or drawn. The START and pause buttons were the worst offenders.
- After finishing a level you can go straight to Retry or Next Level, not just back to the level select.
- The score summary no longer runs into the buttons, and the stars sit above it instead of through it.
- Recognition is now a fixed amount per level, unlocked by stars only: 3 stars pays the whole thing, 2 stars pays two thirds, and coming back later to improve pays only the difference. It no longer scales with score, which was handing out far too much.
- New hidden reward: finish a level without losing a single Focus and you get a big extra star and a Recognition bonus.
- Every tower now starts on First targeting, which is what you usually want.
- Level select: the stars sit centred under each level, and the Tutorial button no longer overlaps your rank.

## v0.71.0 — 2026-07-25
- Stars and the feedback vote arrows showed up as empty boxes on Linux/Proton. They are drawn now, so they look the same everywhere.
- Eat the Pizza: you can bite with a mouse click as well as the space bar.
- No Internet: there is now a reconnection bar that visibly jumps forward every time you dodge, so you can see that playing well actually shortens it. And the runner is a proper dinosaur.
- The phone call is now an actual phone that slides up and buzzes, with a red hang-up and a green answer button. Answering does not help.
- Sign here is now a five-page compliance document -- GDPR, acceptable use, security, health & safety, tone of voice -- with signature lines to click on every page.

## v0.70.0 — 2026-07-25
- The Art Room is readable again: it scrolls, everything has room, and nothing overlaps.
- It now shows all 14 towers (Pomodoro, Reply All and Ctrl+Alt+Del were missing) and lets you try all five mini-games, not just the projector.

## v0.69.0 — 2026-07-25
- The Shredder no longer deletes swarms: its damage is now shared out over everyone in the zone, so it slows things down and your damage towers finish the job.
- Buying another tower of a type you already own costs more each time, so upgrading is now worth it instead of spamming level 1 towers.
- You now get paid a little Coffee for every wave you survive, so a bad opening no longer locks you out of the run.
- The enemy list stays closed if you closed it. It used to pop back open every time a new enemy showed up.
- Sound starts a lot quieter. Turn it back up in Settings if you want.
- The Tutorial now sits at the top of the level select, on its own, instead of among the levels.
- Boss Rush and Endless are hidden until you make Specialist -- they are a reward, not a starting option.
- The colleagues question is now a list: every enemy with what it does, and a box to name the colleague who behaves like that.
- Website: links were dark blue on black. Readable now.

## v0.68.0 — 2026-07-25
- Focus and Coffee now have icons in the top bar -- a lightning bolt and a coffee cup -- so you can read your status at a glance.
- The tower shop now shows every tower's name, and lists them in the order you unlock them.
- Game speed goes 1x, 2x, 4x, 8x instead of 1x, 2x, 3x. Powers of two, as nature intended.

## v0.67.0 — 2026-07-25
- The download is now just CTRL-ALT-DEFEND.exe -- no zip, nothing to unpack. Download it and play.
- Updates download the new .exe directly too, so updating is one click and one file.
- The download button on the site always gives you the newest release.

## v0.66.0 — 2026-07-25
- The game is now called CTRL-ALT-DEFEND. Same game, better name.
- Downloads and updates now come from GitHub instead of my own server, which is a safer place to keep a program that updates itself.
- The source code is public at github.com/Malse-Makker/CTRL-ALT-DEFEND.

## v0.65.0 — 2026-07-25
- The rating after each level now asks how much FUN it was (0 = no fun, 10 = loved it) instead of how hard it was. The old question was ambiguous and the answers contradicted what people wrote.
- Feedback can now be emailed straight to games@makkers.net, on top of copy-paste and saving files.
- Your feedback now lists which version you played each level on, so old reports about already-fixed things can be spotted.
- New "What's New" page in the main menu with the full changelog.
- The main menu now shows a short build fingerprint you can check against the website.

## v0.64.0 — 2026-07-25
- The game checks for updates when it starts and can update itself.
- You choose how to update: automatic (the game replaces itself and restarts) or safe (it downloads the zip and you swap the file yourself).
- Downloads are verified against a checksum, so a corrupted download can never overwrite your game.

## v0.63.0 — 2026-07-25
- Feedback: new COPY ALL TO CLIPBOARD button, so you can paste it straight into Discord without wrestling with files.
- Fixed: the feedback export said "version: ?" instead of the version you played.
- Fixed: vote arrows now clearly turn green or red, so you can see your vote registered. Before this, votes looked like they did nothing.

## v0.62.0 — 2026-07-25
- First public alpha build for Windows, with a download page.

## v0.61.0 — 2026-07-25
- New Feedback page in the main menu: vote on the plans, tell us what is missing, and export it all.

## Earlier

The game was built up to v0.60.0 before the first alpha went out: 15 levels in three career
blocks with promotions, all towers, enemies and bosses, the map mechanics, and three extra
modes (Tutorial, Boss Rush, Endless). See `HANDOFF.md` for that history in detail.
