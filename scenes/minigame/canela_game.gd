extends Control

const GAME_TIME := 20.0
const ITEM_SIZE := 56.0
const SPAWN_EVERY := 0.6
const RAYITAS_PATH := "res://assets/sprites/rayitas/canasta.png"  
const RAYITAS_SIZE := Vector2(110, 130)
const BASKET_ZONE := Rect2(0.30, 0.0, 0.62, 0.22) 
const MAP_SCENE := "res://scenes/map/LevelMap.tscn"
const GAME_SCENE := "res://scenes/minigame/CanelaGame.tscn"

var time_left := GAME_TIME
var score := 0
var spawn_timer := 0.0
var playing := true
var screen: Vector2
var canela_tex: Texture2D
var items_layer: Control
var rayitas: Control
var basket: Panel
var score_label: Label
var time_label: Label


func _ready() -> void:
	randomize()
	screen = get_viewport_rect().size
	canela_tex = load("res://scripts/board/piece.gd").TEXTURES[4]

	var bg = ColorRect.new()
	bg.color = Color("#FFF3E0")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	items_layer = Control.new()
	items_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	items_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(items_layer)

	build_rayitas()

	var bar = Panel.new()
	bar.size = Vector2(screen.x, 70)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs = make_style(Color("#8B5A3C"), 0)
	bs.corner_radius_bottom_left = 24
	bs.corner_radius_bottom_right = 24
	bs.border_width_bottom = 4
	bs.border_color = Color("#E0A458")
	bar.add_theme_stylebox_override("panel", bs)
	add_child(bar)

	score_label = make_label(Vector2(16, 16), 28)
	time_label = make_label(Vector2(screen.x - 110, 16), 28)
	time_label.size = Vector2(94, 40)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	update_labels()

	show_hint()


func build_rayitas() -> void:
	rayitas = Control.new()
	rayitas.size = RAYITAS_SIZE
	rayitas.pivot_offset = Vector2(RAYITAS_SIZE.x / 2.0, RAYITAS_SIZE.y)
	rayitas.position = Vector2((screen.x - RAYITAS_SIZE.x) / 2.0, screen.y - RAYITAS_SIZE.y - 16)
	rayitas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rayitas)

	# Recorta automáticamente el espacio transparente de la imagen
	var full: Texture2D = load(RAYITAS_PATH)
	
	var tex = AtlasTexture.new()
	tex.atlas = full
	tex.region = Rect2(full.get_image().get_used_rect())

	var body = TextureRect.new()
	body.texture = tex
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.size = RAYITAS_SIZE
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rayitas.add_child(body)

	# Zona invisible donde se atrapan las canelas (la boca de la canasta)
	basket = Panel.new()
	basket.position = BASKET_ZONE.position * RAYITAS_SIZE
	basket.size = BASKET_ZONE.size * RAYITAS_SIZE
	basket.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rayitas.add_child(basket)

func show_hint() -> void:
	var hint = Label.new()
	hint.text = "¡Mueve a Rayitas y atrapa las canelas!"
	hint.size = Vector2(screen.x, 40)
	hint.position = Vector2(0, 90)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_text(hint, 20)
	add_child(hint)
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_property(hint, "modulate:a", 0.0, 0.5)
	t.tween_callback(hint.queue_free)
	add_child(preload("res://scripts/ui/pause_menu.gd").new())

func basket_rect() -> Rect2:
	return Rect2(rayitas.position + basket.position, basket.size)

func _process(delta: float) -> void:
	if not playing:
		return

	time_left -= delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_item()
		spawn_timer = SPAWN_EVERY

	move_rayitas(delta)

	var rect = basket_rect()
	for it in items_layer.get_children():
		if it.get_meta("caught"):
			continue
		it.position.y += it.get_meta("speed") * delta
		it.rotation += delta * it.get_meta("spin")
		if rect.has_point(it.position + it.size / 2.0):
			catch_item(it)
		elif it.position.y > screen.y:
			it.queue_free()

	update_labels()
	if time_left <= 0.0:
		end_game()


