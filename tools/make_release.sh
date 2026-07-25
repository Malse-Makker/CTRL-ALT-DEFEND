#!/bin/bash
# Bouwt een Windows-release, publiceert 'm als GitHub Release en zet de site op OVH.
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
ZIP_NAME="CTRL-ALT-DEFEND_v${VERSION}_alpha_windows.zip"
EXE_NAME="CTRL-ALT-DEFEND.exe"
RELEASE_BASE="https://github.com/${REPO}/releases/download/${TAG}"

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

# 3. Inpakken (de spelers-README komt uit deploy/, want build/ zit niet in de repo)
echo "==> Inpakken"
sed -E "s/alpha v[0-9]+\.[0-9]+\.[0-9]+/alpha v${VERSION}/" deploy/player_readme.txt > build/windows/README.txt
rm -f "build/${ZIP_NAME}"
(cd build/windows && zip -q -X "../${ZIP_NAME}" "${EXE_NAME}" README.txt)

SHA="$(shasum -a 256 "build/${ZIP_NAME}" | cut -d' ' -f1)"
SIZE="$(wc -c < "build/${ZIP_NAME}" | tr -d ' ')"
EXE_SHA="$(shasum -a 256 "build/windows/${EXE_NAME}" | cut -d' ' -f1)"

# 4. version.json + changelog.html uit CHANGELOG.md.
#    De zip-URL wijst naar het GitHub-asset van deze tag; dat adres bestaat zodra stap 6 klaar is.
echo "==> version.json + changelog"
python3 tools/gen_release_files.py \
	--version "$VERSION" --zip-name "$ZIP_NAME" --exe "$EXE_NAME" \
	--zip-sha "$SHA" --exe-sha "$EXE_SHA" --size "$SIZE" \
	--zip-url "${RELEASE_BASE}/${ZIP_NAME}" --site-url "$SITE_URL"

# 5. Downloadknop op de site naar het GitHub-asset laten wijzen
echo "==> Site bijwerken"
MB=$(( SIZE / 1048576 ))
sed -i '' -E \
	-e "s/alpha v[0-9]+\.[0-9]+\.[0-9]+/alpha v${VERSION}/" \
	-e "s#href=\"[^\"]*CTRL-ALT-DEFEND_v[^\"]*\.zip\"#href=\"${RELEASE_BASE}/${ZIP_NAME}\"#g" \
	-e "s/Windows, [0-9]+ MB/Windows, ${MB} MB/" \
	deploy/public/index.html

if [[ "$DRY_RUN" -eq 1 ]]; then
	echo "==> --dry-run: niets gepubliceerd. Klaar in build/ en deploy/public/"
	exit 0
fi

# 6. GitHub Release: de zip en version.json als assets
echo "==> GitHub Release ${TAG}"
python3 tools/github_release.py --repo "$REPO" --tag "$TAG" \
	--assets "build/${ZIP_NAME}" "deploy/public/version.json"

# 7. Site naar OVH (pagina's, geen binary meer)
echo "==> Site uploaden naar ${REMOTE}"
rsync -avz --delete deploy/public/ "${REMOTE}:${REMOTE_DIR}/public/" | tail -3
ssh "$REMOTE" "cd ${REMOTE_DIR} && docker compose up -d" > /dev/null 2>&1

echo "==> Controle"
curl -sfI "${RELEASE_BASE}/${ZIP_NAME}" | head -1
curl -sf "https://github.com/${REPO}/releases/latest/download/version.json" \
	| python3 -c 'import json,sys; d=json.load(sys.stdin); print("version.json (latest):", d["version"])'
curl -sf "${SITE_URL}/changelog.html" > /dev/null && echo "changelog.html OK"

echo
echo "Klaar: ${SITE_URL}  (${TAG})"
echo "Release:   https://github.com/${REPO}/releases/tag/${TAG}"
echo "Changelog: ${SITE_URL}/changelog.html"
