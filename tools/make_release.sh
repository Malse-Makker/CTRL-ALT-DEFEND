#!/bin/bash
# Bouwt een Windows-release, pakt 'm in en zet 'm samen met version.json op de OVH-server.
#
# Gebruik:
#   tools/make_release.sh                 # changelog uit CHANGELOG_NEXT.md
#   tools/make_release.sh --dry-run       # alles bouwen, niets uploaden
#
# De game leest version.json bij het opstarten (scripts/updater.gd). Daarom worden versie,
# checksum en download-URL hier op één plek gegenereerd — handmatig bijwerken loopt gegarandeerd
# een keer uit de pas met de zip die er echt staat.

set -euo pipefail

GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
REMOTE="ubuntu@makkers.net"
REMOTE_DIR="/home/ubuntu/office-td"
BASE_URL="https://game.makkers.net"

cd "$GAME_DIR"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

VERSION="$(tr -d ' \n\r' < VERSION)"
# Vroeg falen als de changelog niet klopt (scheelt een build van 5 minuten) én changelog.json
# schrijven, want die moet in de export zitten.
python3 tools/gen_release_files.py --version "$VERSION" --check-only
ZIP_NAME="OfficeTowerDefense_v${VERSION}_alpha_windows.zip"
EXE_NAME="OfficeTowerDefense.exe"

echo "==> Office Tower Defense v${VERSION}"

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

# 3. Inpakken (README meeleveren; versie erin bijwerken)
echo "==> Inpakken"
sed -i '' -E "s/alpha v[0-9]+\.[0-9]+\.[0-9]+/alpha v${VERSION}/" build/windows/README.txt
rm -f "build/${ZIP_NAME}"
(cd build/windows && zip -q -X "../${ZIP_NAME}" "${EXE_NAME}" README.txt)

SHA="$(shasum -a 256 "build/${ZIP_NAME}" | cut -d' ' -f1)"
SIZE="$(wc -c < "build/${ZIP_NAME}" | tr -d ' ')"

# 4. version.json + changelog-pagina — beide uit CHANGELOG.md, de enige bron van waarheid
echo "==> version.json + changelog"
EXE_SHA="$(shasum -a 256 "build/windows/${EXE_NAME}" | cut -d' ' -f1)"
python3 tools/gen_release_files.py \
	--version "$VERSION" --zip-name "$ZIP_NAME" --exe "$EXE_NAME" \
	--zip-sha "$SHA" --exe-sha "$EXE_SHA" --size "$SIZE" --base-url "$BASE_URL"

# 5. Klaarzetten in deploy/public (oude zip weg, downloadpagina bijwerken)
echo "==> Site bijwerken"
rm -f deploy/public/OfficeTowerDefense_v*_alpha_windows.zip
cp "build/${ZIP_NAME}" deploy/public/
MB=$(( SIZE / 1048576 ))
sed -i '' -E \
	-e "s/alpha v[0-9]+\.[0-9]+\.[0-9]+/alpha v${VERSION}/" \
	-e "s#OfficeTowerDefense_v[0-9]+\.[0-9]+\.[0-9]+_alpha_windows\.zip#${ZIP_NAME}#g" \
	-e "s/Windows, [0-9]+ MB/Windows, ${MB} MB/" \
	deploy/public/index.html

if [[ "$DRY_RUN" -eq 1 ]]; then
	echo "==> --dry-run: niet geüpload. Klaar in deploy/public/"
	exit 0
fi

# 6. Uploaden
echo "==> Uploaden naar ${REMOTE}"
rsync -avz --delete deploy/ "${REMOTE}:${REMOTE_DIR}/" | tail -3
ssh "$REMOTE" "cd ${REMOTE_DIR} && docker compose up -d" > /dev/null 2>&1

echo "==> Controle"
curl -sf "${BASE_URL}/version.json" | python3 -m json.tool | head -8
curl -sfI "${BASE_URL}/${ZIP_NAME}" | head -1

curl -sf "${BASE_URL}/changelog.html" > /dev/null && echo "changelog.html OK"

echo
echo "Klaar: ${BASE_URL}  (v${VERSION})"
echo "Changelog: ${BASE_URL}/changelog.html"
