extends SceneTree
const Localizer = preload("res://scripts/localization/localizer.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var locale = Localizer.new()
	check(locale.catalogs.has("uz"), "Bundled Uzbek catalog loads offline")
	check(locale.catalogs.uz.size() > 250, "Catalog includes game and data strings")
	check(locale.text("Davom etish") == "Davom etish", "Uzbek source is default")
	check(locale.text("O‘qilmagan matn") == "O‘qilmagan matn", "Unknown key retains readable source")
	check(locale.register_catalog("en", {"Davom etish": "Continue", "{name}, xush kelibsiz!": "Welcome, {name}!"}), "Additional language registers without scene changes")
	check(locale.set_locale("en"), "Locale can change")
	check(locale.text("Davom etish") == "Continue", "Registered translation resolves")
	check(locale.text("{name}, xush kelibsiz!", {"name": "Nodir"}) == "Welcome, Nodir!", "Named format parameters preserved")
	check(locale.text("Sozlamalar") == "Sozlamalar", "Missing translation falls back to Uzbek")
	check(not locale.set_locale("unavailable"), "Unavailable locale rejected")
	check(locale.language == "en", "Failed switch retains current locale")
	check(not locale.load_catalog("../../bad"), "Locale filenames cannot traverse directories")
	check(not locale.register_catalog("en", {"bad": 12}), "Catalog values must be strings")
	check(locale.text("Davom etish") == "Continue", "Invalid replacement does not damage active catalog")
	check(locale.install("en"), "Native Godot translation installs")
	check(TranslationServer.translate("Davom etish") == "Continue", "Godot TranslationServer receives translated messages")
	locale.uninstall()
	check(locale.install("uz"), "Uzbek native translation installs")
	check(TranslationServer.translate("Sozlamalar") == "Sozlamalar", "Uzbek Latin characters remain available")
	locale.uninstall()
	print("LOCALIZATION TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
