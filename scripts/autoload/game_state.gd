extends Node

var current_level := 0
var unlocked := 0                 # último nivel desbloqueado
var stars := [0, 0, 0, 0]         # estrellas por nivel

const LEVELS = [
	{"name": "Primer día",       "goal": 600,  "moves": 15, "types": 3},
	{"name": "Se corre la voz",  "goal": 1200, "moves": 15, "types": 4},
	{"name": "Hora pico",        "goal": 0,    "moves": 15, "types": 5, "collect_type": 4, "collect": 14},
	{"name": "Panadería llena",  "goal": 2500, "moves": 16, "types": 5},
]

var minigame_unlocked := false
var best_canela := 0
var canelas := 100  

const OUTFITS = [
	{"id": "base", "name": "Normal", "price": 0, "path": "res://assets/sprites/rayitas/rayitas_base.png", "tint": Color("#FFFFFF")},
	{"id": "gorro",    "name": "Gorrito de chef",   "price": 30, "path": "res://assets/sprites/rayitas/gorro.png",    "tint": Color("#FFF1C9")},
	{"id": "mono",     "name": "Moño",              "price": 45, "path": "res://assets/sprites/rayitas/mono.png",     "tint": Color("#FFD6E5")},
	{"id": "bufanda",  "name": "Bufanda",           "price": 60, "path": "res://assets/sprites/rayitas/bufanda.png",  "tint": Color("#D6ECFF")},
	{"id": "delantal", "name": "Delantal especial", "price": 90, "path": "res://assets/sprites/rayitas/delantal.png", "tint": Color("#FFE0A8")},
]

var owned := ["base"]
var equipped := "base"

func data() -> Dictionary:
	return LEVELS[current_level]

func has_next() -> bool:
	return current_level < LEVELS.size() - 1

func complete_level(s: int) -> void:
	stars[current_level] = max(stars[current_level], s)
	if current_level == 2:                 # nivel 3 = índice 2
		minigame_unlocked = true
	if has_next():
		unlocked = max(unlocked, current_level + 1)

func get_outfit(id: String) -> Dictionary:
	for o in OUTFITS:
		if o.id == id:
			return o
	return OUTFITS[0]

func buy(id: String) -> bool:
	var o = get_outfit(id)
	if owned.has(id) or canelas < o.price:
		return false
	canelas -= o.price
	owned.append(id)
	return true

func equip(id: String) -> void:
	if owned.has(id):
		equipped = id
