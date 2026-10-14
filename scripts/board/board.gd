extends Node2D

const PIECE_SCENE = preload("res://scenes/board/Piece.tscn")

const GRID_WIDTH = 8
const GRID_HEIGHT = 8
const MARGIN = 20
const PIECE_BASE_SIZE = 80

var cell_size: float
var board_offset: Vector2
var grid: Array = []
var selected: Vector2i = Vector2i(-1, -1)
var busy: bool = false

var goal_score: int
var total_moves: int
var num_types: int
var moves: int
var score: int = 0

var hud_label: Label
var game_over: bool = false
var restart_button: Button
var hud_layer: CanvasLayer
var score_bar: ProgressBar
var score_label: Label
var moves_label: Label
var moves_circle: Panel
# hud_label ahora es el mensaje de fin de juego (Ganaste / Sin movimientos)
const SP_NONE = 0
const SP_ROW = 1
const SP_COL = 2
const SP_BOMB = 3
const SP_COLOR = 4

const SPECIAL_PIECE_POINTS = 2   # puntos por pieza limpiada por un power-up
const COMBO_FONT = preload("res://assets/fonts/Papernotes Sketch.ttf")

const PRAISE = [
	{"text": "¡Dulce!",     "color": Color("#F4A3B5")},
	{"text": "¡Asombroso!",   "color": Color("#F2B134")},
	{"text": "¡Excelente!", "color": Color("#F08A3C")},
	{"text": "¡Ganador!",    "color": Color("#FFF3C4")},
]

var collect_type := -1
var collect_goal := 0
var collected := 0

func _ready() -> void:
	randomize()
	var d = GameState.data()
	goal_score = d.goal
	collect_type = d.get("collect_type", -1)
	collect_goal = d.get("collect", 0)
	total_moves = d.moves
	num_types = d.types
	moves = total_moves
	setup_layout()
	generate_board()
	create_hud()
	create_board_background()
	add_child(preload("res://scripts/ui/pause_menu.gd").new())

func make_style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s


func style_text(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("#4A2C1A"))
	label.add_theme_constant_override("outline_size", 5)


func create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var screen = get_viewport_rect().size

	# --- Barra superior ---
	var top_bar = Panel.new()
	top_bar.size = Vector2(screen.x, 84)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_style = make_style(Color("#8B5A3C"), 0)
	bar_style.corner_radius_bottom_left = 24
	bar_style.corner_radius_bottom_right = 24
	bar_style.border_width_bottom = 4
	bar_style.border_color = Color("#E0A458")
	top_bar.add_theme_stylebox_override("panel", bar_style)
	hud_layer.add_child(top_bar)

	# --- Izquierda: progreso de puntos ---
	score_label = Label.new()
	score_label.position = Vector2(14, 14)
	style_text(score_label, 16)
	hud_layer.add_child(score_label)

	score_bar = ProgressBar.new()
	score_bar.position = Vector2(14, 46)
	score_bar.size = Vector2(122, 20)
	score_bar.min_value = 0
	score_bar.max_value = target()
	score_bar.show_percentage = false
	score_bar.add_theme_stylebox_override("background", make_style(Color("#4A2C1A"), 10))
	score_bar.add_theme_stylebox_override("fill", make_style(Color("#F2B134"), 10))
	hud_layer.add_child(score_bar)

	# --- Centro: círculo de movimientos ---
	moves_circle = Panel.new()
	moves_circle.size = Vector2(72, 72)
	moves_circle.position = Vector2((screen.x - 72) / 2.0, 6)
	moves_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var circle_style = make_style(Color("#FFF3E0"), 36)
	circle_style.border_width_left = 4
	circle_style.border_width_right = 4
	circle_style.border_width_top = 4
	circle_style.border_width_bottom = 4
	circle_style.border_color = Color("#E0A458")
	moves_circle.add_theme_stylebox_override("panel", circle_style)
	hud_layer.add_child(moves_circle)

	moves_label = Label.new()
	moves_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	moves_label.add_theme_font_size_override("font_size", 32)
	moves_label.add_theme_color_override("font_color", Color("#5C3A21"))
	moves_circle.add_child(moves_label)

	# --- Derecha: meta ---
	var goal_panel = Panel.new()
	goal_panel.size = Vector2(100, 56)
	goal_panel.position = Vector2(screen.x - 114, 14)
	goal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_panel.add_theme_stylebox_override("panel", make_style(Color("#6B4226"), 14))
	hud_layer.add_child(goal_panel)

	var goal_label = Label.new()
	goal_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.text = ("Junta\n%d" if collect_goal > 0 else "Meta\n%d") % target()
	goal_label.add_theme_font_size_override("font_size", 16)
	goal_label.add_theme_color_override("font_color", Color("#FFF3E0"))
	goal_panel.add_child(goal_label)

	# --- Mensaje de fin de juego (oculto al inicio) ---
	hud_label = Label.new()
	hud_label.position = Vector2(0, 96)
	hud_label.size = Vector2(screen.x, 30)
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_text(hud_label, 22)
	hud_label.visible = false
	hud_layer.add_child(hud_label)
	if collect_goal > 0:
		var icon = TextureRect.new()
		icon.texture = load("res://scripts/board/piece.gd").TEXTURES[collect_type]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(34, 34)
		icon.position = Vector2(8, 11)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		goal_panel.add_child(icon)
		goal_label.offset_left = 34   # recorre el texto para dejar espacio al ícono
	update_hud()


