extends RefCounted
# Leest res://changelog.json: [{version, date, items[]}], nieuwste eerst.
#
# Dat bestand wordt door tools/gen_release_files.py gegenereerd uit CHANGELOG.md — de enige
# bron van waarheid, die ook de site en version.json voedt. CHANGELOG.md zélf meeleveren kan
# niet: het export-preset sluit `*.md` uit en dat exclude-filter wint van het include-filter.

const PATH := "res://changelog.json"


static func entries() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return []
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return []
	var list = data.get("entries", [])
	return list if typeof(list) == TYPE_ARRAY else []


static func items_for(version: String) -> Array:
	for e in entries():
		if str(e.get("version", "")) == version:
			return e.get("items", [])
	return []
