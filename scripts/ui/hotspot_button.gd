extends Button

var owner_ui: Control
var interact: Callable

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("enigma_item")

func _drop_data(_position: Vector2, data: Variant) -> void:
	owner_ui.selected_item = data.enigma_item
	interact.call()
