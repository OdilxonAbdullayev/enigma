extends SceneTree
## Independent pointer QA. Sends coordinates through the viewport/input system, never button signals.
var checks: int = 0
var failures: int = 0
var game: Control

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("INPUT: " + message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame

func buttons(node: Node, prefix: String) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and child.text.begins_with(prefix):
			result.append(child)
		result.append_array(buttons(child,prefix))
	return result

func pointer(point: Vector2, touch: bool = false) -> void:
	if touch:
		# Input singleton performs the same touch→mouse emulation enabled for Android.
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.position = point
		down.pressed = true
		Input.parse_input_event(down)
		await frames(2)
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.position = point
		up.pressed = false
		Input.parse_input_event(up)
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		root.push_input(motion,true)
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.position = point
		down.global_position = point
		down.pressed = true
		root.push_input(down,true)
		await frames(2)
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = point
		up.global_position = point
		up.pressed = false
		root.push_input(up,true)
	await frames(3)

func click(prefix: String, touch: bool = false) -> bool:
	var found: Array = buttons(game.modal if is_instance_valid(game.modal) else game.layer,prefix)
	check(found.size()==1,"unique visible control: "+prefix)
	if found.size()!=1:
		return false
	var button: Button = found[0]
	check(not button.disabled,"control enabled: "+prefix)
	var rect: Rect2 = button.get_global_rect()
	check(rect.size.x>=44 and rect.size.y>=44,"touch area at least 44 px: "+prefix)
	check(Rect2(Vector2.ZERO,game.size).encloses(rect),"control inside viewport: "+prefix)
	await pointer(rect.get_center(),touch)
	return true

func inventory_item(id: String) -> Button:
	for b in buttons(game.layer, ""):
		if b.has_meta("item_id") and b.get_meta("item_id")==id:
			return b
	return null

func drag(source: Button, target: Button) -> void:
	check(is_instance_valid(source) and is_instance_valid(target),"native drag source and target exist")
	if not is_instance_valid(source) or not is_instance_valid(target):
		return
	var start: Vector2 = source.get_global_rect().get_center()
	var finish: Vector2 = target.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = start
	motion.global_position = start
	root.push_input(motion,true)
	var down := InputEventMouseButton.new()
	down.position = start
	down.global_position = start
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down,true)
	await frames(2)
	var previous: Vector2 = start
	for step in range(1,13):
		var next: Vector2 = start.lerp(finish,float(step)/12.0)
		var move := InputEventMouseMotion.new()
		move.position = next
		move.global_position = next
		move.relative = next-previous
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(move,true)
		previous = next
		await frames(1)
	check(root.gui_is_dragging(),"viewport recognizes native mouse drag")
	var up := InputEventMouseButton.new()
	up.position = finish
	up.global_position = finish
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	root.push_input(up,true)
	await frames(4)
	check(not root.gui_is_dragging(),"native drag ends after mouse release")

func modal_contains(text: String) -> bool:
	return is_instance_valid(game.modal) and _contains(game.modal,text)

func _contains(node: Node, text: String) -> bool:
	if node is Label and text in node.text:
		return true
	for child in node.get_children():
		if _contains(child,text): return true
	return false

func begin_game() -> void:
	await click("Sayohatni boshlash")
	if modal_contains("Hozirgi bobdagi"):
		await click("Yangi sayohatni boshlash")
	check(modal_contains("Noma’lum xat"),"mouse coordinate opens story introduction")
	await click("Perronga qadam qo‘yish")
	check(game.playing and not is_instance_valid(game.modal),"intro dismissal by coordinates")

