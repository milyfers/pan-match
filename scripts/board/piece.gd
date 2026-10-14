extends Node2D
var special: int = 0   # 0 = normal

enum PieceType {
	CONCHA,
	CUERNITO,
	OREJA,
	COCHINITO,
	CANELA
}

const TEXTURES = {
	PieceType.CONCHA: preload("res://assets/sprites/pieces/triangulo.png"),
	PieceType.CUERNITO: preload("res://assets/sprites/pieces/cuerno.png"),
	PieceType.OREJA: preload("res://assets/sprites/pieces/oreja.png"),
	PieceType.COCHINITO: preload("res://assets/sprites/pieces/cerdo.png"),
	PieceType.CANELA: preload("res://assets/sprites/pieces/roldecanela.png")
}

const BASE_SIZE = 80.0  # debe coincidir con PIECE_BASE_SIZE de board.gd

@export var piece_type: PieceType = PieceType.CONCHA

var grid_position: Vector2i = Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	update_visual()

func set_type(new_type: PieceType) -> void:
	piece_type = new_type
	update_visual()

func update_visual() -> void:
	if sprite:
		var tex: Texture2D = TEXTURES[piece_type]
		sprite.texture = tex
		sprite.scale = Vector2(BASE_SIZE / tex.get_width(), BASE_SIZE / tex.get_height())

const SPECIAL_TEXTURES = {
	1: preload("res://assets/sprites/pieces/concha_chocolate.png"),  # fila
	2: preload("res://assets/sprites/pieces/concha_vainilla.png"),  # columna
	3: preload("res://assets/sprites/pieces/concha_fresa.png"),
	4: preload("res://assets/sprites/pieces/colores.png")
}

func set_special(kind: int) -> void:
	special = kind
	var tex: Texture2D = SPECIAL_TEXTURES[kind]
	sprite.texture = tex
	var s = BASE_SIZE / max(tex.get_width(), tex.get_height())
	sprite.scale = Vector2(s, s)
	sprite.modulate = Color.WHITE

	# Latido para que se note que es especial
	var t = create_tween().set_loops()
	t.tween_property(sprite, "scale", Vector2(s, s) * 1.08, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(sprite, "scale", Vector2(s, s), 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
