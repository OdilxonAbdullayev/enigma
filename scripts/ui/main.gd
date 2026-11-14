extends Control

const Localizer = preload("res://scripts/localization/localizer.gd")
const StateScript = preload("res://scripts/core/game_state.gd")
const ArtScript = preload("res://scripts/world/station_art.gd")
const SoundScript = preload("res://scripts/audio/soundscape.gd")
const PuzzleArt = preload("res://scripts/ui/puzzle_art.gd")
const GOLD := Color("c9aa70")
const IVORY := Color("eee5cf")
const MUTED := Color("9eafb0")
const INK := Color("0b1c25")
const GREEN := Color("204e50")
var localizer = Localizer.new()
var state = StateScript.new()
var art: Control
var sound: Node
var layer: Control
var modal: Control
var panel: VBoxContainer
var toast_label: Label
var selected_item := ""
var playing := false
var puzzle_values: Array = []
var memory_input: Array = []
var memory_busy := false
var hint_level := 0
var toast_generation := 0
var evidence_selected: Array = []
var transition_busy := false
var serif = preload("res://assets/fonts/DejaVuSerif.ttf")
var sans = preload("res://assets/fonts/DejaVuSans.ttf")
var location_names := {"platform":"Tashlandiq perron", "hall":"Sukutdagi kutish zali", "office":"Bekat boshlig‘i xonasi", "cellar":"Yerosti aloqa xonasi"}
var hints := {
	"suitcase_open": ["Jomadon egasi safar vaqtini unutmaslikka harakat qilgan.", "Perrondagi qatnov jadvalini tekshiring.", "Jadvaldagi 03:14 va yozuvni solishtiring: qulfga 314 ni kiriting."],
	"cipher_solved": ["Xat chetidagi belgilar bezak emas.", "Xatda har bir belgi yonida raqam bor.", "Oy — 2, ko‘z — 1, quyosh — 3. Shu tartibni xat muhrida takrorlang."],
	"office_unlocked": ["Jomadonda eshikka mos keladigan buyum bor.", "Anjomlardan jez kalitni tanlab, zal eshigiga teging.", "Kutish zaliga o‘ting. Jez kalitni tanlang va boshliq xonasini oching."],
	"cabinet_open": ["Shkaf va xat bir xil ustaning ishi.", "Avval xatdagi shifrni yeching.", "Shkaf halqalarini Oy, Ko‘z, Quyosh tartibiga burang."],
	"watch_repaired": ["Soatning yuragi yetishmayapti.", "Shkafdagi tishli g‘ildirakni cho‘ntak soati bilan birlashtiring.", "Anjomlarda singan soatni, so‘ng tishli g‘ildirakni tanlang."],
	"clock_set": ["Tuzatilgan soat oxirgi daqiqani saqlab qolgan.", "Cho‘ntak soatining tavsifini o‘qing.", "Zaldagi katta soatni 21:15 ga qo‘ying."],
	"power_restored": ["Soat ichidagi saqlagich eski tarmoqqa mos.", "Yerosti xonasidagi lavhada kalitlar tartibi chizilgan.", "Birinchi va uchinchi kalit yoniq, o‘rtadagisi o‘chiq bo‘lsin."],
	"evidence_linked": ["Yaqinda bu yerga kimdir kelgan.", "Perrondagi chipta va boshliq stolidagi nam yozuvni toping.", "Dalillar doskasida chipta va nam yozuvni tanlab, bog‘lang."],
	"signal_sent": ["Yozuvdagi chiroqlar ketma-ketligi poyezdni chaqiradi.", "Signal panelidagi namoyishni kuzating.", "Chap, o‘ng, o‘rta, chap chiroqni bosing."],
}

func _ready() -> void:
	localizer.install("uz")
	var ui_theme := Theme.new()
	ui_theme.default_font = sans
	ui_theme.default_font_size = 20
	theme = ui_theme
	art = ArtScript.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	sound = SoundScript.new()
	add_child(sound)
	sound.start()
	state.load_game()
	sound.apply_settings(state.data.settings)
	Engine.max_fps = [30,60,60][state.data.settings.quality]
	art.quality = state.data.settings.quality
	resized.connect(_on_resize)
	show_menu()

func _on_resize() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
		modal = null
	if playing:
		render_game()
	else:
		show_menu()

