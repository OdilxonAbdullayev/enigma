extends RefCounted
## Pure game rules: independent of scene tree, rendering and input.
## Save files are atomic, checksummed JSON envelopes with a last-valid backup.

const SCHEMA_VERSION := 1
const DEFAULT_SAVE := "user://save.json"
const ROOMS := ["platform", "hall", "office", "cellar"]
const MAX_SAVE_BYTES := 2097152

var data: Dictionary
var items: Dictionary
var chapters: Array
var evidence_defs: Dictionary
var journal_defs: Dictionary
var puzzle_defs: Dictionary

func _init() -> void:
	items = _read_data("res://data/items.json", {})
	chapters = _read_data("res://data/chapters.json", [])
	evidence_defs = _read_data("res://data/evidence.json", {})
	journal_defs = _read_data("res://data/journal.json", {})
	puzzle_defs = _read_data("res://data/puzzles.json", {})
	reset()

func _read_data(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var parsed := JSON.new()
	if parsed.parse(FileAccess.get_file_as_string(path)) != OK:
		return fallback
	return parsed.data

func reset(keep_settings: bool = false) -> void:
	var settings: Dictionary = {"music": 0.55, "sfx": 0.75, "ambient": 0.45, "quality": 1}
	if keep_settings and data is Dictionary and data.has("settings"):
		settings = data.settings.duplicate(true)
	data = {
		"version": SCHEMA_VERSION, "chapter": 1, "room": "platform",
		"inventory": ["letter"], "flags": {}, "journal": ["arrival", "letter"],
		"evidence": ["letter"], "choices": {}, "achievements": [],
		"settings": settings, "ending": "", "hint_levels": {},
	}

func has_item(id: String) -> bool:
	return data.inventory.has(id)

func add_item(id: String) -> bool:
	if not items.has(id) or has_item(id):
		return false
	data.inventory.append(id)
	return true

func remove_item(id: String) -> bool:
	if not has_item(id):
		return false
	data.inventory.erase(id)
	return true

func flag(id: String) -> bool:
	return bool(data.flags.get(id, false))

func set_flag(id: String, value: bool = true) -> void:
	data.flags[id] = value

func add_journal(id: String) -> bool:
	if data.journal.has(id):
		return false
	data.journal.append(id)
	return true

func add_evidence(id: String) -> bool:
	if data.evidence.has(id):
		return false
	data.evidence.append(id)
	return true

func combine(a: String, b: String) -> bool:
	# The broken watch is never consumed unless the entire recipe can succeed.
	if a == "watch":
		a = "broken_watch"
	if b == "watch":
		b = "broken_watch"
	if not has_item(a) or not has_item(b) or a == b:
		return false
	if not ([a, b].has("broken_watch") and [a, b].has("gear")):
		return false
	remove_item("broken_watch")
	remove_item("gear")
	add_item("repaired_watch")
	set_flag("watch_repaired")
	add_journal("watch")
	add_evidence("watch")
	return true

func solve_puzzle(id: String, answer: Variant) -> bool:
	if not puzzle_defs.has(id):
		return false
	if flag(id):
		return true
	if id == "watch_repaired":
		return answer is Array and answer.size() == 2 and combine(str(answer[0]), str(answer[1]))
	var definition: Dictionary = puzzle_defs[id]
	for dependency: String in definition.get("requires", []):
		if not flag(dependency):
			return false
	for item: String in definition.get("requires_items", []):
		if not has_item(item):
			return false
	var correct := false
	if id == "suitcase_open":
		correct = str(answer) == "314"
	elif id == "office_unlocked":
		correct = str(answer) == "brass_key"
	elif id == "evidence_linked":
		correct = answer is Array and answer.size() == 2 and answer.has("ticket") and answer.has("wet_note")
		correct = correct and data.evidence.has("ticket") and data.evidence.has("wet_note")
	else:
		correct = _answers_equal(answer, definition.get("solution"))
	if not correct:
		return false
	for item: String in definition.get("consumes", []):
		remove_item(item)
	for item: String in definition.get("rewards", []):
		add_item(item)
	set_flag(id)
	add_journal(str(definition.get("journal", id)))
	if id == "evidence_linked":
		_unlock_achievement("investigator")
	return true

func _answers_equal(actual: Variant, expected: Variant) -> bool:
	if actual is Array and expected is Array:
		if actual.size() != expected.size():
			return false
		for i: int in range(actual.size()):
			if not _answers_equal(actual[i], expected[i]):
				return false
		return true
	if (actual is int or actual is float) and (expected is int or expected is float):
		return is_equal_approx(float(actual), float(expected))
	return actual == expected

func finish_chapter() -> bool:
	if not flag("signal_sent"):
		return false
	set_flag("chapter_complete")
	data.ending = "train_arrival"
	add_journal("ending")
	_unlock_achievement("first_departure")
	return true

func _unlock_achievement(id: String) -> void:
	if not data.achievements.has(id):
		data.achievements.append(id)

func objective() -> String:
	if flag("chapter_complete"):
		return "I bob tugadi. Haydovchisiz poyezd sizni kutmoqda."
	if flag("signal_sent"):
		return "Perronga qayting. Uzoqdan poyezd ovozi eshitilyapti."
	if flag("power_restored") and flag("evidence_linked"):
		return "Perrondagi signal chiroqlarining ketma-ketligini takrorlang."
	if flag("power_restored"):
		return "Chiptani va nam xatni dalillar taxtasida bog‘lang."
	if flag("clock_set"):
		return "Yerosti aloqa xonasidagi taqsimlagichga saqlagichni o‘rnating."
	if flag("watch_repaired"):
		return "Zaldagi katta soatni cho‘ntak soati ko‘rsatgan vaqtga sozlang."
	if flag("cabinet_open"):
		return "Tishli g‘ildirakni singan cho‘ntak soatiga birlashtiring."
	if flag("office_unlocked") and flag("cipher_solved"):
		return "Boshliq xonasidagi belgili javonning halqalarini sozlang."
	if flag("office_unlocked"):
		return "Xatdagi belgilarni yeching: oy, ko‘z va quyosh."
	if flag("suitcase_open"):
		return "Jez kalit bilan bekat boshlig‘ining xonasini oching."
	return "Yo‘nalish jadvalidagi raqamlardan jomadon qulfini ochish uchun foydalaning."

func hint(level: int = 0) -> String:
	var id := current_puzzle()
	if id.is_empty():
		return "Perronga qayting va kelgan poyezdni ko‘ring."
	var hints: Array = puzzle_defs[id].get("hints", [])
	if hints.is_empty():
		return objective()
	return str(hints[clampi(level, 0, hints.size() - 1)])

func current_puzzle() -> String:
	for id: String in ["suitcase_open", "office_unlocked", "cipher_solved", "cabinet_open", "watch_repaired", "clock_set", "power_restored", "evidence_linked", "signal_sent"]:
		if not flag(id):
			return id
	return ""

func has_save(path: String = DEFAULT_SAVE) -> bool:
	return _read_save(path).valid or _read_save(path + ".bak").valid

func save_game(path: String = DEFAULT_SAVE) -> Error:
	if not _valid_data(data):
		return ERR_INVALID_DATA
	var payload := JSON.stringify(data)
	var envelope := JSON.stringify({"schema_version": SCHEMA_VERSION, "payload_json": payload, "sha256": payload.sha256_text()})
	var temp_path := path + ".tmp"
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return FileAccess.get_open_error()
	temp.store_string(envelope)
	temp.flush()
	var write_error := temp.get_error()
	temp.close()
	if write_error != OK:
		return write_error
	# Back up only a verified save. A damaged main file never replaces a good backup.
	if _read_save(path).valid:
		var backup := FileAccess.open(path + ".bak", FileAccess.WRITE)
		if backup == null:
			return FileAccess.get_open_error()
		backup.store_string(FileAccess.get_file_as_string(path))
		backup.flush()
		write_error = backup.get_error()
		backup.close()
		if write_error != OK:
			return write_error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))

