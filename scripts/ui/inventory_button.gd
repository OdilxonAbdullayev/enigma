extends Button

var item_id := ""
var owner_ui: Control

func _get_drag_data(_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = text
	set_drag_preview(preview)
	owner_ui.selected_item = item_id
	return {"enigma_item": item_id}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("enigma_item") and data.enigma_item != item_id

func _drop_data(_position: Vector2, data: Variant) -> void:
	owner_ui.combine_items(data.enigma_item,item_id)