func box(bg: Color = INK, border: Color = Color("3b5557"), radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func label_text(value: String, font_size: int = 20, color: Color = IVORY) -> Label:
	var l := Label.new()
	l.text = localizer.text(value)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func button(value: String, action: Callable, parent: Node, min_width: float = 0) -> Button:
	var b := Button.new()
	b.text = localizer.text(value)
	b.custom_minimum_size = Vector2(min_width, 60)
	b.add_theme_stylebox_override("normal", box())
	b.add_theme_stylebox_override("hover", box(Color("193d43"), GOLD))
	b.add_theme_stylebox_override("pressed", box(Color("36534b"), IVORY))
	b.add_theme_stylebox_override("focus", box(Color(0,0,0,0), GOLD))
	b.add_theme_stylebox_override("disabled", box(Color("102028"), Color("263b43")))
	b.add_theme_color_override("font_color", IVORY)
	b.add_theme_color_override("font_disabled_color", Color("62747b"))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		sound.effect("click")
		action.call())
	parent.add_child(b)
	return b

func clear_layer() -> void:
	close_modal()
	if is_instance_valid(layer):
		layer.hide()
		layer.queue_free()
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)

func place(node: Control, rect: Rect2, parent: Node = layer) -> void:
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size

func show_menu() -> void:
	playing = false
	clear_layer()
	art.set_room("platform")
	art.completed = false
	var shade := ColorRect.new()
	shade.color = Color(0.018,0.047,0.065,0.74)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(shade, Rect2(Vector2.ZERO,size))
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 16)
	place(left, Rect2(size.x*0.09,size.y*0.13,size.x*0.54,size.y*0.76))
	left.add_child(label_text("UNUTILGAN OLAM SOLNOMASI", 16, GOLD))
	var title := label_text("E N I G M A", 72)
	title.add_theme_font_override("font",serif)
	left.add_child(title)
	left.add_child(label_text("Ba’zi xatlar kelajakdan keladi.",24,MUTED))
	left.add_child(label_text("I BOB   /   NOMA’LUM XAT",18,GOLD))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	left.add_child(gap)
	button("Sayohatni boshlash   →",start_new_prompt,left,380)
	var continue_button := button("Davom etish",continue_game,left)
	continue_button.disabled = not state.has_save()
	button("Boblar xaritasi",show_chapters,left)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	left.add_child(row)
	button("Sozlamalar",show_settings,row,200)
	button("Mualliflar",show_credits,row,168)
	var seal := label_text("◈\n03 : 14\n\nVAQT TO‘XTAGAN.\nXOTIRA UYG‘OQ.",26,GOLD)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(seal,Rect2(size.x*0.7,size.y*0.34,size.x*0.23,size.y*0.4))
	var foot := label_text("OF­LAYN SARGUZASHT     •     1-BOB     •     v0.2",14,MUTED)
	place(foot,Rect2(size.x*0.09,size.y-48,size.x*0.8,30))
	title.modulate.a = 0
	create_tween().tween_property(title,"modulate:a",1.0,1.1)

func start_new_prompt() -> void:
	if state.has_save():
		open_modal("Yangi sayohat", "Hozirgi bobdagi saqlangan yo‘l yangilanadi. Boshlaysizmi?")
		button("Yangi sayohatni boshlash",start_new,panel)
	else:
		start_new()

func start_new() -> void:
	state.reset(true)
	selected_item = ""
	hint_level = 0
	state.add_item("letter")
	state.add_journal("arrival")
	persist()
	playing = true
	render_game()
	open_modal("Noma’lum xat", "«Agar bu xat qo‘lingizga yetgan bo‘lsa, meni hali unutishmagan.\n\nQoratepa bekatiga keling. Hamma soatlar to‘xtagan daqiqada men sizni kutaman. O‘zingiz bilan faqat xotirangizni olib keling.\n\n— M.»")
	button("Perronga qadam qo‘yish",close_modal,panel)

func continue_game() -> void:
	if not state.load_game():
		notify("Saqlangan yo‘l o‘qilmadi. Yangi sayohatni boshlang.")
		return
	playing = true
	selected_item = ""
	sound.apply_settings(state.data.settings)
	render_game()
	if state.flag("chapter_complete"):
		show_ending()

