extends SceneTree

const State = preload("res://scripts/core/game_state.gd")
var checks := 0
var failures := 0
var save_path := "user://test_state_save.json"

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	_cleanup()
	_test_inventory()
	_test_dependencies_and_complete_path()
	_test_save_and_recovery()
	_test_database()
	_cleanup()
	print("STATE TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_inventory() -> void:
	var state = State.new()
	check(state.data.room == "platform", "New game starts on the platform")
	check(state.has_item("letter"), "Invitation is available immediately")
	check(not state.add_item("does_not_exist"), "Unknown items cannot enter inventory")
	check(not state.add_item("letter"), "Inventory cannot duplicate invitation")
	check(not state.remove_item("gear"), "Absent item removal is harmless")
	check(not state.combine("letter", "letter"), "Invalid combination fails")
	check(state.has_item("letter"), "Invalid combination preserves items")
	state.add_item("broken_watch")
	check(not state.combine("broken_watch", "gear"), "Missing recipe ingredient cannot be consumed")
	check(state.has_item("broken_watch"), "Watch survives missing ingredient")
	state.add_item("gear")
	check(state.combine("gear", "broken_watch"), "Recipe supports either ingredient order")
	check(state.has_item("repaired_watch"), "Recipe produces repaired watch")
	check(not state.has_item("broken_watch") and not state.has_item("gear"), "Recipe consumes exactly its ingredients")
	check(state.flag("watch_repaired"), "Recipe records completion")
	check(state.data.journal.has("watch") and state.data.evidence.has("watch"), "Recipe records discovered clue")
	check(not state.combine("gear", "broken_watch"), "Repeated combination cannot duplicate reward")
	check(state.add_journal("footprints"), "Journal can add discovery")
	check(not state.add_journal("footprints"), "Journal has no duplicates")
	check(state.add_evidence("ticket"), "Evidence can be collected")
	check(not state.add_evidence("ticket"), "Evidence has no duplicates")
	state.data.settings.music = 0.2
	state.reset(true)
	check(is_equal_approx(state.data.settings.music, 0.2), "New game can retain settings")
	check(not state.flag("watch_repaired"), "New game clears progression")

func _test_dependencies_and_complete_path() -> void:
	var state = State.new()
	check(not state.solve_puzzle("nonexistent", []), "Unknown puzzle rejected")
	check(not state.finish_chapter(), "Chapter cannot end before signal")
	check(not state.solve_puzzle("signal_sent", [0, 2, 1, 0]), "Final memory sequence requires prerequisites")
	check(not state.solve_puzzle("cabinet_open", [2, 1, 3]), "Cabinet cannot bypass office and cipher")
	check(not state.solve_puzzle("clock_set", [21, 15]), "Clock cannot bypass repaired watch")
	check(not state.solve_puzzle("power_restored", [true, false, true]), "Power requires fuse")
	check(not state.solve_puzzle("suitcase_open", "000"), "Incorrect lock combination rejected")
	check(not state.has_item("brass_key"), "Wrong answer grants no reward")
	check(state.solve_puzzle("suitcase_open", "314"), "Timetable unlocks suitcase")
	check(state.has_item("brass_key") and state.has_item("broken_watch"), "Suitcase grants both critical items")
	var item_count: int = state.data.inventory.size()
	check(state.solve_puzzle("suitcase_open", "314"), "Completed puzzle is idempotent")
	check(state.data.inventory.size() == item_count, "Idempotent completion duplicates no rewards")
	check(not state.solve_puzzle("office_unlocked", "letter"), "Only actual room key unlocks office")
	check(state.solve_puzzle("office_unlocked", "brass_key"), "Brass key unlocks office")
	check(not state.solve_puzzle("cipher_solved", [3, 1, 2]), "Wrong symbol order rejected")
	check(state.solve_puzzle("cipher_solved", [2, 1, 3]), "Invitation solves symbol substitution")
	check(state.solve_puzzle("cabinet_open", [2, 1, 3]), "Cipher unlocks rotating cabinet discs")
	check(state.has_item("gear"), "Cabinet gives gear")
	check(state.combine("broken_watch", "gear"), "Gear repairs watch in normal flow")
	check(not state.solve_puzzle("clock_set", [9, 15]), "Clock needs evening time")
	check(state.solve_puzzle("clock_set", [21, 15]), "Restored watch solves clock")
	check(state.has_item("fuse"), "Clock rewards fuse")
	check(not state.solve_puzzle("power_restored", [true, true, true]), "Short circuit configuration fails")
	check(state.has_item("fuse"), "Wrong circuit attempt preserves critical fuse")
	check(state.solve_puzzle("power_restored", [true, false, true]), "Circuit restored")
	check(not state.has_item("fuse"), "Fuse installed only after successful circuit")
	check(not state.solve_puzzle("evidence_linked", ["ticket", "wet_note"]), "Undiscovered evidence cannot be linked")
	state.add_item("ticket")
	state.add_evidence("ticket")
	check(not state.solve_puzzle("evidence_linked", ["ticket", "wet_note"]), "Both clues must be discovered")
	state.add_item("wet_note")
	state.add_evidence("wet_note")
	check(not state.solve_puzzle("evidence_linked", ["ticket", "letter"]), "Wrong evidence relation fails")
	check(state.solve_puzzle("evidence_linked", ["wet_note", "ticket"]), "Evidence link works in either order")
	check(state.data.achievements.has("investigator"), "Investigation achievement recorded")
	check(not state.solve_puzzle("signal_sent", [0, 1, 2, 0]), "Wrong memory sequence rejected")
	check(state.solve_puzzle("signal_sent", [0, 2, 1, 0]), "Correct memory sequence sends signal")
	check(state.finish_chapter(), "Complete dependency chain reaches train arrival")
	check(state.flag("chapter_complete") and state.data.ending == "train_arrival", "Chapter ending persisted in state")
	check(state.data.achievements.has("first_departure"), "Chapter achievement recorded")
	check(state.finish_chapter(), "Repeated completion safe")
	check(state.data.achievements.count("first_departure") == 1, "Achievement reward unique")
	for id: String in state.puzzle_defs:
		check(state.flag(id), "Required puzzle completed: " + id)
	check(not state.objective().is_empty(), "Completed chapter has objective text")
	check(not state.hint(2).is_empty(), "Post-completion hint remains usable")

func _test_save_and_recovery() -> void:
	var state = State.new()
	check(not state.has_save(save_path), "No save before first write")
	check(not state.load_game(save_path), "Absent save returns false")
	state.data.room = "office"
	state.add_item("brass_key")
	state.set_flag("suitcase_open")
	state.add_evidence("ticket")
	state.add_journal("ticket")
	state.data.choices["keeper"] = "trust"
	state.data.settings = {"music": 0.2, "sfx": 0.3, "ambient": 0.4, "quality": 2}
	state.data.hint_levels["suitcase_open"] = 1
	check(state.save_game(save_path) == OK, "First atomic save succeeds")
	check(state.has_save(save_path), "Valid save detected")
	var restored = State.new()
	check(restored.load_game(save_path), "Saved game loads")
	check(restored.data.room == "office", "Location roundtrip")
	check(restored.has_item("brass_key"), "Inventory roundtrip")
	check(restored.flag("suitcase_open"), "Puzzle roundtrip")
	check(restored.data.journal.has("ticket"), "Journal roundtrip")
	check(restored.data.evidence.has("ticket"), "Evidence roundtrip")
	check(restored.data.choices.keeper == "trust", "Dialogue decision roundtrip")
	check(is_equal_approx(restored.data.settings.ambient, 0.4), "Audio settings roundtrip")
	check(restored.data.settings.quality == 2, "Quality setting roundtrip")
	check(restored.data.hint_levels.suitcase_open == 1, "Hint progress roundtrip")
	state.data.room = "cellar"
	check(state.save_game(save_path) == OK, "Second save succeeds")
	check(FileAccess.file_exists(save_path + ".bak"), "Previous verified state backed up")
	_write(save_path, "{corrupted file")
	check(restored.load_game(save_path), "Corrupt main recovers from valid backup")
	check(restored.data.room == "office", "Recovery uses actual previous snapshot")
	check(restored.save_game(save_path) == OK, "Recovered save can replace corrupt main")
	check(restored.load_game(save_path), "Repaired main reloads")
	# Tamper with envelope but leave checksum unchanged: must reject it.
	var content := FileAccess.get_file_as_string(save_path)
	_write(save_path, content.replace("office", "cellar"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak"))
	check(not restored.load_game(save_path), "Checksum detects tampering without backup")
	check(restored.data.room == "office", "Failed load preserves in-memory progress")
	check(not restored.has_save(save_path), "Corrupt-only save is not offered as Continue")
	state.data.settings.music = 4.0
	check(state.save_game(save_path) == ERR_INVALID_DATA, "Out of range setting rejected")
	state.reset()
	state.data.inventory.append("fake")
	check(state.save_game(save_path) == ERR_INVALID_DATA, "Unknown saved item rejected")
	state.reset()
	state.data.room = "nonexistent"
	check(state.save_game(save_path) == ERR_INVALID_DATA, "Invalid saved room rejected")
	state.reset()
	state.data.flags["bad"] = "yes"
	check(state.save_game(save_path) == ERR_INVALID_DATA, "Nonboolean flag rejected")
	state.reset()
	state.data.inventory.append("letter")
	check(state.save_game(save_path) == ERR_INVALID_DATA, "Duplicate inventory rejected")
	state.reset()
	state.data.settings.quality = 1.5
	check(state.save_game(save_path) == ERR_INVALID_DATA, "Fractional quality rejected")

func _test_database() -> void:
	var state = State.new()
	check(state.chapters.size() == 7, "Database preserves all seven chapters")
	check(state.puzzle_defs.size() == 9, "Chapter one has nine connected puzzle definitions")
	var ids := {}
	var count := 0
	for chapter: Dictionary in state.chapters:
		check(chapter.status == ("implemented" if chapter.id == 1 else "planned"), "Chapter status honest: " + str(chapter.id))
		for puzzle: Dictionary in chapter.puzzles:
			check(not ids.has(puzzle.id), "Puzzle id unique: " + puzzle.id)
			ids[puzzle.id] = true
			count += 1
	check(count >= 50, "All-chapter design contains at least fifty puzzles")
	for chapter: Dictionary in state.chapters:
		for puzzle: Dictionary in chapter.puzzles:
			for dependency: String in puzzle.depends_on:
				check(ids.has(dependency), "Dependency exists: " + dependency)
	for id: String in state.puzzle_defs:
		var definition: Dictionary = state.puzzle_defs[id]
		check(definition.hints.size() == 3, "Three progressive hints: " + id)
		check(not definition.explicit_solution.is_empty(), "Explicit solution available separately: " + id)
		for item: String in definition.get("rewards", []):
			check(state.items.has(item), "Reward exists: " + item)
		for required: String in definition.get("requires_items", []):
			check(state.items.has(required), "Required item exists: " + required)

func _write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := ProjectSettings.globalize_path(save_path + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
