extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/menu.png")
	game.start_new()
	game.close_modal()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/platform.png")
	for room in ["hall","office","cellar"]:
		game.state.data.room=room
		game.render_game()
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/"+room+".png")
	game.show_suitcase()
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/puzzle.png")
	game.close_modal()
	game.state.data.room="platform"
	game.state.set_flag("chapter_complete")
	game.render_game()
	await create_timer(3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/train.png")
	await create_timer(0.5).timeout
	game.queue_free()
	await create_timer(0.15).timeout
	quit()
