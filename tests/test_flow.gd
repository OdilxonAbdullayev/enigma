extends SceneTree
## Runs real scene controllers and button callbacks through the entire first chapter.
var failures := 0
var checks := 0
var game: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FLOW: " + message)

func buttons(node: Node, value: String = "") -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is Button and (value.is_empty() or child.text.begins_with(value)):
			found.append(child)
		found.append_array(buttons(child,value))
	return found

func press(prefix: String, parent: Node = null) -> void:
	var found := buttons(parent if parent else game.modal,prefix)
	check(not found.is_empty(),"button exists: "+prefix)
	if not found.is_empty():
		check(not found[0].disabled,"button enabled: "+prefix)
		found[0].pressed.emit()

func frames(n := 2) -> void:
	for i in range(n):
		await process_frame

func run() -> void:
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	check(not buttons(game.layer,"Sayohatni boshlash").is_empty(),"main menu rendered")
	game.start_new()
	await frames()
	check(is_instance_valid(game.modal),"intro exists")
	game.close_modal()
	game.show_timetable()
	check(game.state.data.journal.has("timetable"),"timetable persisted to journal")
	game.close_modal()
	game.show_suitcase()
	await frames()
	# Three real rotating lock buttons, values entered through their signals.
	var digits: Array = []
	for b in buttons(game.panel):
		if b.text == "0": digits.append(b)
	check(digits.size()==3,"number lock has three wheels")
	for i in range(3):
		for turn in range([3,1,4][i]):
			digits[i].pressed.emit()
	press("Qulfni ochish")
	check(game.state.flag("suitcase_open"),"suitcase solved via UI")
	check(game.state.has_item("brass_key"),"key reward visible")
	await game.go_room("hall")
	check(game.state.data.room=="hall","room transition")
	game.show_cipher()
	await frames()
	var symbols := buttons(game.panel,"◉")
	check(symbols.size()==3,"cipher has three symbol controls")
	symbols[0].pressed.emit()
	symbols[2].pressed.emit()
	symbols[2].pressed.emit()
	press("Muhrni tekshirish")
	check(game.state.flag("cipher_solved"),"cipher solved")
	game.selected_item="brass_key"
	game.unlock_office()
	check(game.state.flag("office_unlocked"),"inventory key unlocks office")
	await game.go_room("office")
	game.show_cabinet()
	await frames()
	symbols = buttons(game.panel,"◉")
	symbols[0].pressed.emit()
	symbols[2].pressed.emit()
	symbols[2].pressed.emit()
	press("Muhrni tekshirish")
	check(game.state.has_item("gear"),"cabinet reward")
	game.choose_item("broken_watch")
	game.close_modal()
	game.choose_item("gear")
	check(game.state.flag("watch_repaired"),"tap inventory combination")
	check(not game.state.has_item("gear"),"ingredient consumed")
	await game.go_room("hall")
	game.show_clock()
	for i in range(21): press("Soat +1")
	for i in range(3): press("Daqiqa +5")
	press("Mexanizmni uyg‘otish")
	check(game.state.flag("clock_set"),"clock synchronized via UI")
	await game.go_room("cellar")
	game.show_power()
	press("1\n")
	press("3\n")
	press("Tarmoqni ulash")
	check(game.state.flag("power_restored"),"power UI switches")
	await game.go_room("platform")
	game.collect("ticket","Test")
	game.close_modal()
	await game.go_room("office")
	game.collect("wet_note","Test")
	game.show_evidence()
	press("◇ "+game.state.items.ticket.name)
	press("◇ "+game.state.items.wet_note.name)
	press("Tanlangan dalillarni bog‘lash")
	check(game.state.flag("evidence_linked"),"evidence card linkage")
	game.show_dialogue()
	press("«Siz kimsiz?»")
	check(game.state.data.choices.get("malik")=="identity","branching dialogue choice persists")
	await game.go_room("hall")
	game.show_secret()
	check(game.state.has_item("artifact"),"optional artifact accessible")
	await game.go_room("platform")
	game.show_signal()
	press("Chap")
	press("O‘ng")
	press("O‘rta")
	press("Chap")
	check(game.state.flag("chapter_complete"),"full first chapter completes via controller inputs")
	check(game.art.completed,"train visual state")
	check(game.state.data.achievements.has("first_departure"),"chapter achievement")
	check(game.state.save_game()==OK,"UI state valid save")
	game.show_menu()
	game.continue_game()
	check(game.state.flag("chapter_complete"),"continue restores completion")
	check(game.state.has_item("artifact"),"continue restores artifact")
	game.show_settings()
	for slider in game.panel.get_children():
		if slider is HSlider: slider.value=0.2
	press("Tejamkor")
	press("Sozlamalarni saqlash")
	check(game.state.data.settings.quality==0,"performance setting")
	check(is_equal_approx(game.sound.settings.music,0.2),"music independent volume")
	check(game.state.load_game(),"settings save reload")
	check(game.state.data.settings.quality==0,"quality persisted")
	game.show_journal()
	check(game.panel.get_child_count()>10,"discovery journal populated")
	game.show_map()
	check(buttons(game.panel).size()==5,"all map controls")
	game.show_chapters()
	check(buttons(game.panel).size()==1,"planned chapters not fake playable buttons")
	# Validate modal and main layout stays accessible at two landscape ratios.
	for resolution in [Vector2i(1280,720),Vector2i(1920,864),Vector2i(1440,900)]:
		root.size=resolution
		await frames(4)
		game.playing=true
		game.render_game()
		game.show_settings()
		await frames(3)
		check(game.modal.get_child(1).get_global_rect().size.y<=game.size.y,"modal fits ratio "+str(resolution))
		check(buttons(game.modal,"Yopish")[0].get_global_rect().end.x<=game.size.x,"close fits ratio "+str(resolution))
	game.close_modal()
	# Allow outstanding discovery toasts / scene tweens to finish before destroying nodes.
	await create_timer(4.1).timeout
	game.queue_free()
	await frames(3)
	print("FLOW TESTS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
