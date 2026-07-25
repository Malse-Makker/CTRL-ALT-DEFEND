# Changelog — Office Tower Defense

Dit bestand is de **bron van waarheid** voor de changelog. Hij wordt op drie plekken getoond:
de website (`changelog.html`), het update-scherm in de game (`version.json`) en de
"What's New"-pagina in de game (leest dit bestand rechtstreeks).

**Format — niet vrij invullen, er wordt op geparsed:**
- `## v<versie> — <datum>` begint een versie. De bovenste moet gelijk zijn aan `VERSION`.
- Regels die met `- ` beginnen zijn de punten van die versie.
- Schrijf **Engels** (in-game tekst is Engels) en speler-gericht: wat merkt een tester ervan?
  Interne refactors horen in `HANDOFF.md`, niet hier.

`tools/make_release.sh` leest dit bestand en weigert te releasen als de bovenste versie niet
overeenkomt met `VERSION`.

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
