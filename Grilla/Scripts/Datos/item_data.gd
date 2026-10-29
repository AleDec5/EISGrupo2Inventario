class_name ItemData
extends Resource

const LIMITE_MAXIMO: int = 64

@export var nombre: String
@export var dimensiones: Vector2i = Vector2i(1, 1)
@export var texture: Texture2D
@export var stackeable: bool = false
@export_enum("8:8", "16:16", "32:32", "64:64") var cantidad_maxima: int = 16:
	set(valor):
		cantidad_maxima = clampi(valor, 1, LIMITE_MAXIMO)
@export var cantidad_inicial: int = 1
