extends Node
## Original offline score, rain and pooled interaction audio with independent gains.
var music: AudioStreamPlayer
var ambient: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var settings: Dictionary = {"music": 0.6, "ambient": 0.5, "sfx": 0.7}
var cursor := 0

func start() -> void:
	if is_instance_valid(music):
		return
	music = _loop_player("res://assets/audio/station_theme.wav")
	ambient = _loop_player("res://assets/audio/station_rain.wav")
	for i in range(4):
		var player := AudioStreamPlayer.new()
		add_child(player)
		effects.append(player)
	apply_settings(settings)

func _loop_player(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := load(path) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	player.stream = stream
	add_child(player)
	player.play()
	return player

func apply_settings(values: Dictionary) -> void:
	for key in ["music", "ambient", "sfx"]:
		settings[key] = clampf(float(values.get(key, settings[key])), 0.0, 1.0)
	if is_instance_valid(music):
		music.volume_db = linear_to_db(maxf(float(settings.music), 0.0001))
		music.stream_paused = float(settings.music) <= 0.0
	if is_instance_valid(ambient):
		ambient.volume_db = linear_to_db(maxf(float(settings.ambient), 0.0001))
		ambient.stream_paused = float(settings.ambient) <= 0.0
	for player in effects:
		player.volume_db = linear_to_db(maxf(float(settings.sfx), 0.0001))

func effect(kind: String = "touch") -> void:
	if effects.is_empty() or float(settings.sfx) <= 0.0:
		return
	var file := "touch"
	if kind in ["success", "solved", "collect", "discovery"]:
		file = "success"
	elif kind in ["mechanism", "door", "clock", "switch", "error"]:
		file = "mechanism"
	elif kind in ["train", "ending"]:
		file = "train"
	var player := effects[cursor % effects.size()]
	cursor += 1
	player.stream = load("res://assets/audio/%s.wav" % file)
	player.play()

func _exit_tree() -> void:
	# Explicitly detach playback resources before the audio server shuts down.
	for player in [music, ambient]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for player in effects:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	effects.clear()
