extends Control

const NODE_SIZE := 76
const FONT = preload("res://assets/fonts/Papernotes Sketch.ttf")
const BOARD_SCENE := "res://scenes/board/Board.tscn"
const MINIGAME_SCENE := "res://scenes/minigame/CanelaGame.tscn"


func _ready() -> void:
	var screen = get_viewport_rect().size
	size = screen

	var bg = ColorRect.new()
	bg.color = Color("#FFF3E0")
	bg.position = Vector2.ZERO
	bg.size = screen
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	build_title(screen)

	var pts = level_points(screen)
	draw_road(pts)
	for i in pts.size():
		add_level(i, pts[i])

	add_minigame_button(screen)


func build_title(screen: Vector2) -> void:
	var panel = Panel.new()
	panel.size = Vector2(screen.x - 40, 56)
	panel.position = Vector2(20, 18)
	var st = make_style(Color("#8B5A3C"), 24)
	st.set_border_width_all(4)
	st.border_color = Color("#F2B134")
	panel.add_theme_stylebox_override("panel", st)
	add_child(panel)

	var lbl = Label.new()
	lbl.text = "Camino a la panadería"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color("#FFF3E0"))
	panel.add_child(lbl)

	# Total de canelas
	var coins = Label.new()
	coins.text = "Canelas: %d" % GameState.canelas
	coins.size = Vector2(screen.x - 40, 30)
	coins.position = Vector2(20, 82)
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins.add_theme_font_override("font", FONT)
	coins.add_theme_font_size_override("font_size", 22)
	coins.add_theme_color_override("font_color", Color("#8B5A3C"))
	add_child(coins)


func level_points(screen: Vector2) -> PackedVector2Array:
	var n = GameState.LEVELS.size()
	var pts = PackedVector2Array()
	var top = screen.y * 0.26
	var bottom = screen.y * 0.70
	for i in n:
		var y = bottom - i * (bottom - top) / max(n - 1, 1)
		var x = screen.x * (0.30 if i % 2 == 0 else 0.70)
		pts.append(Vector2(x, y))
	return pts


func draw_road(pts: PackedVector2Array) -> void:
	var curve = Curve2D.new()
	for p in pts:
		curve.add_point(p, Vector2(0, 50), Vector2(0, -50))
	var line_pts = curve.tessellate()

	for cfg in [[30.0, Color("#8B5A3C")], [20.0, Color("#E0A458")]]:
		var road = Line2D.new()
		road.points = line_pts
		road.width = cfg[0]
		road.default_color = cfg[1]
		road.joint_mode = Line2D.LINE_JOINT_ROUND
		road.begin_cap_mode = Line2D.LINE_CAP_ROUND
		road.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(road)


func add_level(i: int, pos: Vector2) -> void:
	var locked = i > GameState.unlocked
	var current = (i == GameState.unlocked and GameState.stars[i] == 0)

	var btn = Button.new()
	btn.text = "🔒" if locked else str(i + 1)
	btn.size = Vector2(NODE_SIZE, NODE_SIZE)
	btn.position = pos - btn.size / 2.0
	btn.pivot_offset = btn.size / 2.0
	btn.disabled = locked

	var base = Color("#B9A38F") if locked else (Color("#F2B134") if current else Color("#C97B4A"))
	btn.add_theme_stylebox_override("normal", circle_style(base))
	btn.add_theme_stylebox_override("hover", circle_style(base.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", circle_style(base.darkened(0.15)))
	btn.add_theme_stylebox_override("disabled", circle_style(base))
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 36)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color.WHITE)
	btn.pressed.connect(_on_level_pressed.bind(i))
	add_child(btn)

	# El nivel actual late para llamar la atención
	if current:
		var t = create_tween().set_loops()
		t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(btn, "scale", Vector2.ONE, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Nombre del nivel
	var name_lbl = Label.new()
	name_lbl.text = GameState.LEVELS[i].name
	name_lbl.size = Vector2(160, 26)
	name_lbl.position = pos + Vector2(-80, NODE_SIZE / 2.0 + 2)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", FONT)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color("#8B5A3C") if not locked else Color("#B9A38F"))
	add_child(name_lbl)

	# Estrellas
	if not locked:
		for s in range(3):
			var earned = s < GameState.stars[i]
			var star = make_star(10, Color("#F2B134") if earned else Color("#D9C7B0"))
			star.position = pos + Vector2((s - 1) * 26, NODE_SIZE / 2.0 + 40)
			add_child(star)


func circle_style(color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(NODE_SIZE / 2)
	s.set_border_width_all(5)
	s.border_color = Color("#8B5A3C")
	return s


func make_style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s


func make_star(radius: float, color: Color) -> Polygon2D:
	var pts = PackedVector2Array()
	for i in range(10):
		var r = radius if i % 2 == 0 else radius * 0.45
		var a = -PI / 2 + i * PI / 5
		pts.append(Vector2(cos(a), sin(a)) * r)
	var star = Polygon2D.new()
	star.polygon = pts
	star.color = color
	return star


func add_minigame_button(screen: Vector2) -> void:
	var open = GameState.minigame_unlocked
	var btn = Button.new()
	btn.text = "Minijuego de canela" if open else "🔒 Pasa el nivel 3"
	btn.disabled = not open
	btn.size = Vector2(250, 54)
	btn.position = Vector2((screen.x - 250) / 2.0, screen.y - 80)
	var color = Color("#C97B4A") if open else Color("#B9A38F")
	btn.add_theme_stylebox_override("normal", make_style(color, 20))
	btn.add_theme_stylebox_override("hover", make_style(color.lightened(0.12), 20))
	btn.add_theme_stylebox_override("pressed", make_style(color.darkened(0.15), 20))
	btn.add_theme_stylebox_override("disabled", make_style(color, 20))
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color.WHITE)
	btn.pressed.connect(func(): get_tree().change_scene_to_file(MINIGAME_SCENE))
	add_child(btn)


func _on_level_pressed(i: int) -> void:
	GameState.current_level = i
	get_tree().change_scene_to_file(BOARD_SCENE)
