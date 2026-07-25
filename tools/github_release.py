#!/usr/bin/env python3
"""Maakt (of hergebruikt) een GitHub Release en uploadt de assets.

Alleen de standaardbibliotheek — geen pip-afhankelijkheden en geen `gh` nodig.

Token: Contents "read and write" op deze repo, gelezen uit $GITHUB_TOKEN of
~/.config/makkers/github_token. Een fijnmazig token dat alléén deze repo mag beschrijven is
ruim voldoende; geef het niet meer rechten dan dat.

De release-notes komen uit CHANGELOG.md (de sectie van deze versie), zodat de GitHub-pagina
hetzelfde vertelt als het update-scherm in de game en de site.
"""

import argparse
import json
import mimetypes
import os
import pathlib
import sys
import urllib.error
import urllib.request

API = "https://api.github.com"
UPLOADS = "https://uploads.github.com"
ROOT = pathlib.Path(__file__).resolve().parent.parent
TOKEN_FILE = pathlib.Path.home() / ".config" / "makkers" / "github_token"


def token() -> str:
    t = os.environ.get("GITHUB_TOKEN", "").strip()
    if not t and TOKEN_FILE.exists():
        t = TOKEN_FILE.read_text(encoding="utf-8").strip()
    if not t:
        sys.exit(
            "!! Geen GitHub-token gevonden.\n"
            f"   Zet 'm in {TOKEN_FILE} (chmod 600) of in $GITHUB_TOKEN.\n"
            "   Maak 'm aan op https://github.com/settings/personal-access-tokens/new :\n"
            "   fine-grained, alleen deze repo, permission 'Contents: Read and write'."
        )
    return t


def call(method: str, url: str, data=None, headers=None, raw: bytes = None):
    h = {
        "Authorization": f"Bearer {token()}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "ctrl-alt-defend-release",
    }
    h.update(headers or {})
    body = raw if raw is not None else (json.dumps(data).encode() if data is not None else None)
    if data is not None and raw is None:
        h["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            payload = r.read()
            return json.loads(payload) if payload else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:400]
        sys.exit(f"!! GitHub {method} {url} -> {e.code}\n   {detail}")


def notes_for(version: str) -> str:
    """De changelog-sectie van deze versie, als markdown-lijst."""
    items, inside = [], False
    for raw in (ROOT / "CHANGELOG.md").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line.startswith("## v"):
            if inside:
                break
            inside = line[4:].split()[0].strip("—–- ") == version
        elif inside and line.startswith("- "):
            items.append(line)
    body = "\n".join(items) if items else "_Geen changelog-punten gevonden._"
    return (
        f"{body}\n\n---\n\nUnzip and run `CTRL-ALT-DEFEND.exe`. Windows SmartScreen will warn "
        "about the unsigned build: **More info -> Run anyway**.\n\n"
        "The game checks for updates on startup, so this is the last version you need to "
        "download by hand. Checksums are on https://game.makkers.net/changelog.html"
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--tag", required=True)
    ap.add_argument("--assets", nargs="+", required=True)
    a = ap.parse_args()
    version = a.tag.lstrip("v")

    # Bestaat de release al (bijvoorbeeld na een mislukte poging)? Dan hergebruiken we 'm,
    # zodat opnieuw draaien geen tweede release van dezelfde versie oplevert.
    try:
        rel = call("GET", f"{API}/repos/{a.repo}/releases/tags/{a.tag}")
        print(f"   bestaande release {a.tag} hergebruikt")
    except SystemExit:
        rel = None
    if not rel:
        rel = call(
            "POST",
            f"{API}/repos/{a.repo}/releases",
            {
                "tag_name": a.tag,
                "name": f"CTRL-ALT-DEFEND {a.tag}",
                "body": notes_for(version),
                "draft": False,
                "prerelease": True,  # alpha
            },
        )
        print(f"   release {a.tag} aangemaakt")

    existing = {asset["name"]: asset["id"] for asset in rel.get("assets", [])}
    for path_str in a.assets:
        p = pathlib.Path(path_str)
        if not p.exists():
            sys.exit(f"!! asset ontbreekt: {p}")
        # Een asset met dezelfde naam moet eerst weg, anders hangt GitHub er "-1" achter.
        if p.name in existing:
            call("DELETE", f"{API}/repos/{a.repo}/releases/assets/{existing[p.name]}")
        ctype = mimetypes.guess_type(p.name)[0] or "application/octet-stream"
        call(
            "POST",
            f"{UPLOADS}/repos/{a.repo}/releases/{rel['id']}/assets?name={p.name}",
            raw=p.read_bytes(),
            headers={"Content-Type": ctype},
        )
        print(f"   geüpload: {p.name} ({p.stat().st_size / 1048576:.1f} MB)")

    print(f"   https://github.com/{a.repo}/releases/tag/{a.tag}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
