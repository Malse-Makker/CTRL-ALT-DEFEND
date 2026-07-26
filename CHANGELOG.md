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
