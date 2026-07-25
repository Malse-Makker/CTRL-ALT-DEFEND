#!/usr/bin/env python3
"""Genereert changelog.json, version.json en changelog.html uit CHANGELOG.md.

CHANGELOG.md is de enige bron van waarheid voor de changelog. Hij wordt op drie plekken
getoond, en die worden hier allemaal uit datzelfde bestand afgeleid zodat ze niet uit elkaar
kunnen lopen:

  changelog.json        -> res://changelog.json, gelezen door de "What's New"-pagina in de game
  version.json          -> het update-scherm (alleen de punten van de nieuwste versie)
  changelog.html        -> de changelog-pagina op de site, inclusief de checksums

Waarom changelog.json en niet CHANGELOG.md meeleveren: het export-preset sluit `*.md` uit, en
dat exclude-filter wint van het include-filter — de .md komt dus nooit mee in de build.

--check-only valideert en schrijft alleen changelog.json (nog geen versie-afhankelijke
bestanden). make_release.sh gebruikt dat vóór de build, zodat een fout in de changelog niet pas
na vijf minuten exporteren aan het licht komt.
"""

import argparse
import datetime
import html
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHANGELOG = ROOT / "CHANGELOG.md"
PUBLIC = ROOT / "deploy" / "public"

HEADING = re.compile(r"^##\s+v(?P<version>[0-9][^\s—–-]*)\s*[—–-]*\s*(?P<date>.*)$")


def parse_changelog():
    """-> [{version, date, items}] in bestandsvolgorde (nieuwste eerst)."""
    entries = []
    current = None
    for raw in CHANGELOG.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        m = HEADING.match(line)
        if m:
            current = {
                "version": m.group("version").strip(),
                "date": m.group("date").strip(),
                "items": [],
            }
            entries.append(current)
        elif line.startswith("- ") and current is not None:
            current["items"].append(line[2:].strip())
    return entries


def render_changelog_html(entries, version, zip_sha, exe_sha):
    rows = []
    for e in entries:
        items = "\n".join(
            f"      <li>{html.escape(i)}</li>" for i in e["items"]
        )
        current = ' class="current"' if e["version"] == version else ""
        date = f' <span class="date">{html.escape(e["date"])}</span>' if e["date"] else ""
        rows.append(
            f'  <section{current}>\n'
            f'    <h2>v{html.escape(e["version"])}{date}</h2>\n'
            f'    <ul>\n{items}\n    </ul>\n'
            f'  </section>'
        )
    body = "\n".join(rows)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CTRL-ALT-DEFEND — changelog</title>
<style>
  :root {{
    --bg: #1f2126; --panel: #2a2d34; --text: #e8e6e3; --dim: #9a9da6;
    --accent: #e7c84a; --green: #5fb98f;
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    background: var(--bg); color: var(--text);
    font-family: "Courier New", ui-monospace, monospace;
    line-height: 1.6; display: flex; flex-direction: column; min-height: 100vh;
  }}
  main {{ max-width: 680px; margin: 0 auto; padding: 48px 20px 32px; flex: 1; width: 100%; }}
  h1 {{ color: var(--accent); font-size: 1.6rem; letter-spacing: 1px; margin-bottom: 4px; }}
  .lead {{ color: var(--dim); margin-bottom: 28px; }}
  .back {{ display: inline-block; color: var(--dim); margin-bottom: 24px; }}
  section {{
    background: var(--panel); border-radius: 8px;
    padding: 16px 20px; margin-bottom: 14px;
  }}
  section.current {{ border-left: 3px solid var(--green); }}
  section h2 {{ font-size: 1rem; color: var(--accent); margin-bottom: 8px; }}
  section.current h2 {{ color: var(--green); }}
  .date {{ color: var(--dim); font-size: 0.8rem; font-weight: normal; }}
  ul {{ padding-left: 20px; }}
  li {{ font-size: 0.9rem; margin-bottom: 4px; }}
  .verify {{
    background: var(--panel); border-radius: 8px; padding: 16px 20px; margin-bottom: 24px;
  }}
  .verify h2 {{ font-size: 0.95rem; margin-bottom: 8px; }}
  .verify p {{ font-size: 0.85rem; color: var(--dim); margin-bottom: 8px; }}
  code {{
    display: block; background: #1a1c20; padding: 8px 10px; border-radius: 4px;
    font-family: inherit; font-size: 0.72rem; word-break: break-all; margin-bottom: 8px;
  }}
  footer {{ text-align: center; color: var(--dim); font-size: 0.8rem; padding: 24px 20px; }}
  footer a, .back {{ color: var(--dim); }}