func render_game() -> void:
	clear_layer()
	art.set_room(state.data.room)
	art.completed = state.flag("chapter_complete")
	art.quality = state.data.settings.quality
	var top := Panel.new()
	top.add_theme_stylebox_override("panel",box(Color("0b1c25e8"),Color("405958"),0))
	place(top,Rect2(0,0,size.x,140))
	var brand := label_text("E N I G M A",26,GOLD)
	brand.add_theme_font_override("font",serif)
	place(brand,Rect2(32,18,270,40))
	place(label_text("I  /  NOMA’LUM XAT",14,MUTED),Rect2(34,66,280,25))
	place(label_text(location_names[state.data.room],24),Rect2(330,18,size.x-680,38))
	place(label_text(state.objective(),17,MUTED),Rect2(330,64,size.x-670,60))
	var top_buttons := HBoxContainer.new()
	top_buttons.add_theme_constant_override("separation",10)
	place(top_buttons,Rect2(size.x-310,24,280,64))
	button("Yordam",show_hint,top_buttons,130)
	button("Tanaffus",show_pause,top_buttons,130)
	add_hotspots()
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation",10)
	place(nav,Rect2(32,size.y-245,size.x-64,60))
	for room_id in ["platform","hall","office","cellar"]:
		var id: String = room_id
		var title: String = {"platform":"Perron","hall":"Kutish zali","office":"Boshliq xonasi","cellar":"Yerosti xona"}[id]
		if id == state.data.room:
			title = "◈ " + title
		var b := button(title,func(): go_room(id),nav)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = (id == "office" and not state.flag("office_unlocked")) or (id == "cellar" and not state.flag("clock_set"))
	var bottom := Panel.new()
	bottom.add_theme_stylebox_override("panel",box(Color("0b1c25f5"),Color("405958"),0))
	place(bottom,Rect2(0,size.y-170,size.x,170))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	place(actions,Rect2(24,size.y-155,230,145))
	button("Kundalik",show_journal,actions)
	button("Xarita va dalillar",show_map,actions)
	var inventory := HBoxContainer.new()
	inventory.add_theme_constant_override("separation",10)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	place(scroll,Rect2(280,size.y-126,size.x-306,116))
	scroll.add_child(inventory)
	place(label_text("ANJOMLAR   /   Buyumni tanlang, keyin joyga yoki boshqa buyumga teging",14,GOLD),Rect2(286,size.y-155,size.x-316,25))
	for item_id in state.data.inventory:
		var id: String = item_id
		var item: Dictionary = state.items[id]
		var b := button(("◈ " if selected_item == id else "◇ ") + item.name,func(): choose_item(id),inventory,170)
		b.custom_minimum_size.y = 82
		b.add_theme_font_size_override("font_size",17)
		b.set_meta("item_id",id)
		b.set_script(preload("res://scripts/ui/inventory_button.gd"))
		b.item_id = id
		b.owner_ui = self
	if state.data.inventory.is_empty():
		inventory.add_child(label_text("Hozircha buyum yo‘q. Atrofni tekshiring.",18,MUTED))

func add_hotspot(title: String, point: Vector2, action: Callable, done := false) -> void:
	var b := button(("✓ " if done else "◇ ")+title,action,layer)
	b.set_script(preload("res://scripts/ui/hotspot_button.gd"))
	b.owner_ui = self
	b.interact = action
	b.add_theme_font_size_override("font_size",17)
	b.add_theme_stylebox_override("normal",box(Color("10272dd9"),Color("778777")))
	b.position = Vector2(point.x*size.x/1440 - 90, clampf(point.y*size.y/900,155,size.y-325))
	b.custom_minimum_size.x = 180
	b.size.y = 60

func add_hotspots() -> void:
	match state.data.room:
		"platform":
			add_hotspot("Jomadon",Vector2(1000,575),show_suitcase,state.flag("suitcase_open"))
			add_hotspot("Qatnov jadvali",Vector2(420,390),show_timetable)
			add_hotspot("Bekat eshigi",Vector2(740,450),func(): go_room("hall"))
			if not state.has_item("ticket"):
				add_hotspot("Yirtilgan chipta",Vector2(260,580),func(): collect("ticket","Perron changli, lekin chipta hali quruq. Kimdir hozirgina shu yerda bo‘lgan."))
			add_hotspot("Signal chiroqlari",Vector2(1200,410),show_signal,state.flag("signal_sent"))
		"hall":
			add_hotspot("Xatning muhri",Vector2(380,510),show_cipher,state.flag("cipher_solved"))
			add_hotspot("Boshliq eshigi",Vector2(1040,430),unlock_office,state.flag("office_unlocked"))
			add_hotspot("Katta soat",Vector2(720,340),show_clock,state.flag("clock_set"))
			add_hotspot("G‘alati tamg‘a",Vector2(180,390),show_secret,state.flag("secret_found"))
		"office":
			add_hotspot("Halqali shkaf",Vector2(1100,440),show_cabinet,state.flag("cabinet_open"))
			if not state.has_item("wet_note"):
				add_hotspot("Nam yozuv",Vector2(650,530),func(): collect("wet_note","«Chiroqni chap, o‘ng, o‘rta, chap tartibida yoq. Poyezd elektrni emas, xotirani eshitadi.»\n\nSiyoh hali qurimagan. Imzo: M. — 21:16."))
			add_hotspot("Eski portret",Vector2(300,350),show_dialogue)
		"cellar":
			add_hotspot("Tarmoq paneli",Vector2(760,400),show_power,state.flag("power_restored"))
			add_hotspot("Zinapoya",Vector2(250,500),func(): go_room("hall"))

