extends Control
## Original vector-painted station. All world geometry is generated locally; no network assets.
## Coordinates are authored at 1440×900 and scale independently with the viewport.
var room: String = "platform":
	set(value):
		room = value
		queue_redraw()
var completed: bool = false
var quality: int = 1
var elapsed: float = 0.0
var frame_time: float = 0.0
const INK := Color("08131e")
const NAVY := Color("102a3b")
const BLUE := Color("1d4053")
const STONE := Color("35454b")
const GOLD := Color("b99c61")
const BRONZE := Color("62523c")
const LIGHT := Color("f5de9b")
const IVORY := Color("dfdcc5")
const GREEN := Color("44776b")
const DARK := Color("0b151b")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_room(value: String) -> void:
	room = value
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	frame_time += delta
	if frame_time > (1.0 / (20.0 if quality == 0 else 30.0)):
		frame_time = 0.0
		queue_redraw()

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: Array = []
	for i in range(40):
		var a: float = TAU*float(i)/40.0
		points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	_poly(points,color)

func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x,y,w,h),color)

func _line(a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	draw_line(a,b,color,width,true)

func _arch(x: float, bottom: float, w: float, h: float, color: Color, outline: Color = Color.TRANSPARENT) -> void:
	var rise: float = minf(w/2.0,h*0.60)
	var points: Array = [Vector2(x,bottom)]
	for i in range(25):
		var angle: float = PI + PI*float(i)/24.0
		points.append(Vector2(x+w/2.0+cos(angle)*w/2.0,bottom-h+rise+sin(angle)*rise))
	points.append(Vector2(x+w,bottom))
	_poly(points,color)
	if outline.a > 0:
		points.append(points[0])
		draw_polyline(PackedVector2Array(points),outline,2.0,true)

func _panel(x: float,y: float,w: float,h: float, fill: Color = NAVY) -> void:
	_rect(x+7,y+8,w,h,Color(0,0,0,0.32))
	_rect(x,y,w,h,BRONZE)
	_rect(x+3,y+3,w-6,h-6,fill)
	draw_rect(Rect2(x+10,y+10,w-20,h-20),Color(0.63,0.54,0.34,0.4),false,1.0)
	for p in [Vector2(x+5,y+5),Vector2(x+w-5,y+5),Vector2(x+5,y+h-5),Vector2(x+w-5,y+h-5)]:
		draw_circle(p,1.8,GOLD)

func _lamp(x: float,y: float,scale_value: float = 1.0) -> void:
	var pulse: float = 0.93 + sin(elapsed*2.3+x)*0.04+sin(elapsed*8.1)*0.02
	for i in range(6,0,-1):
		draw_circle(Vector2(x,y+20*scale_value),float(i)*15*scale_value,Color(1.0,0.73,0.32,0.009*pulse))
	_line(Vector2(x,y-20*scale_value),Vector2(x,y+45*scale_value),INK,4*scale_value)
	_poly([Vector2(x-20*scale_value,y-8*scale_value),Vector2(x+20*scale_value,y-8*scale_value),Vector2(x+14*scale_value,y+30*scale_value),Vector2(x-14*scale_value,y+30*scale_value)],Color("bd9756"))
	_poly([Vector2(x-15*scale_value,y-4*scale_value),Vector2(x+15*scale_value,y-4*scale_value),Vector2(x+10*scale_value,y+24*scale_value),Vector2(x-10*scale_value,y+24*scale_value)],Color(0.98,0.83,0.51,pulse))
	_line(Vector2(x,y-5*scale_value),Vector2(x,y+28*scale_value),BRONZE,2)
	_poly([Vector2(x-25*scale_value,y-8*scale_value),Vector2(x,y-27*scale_value),Vector2(x+25*scale_value,y-8*scale_value)],INK)
	_rect(x-17*scale_value,y+29*scale_value,34*scale_value,6*scale_value,INK)

func _gear(c: Vector2,r: float,angle: float,color: Color) -> void:
	var points: Array = []
	for i in range(64):
		var a: float = TAU*float(i)/64.0+angle
		var rr: float = r if i%4<2 else r*0.85
		points.append(c+Vector2(cos(a),sin(a))*rr)
	_poly(points,color)
	draw_circle(c,r*0.62,INK)
	for i in range(6):
		var a: float = TAU*float(i)/6.0+angle
		_line(c,c+Vector2(cos(a),sin(a))*r*0.70,color,r*0.11)
	draw_circle(c,r*0.19,color)
	draw_circle(c,r*0.07,INK)

func _clock(x: float,y: float,r: float) -> void:
	draw_circle(Vector2(x+6,y+6),r+9,Color(0,0,0,0.3))
	draw_circle(Vector2(x,y),r+8,BRONZE)
	draw_circle(Vector2(x,y),r+3,GOLD)
	draw_circle(Vector2(x,y),r,Color("c2c3ae"))
	draw_arc(Vector2(x,y),r-6,0,TAU,64,BRONZE,1.5,true)
	for i in range(60):
		var a: float = TAU*float(i)/60.0-PI/2
		var l: float = 12.0 if i%5==0 else 5.0
		_line(Vector2(x,y)+Vector2(cos(a),sin(a))*(r-9),Vector2(x,y)+Vector2(cos(a),sin(a))*(r-9-l),BRONZE,2.5 if i%5==0 else 1)
	_line(Vector2(x,y),Vector2(x-r*0.47,y-r*0.12),INK,5)
	_line(Vector2(x,y),Vector2(x+r*0.68,y),INK,3)
	draw_circle(Vector2(x,y),5,GOLD)

func _floor(horizon: float, tint: Color = Color("20333c")) -> void:
	_rect(0,horizon,1440,900-horizon,tint)
	for i in range(12):
		var yy: float = horizon+pow(float(i)/11.0,1.7)*(900-horizon)
		_line(Vector2(0,yy),Vector2(1440,yy),Color(0.40,0.48,0.49,0.20),1)
	for i in range(-9,10):
		_line(Vector2(720+float(i)*30,horizon),Vector2(720+float(i)*260,900),Color(0.02,0.06,0.08,0.5),2)
	for i in range(20):
		var x: float = fmod(float(i)*181.7,1440)
		var y: float = horizon+30+fmod(float(i)*79.1,310)
		_line(Vector2(x,y),Vector2(x+32+float(i%4)*17,y),Color(0.57,0.64,0.58,0.07),2)

func _brick_wall(top: float,bottom: float) -> void:
	_rect(0,top,1440,bottom-top,Color("233b46"))
	for j in range(int((bottom-top)/33.0)):
		var y: float = top+float(j)*33.0
		_line(Vector2(0,y),Vector2(1440,y),Color(0.08,0.16,0.19,0.48),1)
		for i in range(15):
			var x: float = float(i)*104.0+float(j%2)*52.0
			_line(Vector2(x,y),Vector2(x,y+33),Color(0.08,0.16,0.19,0.48),1)
			if (i+j)%7==0:
				_rect(x+5,y+5,87,23,Color(0.42,0.46,0.44,0.035))

func _window(x: float,y: float,w: float,h: float) -> void:
	_arch(x-8,y,w+16,h+9,Color("172530"),BRONZE)
	_arch(x,y,w,h,Color("294957"),Color("697873"))
	_arch(x+8,y-4,w-16,h-14,Color("345b63"))
	for i in range(1,4):
		_line(Vector2(x+w*float(i)/4,y-8),Vector2(x+w*float(i)/4,y-h+w/2),Color("172b33"),4)
	for yy in [y-h*0.65,y-h*0.35]:
		_line(Vector2(x+5,yy),Vector2(x+w-5,yy),Color("172b33"),5)
	_poly([Vector2(x+10,y-h+60),Vector2(x+w-10,y-h+60),Vector2(x+w+100,y+130),Vector2(x+15,y+130)],Color(0.51,0.76,0.77,0.035))
	_rect(x-13,y, w+26,11,BRONZE)

func _platform() -> void:
	_rect(0,0,1440,900,Color("132a3a"))
	# Distant hills, telegraph wires, and an abandoned track beyond the canopy.
	_poly([Vector2(0,350),Vector2(120,260),Vector2(260,323),Vector2(420,234),Vector2(610,332),Vector2(830,260),Vector2(1100,325),Vector2(1440,230),Vector2(1440,560),Vector2(0,560)],Color("183440"))
	for i in range(5):
		_line(Vector2(920,310+float(i)*24),Vector2(1440,285+float(i)*22),Color("0c222e"),1)
	_rect(0,170,1000,365,Color("223945"))
	for i in range(11):
		_line(Vector2(0,190+float(i)*31),Vector2(1000,190+float(i)*31),Color("1c303a"))
	_window(65,506,142,294)
	_window(480,506,112,294)
	# Time table, with the authored numerical clue supplied by the game UI.
	_panel(315,287,210,223,Color("192d33"))
	_rect(326,300,188,24,BRONZE)
	for i in range(6):
		_line(Vector2(334,342+float(i)*25),Vector2(504,342+float(i)*25),Color(0.67,0.67,0.52,0.3))
	# Entrance: carved arch, glass fanlight, and double timber doors.
	_arch(625,546,234,368,Color("101d27"),BRONZE)
	_arch(638,542,208,351,Color("3e554f"),GOLD)
	_arch(650,540,184,333,Color("142a31"),BRONZE)
	for xx in [650.0,744.0]:
		_panel(xx,327,90,207,Color("233b3d"))
		_panel(xx+13,341,64,77,Color("1b3035"))
		_panel(xx+13,433,64,78,Color("1b3035"))
	for i in range(9):
		var a: float = PI+PI*float(i)/8
		_line(Vector2(742,319),Vector2(742+cos(a)*85,319+sin(a)*85),BRONZE,2)
	draw_circle(Vector2(730,443),4,GOLD)
	draw_circle(Vector2(755,443),4,GOLD)
	# Canopy, heavy steelwork and rivets.
	_poly([Vector2(0,120),Vector2(1440,88),Vector2(1440,163),Vector2(0,205)],Color("0a1822"))
	_line(Vector2(0,197),Vector2(1440,157),GOLD,3)
	for i in range(7):
		var x: float = float(i)*235.0
		_line(Vector2(x,157),Vector2(x+176,206),Color("344b51"),6)
		_line(Vector2(x,180),Vector2(x+176,144),Color("344b51"),3)
		for j in range(4):
			draw_circle(Vector2(x+float(j)*48,181-float(j)),2,BRONZE)
	_rect(888,176,24,409,Color("15282f"))
	_rect(885,176,5,409,Color("53635e"))
	_rect(874,519,54,66,Color("10222b"))
	_line(Vector2(900,183),Vector2(1023,174),Color("4b625e"),5)
	_poly([Vector2(903,250),Vector2(904,187),Vector2(976,184)],Color("213a40"))
	_lamp(568,260,0.8)
	_lamp(925,268,0.9)
	_floor(544)
	# Rails and white platform edge.
	_poly([Vector2(1080,548),Vector2(1440,508),Vector2(1440,900),Vector2(1310,900)],Color("0a1c27"))
	_line(Vector2(1112,559),Vector2(1370,900),Color("879a98"),4)
	_line(Vector2(1238,546),Vector2(1530,900),Color("627f82"),4)
	for i in range(14):
		var y: float = 559+float(i)*27
		_line(Vector2(1105+(y-559)*0.73,y),Vector2(1245+(y-559)*0.84,y-10),Color("25343a"),7)
	_line(Vector2(1076,548),Vector2(1306,900),Color("b2b7a1"),8)
	# Bench and lost ticket.
	for i in range(4):
		_rect(112,548+float(i)*12,245,8,Color("5a5345"))
	_rect(114,600,240,13,Color("655a46"))
	_line(Vector2(133,607),Vector2(122,659),INK,8)
	_line(Vector2(333,607),Vector2(347,659),INK,8)
	_poly([Vector2(242,609),Vector2(280,614),Vector2(276,633),Vector2(239,627)],IVORY)
	_line(Vector2(247,615),Vector2(269,618),BRONZE,2)
	# Brass suitcase and leather straps.
	_ellipse(Vector2(1008,645),Vector2(90,10),Color(0,0,0,0.28))
	_panel(922,555,157,82,Color("624d38"))
	_rect(923,578,156,4,Color("b79a69"))
	for xx in [942.0,1045.0]:
		_rect(xx,555,12,81,Color("2a302c"))
		_rect(xx+1,575,10,16,GOLD)
		draw_rect(Rect2(xx+3,578,6,10),BRONZE,false,1)
	draw_arc(Vector2(1000,552),18,PI,TAU,24,GOLD,5,true)
	_panel(988,581,25,20,Color("85724f"))
	draw_circle(Vector2(1000,590),3,INK)
	# Signal box.
	_rect(1192,321,15,275,Color("213338"))
	_rect(1190,321,4,275,Color("61756c"))
	_panel(1168,365,62,142,Color("203b3d"))
	for i in range(3):
		draw_circle(Vector2(1199,389+float(i)*43),16,INK)
		draw_circle(Vector2(1199,389+float(i)*43),12,Color("934b3b") if i==0 else Color("283e3d"))
	draw_circle(Vector2(1196,385),4,Color("c47c50"))
	if completed:
		_train()

func _train() -> void:
	var t: float = fmod(elapsed*35.0,1000.0)
	var x: float = maxf(850,1510-t)
	# Phantom train slides along the far line, lit from within.
	_poly([Vector2(x,415),Vector2(x+150,365),Vector2(x+600,365),Vector2(x+600,628),Vector2(x,603)],Color("10272e"))
	_rect(x+32,451,640,94,Color("1e4444"))
	for i in range(7):
		_rect(x+55+float(i)*88,418,58,71,Color("bba474"))
		_rect(x+59+float(i)*88,422,50,61,Color("657f6d"))
	_line(Vector2(x,554),Vector2(x+650,554),GOLD,3)
	for i in range(6):
		draw_circle(Vector2(x+62+float(i)*100,608),25,INK)
		draw_circle(Vector2(x+62+float(i)*100,608),15,BRONZE)
	for i in range(9):
		draw_circle(Vector2(x-25-float(i)*30,545+sin(elapsed+float(i))*15),30+float(i)*4,Color(0.65,0.78,0.70,0.035))

func _hall() -> void:
	_brick_wall(120,590)
	_floor(579,Color("273e40"))
	# Tall coffered ceiling and cream columns.
	for x in [56.0,465.0,895.0,1320.0]:
		_rect(x,170,32,414,Color("546460"))
		_rect(x+5,173,7,403,Color("78847a"))
		_rect(x-13,167,58,20,BRONZE)
		_rect(x-9,558,50,28,BRONZE)
	for x in [100.0,505.0,935.0]:
		_arch(x,580,360,430,Color("172b32"),Color("59645a"))
		_arch(x+14,578,332,410,Color("283d42"),BRONZE)
	_window(560,568,115,293)
	_window(768,568,115,293)
	# Ticket office shutter, enamel framed clock.
	_panel(949,274,210,307,Color("1a2e30"))
	_arch(967,568,174,270,Color("304744"),BRONZE)
	for i in range(13):
		_line(Vector2(974,340+float(i)*16),Vector2(1134,340+float(i)*16),Color("526356"),2)
	_rect(954,534,200,17,BRONZE)
	draw_circle(Vector2(1108,492),6,GOLD)
	_clock(720,330,76)
	_rect(704,410,31,104,Color("172a2d"))
	_line(Vector2(720,415),Vector2(720+sin(elapsed*1.1)*9,493),BRONZE,3)
	draw_circle(Vector2(720+sin(elapsed*1.1)*9,493),17,GOLD)
	# Letter on a carved reception lectern.
	_poly([Vector2(287,518),Vector2(437,506),Vector2(462,556),Vector2(307,571)],Color("746348"))
	_poly([Vector2(307,571),Vector2(462,556),Vector2(457,586),Vector2(309,596)],Color("463e31"))
	_rect(322,589,18,79,BRONZE)
	_rect(429,579,17,83,BRONZE)
	_poly([Vector2(337,522),Vector2(407,519),Vector2(426,548),Vector2(351,554)],Color("d1c4a3"))
	_poly([Vector2(339,523),Vector2(381,542),Vector2(406,520)],Color("b7ac91"))
	draw_circle(Vector2(383,538),7,Color("97494a"))
	# Secret carved medallion and ornamental scrollwork.
	draw_circle(Vector2(180,400),55,Color("0e242a"))
	draw_arc(Vector2(180,400),49,0,TAU,48,BRONZE,4,true)
	_gear(Vector2(180,400),36,0.0,Color("7b7553"))
	draw_circle(Vector2(180,400),16,Color("243e3e"))
	_poly([Vector2(180,381),Vector2(190,400),Vector2(180,418),Vector2(169,400)],GOLD)
	for x in [180.0,1225.0]:
		_lamp(x,264,0.9)
	# Suitably worn runner leads the eye toward the clock.
	_poly([Vector2(659,584),Vector2(786,584),Vector2(1040,900),Vector2(394,900)],Color(0.22,0.25,0.23,0.72))
	_line(Vector2(668,585),Vector2(420,900),Color(0.58,0.49,0.32,0.4),3)
	_line(Vector2(778,585),Vector2(1014,900),Color(0.58,0.49,0.32,0.4),3)

func _office() -> void:
	_rect(0,0,1440,900,Color("1a3036"))
	_rect(0,185,1440,390,Color("29443f"))
	for x in range(0,1440,72):
		_line(Vector2(float(x),191),Vector2(float(x),551),Color("344f44"),2)
		for y in range(215,540,65):
			_poly([Vector2(float(x)+36,float(y)),Vector2(float(x)+42,float(y)+12),Vector2(float(x)+36,float(y)+24),Vector2(float(x)+30,float(y)+12)],Color(0.56,0.57,0.36,0.12))
	_rect(0,540,1440,18,BRONZE)
	_rect(0,558,1440,65,Color("1a2e2c"))
	_floor(622,Color("21312e"))
	for i in range(10):
		_rect(float(i)*150,560,138,55,Color("233a34"))
	_window(530,480,191,282)
	# Window illuminates the work desk and part of the floor.
	_poly([Vector2(549,312),Vector2(707,312),Vector2(992,735),Vector2(484,735)],Color(0.59,0.78,0.64,0.055))
	# Empty portrait: the silhouette never quite meets the eye.
	_panel(208,232,183,239,Color("776347"))
	_panel(218,242,163,219,Color("152b2d"))
	_arch(239,449,122,177,Color("1c3434"))
	draw_circle(Vector2(300,320),29,Color("43574b"))
	_poly([Vector2(278,341),Vector2(324,341),Vector2(351,430),Vector2(253,430)],Color("344238"))
	_poly([Vector2(290,346),Vector2(301,371),Vector2(313,345),Vector2(308,386),Vector2(291,386)],BRONZE)
	_rect(239,434,121,8,Color("716448"))
	# Filing cabinet: twin doors with mechanical disc lock.
	_panel(988,237,226,374,Color("36443a"))
	for xx in [1002.0,1106.0]:
		_panel(xx,258,94,325,Color("30453b"))
		for j in range(5):
			_line(Vector2(xx+10,280+float(j)*8),Vector2(xx+83,280+float(j)*8),Color("526052"),2)
		_rect(xx+41,398,6,57,BRONZE)
	_panel(1051,447,99,45,Color("222f2a"))
	for i in range(3):
		draw_circle(Vector2(1071+float(i)*31,469),12,BRONZE)
		draw_circle(Vector2(1071+float(i)*31,469),8,Color("9a9064"))
		_line(Vector2(1071+float(i)*31,463),Vector2(1071+float(i)*31,474),INK,1.5)
	# Carpentry, rolled plans, letter, ink, and warm task light.
	_poly([Vector2(446,543),Vector2(799,521),Vector2(876,605),Vector2(482,634)],Color("726145"))
	_poly([Vector2(482,634),Vector2(876,605),Vector2(874,625),Vector2(485,656)],Color("352e25"))
	_rect(505,650,19,92,Color("3c3529"))
	_rect(822,626,19,90,Color("3c3529"))
	_poly([Vector2(593,540),Vector2(674,540),Vector2(714,583),Vector2(619,592)],Color("c3c2a3"))
	for i in range(5):
		_line(Vector2(611+float(i)*4,552+float(i)*6),Vector2(668+float(i)*5,552+float(i)*6),Color("6b7965"),1)
	draw_circle(Vector2(667,567),12,Color(0.11,0.21,0.21,0.35))
	_rect(742,546,20,27,INK)
	draw_circle(Vector2(752,546),10,Color("576552"))
	_line(Vector2(753,547),Vector2(773,514),GOLD,2)
	_rect(489,536,60,7,Color("b2a284"))
	_rect(486,526,56,8,Color("374b3b"))
	_lamp(807,472,0.9)
	# Side bookcase and stacked archival cases.
	_panel(57,335,106,280,Color("172a2a"))
	for i in range(3):
		_rect(61,411+float(i)*66,97,6,BRONZE)
		for j in range(6):
			_rect(68+float(j)*14,360+float(i)*66,10,49-float(j%3)*6,Color(0.22+float(j%2)*0.09,0.30,0.26))

func _cellar() -> void:
	_rect(0,0,1440,900,Color("0d252d"))
	# Arched brick service tunnel.
	for i in range(9):
		_arch(-100+float(i)*42,755-float(i)*13,1640-float(i)*84,750-float(i)*39,Color("1e353b") if i%2==0 else Color("172d34"))
	_rect(395,250,660,398,Color("19343b"))
	for i in range(12):
		_line(Vector2(395,262+float(i)*32),Vector2(1055,262+float(i)*32),Color("10282f"),2)
	_floor(645,Color("172d33"))
	# Heavy pipes along the walls, down to the generator.
	for yy in [225.0,261.0]:
		_line(Vector2(0,yy),Vector2(637,yy),Color("101e23"),23)
		_line(Vector2(0,yy-4),Vector2(637,yy-4),Color("52635a"),5)
		_line(Vector2(638,yy),Vector2(638,369),Color("2f4847"),21)
		for x in range(60,640,120):
			_rect(float(x),yy-16,12,33,BRONZE)
	# Exit stairs carved into the left-hand tunnel.
	_arch(140,646,238,331,Color("0a1e27"),BRONZE)
	for i in range(8):
		var y: float = 441+float(i)*26
		_rect(160-float(i)*3,y,199+float(i)*6,19,Color(0.18+float(i)*0.012,0.26+float(i)*0.01,0.27))
		_line(Vector2(159-float(i)*3,y),Vector2(360+float(i)*3,y),Color("62756d"),2)
	_line(Vector2(150,611),Vector2(210,374),BRONZE,5)
	_line(Vector2(367,610),Vector2(312,374),BRONZE,5)
	# Three-stage electrical distribution cabinet.
	_panel(649,281,226,274,Color("344e47"))
	_panel(663,295,198,86,Color("152b2c"))
	for i in range(2):
		draw_circle(Vector2(705+float(i)*103,337),29,BRONZE)
		draw_circle(Vector2(705+float(i)*103,337),24,Color("afb496"))
		draw_arc(Vector2(705+float(i)*103,337),18,PI,TAU,24,Color("2e423c"),2,true)
		_line(Vector2(705+float(i)*103,351),Vector2(699+float(i)*103,325),INK,2)
	for i in range(3):
		var x: float = 694+float(i)*67
		_panel(x-16,410,38,87,Color("1c302d"))
		draw_circle(Vector2(x+3,425),8,Color("527760"))
		_line(Vector2(x+3,479),Vector2(x-8,450),GOLD,7)
		draw_circle(Vector2(x-8,450),8,INK)
	_rect(679,517,165,15,Color("b8ac7e"))
	for x in [675.0,710.0,821.0,850.0]:
		_line(Vector2(x,555),Vector2(x,635),Color("344b44"),8)
	# Flywheel dynamo, copper coils, reflected green light.
	_gear(Vector2(1060,531),91,elapsed*0.04,Color("536558"))
	_panel(1152,437,129,158,Color("33483b"))
	for i in range(8):
		draw_arc(Vector2(1183,515),42+float(i)*3,-PI/2,PI/2,32,Color("9f794d"),3,true)
	_line(Vector2(865,478),Vector2(1020,478),Color("6a6651"),7)
	_line(Vector2(1061,624),Vector2(1061,693),Color("2e4440"),12)
	_lamp(428,343,0.8)
	_lamp(1288,308,0.75)
	for i in range(9):
		var x: float = 400+float(i)*84
		_line(Vector2(x,718+sin(float(i))*20),Vector2(x+61,718+sin(float(i))*20),Color(0.4,0.65,0.6,0.08),4)

func _atmosphere() -> void:
	var count: int = 16 if quality==0 else (36 if quality==1 else 60)
	if room=="platform":
		for i in range(count):
			var x: float = fmod(float(i)*179.7+elapsed*57.0,1540.0)-50.0
			var y: float = 160+fmod(float(i)*91.9+elapsed*280.0,590.0)
			_line(Vector2(x,y),Vector2(x-7,y+23),Color(0.61,0.76,0.78,0.13),1)
	else:
		for i in range(count/2):
			var x: float = fmod(float(i)*131.7+elapsed*7,1440)
			var y: float = 220+fmod(float(i)*89.8+sin(elapsed*0.4+float(i))*20,420)
			draw_circle(Vector2(x,y),1.2,Color(0.85,0.83,0.63,0.10+sin(elapsed+float(i))*0.06))
	# Low drifting mist, painted as soft translucent horizontal layers.
	for i in range(10):
		var y: float = 598+float(i)*8
		var shift: float = sin(elapsed*0.17+float(i)*0.5)*110
		_rect(-120+shift,y,1630,9,Color(0.41,0.61,0.62,0.010))
	# Edge glazing; important details remain comfortably readable on a phone.
	for i in range(8):
		_rect(float(i)*9,120,9,650,Color(0.01,0.04,0.06,0.11-float(i)*0.01))
		_rect(1431-float(i)*9,120,9,650,Color(0.01,0.04,0.06,0.11-float(i)*0.01))
	_rect(0,790,1440,110,Color(0.02,0.05,0.08,0.4))

func _draw() -> void:
	if size.x<1 or size.y<1:
		return
	draw_set_transform(Vector2.ZERO,0,Vector2(size.x/1440.0,size.y/900.0))
	match room:
		"hall": _hall()
		"office": _office()
		"cellar": _cellar()
		_: _platform()
	_atmosphere()