func update_hud() -> void:
	score_label.text = "%d / %d" % [min(progress(), target()), target()]
	moves_label.text = str(moves)
	var t = create_tween()
	t.tween_property(score_bar, "value", progress(), 0.3)
# ---------- LAYOUT ----------

func setup_layout() -> void:
	var screen = get_viewport_rect().size
	cell_size = (screen.x - MARGIN * 2) / GRID_WIDTH
	var board_size = Vector2(GRID_WIDTH, GRID_HEIGHT) * cell_size
	board_offset = Vector2(
		(screen.x - board_size.x) / 2.0,
		(screen.y - board_size.y) / 2.0
	)


func grid_to_pixel(x: int, y: int) -> Vector2:
	return board_offset + Vector2(x + 0.5, y + 0.5) * cell_size


func piece_scale() -> Vector2:
	var s = (cell_size * 0.92) / PIECE_BASE_SIZE
	return Vector2(s, s)


# ---------- GENERAR TABLERO ----------

func generate_board() -> void:
	grid.clear()
	for x in range(GRID_WIDTH):
		grid.append([])
		for y in range(GRID_HEIGHT):
			var piece = spawn_piece(x, y)
			grid[x].append(piece)


func spawn_piece(x: int, y: int) -> Node:
	var piece = PIECE_SCENE.instantiate()
	add_child(piece)
	piece.set_type(get_safe_type(x, y))
	piece.grid_position = Vector2i(x, y)
	piece.position = grid_to_pixel(x, y)
	piece.scale = piece_scale()
	return piece

func get_safe_type(x: int, y: int) -> int:
	var options = range(num_types)
	options.shuffle()
	for t in options:
		if not would_match(x, y, t):
			return t
	return options[0]


func would_match(x: int, y: int, t: int) -> bool:
	if x >= 2:
		if grid[x - 1][y].piece_type == t and grid[x - 2][y].piece_type == t:
			return true
	if y >= 2:
		if grid[x][y - 1].piece_type == t and grid[x][y - 2].piece_type == t:
			return true
	return false

func create_board_background() -> void:
	var panel = Panel.new()
	var pad = 6.0
	var board_size = Vector2(GRID_WIDTH, GRID_HEIGHT) * cell_size
	panel.position = board_offset - Vector2(pad, pad)
	panel.size = board_size + Vector2(pad, pad) * 2
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE   # importante: que no se coma los clics

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.707, 0.847, 0.997, 0.85)   # café oscuro semitransparente
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)

	add_child(panel)
	move_child(panel, $Fondo.get_index() + 1)   # cambia $Fondo por el nombre real de tu nodo de imagen
# ---------- INPUT ----------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if busy or game_over:
			return
		var cell = pixel_to_grid(event.position)
		if is_valid_cell(cell):
			handle_selection(cell)