func run() -> void:
	Input.emulate_mouse_from_touch = true
	for resolution in [Vector2i(1440,900),Vector2i(1920,864)]:
		root.size = resolution
		root.content_scale_size = resolution
		game = load("res://scenes/main/main.tscn").instantiate()
		root.add_child(game)
		await frames(5)
		print("INPUT ratio: ",resolution," UI size: ",game.size)
		await begin_game()
		await click("◇ Qatnov jadvali")
		check(modal_contains("Qoratepa • Qatnov jadvali"),"mouse hotspot opens timetable")
		check(game.state.data.journal.has("timetable"),"input discovery saved to journal")
		await click("Yopish")
		check(not is_instance_valid(game.modal),"close button receives mouse coordinates")
		# Touchable inventory and footer actions must occupy disjoint rectangles.
		var journal: Array = buttons(game.layer,"Kundalik")
		var map: Array = buttons(game.layer,"Xarita va dalillar")
		var letter: Array = buttons(game.layer,"◇ Noma’lum xat")
		if letter.is_empty(): letter = buttons(game.layer,"◇ Sirli xat")
		if letter.is_empty():
			for b in buttons(game.layer,"◇ "):
				if b.has_meta("item_id") and b.get_meta("item_id")=="letter": letter.append(b)
		check(journal.size()==1 and map.size()==1 and letter.size()==1,"footer controls and letter exist")
		if letter.size()==1 and journal.size()==1 and map.size()==1:
			check(not letter[0].get_global_rect().intersects(journal[0].get_global_rect()),"inventory does not overlap journal")
			check(not letter[0].get_global_rect().intersects(map[0].get_global_rect()),"inventory does not overlap map")
			await pointer(letter[0].get_global_rect().get_center(),true)
			check(game.selected_item=="letter","inventory selected using emulated touch coordinates")
			check(modal_contains(game.state.items.letter.name),"item inspection opens after pointer selection")
			await click("Tanlash va joyga ishlatish")
		await click("Kutish zali",true)
		await create_timer(0.6).timeout
		check(game.state.data.room=="hall","navigation button changes room by touch")
		await click("◇ Xatning muhri",true)
		check(modal_contains("Xotira muhri"),"touch coordinates open cipher hotspot")
		if is_instance_valid(game.modal):
			await click("Yopish",true)
		check(not is_instance_valid(game.modal),"touch coordinates close modal")
		await click("Perron")
		await create_timer(0.6).timeout
		check(game.state.data.room=="platform","return navigation after touch interaction")
		# Fixtures only prepare isolated drag prerequisites; gestures still go through GUI routing.
		check(game.state.solve_puzzle("suitcase_open","314"),"drag fixture supplies suitcase rewards")
		game.render_game()
		await frames(3)
		await click("Kutish zali")
		await create_timer(0.6).timeout
		var key: Button = inventory_item("brass_key")
		var doors: Array = buttons(game.layer,"◇ Boshliq eshigi")
		check(doors.size()==1,"door hotspot available for native drop")
		if doors.size()==1:
			await drag(key,doors[0])
		check(game.state.flag("office_unlocked"),"native key drag unlocks office")
		check(game.state.solve_puzzle("cipher_solved",[2,1,3]),"drag fixture decodes cipher")
		check(game.state.solve_puzzle("cabinet_open",[2,1,3]),"drag fixture supplies gear")
		game.render_game()
		await frames(3)
		var gear: Button = inventory_item("gear")
		var watch: Button = inventory_item("broken_watch")
		await drag(gear,watch)
		check(game.state.flag("watch_repaired"),"native inventory drag combines compatible items")
		check(game.state.has_item("repaired_watch"),"native drop grants repaired watch")
		check(not game.state.has_item("gear") and not game.state.has_item("broken_watch"),"native drop consumes ingredients")
		var nav: Array = buttons(game.layer,"Perron")
		var inventory_buttons: Array = []
		for b in buttons(game.layer,""):
			if b.has_meta("item_id"): inventory_buttons.append(b)
		check(nav.size()==1,"navigation control remains available")
		if nav.size()==1:
			for b in inventory_buttons:
				check(not nav[0].get_global_rect().intersects(b.get_global_rect()),"navigation and inventory do not overlap")
			for b in buttons(game.layer,"Kundalik")+buttons(game.layer,"Xarita va dalillar"):
				check(not nav[0].get_global_rect().intersects(b.get_global_rect()),"navigation and footer action do not overlap")
		# Discovery notifications own four-second timers; allow them to expire before freeing scene.
		await create_timer(4.1).timeout

		game.queue_free()
		await frames(4)
	print("INPUT TESTS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
