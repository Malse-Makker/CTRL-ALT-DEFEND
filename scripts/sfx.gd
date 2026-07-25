extends RefCounted
# Procedureel gegenereerde geluidseffecten. Geen audiobestanden nodig: alles wordt bij het
# starten van een level als golfvorm berekend. Klinkt bescheiden maar past bij de stijl, en
# het scheelt losse assets die je moet beheren.
#
# Alles is mono 22 kHz — ruim genoeg voor korte kantoorgeluidjes en klein in geheugen.

const RATE := 22050


static func _normalize(s: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	# Schaalt naar een doelpiek. Nodig bij geluiden die uit veel opgetelde stemmen bestaan:
	# die heffen elkaar deels op, dus de uiteindelijke piek is niet te voorspellen uit het
	# opgegeven volume. Zonder dit verdrinkt het geroezemoes onder de rest.
	var cur := 0.0
	for v in s:
		cur = maxf(cur, absf(v))
	if cur < 0.0001:
		return s
	var k: float = peak / cur
	for i in s.size():
		s[i] *= k
	return s


static func _wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


static func tone(freq: float, dur: float, vol: float = 0.4, curve: float = 1.0) -> AudioStreamWAV:
	# Enkele toon die uitdooft. curve > 1 = sneller weg (korter, droger).
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var env: float = pow(1.0 - float(i) / float(n), curve)
		s[i] = sin(TAU * freq * t) * env * vol
	return _wav(s)


static func sweep(f0: float, f1: float, dur: float, vol: float = 0.35) -> AudioStreamWAV:
	# Glijdende toon: omhoog voelt als "verzonden", omlaag als "mislukt".
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var k: float = float(i) / float(n)
		phase += TAU * lerpf(f0, f1, k) / RATE
		s[i] = sin(phase) * pow(1.0 - k, 1.2) * vol
	return _wav(s)


static func noise(dur: float, vol: float = 0.3, smooth: float = 0.35, curve: float = 2.0) -> AudioStreamWAV:
	# Ruis met een simpel laagdoorlaatfilter: hoe hoger smooth, hoe doffer/luchtiger.
	# Gebruikt voor papiergeritsel, poefjes en het suizen van een vliegtuigje.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var last := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in n:
		var white: float = rng.randf_range(-1.0, 1.0)
		last = lerpf(last, white, 1.0 - smooth)
		s[i] = last * pow(1.0 - float(i) / float(n), curve) * vol
	return _wav(s)


static func thump(freq: float, dur: float, vol: float = 0.5) -> AudioStreamWAV:
	# Lage klap met dalende toonhoogte: de zware treffer van de sniper.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var k: float = float(i) / float(n)
		phase += TAU * lerpf(freq, freq * 0.35, k) / RATE
		s[i] = sin(phase) * pow(1.0 - k, 2.5) * vol
	return _wav(s)


static func siren(dur: float, vol: float = 0.3) -> AudioStreamWAV:
	# Twee afwisselende tonen: het brandalarm.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var f: float = 720.0 if fmod(t, 0.7) < 0.35 else 560.0
		var env: float = clampf(minf(t, dur - t) * 6.0, 0.0, 1.0)
		s[i] = sin(TAU * f * t) * env * vol
	return _wav(s)


static func bubble(dur: float = 0.5, vol: float = 0.30) -> AudioStreamWAV:
	# Koffie die doorloopt: een paar korte opgaande blubjes achter elkaar. Elke blub is
	# een snel stijgende sinus — dat is precies hoe een luchtbel in water klinkt.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var count := 5
	for b in count:
		var start := int((float(b) / float(count)) * n * 0.85 + rng.randf_range(0.0, 0.03) * RATE)
		var blen := int(rng.randf_range(0.05, 0.09) * RATE)
		var f0 := rng.randf_range(300.0, 480.0)
		var phase := 0.0
		for j in blen:
			var idx := start + j
			if idx >= n:
				break
			var k: float = float(j) / float(blen)
			phase += TAU * lerpf(f0, f0 * 2.4, k) / RATE
			s[idx] += sin(phase) * pow(1.0 - k, 1.8) * vol
	return _wav(s)


static func alarm_clock(vol: float = 0.28) -> AudioStreamWAV:
	# Digitale wekker: drie groepjes van drie korte bliepjes. Een blokgolf in plaats van een
	# sinus, want dat is precies het goedkope piezo-geluid van een bureauwekker.
	var beep := 0.085
	var gap := 0.055
	var group_gap := 0.30
	var group := 3.0 * (beep + gap) + group_gap
	var n := int(3.0 * group * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for g in 3:
		for b in 3:
			var start := int((float(g) * group + float(b) * (beep + gap)) * RATE)
			var blen := int(beep * RATE)
			for j in blen:
				var idx := start + j
				if idx >= n:
					break
				var t: float = float(j) / RATE
				# Korte aan- en uitloop, anders klikt elk bliepje aan het begin en eind.
				var k: float = float(j) / float(blen)
				var env: float = clampf(minf(k, 1.0 - k) * 12.0, 0.0, 1.0)
				s[idx] += signf(sin(TAU * 2400.0 * t)) * env * vol
	return _wav(s)


static func crowd(dur: float = 2.2, vol: float = 0.22) -> AudioStreamWAV:
	# Geroezemoes: een hele afdeling die tegelijk opstaat om te gaan lunchen. Opgebouwd uit
	# een stuk of wat "stemmen" — lage sinussen die in toonhoogte en volume dobberen — plus
	# zachte ruis eroverheen. Zwelt aan en ebt weer weg, zodat het als een golf voelt.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9182
	var voices := 14
	for v in voices:
		var base: float = rng.randf_range(95.0, 320.0)
		var wobble_f: float = rng.randf_range(2.5, 6.5)
		var wobble_d: float = rng.randf_range(3.0, 14.0)
		var amp_f: float = rng.randf_range(1.2, 3.8)
		var phase := 0.0
		var off: float = rng.randf_range(0.0, TAU)
		for i in n:
			var t: float = float(i) / RATE
			phase += TAU * (base + sin(TAU * wobble_f * t + off) * wobble_d) / RATE
			var amp: float = 0.55 + 0.45 * sin(TAU * amp_f * t + off)
			s[i] += sin(phase) * amp / float(voices)
	var last := 0.0
	for i in n:
		var k: float = float(i) / float(n)
		# Aanzwellen tot ongeveer een derde, daarna langzaam wegebben.
		var env: float = clampf(k / 0.30, 0.0, 1.0) * pow(1.0 - maxf(k - 0.30, 0.0) / 0.70, 1.5)
		last = lerpf(last, rng.randf_range(-1.0, 1.0), 0.35)
		s[i] = (s[i] * 0.8 + last * 0.2) * env
	return _wav(_normalize(s, vol))


static func chime(freq: float = 880.0, dur: float = 0.34, vol: float = 0.32) -> AudioStreamWAV:
	# Kassa-achtig belletje: grondtoon plus kwint, snelle aanslag en lange uitloop. Gebruikt
	# voor verkopen — je krijgt iets terug, dus het mag vriendelijker klinken dan een koop.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var k: float = float(i) / float(n)
		var env: float = clampf(k * 60.0, 0.0, 1.0) * pow(1.0 - k, 2.2)
		s[i] = (sin(TAU * freq * t) * 0.6 + sin(TAU * freq * 1.5 * t) * 0.4) * env * vol
	return _wav(s)


static func typing(dur: float, vol: float = 0.16) -> AudioStreamWAV:
	# Kantoor-ambient: onregelmatig getik op toetsenborden, ver weg. Bedoeld om te loopen
	# en zó zacht te zijn dat je het pas mist als het er niet is.
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var next := 0
	var i := 0
	while i < n:
		if i >= next:
			# één toetsaanslag: heel kort ruisklikje
			var klen := int(rng.randf_range(0.006, 0.014) * RATE)
			var amp := rng.randf_range(0.35, 1.0)
			for j in klen:
				if i + j >= n:
					break
				var env: float = pow(1.0 - float(j) / float(klen), 3.0)
				s[i + j] += rng.randf_range(-1.0, 1.0) * env * vol * amp
			next = i + klen + int(rng.randf_range(0.04, 0.34) * RATE)
		i += 1
	return _wav(s)
