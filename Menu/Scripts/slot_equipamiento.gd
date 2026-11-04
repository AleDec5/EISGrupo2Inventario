class_name SlotEquipamiento
extends ColorRect

enum Rol { ATAJO, DEFENSA, SOMBRERO, TORSO, PANTALON, CALZADO, ARMA }

const TIPOS_ACEPTADOS: Dictionary = {
	Rol.ATAJO: [ItemData.Tipo.ARMA, ItemData.Tipo.CONSUMIBLE, ItemData.Tipo.EQUIPABLE],
	Rol.DEFENSA: [ItemData.Tipo.DEFENSA],
	Rol.SOMBRERO: [ItemData.Tipo.SOMBRERO],
	Rol.TORSO: [ItemData.Tipo.TORSO],
	Rol.PANTALON: [ItemData.Tipo.PANTALON],
	Rol.CALZADO: [ItemData.Tipo.CALZADO],
	Rol.ARMA: [ItemData.Tipo.ARMA],
}

@export var rol: Rol = Rol.ATAJO

var item: Node = null
var data: ItemData = null

var _icono: TextureRect
var _cantidad: Label


func _ready() -> void:
	add_to_group("slots_equipamiento")

	_icono = TextureRect.new()
	_icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icono)

	_cantidad = Label.new()
	_cantidad.add_theme_font_size_override("font_size", 10)
	_cantidad.add_theme_constant_override("outline_size", 3)
	_cantidad.add_theme_color_override("font_outline_color", Color.BLACK)
	_cantidad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cantidad.hide()
	add_child(_cantidad)


func es_atajo() -> bool:
	return rol == Rol.ATAJO


func esta_vacio() -> bool:
	return data == null


func acepta(d: ItemData) -> bool:
	return d != null and d.tipo in TIPOS_ACEPTADOS[rol]


func poner_item(nuevo: Node) -> void:
	item = nuevo
	_mostrar(nuevo.data)


func poner_atajo(d: ItemData) -> void:
	item = null
	_mostrar(d)


func vaciar() -> void:
	item = null
	data = null
	_icono.texture = null
	_cantidad.hide()


func mostrar_cantidad(total: int) -> void:
	_cantidad.visible = data != null and data.stackeable
	_cantidad.text = str(total)
	_cantidad.position = size - _cantidad.get_combined_minimum_size() - Vector2(2, 0)


func obtener_opciones() -> Array[String]:
	var opciones: Array[String] = []
	opciones.append("Quitar atajo" if es_atajo() and item == null else "Desequipar")
	return opciones


func _mostrar(d: ItemData) -> void:
	data = d
	_icono.texture = d.texture
	_cantidad.hide()
