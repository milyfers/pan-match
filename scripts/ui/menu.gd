extends Control

@onready var play_button: Button = $Button
@onready var logo: TextureRect = $Logo  
@onready var rayitas: TextureRect = $Rayitas

var rayitas_hidden_y: float
var rayitas_visible_y: float

func _ready() -> void:
	style_button()
	$Button.pressed.connect(_on_play_pressed)
	logo.scale = Vector2(0.5, 0.5)   # fuerza el tamaño por código
	rayitas.scale = Vector2(0.5, 0.5)    # ajusta a tu gusto
	animate_logo_entrance()
	setup_rayitas_peek()

func style_button() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#C97B4A")       # terracota/café cálido
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10

	var hover = normal.duplicate()
	hover.bg_color = Color("#E0965F")         # un poco más claro al pasar el mouse

	var pressed = normal.duplicate()
	pressed.bg_color = Color("#A8623A")       # más oscuro al presionar

	play_button.add_theme_stylebox_override("normal", normal)
	play_button.add_theme_stylebox_override("hover", hover)
	play_button.add_theme_stylebox_override("pressed", pressed)

	play_button.add_theme_color_override("font_color", Color.WHITE)
	play_button.add_theme_font_size_override("font_size", 24)

	var font = load("res://assets/fonts/Papernotes Sketch.ttf")   # cambia por el nombre real
	play_button.add_theme_font_override("font", font)

func animate_logo_entrance() -> void:
	logo.pivot_offset = Vector2(logo.size.x / 2.0, 0)  # pivote arriba-centro, donde está el cordón

	var start_pos = logo.position
	logo.position.y = start_pos.y - 60   # una caída corta, no 400px
	logo.modulate.a = 0.0                # empieza invisible

	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 0.3)  # aparece con fade
	tween.parallel().tween_property(logo, "position:y", start_pos.y, 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(start_idle_sway)

func start_idle_sway() -> void:
	var sway = create_tween().set_loops()
	sway.tween_property(logo, "rotation_degrees", 4, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(logo, "rotation_degrees", -4, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func setup_rayitas_peek() -> void:
	rayitas_visible_y = rayitas.position.y       # la posición actual, donde se ve bien
	rayitas_hidden_y = rayitas_visible_y + 80     # cuánto baja para esconderse (ajusta este número)

	rayitas.position.y = rayitas_hidden_y   # empieza escondida
	peek_loop()

func peek_loop() -> void:
	var tween = create_tween()
	tween.tween_interval(2.0)   # espera 2 segundos escondida
	tween.tween_property(rayitas, "position:y", rayitas_visible_y, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # sube asomándose
	tween.tween_interval(1.5)   # se queda visible 1.5 segundos
	tween.tween_property(rayitas, "position:y", rayitas_hidden_y, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)     # se esconde de nuevo
	tween.tween_callback(peek_loop)   # se repite para siempre
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/LevelMap.tscn")