func pixel_to_grid(pos: Vector2) -> Vector2i:
	var local = pos - board_offset
	return Vector2i(floor(local.x / cell_size), floor(local.y / cell_size))


func is_valid_cell(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < GRID_WIDTH and c.y >= 0 and c.y < GRID_HEIGHT


func handle_selection(cell: Vector2i) -> void:
	# Primer toque: seleccionar
	if selected == Vector2i(-1, -1):
		selected = cell
		grid[cell.x][cell.y].scale *= 1.15
		return

	# Tocar la misma pieza: deseleccionar
	if selected == cell:
		grid[cell.x][cell.y].scale /= 1.15
		selected = Vector2i(-1, -1)
		return

	# Segundo toque
	var prev = selected
	grid[prev.x][prev.y].scale /= 1.15
	selected = Vector2i(-1, -1)

	if are_neighbors(prev, cell):
		swap_pieces(prev, cell)
	else:
		selected = cell
		grid[cell.x][cell.y].scale *= 1.15


func are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1


# ---------- INTERCAMBIO ----------

func swap_pieces(a: Vector2i, b: Vector2i) -> void:
	busy = true
	await do_swap(a, b)

	var forced: Dictionary = {}
	# Tras el swap, la pieza en 'a' es la que antes estaba en 'b' y viceversa
	if grid[a.x][a.y].special != SP_NONE:
		forced[a] = grid[b.x][b.y].piece_type
	if grid[b.x][b.y].special != SP_NONE:
		forced[b] = grid[a.x][a.y].piece_type

	if find_matches().is_empty() and forced.is_empty():
		await do_swap(a, b)
		busy = false
		return

	moves -= 1
	update_hud()
	await resolve_matches(forced)
	check_game_state()

	if not game_over:
		busy = false

func do_swap(a: Vector2i, b: Vector2i) -> void:
	var piece_a = grid[a.x][a.y]
	var piece_b = grid[b.x][b.y]
	grid[a.x][a.y] = piece_b
	grid[b.x][b.y] = piece_a
	piece_a.grid_position = b
	piece_b.grid_position = a

	var tween = create_tween().set_parallel(true)
	tween.tween_property(piece_a, "position", grid_to_pixel(b.x, b.y), 0.2)
	tween.tween_property(piece_b, "position", grid_to_pixel(a.x, a.y), 0.2)
	await tween.finished

func check_game_state() -> void:
	if goal_met():
		game_over = true
		hud_label.text = "¡Nivel completado!"
		hud_label.visible = true
		var s = calculate_stars()
		show_stars(s)
		GameState.complete_level(s)
		if GameState.has_next():
			show_button("Siguiente nivel", _on_next_pressed)
			show_button("Mapa", _on_map_pressed, 60)
		else:
			hud_label.text = "¡Prototipo completado!"
			show_button("Mapa", _on_map_pressed)
	elif moves <= 0:
		game_over = true
		hud_label.text = "Sin movimientos"
		hud_label.visible = true
		show_button("Reintentar", _on_restart_pressed)
		show_button("Mapa", _on_map_pressed, 60)

func calculate_stars() -> int:
	var ratio = float(moves) / total_moves
	if ratio >= 0.5:
		return 3
	elif ratio >= 0.25:
		return 2
	return 1


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


func show_stars(count: int) -> void:
	var screen = get_viewport_rect().size
	var board_bottom = board_offset.y + GRID_HEIGHT * cell_size
	var center_y = board_bottom + 34

	for i in range(3):
		var earned = i < count
		var color = Color("#F2B134") if earned else Color("#B9A38F")
		var star = make_star(22, color)
		star.position = Vector2(screen.x / 2.0 + (i - 1) * 56, center_y)
		hud_layer.add_child(star)

		if earned:
			star.scale = Vector2.ZERO
			var t = create_tween()
			t.tween_interval(0.3 + i * 0.3)   # una tras otra
			t.tween_property(star, "scale", Vector2.ONE, 0.35) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_button(text: String, callback: Callable, offset_y := 0.0) -> void:
	var btn = Button.new()
	btn.text = text
	var screen = get_viewport_rect().size
	var board_bottom = board_offset.y + GRID_HEIGHT * cell_size
	btn.size = Vector2(200, 50)
	btn.position = Vector2((screen.x - 200) / 2.0, board_bottom + 66 + offset_y)
	btn.add_theme_stylebox_override("normal", make_style(Color("#C97B4A"), 16))
	btn.add_theme_stylebox_override("hover", make_style(Color("#E0965F"), 16))
	btn.add_theme_stylebox_override("pressed", make_style(Color("#A8623A"), 16))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(callback)
	hud_layer.add_child(btn)

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/LevelMap.tscn")
	
func _on_next_pressed() -> void:
	GameState.current_level += 1
	get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

# Devuelve cada línea de 3+ como {cells: Array, horizontal: bool}
func find_runs() -> Array:
	var runs: Array = []
	for y in range(GRID_HEIGHT):
		var run = 1
		for x in range(1, GRID_WIDTH + 1):
			var same = x < GRID_WIDTH and \
				grid[x][y].piece_type == grid[x - 1][y].piece_type
			if same:
				run += 1
			else:
				if run >= 3:
					var cells = []
					for k in range(x - run, x):
						cells.append(Vector2i(k, y))
					runs.append({"cells": cells, "horizontal": true})
				run = 1
	for x in range(GRID_WIDTH):
		var run = 1
		for y in range(1, GRID_HEIGHT + 1):
			var same = y < GRID_HEIGHT and \
				grid[x][y].piece_type == grid[x][y - 1].piece_type
			if same:
				run += 1
			else:
				if run >= 3:
					var cells = []
					for k in range(y - run, y):
						cells.append(Vector2i(x, k))
					runs.append({"cells": cells, "horizontal": false})
				run = 1
	return runs


func find_matches() -> Array:
	var matched: Dictionary = {}
	for r in find_runs():
		for c in r.cells:
			matched[c] = true
	return matched.keys()


# Decide qué power-ups se crean con estas líneas
func special_spawns(runs: Array) -> Array:
	var spawns: Array = []
	var used: Dictionary = {}

	# 5 o más en línea -> Orejón
	for r in runs:
		if r.cells.size() >= 5:
			spawns.append({"pos": r.cells[r.cells.size() / 2], "kind": SP_COLOR})
			for c in r.cells: used[c] = true

	# L o T (cruce de línea horizontal y vertical) -> Cuernitón
	var h: Dictionary = {}
	var v: Dictionary = {}
	for r in runs:
		for c in r.cells:
			if r.horizontal: h[c] = true
			else: v[c] = true
	for c in h:
		if v.has(c) and not used.has(c):
			spawns.append({"pos": c, "kind": SP_BOMB})
			used[c] = true

	# 4 en línea -> Maxiconcha
	for r in runs:
		if r.cells.size() == 4:
			var free = true
			for c in r.cells:
				if used.has(c): free = false
			if free:
				spawns.append({"pos": r.cells[1], "kind": SP_ROW if r.horizontal else SP_COL})
				for c in r.cells: used[c] = true
	return spawns


# Zona que limpia un power-up
func special_area(p: Vector2i, piece, target_type: int) -> Array:
	var area: Array = []
	match piece.special:
		SP_ROW:
			for x in range(GRID_WIDTH): area.append(Vector2i(x, p.y))
		SP_COL:
			for y in range(GRID_HEIGHT): area.append(Vector2i(p.x, y))
		SP_BOMB:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var c = Vector2i(p.x + dx, p.y + dy)
					if is_valid_cell(c): area.append(c)
		SP_COLOR:
			for x in range(GRID_WIDTH):
				for y in range(GRID_HEIGHT):
					if grid[x][y] != null and grid[x][y].piece_type == target_type:
						area.append(Vector2i(x, y))
	return area


# Si en la zona hay otros power-ups, también explotan (reacción en cadena)
func expand_specials(cells: Dictionary, forced: Dictionary) -> Dictionary:
	var queue = cells.keys()
	while not queue.is_empty():
		var p = queue.pop_back()
		var piece = grid[p.x][p.y]
		if piece == null or piece.special == SP_NONE:
			continue
		for e in special_area(p, piece, forced.get(p, piece.piece_type)):
			if not cells.has(e):
				cells[e] = true
				queue.append(e)
	return cells

func resolve_matches(forced: Dictionary = {}) -> void:
	var combo = 1
	var runs = find_runs()
	while not runs.is_empty() or not forced.is_empty():
		# Solo se crean power-ups con la jugada del jugador, no en cascadas
		var spawns = special_spawns(runs) if combo == 1 else []

		var natural: Dictionary = {}
		for r in runs:
			for c in r.cells: natural[c] = true

		var cells: Dictionary = natural.duplicate()
		for p in forced: cells[p] = true

		if forced.size() == 2:   # Combo Cafecito
			for x in range(GRID_WIDTH):
				for y in range(GRID_HEIGHT):
					cells[Vector2i(x, y)] = true
		else:
			cells = expand_specials(cells, forced)

		for s in spawns:
			cells.erase(s.pos)
			natural.erase(s.pos)

		# Puntos: piezas de combinación normal valen más que las de power-up
		var extra = 0
		for c in cells:
			if not natural.has(c): extra += 1
		var gained = int(natural.size() * 5 * (1.0 + 0.25 * (combo - 1))) \
			+ extra * SPECIAL_PIECE_POINTS

		var had_special = false
		for p in cells:
			var pc = grid[p.x][p.y]
			if pc != null and pc.special != SP_NONE:
				special_fx(p, pc.special)
				had_special = true
		if collect_type >= 0:
			for p in cells:
				var pc2 = grid[p.x][p.y]
				if pc2 != null and pc2.piece_type == collect_type:
					collected += 1
		score += gained
		show_popup(gained, combo, cells.keys())
		if had_special:
			shake(12.0)
		elif cells.size() >= 6:
			shake(6.0)
		combo += 1
		update_hud()
		await clear_matches(cells.keys())

		for s in spawns:
			grid[s.pos.x][s.pos.y].set_special(s.kind)

		await apply_gravity()
		await refill_board()
		forced = {}
		runs = find_runs()

# Elimina las piezas combinadas con una animación corta
func clear_matches(matches: Array) -> void:
	var tween = create_tween().set_parallel(true)
	for pos in matches:
		var piece = grid[pos.x][pos.y]
		burst(piece.position, PIECE_COLORS[piece.piece_type])
		tween.tween_property(piece, "scale", Vector2.ZERO, 0.15)
		tween.tween_property(piece, "rotation", 0.6, 0.15)
	await tween.finished

	for pos in matches:
		grid[pos.x][pos.y].queue_free()
		grid[pos.x][pos.y] = null

# Las piezas de arriba caen a los huecos
func apply_gravity() -> void:
	var tween = create_tween().set_parallel(true)
	var moved = false
	for x in range(GRID_WIDTH):
		var write_y = GRID_HEIGHT - 1
		for y in range(GRID_HEIGHT - 1, -1, -1):
			var piece = grid[x][y]
			if piece != null:
				if write_y != y:
					grid[x][write_y] = piece
					grid[x][y] = null
					piece.grid_position = Vector2i(x, write_y)
					tween.tween_property(piece, "position", grid_to_pixel(x, write_y), 0.2)
					moved = true
				write_y -= 1
	if moved:
		await tween.finished
	else:
		tween.kill()


# Crea piezas nuevas arriba y las hace caer
func refill_board() -> void:
	var tween = create_tween().set_parallel(true)
	var added = false
	for x in range(GRID_WIDTH):
		var empty_count = 0
		for y in range(GRID_HEIGHT):
			if grid[x][y] == null:
				empty_count += 1
		var slot = 0
		for y in range(GRID_HEIGHT):
			if grid[x][y] == null:
				var piece = PIECE_SCENE.instantiate()
				add_child(piece)
				piece.set_type(randi() % num_types)
				piece.grid_position = Vector2i(x, y)
				piece.scale = piece_scale()
				piece.position = grid_to_pixel(x, -(empty_count - slot))
				grid[x][y] = piece
				tween.tween_property(piece, "position", grid_to_pixel(x, y), 0.25)
				added = true
				slot += 1
	if added:
		await tween.finished
	else:
		tween.kill()

func target() -> int:
	return collect_goal if collect_goal > 0 else goal_score

func progress() -> int:
	return collected if collect_goal > 0 else score

func goal_met() -> bool:
	return progress() >= target()


# ---------- EFECTOS ----------

const PIECE_COLORS = [Color("#F4A3B5"), Color("#F2B134"), Color("#D98B3A"), Color("#6B4226"), Color("#C97B4A")]

func burst(pos: Vector2, color: Color) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.z_index = 15
	p.one_shot = true
	p.amount = 8
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 300)
	p.initial_velocity_min = 80
	p.initial_velocity_max = 180
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.8
	p.color = color

	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 16
	tex.height = 16
	p.texture = tex

	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

