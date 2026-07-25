#!/bin/bash
# Bouwt een Windows-release, publiceert 'm als GitHub Release en zet de site op OVH.
#
# We publiceren een KALE .exe, geen zip: testers hoeven dan niets uit te pakken en de
# downloadknop op de site kan rechtstreeks naar het bestand wijzen. De assetnaam is bewust
# vast (CTRL-ALT-DEFEND.exe, zonder versienummer), want alleen dan werkt het
# "releases/latest/download/<naam>"-adres -- en dat is wat de knop en de updater gebruiken,
# zodat er per release niets aan URL's bijgewerkt hoeft te worden.
#
# Gebruik:
#   tools/make_release.sh                 # bouwen, publiceren, uploaden
#   tools/make_release.sh --dry-run       # alles bouwen, niets publiceren of uploaden
#
# WAAROM DE BINARY OP GITHUB STAAT EN NIET OP DE EIGEN SERVER:
# de game update zichzelf. Wie de webserver overneemt, kan dus een kwaadaardige build bij
# iedere tester installeren -- en een checksum die op diezelfde server staat helpt daar niets
# tegen. GitHub Releases zet de binary achter een 2FA-account in plaats van achter een
# zelfbeheerde VPS met tien andere diensten erop. game.makkers.net blijft de nette voorkant:
# de downloadknop wijst naar het GitHub-asset van deze release.
#
# De updater haalt version.json op via het "latest"-adres van GitHub, dus die wijst altijd
# vanzelf naar de nieuwste release zonder dat er iets bijgewerkt hoeft te worden.
#
# TOKEN: publiceren vraagt een GitHub-token met Contents: read and write op deze repo.
# Zet 'm in ~/.config/makkers/github_token (chmod 600) of in $GITHUB_TOKEN.

set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
REMOTE="ubuntu@makkers.net"
REMOTE_DIR="/home/ubuntu/office-td"
SITE_URL="https://game.makkers.net"
REPO="Malse-Makker/CTRL-ALT-DEFEND"

cd "$GAME_DIR"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

VERSION="$(tr -d ' \n\r' < VERSION)"
TAG="v${VERSION}"
EXE_NAME="CTRL-ALT-DEFEND.exe"
RELEASE_BASE="https://github.com/${REPO}/releases/download/${TAG}"
LATEST_EXE="https://github.com/${REPO}/releases/latest/download/${EXE_NAME}"

# Vroeg falen als de changelog niet klopt (scheelt een build van 5 minuten) én changelog.json
# schrijven, want die moet in de export zitten.
python3 tools/gen_release_files.py --version "$VERSION" --check-only

echo "==> CTRL-ALT-DEFEND ${TAG}"

# 1. Schoon opstarten? Zo niet, dan heeft exporteren geen zin.
echo "==> Headless check"
OUTPUT="$("$GODOT" --headless --path . --quit-after 120 2>&1)"
if [[ "$(echo "$OUTPUT" | grep -vc '^Godot Engine')" -ne 0 ]]; then
	echo "$OUTPUT"
	echo "!! De headless test is niet schoon. Eerst repareren, dan pas releasen."
	exit 1
fi

# 2. Exporteren
echo "==> Exporteren"
mkdir -p build/windows
"$GODOT" --headless --path . --export-release "Windows" "build/windows/${EXE_NAME}" > /dev/null
[[ -f "build/windows/${EXE_NAME}" ]] || { echo "!! Export mislukt"; exit 1; }

# 3. Checksum + grootte van de .exe die we uitleveren
EXE_SHA="$(shasum -a 256 "build/windows/${EXE_NAME}" | cut -d' ' -f1)"
SIZE="$(wc -c < "build/windows/${EXE_NAME}" | tr -d ' ')"

# 4. version.json + changelog.html uit CHANGELOG.md.
#    De exe-URL wijst naar het asset van DEZE tag (niet 'latest'), zodat een update altijd
#    precies de versie installeert die in version.json beschreven staat.
echo "==> version.json + changelog"
python3 tools/gen_release_files.py \
	--version "$VERSION" --exe "$EXE_NAME" --exe-sha "$EXE_SHA" --size "$SIZE" \
	--exe-url "${RELEASE_BASE}/${EXE_NAME}" --site-url "$SITE_URL"

# 5. Downloadknop op de site naar het GitHub-asset laten wijzen
echo "==> Site bijwerken"
MB=$(( SIZE / 1048576 ))
sed -i '' -E \
	-e "s/alpha v[0-9]+\.[0-9]+\.[0-9]+/alpha v${VERSION}/" \
	-e "s#(<a class=\"dl\" href=)\"[^\"]*\"#\1\"${LATEST_EXE}\"#" \
	-e "s/Windows, [0-9]+ MB/Windows, ${MB} MB/" \
	deploy/public/index.html

if [[ "$DRY_RUN" -eq 1 ]]; then
	echo "==> --dry-run: niets gepubliceerd. Klaar in build/ en deploy/public/"
	exit 0
fi

# 6. GitHub Release: de .exe en version.json als assets
echo "==> GitHub Release ${TAG}"
python3 tools/github_release.py --repo "$REPO" --tag "$TAG" \
	--assets "build/windows/${EXE_NAME}" "deploy/public/version.json"

# 7. Site naar OVH (pagina's, geen binary meer)
echo "==> Site uploaden naar ${REMOTE}"
rsync -avz --delete deploy/public/ "${REMOTE}:${REMOTE_DIR}/public/" | tail -3
ssh "$REMOTE" "cd ${REMOTE_DIR} && docker compose up -d" > /dev/null 2>&1

echo "==> Controle"
curl -sfI -L "${LATEST_EXE}" -o /dev/null -w "latest exe: HTTP %{http_code}, %{size_download} bytes\n"
curl -sf "https://github.com/${REPO}/releases/latest/download/version.json" \
	| python3 -c 'import json,sys; d=json.load(sys.stdin); print("version.json (latest):", d["version"])'
curl -sf "${SITE_URL}/changelog.html" > /dev/null && echo "changelog.html OK"

echo
echo "Klaar: ${SITE_URL}  (${TAG})"
echo "Release:   https://github.com/${REPO}/releases/tag/${TAG}"
echo "Changelog: ${SITE_URL}/changelog.html"
