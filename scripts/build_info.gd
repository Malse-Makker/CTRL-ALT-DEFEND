extends RefCounted
# Korte vingerafdruk van de draaiende .exe, zodat een tester kan controleren dat hij echt de
# build speelt die op de site staat (die publiceert dezelfde sha256 onder Verify your download).
#
# Waarom een thread: sha256 over ~105 MB duurt kort maar merkbaar, en dat hoort niet in de
# opstart van het hoofdmenu te zitten. Het antwoord verandert niet tijdens een sessie, dus we
# rekenen het één keer uit en onthouden het.

static var _cached := ""
static var _thread: Thread = null


static func short() -> String:
	# "" = nog niet klaar; roep opnieuw aan (of gebruik start() + poll).
	return _cached


static func start() -> void:
	if _cached != "" or _thread != null:
		return
	if OS.has_feature("editor"):
		# In de editor is get_executable_path() de Godot-binary zelf: zegt niets over de build.
		_cached = "dev"
		return
	_thread = Thread.new()
	_thread.start(_compute)


static func _compute() -> void:
	var sum := FileAccess.get_sha256(OS.get_executable_path())
	_cached = sum.substr(0, 12) if sum != "" else "unknown"


static func done() -> bool:
	if _thread != null and not _thread.is_alive():
		_thread.wait_to_finish()
		_thread = null
	return _cached != ""


static func full() -> String:
	if OS.has_feature("editor"):
		return ""
	return FileAccess.get_sha256(OS.get_executable_path())
