extends Sprite2D

const TAMAÑO_SLOT: int = 32
const DURACION_ROTACION: float = 0.1
const TAMAÑO_FUENTE: int = 10
const GROSOR_CONTORNO: int = 3
const COLORES_TIER: Array[Color] = [Color.LIME_GREEN, Color.DODGER_BLUE, Color.MEDIUM_PURPLE, Color.ORANGE]
const COLOR_APAGADO := Color(0.1, 0.1, 0.1, 0.6)
const ORDEN_LLENADO: Array[int] = [2, 3, 0, 1]

var data: ItemData = null
var esta_agarrado: bool = false
var pasos_rotacion: int = 0

var cantidad: int = 1:
	set(valor):
		cantidad = valor
		actualizar_indicadores()

var tier: int = 1:
	set(valor):
		tier = clampi(valor, 1, ItemData.TIER_MAXIMO)
		actualizar_indicadores()

var _grados_objetivo: float = 0.0
var _tween: Tween

@onready var etiqueta: Label = $Cantidad
@onready var indicador_tier: GridContainer = $Tier

var dimensiones: Vector2i:
	get():
		if pasos_rotacion % 2 == 1:
			return Vector2i(data.dimensiones.y, data.dimensiones.x)
		return data.dimensiones

var tamaño: Vector2:
	get():
		return Vector2(dimensiones) * TAMAÑO_SLOT

var ancla: Vector2:
	get():
		return global_position - tamaño / 2


func _ready() -> void:
	for nodo in [etiqueta, indicador_tier]:
		nodo.top_level = true
		nodo.z_as_relative = false
		nodo.z_index = 1
	etiqueta.add_theme_font_size_override("font_size", TAMAÑO_FUENTE)
	etiqueta.add_theme_constant_override("outline_size", GROSOR_CONTORNO)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	indicador_tier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cuadrito in indicador_tier.get_children():
		cuadrito.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if data and data.texture:
		texture = data.texture
		scale = Vector2(data.dimensiones) * TAMAÑO_SLOT / texture.get_size()
	actualizar_indicadores()


func _process(_delta: float) -> void:
	if esta_agarrado:
		global_position = get_global_mouse_position()
		actualizar_indicadores()


func _unhandled_input(event: InputEvent) -> void:
	if esta_agarrado and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rotar()


func rotar() -> void:
	pasos_rotacion = (pasos_rotacion + 1) % 4
	_grados_objetivo += 90.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation_degrees", _grados_objetivo, DURACION_ROTACION)
	actualizar_indicadores()


func set_posicion_inicial(pos: Vector2) -> void:
	global_position = pos + tamaño / 2
	actualizar_indicadores()


func agarrar() -> void:
	esta_agarrado = true
	z_index = 10
	etiqueta.z_index = 11
	indicador_tier.z_index = 11
	add_to_group("item_agarrado")


func colocar(pos: Vector2i) -> void:
	esta_agarrado = false
	z_index = 0
	etiqueta.z_index = 1
	indicador_tier.z_index = 1
	global_position = Vector2(pos) + tamaño / 2
	remove_from_group("item_agarrado")
	actualizar_indicadores()


func actualizar_indicadores() -> void:
	if not is_node_ready() or data == null:
		return

	etiqueta.visible = data.stackeable
	etiqueta.text = str(cantidad)
	etiqueta.global_position = ancla + tamaño - etiqueta.get_combined_minimum_size() - Vector2(2, 0)

	indicador_tier.visible = not data.stackeable
	var cuadritos = indicador_tier.get_children()
	for i in cuadritos.size():
		var encendido = ORDEN_LLENADO.find(i) < tier
		cuadritos[i].color = COLORES_TIER[tier - 1] if encendido else COLOR_APAGADO
	indicador_tier.global_position = ancla + Vector2(tamaño.x - indicador_tier.get_combined_minimum_size().x - 2, 2)


func es_mismo_item(otro: Node) -> bool:
	return data == otro.data or (data.nombre != "" and data.nombre == otro.data.nombre)


func puede_apilar(otro: Node) -> bool:
	return otro != self and data.stackeable and es_mismo_item(otro) and cantidad < data.cantidad_maxima


func apilar(otro: Node) -> void:
	var pasan = mini(data.cantidad_maxima - cantidad, otro.cantidad)
	cantidad += pasan
	otro.cantidad -= pasan
	if otro.cantidad == 0:
		otro.esta_agarrado = false
		otro.remove_from_group("item_agarrado")
		otro.queue_free()


func puede_fusionar(otro: Node) -> bool:
	return otro != self and not data.stackeable and es_mismo_item(otro) and otro.tier == tier and tier < ItemData.TIER_MAXIMO


func fusionar(otro: Node) -> void:
	tier += 1
	otro.esta_agarrado = false
	otro.remove_from_group("item_agarrado")
	otro.queue_free()


func dividir_uno() -> Node:
	var nuevo = (load(scene_file_path) as PackedScene).instantiate()
	nuevo.data = data
	nuevo.cantidad = 1
	nuevo.global_position = global_position
	get_parent().add_child(nuevo)
	cantidad -= 1
	return nuevo