func show_popup(_points: int, combo: int, cells: Array) -> void:
	var level = combo - 1                 # combo x2 -> "¡Dulce!"
	if cells.size() >= 8:
		level = max(level, 1)             # limpiezas grandes también celebran
	if level < 1:
		return

	var data = PRAISE[min(level - 1, PRAISE.size() - 1)]
	var screen = get_viewport_rect().size

	var lbl = Label.new()
	lbl.text = data.text
	lbl.size = Vector2(screen.x, 100)
	lbl.pivot_offset = lbl.size / 2.0
	lbl.position = Vector2(0, screen.y / 2.0 - 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.z_index = 30
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", COMBO_FONT)
	lbl.add_theme_font_size_override("font_size", 40 + level * 4)
	lbl.add_theme_color_override("font_color", data.color)
	lbl.add_theme_color_override("font_outline_color", Color("#4A2C1A"))
	lbl.add_theme_constant_override("outline_size", 8)
	add_child(lbl)

	lbl.scale = Vector2(0.2, 0.2)
	lbl.rotation_degrees = -8
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "rotation_degrees", 0.0, 0.3)
	t.chain().tween_interval(0.35)
	t.chain().tween_property(lbl, "scale", Vector2(1.25, 1.25), 0.3)
	t.tween_property(lbl, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(lbl.queue_free)

func shake(strength: float = 8.0) -> void:
	var origin = position
	var t = create_tween()
	for i in range(6):
		t.tween_property(self, "position",
			origin + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, 0.04)
	t.tween_property(self, "position", origin, 0.04)


func flash_rect(pos: Vector2, size_: Vector2) -> void:
	var r = ColorRect.new()
	r.color = Color(1, 0.95, 0.7, 0.85)
	r.position = pos
	r.size = size_
	r.z_index = 10
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	var t = create_tween()
	t.tween_property(r, "modulate:a", 0.0, 0.4)
	t.tween_callback(r.queue_free)

func ring_fx(center: Vector2) -> void:
	var ring = Panel.new()
	ring.size = Vector2(cell_size, cell_size)
	ring.position = center - ring.size / 2.0
	ring.pivot_offset = ring.size / 2.0
	ring.z_index = 10
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s = StyleBoxFlat.new()
	s.bg_color = Color(1, 0.9, 0.5, 0.35)
	s.set_border_width_all(6)
	s.border_color = Color("#F2B134")
	s.set_corner_radius_all(int(cell_size / 2))
	ring.add_theme_stylebox_override("panel", s)
	add_child(ring)
	var t = create_tween().set_parallel(true)
	t.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(ring.queue_free)

func special_fx(p: Vector2i, kind: int) -> void:
	var c = grid_to_pixel(p.x, p.y)
	match kind:
		SP_ROW:
			flash_rect(Vector2(board_offset.x, c.y - cell_size / 2.0),
				Vector2(GRID_WIDTH * cell_size, cell_size))
		SP_COL:
			flash_rect(Vector2(c.x - cell_size / 2.0, board_offset.y),
				Vector2(cell_size, GRID_HEIGHT * cell_size))
		SP_BOMB:
			ring_fx(c)
		SP_COLOR:
			flash_rect(board_offset, Vector2(GRID_WIDTH, GRID_HEIGHT) * cell_size)