func load_game(path: String = DEFAULT_SAVE) -> bool:
	var result := _read_save(path)
	if not result.valid:
		result = _read_save(path + ".bak")
	if not result.valid:
		return false
	data = result.data
	# JSON stores numbers as floats; normalize discrete fields at this boundary.
	data.version = int(data.version)
	data.chapter = int(data.chapter)
	data.settings.quality = int(data.settings.quality)
	return true

func _read_save(path: String) -> Dictionary:
	var invalid := {"valid": false}
	if not FileAccess.file_exists(path):
		return invalid
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return invalid
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return invalid
	var content := file.get_as_text()
	file.close()
	var parsed := JSON.new()
	if parsed.parse(content) != OK or not parsed.data is Dictionary:
		return invalid
	var envelope: Dictionary = parsed.data
	if envelope.get("schema_version") != SCHEMA_VERSION:
		return invalid
	if not envelope.get("payload_json") is String or not envelope.get("sha256") is String:
		return invalid
	var payload: String = envelope.payload_json
	if payload.sha256_text() != envelope.sha256:
		return invalid
	if parsed.parse(payload) != OK or not _valid_data(parsed.data):
		return invalid
	return {"valid": true, "data": parsed.data}

func _valid_data(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key: String in ["version", "chapter", "room", "inventory", "flags", "journal", "evidence", "choices", "achievements", "settings", "ending", "hint_levels"]:
		if not value.has(key):
			return false
	if value.version != SCHEMA_VERSION or not _whole_number(value.chapter, 1, 7):
		return false
	if not value.room is String or not ROOMS.has(value.room) or not value.ending is String:
		return false
	for key: String in ["inventory", "journal", "evidence", "achievements"]:
		if not _string_list(value[key]):
			return false
	for item: String in value.inventory:
		if not items.has(item):
			return false
	for key: String in ["flags", "choices", "settings", "hint_levels"]:
		if not value[key] is Dictionary:
			return false
	for key: Variant in value.flags:
		if not key is String or not value.flags[key] is bool:
			return false
	for key: String in ["music", "sfx", "ambient"]:
		var volume: Variant = value.settings.get(key)
		if not (volume is float or volume is int) or not is_finite(float(volume)) or float(volume) < 0.0 or float(volume) > 1.0:
			return false
	if not _whole_number(value.settings.get("quality"), 0, 2):
		return false
	for key: Variant in value.hint_levels:
		if not key is String or not _whole_number(value.hint_levels[key], 0, 2):
			return false
	return true

func _string_list(value: Variant) -> bool:
	if not value is Array or value.size() > 512:
		return false
	var seen := {}
	for element: Variant in value:
		if not element is String or element.is_empty() or element.length() > 256 or seen.has(element):
			return false
		seen[element] = true
	return true

func _whole_number(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is float or value is int):
		return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum
