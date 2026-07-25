# CTRL-ALT-DEFEND

*I'll Put This With the Rest of the Focus.*

A top-down pixel-art tower defense about defending your workday. Meetings that could have been
an email, reply-all storms, consultants and the printer march down the corridor toward your
desk. You hold them off with coffee machines, headphones, a shredder and the office artillery.

Built in Godot 4.7. In-game language is English; development notes are in Dutch.

**[Download the alpha →](https://game.makkers.net)**

## Status: alpha — playable, unfinished on purpose

Everything works: 15 levels across three career blocks (junior → medior → senior) with
promotions, 14 towers, ~20 enemy types, a boss per level, map mechanics (obstacles, sight
walls, pay-to-build zones, corridor building, revealed lanes), five interactive mini-games,
and three extra modes (Tutorial, Boss Rush, Endless).

Deliberately not done yet:

- **Art.** The maps are greybox — grey floors and coloured blocks. Towers and enemies do have
  sprites.
- **Audio.** Procedurally generated, no audio files. Needs expanding.
- **Balance.** Every number is calculated but barely play-tested. That is what the alpha is for.

## Playing

Grab the zip from [game.makkers.net](https://game.makkers.net), unzip it, run
`CTRL-ALT-DEFEND.exe`. Windows SmartScreen warns about the unsigned build: *More info → Run
anyway*. On Linux it runs through Proton or Wine. The game checks for updates on startup, so
you only download by hand once.

From source:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## Feedback

That is the whole point of the alpha. Main menu → **Feedback**: rate how much fun each level
was, vote on the plans, write what you would change. Then copy it to your clipboard and paste
it into Discord, or mail it to games@makkers.net. Playtest data stays on your own machine
until you send it yourself.

## Repository

```
scripts/       the game (app, level, tower, enemy, mini-games, updater, telemetry)
art/           sprites + STYLE_GUIDE.md
tools/         release script, sprite pipeline, balance report
deploy/        the download site and its docker/nginx setup
CHANGELOG.md   source of truth for the changelog (game, site and update screen)
HANDOFF.md     development notes, pitfalls and the full to-do list
```

Releasing is one command (`tools/make_release.sh`): it builds, packs, checksums, publishes a
GitHub Release and updates the site.

## Disclaimer

Hobby project, in development, built with the help of AI as a way to learn. Non-commercial.
Part of the [makkers collection](https://projecten.makkers.net).
