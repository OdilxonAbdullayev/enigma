extends RefCounted
## Uzbek source strings are stable message IDs. Missing translations fall back to
## the bundled Uzbek catalogue, then to the source text. No network is required.
## Add data/localization/<language>.json with the same message IDs to add a locale.

const DEFAULT_LOCALE := "uz"
const CATALOG_DIRECTORY := "res://data/localization/"
var language := DEFAULT_LOCALE
var catalogs: Dictionary = {}
var installed_translations: Array[Translation] = []

func _init(locale: String = DEFAULT_LOCALE) -> void:
	load_catalog(DEFAULT_LOCALE)
	set_locale(locale)

func load_catalog(locale: String) -> bool:
	if not _valid_locale(locale):
		return false
	var path := CATALOG_DIRECTORY + locale + ".json"
	if not FileAccess.file_exists(path):
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		return false
	var document: Dictionary = parser.data
	if document.get("locale") != locale or not document.get("messages") is Dictionary:
		return false
	return register_catalog(locale, document.messages)

func register_catalog(locale: String, messages: Dictionary) -> bool:
	if not _valid_locale(locale):
		return false
	for key: Variant in messages:
		if not key is String or not messages[key] is String:
			return false
	catalogs[locale] = messages.duplicate(true)
	return true

func set_locale(locale: String) -> bool:
	if not catalogs.has(locale) and not load_catalog(locale):
		return false
	language = locale
	return true

func text(source: String, parameters: Dictionary = {}) -> String:
	var result := source
	if catalogs.has(DEFAULT_LOCALE):
		result = str(catalogs[DEFAULT_LOCALE].get(source, source))
	if catalogs.has(language):
		var translated: String = catalogs[language].get(source, "")
		if not translated.is_empty():
			result = translated
	return result.format(parameters) if not parameters.is_empty() else result

func install(locale: String = DEFAULT_LOCALE) -> bool:
	# Integrates Godot's built-in Label/Button auto-translation and Node.tr().
	if not set_locale(locale):
		return false
	uninstall()
	for code: String in [DEFAULT_LOCALE, language]:
		if not catalogs.has(code):
			continue
		if code == DEFAULT_LOCALE and code == language and not installed_translations.is_empty():
			continue
		var translation := Translation.new()
		translation.locale = code
		for source: String in catalogs[code]:
			var translated: String = catalogs[code][source]
			if not translated.is_empty():
				translation.add_message(source, translated)
		TranslationServer.add_translation(translation)
		installed_translations.append(translation)
	TranslationServer.set_locale(language)
	return true

func uninstall() -> void:
	for translation: Translation in installed_translations:
		TranslationServer.remove_translation(translation)
	installed_translations.clear()

func _valid_locale(locale: String) -> bool:
	# Restrict filenames to locale codes; never allow traversal or arbitrary paths.
	if locale.length() < 2 or locale.length() > 16:
		return false
	for character: String in locale:
		if not "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".contains(character):
			return false
	return true
