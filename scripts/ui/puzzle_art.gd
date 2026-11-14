extends Control

var mode := "clock"
var values: Array = [21, 15]
var gold := Color("c9aa70")

func _draw() -> void:
	var c := size / 2
	var r: float = minf(size.x, size.y) * 0.43
	draw_circle(c, r + 8, Color("102e36"))
	draw_arc(c, r, 0, TAU, 96, gold, 2, true)
	draw_arc(c, r - 12, 0, TAU, 96, Color("57716c"), 1, true)
	for i in range(60):
		var a := i * TAU / 60 - PI / 2
		var length := 15 if i % 5 == 0 else 5
		draw_line(c + Vector2.from_angle(a) * (r - 18), c + Vector2.from_angle(a) * (r - 18 - length), gold, 2, true)
	if mode == "clock":
		var hour: float = float(values[0]) / 12 * TAU + float(values[1]) / 60 * TAU / 12 - PI / 2
		var minute: float = float(values[1]) / 60 * TAU - PI / 2
		draw_line(c, c + Vector2.from_angle(hour) * r * 0.45, gold, 7, true)
		draw_line(c, c + Vector2.from_angle(minute) * r * 0.7, Color("f0e7cf"), 4, true)
		draw_circle(c, 8, gold)
	else:
		for n in range(3):
			var rad := r * (0.35 + n * 0.22)
			draw_arc(c, rad, 0, TAU, 64, gold, 2, true)
			var a := float(values[n]) * TAU / 3 - PI / 2
			draw_circle(c + Vector2.from_angle(a) * rad, 8, Color("ede2c4"))
