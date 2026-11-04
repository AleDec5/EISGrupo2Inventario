class_name ItemData
extends Resource

enum Tipo { NINGUNO, ARMA, CALZADO, PANTALON, TORSO, SOMBRERO, CONSUMIBLE, EQUIPABLE, DEFENSA, MUNICION }

const LIMITE_MAXIMO: int = 64
const TIER_MAXIMO: int = 4
const NOMBRES_TIPO: Dictionary = {
	Tipo.NINGUNO: "General",
	Tipo.ARMA: "Arma",
	Tipo.CALZADO: "Calzado",
	Tipo.PANTALON: "Pantalón",
	Tipo.TORSO: "Prenda de torso",
	Tipo.SOMBRERO: "Sombrero",
	Tipo.CONSUMIBLE: "Consumible",
	Tipo.EQUIPABLE: "Equipable",
	Tipo.DEFENSA: "Item de defensa",
	Tipo.MUNICION: "Munición",
}

@export var nombre: String
@export_multiline var descripcion: String
@export var tipo: Tipo = Tipo.NINGUNO
@export var dimensiones: Vector2i = Vector2i(1, 1)
@export var texture: Texture2D
@export_range(1, 4) var tier: int = 1
@export var stackeable: bool = false
@export_enum("8:8", "16:16", "32:32", "64:64") var cantidad_maxima: int = 16:
	set(valor):
		cantidad_maxima = clampi(valor, 1, LIMITE_MAXIMO)
@export var cantidad_inicial: int = 1
@export var opciones_descripcion: Array[String] = [] # Agregado para el Tooltip
@export var esta_bloqueado: bool = false # Agregado para validar interacciones

#aca cuando tengamos definido que van a tener los items
#digo, por ejemplo el RE que las armas tienen equipar, combinar etc
#definir que cosas va a tener cada items, y agregarlo en las
#"opciones_descripcion" y que traiga -> los consumibles "usar" "mover" "combinar"
# voy a modificar solo el naranja para probar


func es_consumible() -> bool:
	return tipo == Tipo.CONSUMIBLE


func se_puede_equipar() -> bool:
	return tipo != Tipo.NINGUNO and tipo != Tipo.MUNICION


func nombre_tipo() -> String:
	return NOMBRES_TIPO[tipo]


func es_mismo(otro: ItemData) -> bool:
	return otro != null and (self == otro or (nombre != "" and nombre == otro.nombre))