func go_room(id: String) -> void:
	if transition_busy:
		return
	if id == "office" and not state.flag("office_unlocked"):
		unlock_office()
		return
	if id == "cellar" and not state.flag("clock_set"):
		notify("Yerosti eshigi soat mexanizmiga ulangan.")
		return
	transition_busy = true
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.04,0.06,0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var tween := create_tween()
	tween.tween_property(shade,"color:a",1.0,0.18)
	await tween.finished
	state.data.room = id
	persist()
	sound.effect("door")
	render_game()
	move_child(shade,get_child_count()-1)
	create_tween().tween_property(shade,"color:a",0.0,0.3).finished.connect(shade.queue_free)
	transition_busy = false

func open_modal(title: String, description: String = "") -> void:
	close_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.035,0.05,0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel",box(Color("10272f"),GOLD,10))
	frame.position = Vector2(maxf(24,(size.x-960)/2),38)
	frame.size = Vector2(minf(960,size.x-48),size.y-76)
	modal.add_child(frame)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation",14)
	frame.add_child(outer)
	var header := HBoxContainer.new()
	outer.add_child(header)
	var heading := label_text(title,30,GOLD)
	heading.add_theme_font_override("font",serif)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	button("Yopish  ×",close_modal,header,130)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation",18)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	if not description.is_empty():
		panel.add_child(label_text(description,22))
	frame.modulate.a = 0
	create_tween().tween_property(frame,"modulate:a",1.0,0.16)

func close_modal() -> void:
	memory_busy = false
	if is_instance_valid(modal):
		modal.hide()
		modal.queue_free()
	modal = null

func notify(message: String) -> void:
	toast_generation += 1
	var generation := toast_generation
	if is_instance_valid(toast_label):
		toast_label.queue_free()
	toast_label = label_text(message,21,IVORY)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_stylebox_override("normal",box(Color("214741f5"),GOLD))
	toast_label.position = Vector2(size.x*0.16,size.y*0.16)
	toast_label.size = Vector2(size.x*0.68,76)
	add_child(toast_label)
	await get_tree().create_timer(4).timeout
	if generation == toast_generation and is_instance_valid(toast_label):
		toast_label.queue_free()

func collect(id: String, text: String) -> void:
	state.add_item(id)
	if id in ["ticket","wet_note"]:
		state.add_evidence(id)
	state.add_journal(id)
	persist()
	sound.effect("collect")
	render_game()
	open_modal(state.items[id].name,text)
	button("Dalillarni ko‘rish",show_evidence,panel)

func choose_item(id: String) -> void:
	if not selected_item.is_empty() and selected_item != id:
		combine_items(selected_item,id)
		return
	selected_item = id
	render_game()
	open_modal(state.items[id].name,state.items[id].description)
	button("Tanlash va joyga ishlatish",close_modal,panel)
	button("Tanlovni bekor qilish",func(): selected_item=""; close_modal(); render_game(),panel)

func combine_items(a: String,b: String) -> void:
	if state.combine(a,b):
		selected_item = ""
		persist()
		render_game()
		sound.effect("success")
		notify("Soat yana yurdi. Ko‘rsatkichlar 21:15 da to‘xtadi.")
	else:
		selected_item = b
		render_game()
		notify("Bu buyumlar bir-biriga mos kelmaydi. Tanlov o‘zgardi.")

func show_timetable() -> void:
	state.add_journal("timetable")
	persist()
	open_modal("Qoratepa • Qatnov jadvali", "Oxirgi qatnov: 03:14\nYo‘nalish: Qoratepa — noma’lum\nHolat: KUTILMOQDA\n\nJadval chetida tirnalgan yozuv:\n«Jomadonimga vaqtni yashirdim. Boshlang‘ich nolning keragi yo‘q».\n\nSoatlar to‘xtagan. Ammo kimdir hali ham qatnovni kutmoqda.")

func show_suitcase() -> void:
	if state.flag("suitcase_open"):
		open_modal("Ochiq jomadon","Jez kalit va singan cho‘ntak soati olindi. Qopqoq ichida sizning ismingiz yozilgandek… ammo harflar o‘chib ketgan.")
		return
	puzzle_values = [0,0,0]
	open_modal("Yo‘lovchining jomadoni","Uch raqamli eski qulf. Safar vaqti qayerdadir yozilgan bo‘lishi kerak.")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",24)
	panel.add_child(row)
	for i in range(3):
		var index := i
		var b := button("0",func(): pass,row,130)
		b.custom_minimum_size.y = 140
		b.add_theme_font_size_override("font_size",56)
		b.pressed.connect(func(): puzzle_values[index]=(int(puzzle_values[index])+1)%10; b.text=str(puzzle_values[index]); sound.effect("mechanism"))
	panel.add_child(label_text("Har bir g‘ildirakka tegib raqamni aylantiring.",18,MUTED))
	button("Qulfni ochish",func(): attempt("suitcase_open","%d%d%d" % puzzle_values),panel)

