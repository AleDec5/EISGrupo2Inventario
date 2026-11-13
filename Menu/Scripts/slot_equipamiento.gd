class_name SlotEquipamiento
extends ColorRect

enum Rol { CONSUMIBLE, EQUIPABLE, SOMBRERO, TORSO, PANTALON, CALZADO, ARMA_PRINCIPAL, ARMA_SECUNDARIA }

const TIPOS_ACEPTADOS: Dictionary = {
	Rol.CONSUMIBLE: [ItemData.Tipo.CONSUMIBLE],
	Rol.EQUIPABLE: [ItemData.Tipo.EQUIPABLE],
	Rol.SOMBRERO: [ItemData.Tipo.SOMBRERO],
	Rol.TORSO: [ItemData.Tipo.TORSO],
	Rol.PANTALON: [ItemData.Tipo.PANTALON],
	Rol.CALZADO: [ItemData.Tipo.CALZADO],
	Rol.ARMA_PRINCIPAL: [ItemData.Tipo.ARMA],
	Rol.ARMA_SECUNDARIA: [ItemData.Tipo.ARMA],
}

@export var rol: Rol = Rol.CONSUMIBLE

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
	return rol == Rol.CONSUMIBLE


func esta_vacio() -> bool:
	return data == null


func acepta(d: ItemData) -> bool:
	if d == null or not (d.tipo in TIPOS_ACEPTADOS[rol]):
		return false
	if rol == Rol.ARMA_PRINCIPAL:
		return not d.arma_secundaria
	if rol == Rol.ARMA_SECUNDARIA:
		return d.arma_secundaria
	return true


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