# Sigue el dedo/mouse; también funciona con las flechas del teclado
func move_rayitas(delta: float) -> void:
	var dir = Input.get_axis("ui_left", "ui_right")
	var x = rayitas.position.x
	if dir != 0.0:
		x += dir * 650.0 * delta
	else:
		var target = get_global_mouse_position().x - RAYITAS_SIZE.x / 2.0
		x = lerp(x, target, min(1.0, delta * 14.0))
	rayitas.position.x = clamp(x, 0.0, screen.x - RAYITAS_SIZE.x)


func spawn_item() -> void:
	var s = ITEM_SIZE * randf_range(0.85, 1.15)
	var it = TextureRect.new()
	it.texture = canela_tex
	it.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	it.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	it.size = Vector2(s, s)
	it.pivot_offset = it.size / 2.0
	it.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.position = Vector2(randf_range(10, screen.x - s - 10), -s)
	# Cada vez caen más rápido
	it.set_meta("speed", randf_range(160, 260) + (GAME_TIME - time_left) * 10.0)
	it.set_meta("spin", randf_range(-1.5, 1.5))
	it.set_meta("caught", false)
	items_layer.add_child(it)


func catch_item(it: TextureRect) -> void:
	it.set_meta("caught", true)
	score += 1

	var t = create_tween().set_parallel(true)
	t.tween_property(it, "scale", Vector2.ZERO, 0.15)
	t.tween_property(it, "position:y", it.position.y - 20, 0.15)
	t.chain().tween_callback(it.queue_free)

	# Rebote de Rayitas al atrapar
	var b = create_tween()
	b.tween_property(rayitas, "scale", Vector2(1.08, 0.92), 0.06)
	b.tween_property(rayitas, "scale", Vector2.ONE, 0.1)


func update_labels() -> void:
	score_label.text = "Canelas: %d" % score
	time_label.text = "%d s" % ceili(max(time_left, 0.0))


func end_game() -> void:
	playing = false
	for it in items_layer.get_children():
		it.queue_free()

	var new_record = score > GameState.best_canela
	GameState.best_canela = max(score, GameState.best_canela)
	GameState.canelas += score
	var panel = Panel.new()
	panel.size = Vector2(300, 300)
	panel.position = (screen - panel.size) / 2.0
	var ps = make_style(Color("#8B5A3C"), 28)
	ps.set_border_width_all(4)
	ps.border_color = Color("#F2B134")
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var title = Label.new()
	title.text = "¡Tiempo!"
	title.position = Vector2(0, 20)
	title.size = Vector2(300, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_text(title, 34)
	panel.add_child(title)

	var res = Label.new()
	res.text = "Canelas: %d\nMejor: %d" % [score, GameState.best_canela]
	if new_record:
		res.text += "\n¡Nuevo récord!"
	res.position = Vector2(0, 75)
	res.size = Vector2(300, 110)
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_text(res, 24)
	panel.add_child(res)

	add_button(panel, "Jugar de nuevo", 190, func(): get_tree().change_scene_to_file(GAME_SCENE))
	add_button(panel, "Mapa", 245, func(): get_tree().change_scene_to_file(MAP_SCENE))


# ---------- Ayudas de estilo ----------

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


func make_label(pos: Vector2, size: int) -> Label:
	var l = Label.new()
	l.position = pos
	style_text(l, size)
	add_child(l)
	return l


func add_button(parent: Control, text: String, y: float, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.size = Vector2(200, 44)
	btn.position = Vector2(50, y)
	btn.add_theme_stylebox_override("normal", make_style(Color("#C97B4A"), 16))
	btn.add_theme_stylebox_override("hover", make_style(Color("#E0965F"), 16))
	btn.add_theme_stylebox_override("pressed", make_style(Color("#A8623A"), 16))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(callback)
	parent.add_child(btn)