func show_cipher() -> void:
	if state.flag("cipher_solved"):
		open_modal("Xatning yashirin qatlami","Muhr ochildi: «Boshliq shkafi ham shu tartibni eslaydi. Vaqtni qaytarish uchun uning yuragini top».\n\nOy → Ko‘z → Quyosh")
		return
	open_modal("Xotira muhri","Xat chetida kalit bor:\nKo‘z = 1     Oy = 2     Quyosh = 3\n\n«Avval tun uyg‘onar, so‘ng kuzatuvchi qarar, keyin tong ochar».\nBelgilarni shu tartibga keltiring.")
	symbol_controls("cipher_solved")

func symbol_controls(puzzle_id: String) -> void:
	puzzle_values = [1,1,1]
	var rings := PuzzleArt.new()
	rings.mode = "rings"
	rings.values = puzzle_values
	rings.custom_minimum_size = Vector2(300,220)
	panel.add_child(rings)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",16)
	panel.add_child(row)
	var names := ["", "◉  Ko‘z", "☾  Oy", "☀  Quyosh"]
	for i in range(3):
		var index := i
		var b := button(names[1],func(): pass,row,200)
		b.pressed.connect(func(): puzzle_values[index]=int(puzzle_values[index])%3+1; b.text=names[puzzle_values[index]]; rings.queue_redraw(); sound.effect("mechanism"))
	button("Muhrni tekshirish",func(): attempt(puzzle_id,puzzle_values.duplicate()),panel)

func unlock_office() -> void:
	if state.flag("office_unlocked"):
		go_room("office")
		return
	if selected_item == "brass_key" and state.has_item("brass_key"):
		attempt("office_unlocked","brass_key")
		return
	open_modal("Jez qulf","Boshliq xonasi qulflangan. Anjomlardan mos kalitni tanlab, eshikka yana teging.")
	if state.has_item("brass_key"):
		button("Jez kalit bilan ochish",func(): attempt("office_unlocked","brass_key"),panel)

func show_cabinet() -> void:
	if state.flag("cabinet_open"):
		open_modal("Mexanik shkaf","Tishli g‘ildirak olindi. Uni singan soat bilan birlashtirish mumkin.")
		return
	if not state.flag("cipher_solved"):
		open_modal("Uch halqali shkaf","Halqalarda xatdagi belgilar bor. Avval kutish zalidagi xat muhrini yeching.")
		return
	open_modal("Uch halqali mexanizm","Xatdagi ketma-ketlikni halqalarda takrorlang. Ichkarida nimadir sekin jaranglaydi.")
	symbol_controls("cabinet_open")

func show_clock() -> void:
	if state.flag("clock_set"):
		open_modal("Yurgan soat","Soat korpusidagi saqlagich olindi. Polda yerosti xonasiga tushadigan eshik ochildi.")
		return
	if not state.flag("watch_repaired"):
		open_modal("Sukutdagi katta soat","Bu soat qaysi daqiqada to‘xtagan? Singan cho‘ntak soati javobni saqlagan bo‘lishi mumkin.")
		return
	puzzle_values = [0,0]
	open_modal("To‘xtagan daqiqani qaytaring","Tuzatilgan cho‘ntak soati: 21:15. Katta soat ham shu vaqtni kutmoqda.")
	var clock := PuzzleArt.new()
	clock.values = puzzle_values
	clock.custom_minimum_size = Vector2(320,260)
	panel.add_child(clock)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",20)
	panel.add_child(row)
	var time_label := label_text("00:00",32,GOLD)
	button("Soat +1",func(): puzzle_values[0]=(int(puzzle_values[0])+1)%24; time_label.text="%02d:%02d" % puzzle_values; clock.queue_redraw(),row,200)
	row.add_child(time_label)
	button("Daqiqa +5",func(): puzzle_values[1]=(int(puzzle_values[1])+5)%60; time_label.text="%02d:%02d" % puzzle_values; clock.queue_redraw(),row,200)
	button("Mexanizmni uyg‘otish",func(): attempt("clock_set",puzzle_values.duplicate()),panel)

