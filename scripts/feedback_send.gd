extends Node
# Stuurt de feedback als tekstbestand naar een Discord-webhook, zodat een tester alleen op
# een knop hoeft te drukken.
#
# WAAROM DISCORD EN GEEN EIGEN ENDPOINT: alles wat je meelevert in de .exe is eruit te halen,
# dus de vraag is niet of iemand het adres kan vinden maar wat hij ermee kan. Bij een webhook
# is dat "rommel in één kanaal posten" -- je gooit 'm weg, maakt een nieuwe en brengt een
# versie uit. Een endpoint op de eigen server zou daar een blijvend aanvalsoppervlak van maken.
#
# DE URL STAAT NIET IN DE REPO. Hij komt uit res://feedback_target.json, dat in .gitignore
# staat en alleen mee de build in gaat. Stond hij in de code, dan kon iedereen die de publieke
# repo bekijkt het kanaal volspammen zonder de game ook maar te downloaden.
#
# Ontbreekt het bestand of is het leeg, dan is send_available() false en toont de
# feedbackpagina de knop niet -- kopiëren en mailen blijven altijd werken.

signal done(ok: bool, message: String)

const TARGET_PATH := "res://feedback_target.json"
const MAX_BYTES := 900000        # Discord accepteert meer, maar dit is ruim voor tekst

var _http: HTTPRequest = null


static func webhook_url() -> String:
	if not FileAccess.file_exists(TARGET_PATH):
		return ""
	var f := FileAccess.open(TARGET_PATH, FileAccess.READ)
	if f == null:
		return ""
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY:
		return ""
	var url: String = str(d.get("discord_webhook", "")).strip_edges()
	return url if url.begins_with("https://") else ""


static func send_available() -> bool:
	return webhook_url() != ""


func send(body_text: String, player: String, version: String) -> void:
	var url := webhook_url()
	if url == "":
		done.emit(false, "No send target configured in this build.")
		return
	var data := body_text.to_utf8_buffer()
	if data.size() > MAX_BYTES:
		data = data.slice(0, MAX_BYTES)

	# Discord wil multipart/form-data; een bericht mag maar 2000 tekens en de feedback is
	# ruim 7000, dus hij gaat als bestandsbijlage mee in plaats van als berichttekst.
	var boundary := "CADboundary%d" % Time.get_ticks_msec()
	var payload := JSON.stringify({
		"content": "New playtest feedback - v%s - %s" % [version, player],
		"username": "CTRL-ALT-DEFEND",
	})
	var pre := ""
	pre += "--%s\r\n" % boundary
	pre += "Content-Disposition: form-data; name=\"payload_json\"\r\n"
	pre += "Content-Type: application/json\r\n\r\n"
	pre += payload + "\r\n"
	pre += "--%s\r\n" % boundary
	pre += "Content-Disposition: form-data; name=\"files[0]\"; filename=\"feedback_%s.txt\"\r\n" % player
	pre += "Content-Type: text/plain; charset=utf-8\r\n\r\n"
	var post := "\r\n--%s--\r\n" % boundary

	var body := PackedByteArray()
	body.append_array(pre.to_utf8_buffer())
	body.append_array(data)
	body.append_array(post.to_utf8_buffer())

	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	var headers := ["Content-Type: multipart/form-data; boundary=%s" % boundary]
	if _http.request_raw(url, headers, HTTPClient.METHOD_POST, body) != OK:
		_cleanup()
		done.emit(false, "Could not reach the server. Check your internet connection.")


func _on_done(_result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_cleanup()
	# Discord antwoordt 200 of 204 op een geslaagde webhook-post.
	if code == 200 or code == 204:
		done.emit(true, "Sent! Thanks -- it landed straight in my Discord.")
	elif code == 429:
		done.emit(false, "Too many messages at once. Wait a minute and try again, or use COPY.")
	else:
		done.emit(false, "Sending failed (server said %d). Use COPY or the email button instead." % code)


func _cleanup() -> void:
	if _http != null and is_instance_valid(_http):
		_http.queue_free()
	_http = null