</style>
</head>
<body>
<main>
  <a class="back" href="/">&larr; back to the download</a>
  <h1>CHANGELOG</h1>
  <p class="lead">Every version of CTRL-ALT-DEFEND, newest first. The game shows this
  same list under <em>What's New</em>.</p>

  <div class="verify">
    <h2>Verify your download (v{html.escape(version)})</h2>
    <p>SHA-256 of the zip:</p>
    <code>{html.escape(zip_sha)}</code>
    <p>SHA-256 of CTRL-ALT-DEFEND.exe — this is the one the game shows (first 12 characters)
    at the bottom of the main menu:</p>
    <code>{html.escape(exe_sha)}</code>
  </div>

{body}
</main>
<footer>
  Part of the <a href="https://projecten.makkers.net">makkers collection</a> —
  free hobby projects, non-commercial, made for fun and learning.
</footer>
</body>
</html>
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    ap.add_argument("--check-only", action="store_true",
                    help="valideer + schrijf alleen changelog.json (vóór de build)")
    ap.add_argument("--zip-name")
    ap.add_argument("--exe")
    ap.add_argument("--zip-sha")
    ap.add_argument("--exe-sha")
    ap.add_argument("--size", type=int)
    ap.add_argument("--zip-url")
    ap.add_argument("--site-url")
    a = ap.parse_args()

    entries = parse_changelog()
    if not entries:
        print("!! CHANGELOG.md bevat geen enkele '## v<versie>'-kop", file=sys.stderr)
        return 1

    # De bovenste sectie moet de versie zijn die we uitbrengen, anders krijgen testers de
    # changelog van een andere release te zien dan de build die ze installeren.
    if entries[0]["version"] != a.version:
        print(
            f"!! CHANGELOG.md begint met v{entries[0]['version']} maar VERSION zegt {a.version}.\n"
            f"   Zet een '## v{a.version} — {datetime.date.today().isoformat()}'-sectie bovenaan.",
            file=sys.stderr,
        )
        return 1
    if not entries[0]["items"]:
        print(f"!! De sectie voor v{a.version} heeft geen enkel punt.", file=sys.stderr)
        return 1

    # Gaat mee in de build (res://changelog.json) en voedt de "What's New"-pagina.
    (ROOT / "changelog.json").write_text(
        json.dumps({"entries": entries}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    if a.check_only:
        print(f"   changelog.json geschreven ({len(entries)} versies), changelog OK")
        return 0

    missing = [n for n in ("zip_name", "exe", "zip_sha", "exe_sha", "size", "zip_url", "site_url")
               if getattr(a, n) is None]
    if missing:
        print(f"!! ontbrekende argumenten: {', '.join(missing)}", file=sys.stderr)
        return 1

    PUBLIC.mkdir(parents=True, exist_ok=True)
    (PUBLIC / "version.json").write_text(
        json.dumps(
            {
                "version": a.version,
                "date": datetime.date.today().isoformat(),
                "zip": a.zip_url,
                "exe": a.exe,
                "sha256": a.zip_sha,
                "exe_sha256": a.exe_sha,
                "size": a.size,
                "changes": entries[0]["items"],
                "changelog_url": f"{a.site_url}/changelog.html",
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    (PUBLIC / "changelog.html").write_text(
        render_changelog_html(entries, a.version, a.zip_sha, a.exe_sha), encoding="utf-8"
    )
    print(f"   changelog.json + version.json + changelog.html geschreven ({len(entries)} versies)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