func show_power() -> void:
	if state.flag("power_restored"):
		open_modal("Uyg‘ongan tarmoq","Signal chiroqlariga tok yetib bordi. Ammo poyezdni chaqirish uchun dalillarni birlashtirish kerak.")
		return
	if not state.has_item("fuse"):
		open_modal("Uzilgan tarmoq","Saqlagich yetishmaydi. Kutish zalidagi soat korpusini tekshiring.")
		return
	puzzle_values = [false,false,false]
	open_modal("Aloqa tarmog‘i","Saqlagich o‘z joyiga tushdi. Paneldagi lavha: «Ikki chet uyg‘oq, o‘rta uyquda».\nUch kalitni to‘g‘ri holatga keltiring.")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",20)
	panel.add_child(row)
	for i in range(3):
		var index := i
		var b := button("%d\n○ O‘chiq" % (i+1),func(): pass,row,200)
		b.custom_minimum_size.y = 160
		b.pressed.connect(func(): puzzle_values[index]=not puzzle_values[index]; b.text="%d\n%s" % [index+1,"● Yoniq" if puzzle_values[index] else "○ O‘chiq"]; sound.effect("mechanism"))
	button("Tarmoqni ulash",func(): attempt("power_restored",puzzle_values.duplicate()),panel)

func show_signal() -> void:
	if state.flag("signal_sent"):
		show_ending()
		return
	if not state.flag("power_restored") or not state.flag("evidence_linked"):
		open_modal("Sukutdagi signal","Chiroqlarni yoqish uchun tarmoqni tiklang. Chaqiruv tartibini tushunish uchun chipta va nam yozuvni dalillar doskasida bog‘lang.")
		return
	memory_input = []
	open_modal("Xotira signali","Nam yozuv: chap → o‘ng → o‘rta → chap. Namoyishni kuzating, so‘ng shu ketma-ketlikni takrorlang.")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",20)
	panel.add_child(row)
	var lamps: Array = []
	var status := label_text("Ketma-ketlik kiritilmadi.",20,GOLD)
	for i in range(3):
		var index := i
		var b := button(["Chap","O‘rta","O‘ng"][i],func(): signal_press(index,status),row,200)
		b.custom_minimum_size.y = 150
		lamps.append(b)
	panel.add_child(status)
	button("Ketma-ketlikni ko‘rsatish",func(): play_memory(lamps,status),panel)
	button("Qaytadan kiritish",func(): memory_input.clear(); status.text="Yangi urinish.",panel)

func play_memory(lamps: Array,status: Label) -> void:
	if memory_busy:
		return
	memory_busy = true
	memory_input.clear()
	status.text = "Chiroqlarni kuzating…"
	for index in [0,2,1,0]:
		if not is_instance_valid(modal):
			memory_busy = false
			return
		lamps[index].modulate = Color("ffe49f") * 1.7
		sound.effect("clock")
		await get_tree().create_timer(0.5).timeout
		if not is_instance_valid(lamps[index]):
			memory_busy = false
			return
		lamps[index].modulate = Color.WHITE
		await get_tree().create_timer(0.2).timeout
	if is_instance_valid(status):
		status.text = "Endi navbat sizda."
	memory_busy = false

func signal_press(index: int,status: Label) -> void:
	if memory_busy:
		return
	memory_input.append(index)
	sound.effect("clock")
	status.text = "Kiritildi: %d / 4" % memory_input.size()
	if memory_input.size() == 4:
		if state.solve_puzzle("signal_sent",memory_input):
			state.finish_chapter()
			persist()
			sound.effect("success")
			render_game()
			sound.effect("train")
			show_ending()
		else:
			memory_input.clear()
			status.text = "Signal mos kelmadi. Yana urinib ko‘ring."

func attempt(id: String, answer: Variant) -> void:
	if state.solve_puzzle(id,answer):
		selected_item = ""
		persist()
		sound.effect("success")
		render_game()
		var rewards := {"suitcase_open":"Jomadon ochildi. Jez kalit va singan cho‘ntak soati olindi.","cipher_solved":"Muhr yechildi. Shkafning siri xatdagi belgilar bilan bog‘liq.","office_unlocked":"Jez qulf ochildi. Boshliq xonasi endi ochiq.","cabinet_open":"Shkaf ochildi. Kichik tishli g‘ildirak olindi.","clock_set":"Soat uyg‘ondi. Saqlagich olindi, yerosti yo‘li ochildi.","power_restored":"Tarmoq tiklandi. Perrondagi signal chiroqlari yondi.","evidence_linked":"Xulosa: kimdir sizdan bir daqiqa oldin kelgan. Signal ketma-ketligi aniqlandi."}
		success_flash()
		notify(rewards.get(id,"Mexanizm ishga tushdi."))
		hint_level = 0
	else:
		sound.effect("error")
		notify("Hali mos kelmadi. Kundalikdagi ishoralarni tekshiring.")

func show_evidence() -> void:
	evidence_selected = []
	open_modal("Dalillar doskasi","Bir-biriga bog‘liq ikki dalilni tanlang. Nega bir joyda vaqt izlari turlicha?")
	for id in ["ticket","wet_note"]:
		var evidence_id: String = id
		if state.data.evidence.has(id):
			var b := button("◇ "+state.items[id].name,func(): pass,panel)
			b.pressed.connect(func():
				if evidence_selected.has(evidence_id):
					evidence_selected.erase(evidence_id)
					b.text="◇ "+state.items[evidence_id].name
				else:
					evidence_selected.append(evidence_id)
					b.text="◈ "+state.items[evidence_id].name)
			panel.add_child(label_text(state.items[id].description,20,MUTED))
		else:
			panel.add_child(label_text("Topilmagan dalil: "+("perrondagi iz" if id=="ticket" else "boshliq stolidagi yozuv"),20,MUTED))
	if state.flag("evidence_linked"):
		panel.add_child(label_text("XULOSA: Chipta 21:15 da bosilgan. Yozuv esa 21:16 da qoldirilgan. Kimdir hali ham shu yerda. Chiroqlar: chap, o‘ng, o‘rta, chap.",24,GOLD))
	else:
		button("Tanlangan dalillarni bog‘lash",func(): attempt("evidence_linked",evidence_selected.duplicate()),panel)

func show_journal() -> void:
	open_modal("Sayohat kundaligi",state.objective())
	for id in state.data.journal:
		var entry: Variant = state.journal_defs.get(id,id)
		if entry is Dictionary:
			panel.add_child(label_text(entry.get("title",id),24,GOLD))
			panel.add_child(label_text(entry.get("text",""),21))
		else:
			panel.add_child(label_text(str(entry),21))
	button("Dalillar doskasini ochish",show_evidence,panel)

func show_map() -> void:
	open_modal("Qoratepa bekati", "YO‘L XARITASI\nPerron ↔ Kutish zali ↔ Boshliq xonasi\n                         ↕\n                  Yerosti aloqa xonasi\n\nJoriy vazifa: "+state.objective())
	for room_id in ["platform","hall","office","cellar"]:
		var id: String = room_id
		var b := button(("◈ " if id==state.data.room else "→ ")+location_names[id],func(): go_room(id),panel)
		b.disabled = (id=="office" and not state.flag("office_unlocked")) or (id=="cellar" and not state.flag("clock_set"))
	button("Dalillar doskasi",show_evidence,panel)

func show_hint() -> void:
	var next := "signal_sent"
	for id in ["suitcase_open","cipher_solved","office_unlocked","cabinet_open","watch_repaired","clock_set","power_restored","evidence_linked","signal_sent"]:
		if not state.flag(id):
			next = id
			break
	open_modal("Ishora • %d / 3" % (hint_level+1),hints[next][hint_level])
	if hint_level < 2:
		button("Aniqroq ishora",func(): hint_level+=1; show_hint(),panel)
	else:
		button("Izlanishni davom ettirish",close_modal,panel)

func show_dialogue() -> void:
	open_modal("Portret ortidagi ovoz","Portret ostida «M. Orif — bekat boshlig‘i, 1931» deb yozilgan.\n\nEski radio shivirlaydi: «Ismingizni eslaysizmi? Xatda yozilgan ismga ishonmang…»")
	button("«Siz kimsiz?»",func(): dialogue_choice("identity","«Men bu bekatning xotirasiman. Meni Malik deb chaqirishardi. Xatni kim yozganini hali ayta olmayman.»"),panel)
	button("«Bu yerda qolaman. Haqiqatni topaman.»",func(): dialogue_choice("trust","«Unda soatni uyg‘oting. Lekin esda tuting: kelgan har bir poyezd ham qaytmaydi.»"),panel)

func dialogue_choice(choice: String,reply: String) -> void:
	state.data.choices["malik"] = choice
	state.add_journal("malik")
	persist()
	open_modal("Malikning ogohlantirishi",reply)

func show_secret() -> void:
	if not state.flag("cipher_solved"):
		open_modal("Devor tamg‘asi","Ko‘z, oy va quyosh. Xat muhri bilan bir xil belgilar. G‘isht ortidan mayin jarang eshitiladi.")
		return
	state.set_flag("secret_found")
	state.add_item("artifact")
	state.add_journal("secret")
	persist()
	open_modal("Yashirin tokcha","Devor ichidan xotira parchasi topildi. Unda yetti nuqta bor; faqat bittasi yorishgan.\n\nBu topilma yo‘lingizni to‘smaydi. Lekin kimdir uni aynan siz uchun yashirgan.")
	var file := FileAccess.open("res://data/personalized.json",FileAccess.READ)
	if file:
		var content: Variant = JSON.parse_string(file.get_as_text())
		if content is Dictionary and content.get("enabled",false):
			panel.add_child(label_text(content.get("message",""),22,GOLD))

func show_ending() -> void:
	art.completed = true
	open_modal("I bob yakuni • Soatsiz qatnov", "Relslar titradi. Chiroqlar birin-ketin yondi. Qorong‘ilikdan poyezd chiqib keldi — simlarda tok yo‘q, mashinist o‘rni esa bo‘sh edi.\n\nDerazadagi bug‘da bitta jumla paydo bo‘ldi:\n«Xush kelibsiz. Sizni yana kutgandik».\n\nQo‘lingizdagi xatning sanasi o‘zgardi. Endi u ertaga yozilgan edi.")
	button("Poyezdni kuzatish",close_modal,panel)
	button("Boblar xaritasi",show_chapters,panel)
	button("Bosh menyuga qaytish",show_menu,panel)

func show_chapters() -> void:
	open_modal("Unutilgan olam • Yetti bob","Hozir birinchi bob o‘ynaladi. Qolgan boblar hikoya xaritasida rejalashtirilgan; ular hali o‘ynash uchun tayyor emas.")
	var names := ["I — Noma’lum xat","II — Unutilgan qasr","III — Sirlar kutubxonasi","IV — Sehrli o‘rmon","V — Soat minorasi","VI — Yerosti shahri","VII — So‘nggi haqiqat"]
	for i in range(7):
		if i == 0:
			button(names[i]+("  ✓" if state.flag("chapter_complete") else ""),func(): close_modal(); continue_game() if state.has_save() else start_new(),panel)
		else:
			var l := label_text("◇  "+names[i]+"  •  Tayyorlanmoqda",21,MUTED)
			panel.add_child(l)

func show_pause() -> void:
	open_modal("Bir zum to‘xtang","Yo‘lingiz har bir muhim kashfiyotdan keyin avtomatik saqlanadi.")
	button("Davom etish",close_modal,panel)
	button("Hozir saqlash",func(): persist(); notify("Sayohat saqlandi."),panel)
	button("Sozlamalar",show_settings,panel)
	button("Bosh menyu",func(): persist(); show_menu(),panel)

func show_settings() -> void:
	open_modal("Sozlamalar","Ovozlar alohida boshqariladi. Sifat darajasi muhit effektlari va kadrlar chegarasini o‘zgartiradi.")
	for key in ["music","sfx","ambient"]:
		var id: String = key
		panel.add_child(label_text({"music":"Musiqa","sfx":"Tovushlar","ambient":"Atrof-muhit ovozi"}[id],21,GOLD))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = state.data.settings.get(id,0.65)
		slider.custom_minimum_size.y = 60
		panel.add_child(slider)
		slider.value_changed.connect(func(value): state.data.settings[id]=value; sound.apply_settings(state.data.settings))
	var quality_row := HBoxContainer.new()
	quality_row.add_theme_constant_override("separation",12)
	panel.add_child(quality_row)
	for i in range(3):
		var quality := i
		button(["Tejamkor","Muvozanatli","Yuqori sifat"][i],func():
			state.data.settings.quality=quality
			art.quality=quality
			Engine.max_fps=[30,60,60][quality]
			notify("Sifat sozlandi: "+["tejamkor","muvozanatli","yuqori"][quality]),quality_row,220)
	button("Sozlamalarni saqlash",func(): persist(); close_modal(); notify("Sozlamalar saqlandi."),panel)

func show_credits() -> void:
	open_modal("ENIGMA • Unutilgan olam","G‘oya va loyiha egasi: Odilxon Abdullayev\n\nO‘zbek tilidagi mustaqil sirli sarguzasht.\nAsl protseduraviy muhit tasvirlari va sintezlangan musiqa shu loyiha uchun yaratilgan.\n\nShriftlar: DejaVu Sans / Serif (erkin litsenziya).\nDvigatel: Godot (MIT).\n\nBirinchi bob — v0.2.0. Android qurilmadagi ishlash tezligi hali o‘lchanmagan.")

	button("Litsenziyalarni o‘qish",show_licenses,panel)

func show_licenses() -> void:
	open_modal("Dastur va shrift litsenziyalari", FileAccess.get_file_as_string("res://assets/licenses/Godot.txt") + "\n\n" + FileAccess.get_file_as_string("res://assets/fonts/LICENSE.txt"))

func persist() -> bool:
	var result: Error = state.save_game()
	if result != OK:
		notify("Sayohat saqlanmadi. Qurilmadagi bo‘sh joyni tekshiring.")
	return result == OK

func success_flash() -> void:
	var glow := ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.color = Color(0.48,0.69,0.51,0.22)
	add_child(glow)
	create_tween().tween_property(glow,"color:a",0.0,0.65).finished.connect(glow.queue_free)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(modal):
			close_modal()
		elif playing:
			show_pause()
	if what == NOTIFICATION_APPLICATION_PAUSED and playing:
		persist()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(modal):
			close_modal()
		elif playing:
			show_pause()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	localizer.uninstall()
