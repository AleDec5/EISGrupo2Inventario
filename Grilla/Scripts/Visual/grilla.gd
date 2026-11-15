extends GridContainer

signal fusion_bloqueada(motivo: String)
signal item_consumido(data: ItemData)

enum EstadoCasilla { BASE, SELECCIONADO, HOVER, LLENO }

const TAMAÑO_SLOT: int = ItemGrilla.TAMAÑO_SLOT
const ATLAS_1X1: Texture2D = preload("res://Assets/Casillas/spritesheet-casilla1x1.png")
const ATLAS_2X1: Texture2D = preload("res://Assets/Casillas/spritesheet-casilla1x2.png")
const ATLAS_1X2: Texture2D = preload("res://Assets/Casillas/spritesheet-casillas2x1.png")
const ATLAS_2X2: Texture2D = preload("res://Assets/Casillas/spritesheet-casilla2x2.png")

@export var dimensiones: Vector2i

var data_casilla: Array[Node] = []
var item_seleccionado: Node = null

var _capa_arrastre: Node2D


func _ready() -> void:
	add_to_group("grilla_inventario")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	columns = dimensiones.x
	custom_minimum_size = Vector2(dimensiones) * TAMAÑO_SLOT
	init_data_casilla()
	if owner is Control:
		owner.custom_minimum_size = custom_minimum_size

	_capa_arrastre = Node2D.new()
	_capa_arrastre.top_level = true
	_capa_arrastre.z_as_relative = false
	_capa_arrastre.z_index = 9
	_capa_arrastre.draw.connect(_dibujar_capa_arrastre)
	add_child(_capa_arrastre)


func init_data_casilla() -> void:
	data_casilla.resize(dimensiones.x * dimensiones.y)
	data_casilla.fill(null)


func _process(_delta: float) -> void:
	queue_redraw()
	_capa_arrastre.queue_redraw()


func _draw() -> void:
	if item_seleccionado != null and not is_instance_valid(item_seleccionado):
		item_seleccionado = null

	var agarrado = get_tree().get_first_node_in_group("item_agarrado")
	var bajo_el_mouse: Node = null
	if agarrado == null:
		bajo_el_mouse = obtener_item_bajo_el_mouse()

	var dibujados: Dictionary = {}
	for index in data_casilla.size():
		var item = data_casilla[index]
		if item == null:
			_dibujar_marco(self, _posicion_casilla(index), Vector2i.ONE, EstadoCasilla.BASE)
		elif not dibujados.has(item):
			dibujados[item] = true
			_dibujar_marco(self, _posicion_casilla(index), item.dimensiones, _estado_de(item, bajo_el_mouse))


func _dibujar_capa_arrastre() -> void:
	var agarrado = get_tree().get_first_node_in_group("item_agarrado")
	if agarrado == null:
		return
	_dibujar_marco(_capa_arrastre, agarrado.ancla, agarrado.dimensiones, EstadoCasilla.SELECCIONADO)


func _estado_de(item: Node, bajo_el_mouse: Node) -> int:
	if item == item_seleccionado:
		return EstadoCasilla.SELECCIONADO
	if item == bajo_el_mouse:
		return EstadoCasilla.HOVER
	if item.data.stackeable and item.cantidad >= item.data.cantidad_maxima:
		return EstadoCasilla.LLENO
	return EstadoCasilla.BASE


func _posicion_casilla(index: int) -> Vector2:
	return Vector2((index % columns) * TAMAÑO_SLOT, (index / columns) * TAMAÑO_SLOT)


func _dibujar_marco(lienzo: CanvasItem, pos: Vector2, dims: Vector2i, estado: int) -> void:
	var atlas: Texture2D = null
	if dims == Vector2i(1, 1):
		atlas = ATLAS_1X1
	elif dims == Vector2i(2, 1):
		atlas = ATLAS_2X1
	elif dims == Vector2i(1, 2):
		atlas = ATLAS_1X2
	elif dims == Vector2i(2, 2):
		atlas = ATLAS_2X2

	if atlas != null:
		_dibujar_region(lienzo, atlas, Rect2(pos, Vector2(dims) * TAMAÑO_SLOT), estado)
		return

	for y in dims.y:
		for x in dims.x:
			var destino := Rect2(pos + Vector2(x, y) * TAMAÑO_SLOT, Vector2.ONE * TAMAÑO_SLOT)
			_dibujar_region(lienzo, ATLAS_1X1, destino, estado)


func _dibujar_region(lienzo: CanvasItem, atlas: Texture2D, destino: Rect2, estado: int) -> void:
	var tamaño_cuadro := atlas.get_size() / 2.0
	var origen := Vector2(estado % 2, estado / 2) * tamaño_cuadro
	lienzo.draw_texture_rect_region(atlas, destino, Rect2(origen, tamaño_cuadro))


#separe la logica para ver si hay item abajo del mouse en una funcion aparte para usarlo en menu
func obtener_item_bajo_el_mouse() -> Node:
	var index = get_index_casilla_desde_coordenadas(Vector2i(get_global_mouse_position()))
	if index != -1 and data_casilla[index] != null:
		return data_casilla[index]
	return null


func agarrar_item(item: Node) -> void:
	if get_tree().get_first_node_in_group("item_agarrado") != null:
		return
	item.set_meta("casilla_origen", data_casilla.find(item))
	sacar_item_de_data_casilla(item)
	item.agarrar()


func agarrar_uno(item: Node) -> void:
	if get_tree().get_first_node_in_group("item_agarrado") != null or item.cantidad < 2:
		return
	item.dividir(1).agarrar()


func dividir_a_la_mitad(item: Node) -> void:
	if get_tree().get_first_node_in_group("item_agarrado") != null or item.cantidad < 2:
		return
	item.dividir(floori(item.cantidad / 2.0)).agarrar()


func consumir_item(item: Node) -> void:
	if not item.data.es_consumible() or item.data.esta_bloqueado:
		return
	var data_consumida: ItemData = item.data
	if item.data.stackeable and item.cantidad > 1:
		item.cantidad -= 1
	else:
		sacar_item_de_data_casilla(item)
		item.queue_free()
	item_consumido.emit(data_consumida)


func _soltar_item(item_agarrado: Node) -> void:
	var punto = Vector2i(item_agarrado.ancla) + Vector2i.ONE * (TAMAÑO_SLOT / 2)
	var index = get_index_casilla_desde_coordenadas(punto)
	if index == -1:
		return

	var destino = data_casilla[index]
	if destino != null:
		if destino.puede_apilar(item_agarrado):
			destino.apilar(item_agarrado)
		elif destino.puede_fusionar(item_agarrado):
			destino.fusionar(item_agarrado)
		else:
			_avisar_bloqueo(destino, item_agarrado)
		return

	if not item_entra(index, item_agarrado.dimensiones):
		return
	llenar_data_casilla(item_agarrado, index)
	item_agarrado.colocar(get_coordenadas_desde_index_casilla(index))


func _avisar_bloqueo(destino: Node, item: Node) -> void:
	if not destino.es_mismo_item(item) or destino.data.stackeable:
		return
	if destino.tier != item.tier:
		fusion_bloqueada.emit("tier_distinto")
	elif destino.tier >= ItemData.TIER_MAXIMO:
		fusion_bloqueada.emit("tier_maximo")


func intentar_agregar_item_data(item: Node) -> bool:
	var index_casilla := _buscar_lugar(item.dimensiones)
	if index_casilla == -1:
		return false
	llenar_data_casilla(item, index_casilla)
	item.set_posicion_inicial(get_coordenadas_desde_index_casilla(index_casilla))
	return true


func devolver_item(item: Node) -> bool:
	var index: int = item.get_meta("casilla_origen", -1)
	if index == -1 or not item_entra(index, item.dimensiones):
		index = _buscar_lugar(item.dimensiones)
	if index == -1:
		return false
	llenar_data_casilla(item, index)
	item.colocar(get_coordenadas_desde_index_casilla(index))
	return true


func hay_lugar_para(item: Node, ignorar: Node = null) -> bool:
	return _buscar_lugar(item.dimensiones, ignorar) != -1


func _buscar_lugar(tamano_item: Vector2i, ignorar: Node = null) -> int:
	for index in data_casilla.size():
		if item_entra(index, tamano_item, ignorar):
			return index
	return -1


func obtener_items() -> Array[Node]:
	var items: Array[Node] = []
	for item in data_casilla:
		if item != null and not items.has(item):
			items.append(item)
	var agarrado = get_tree().get_first_node_in_group("item_agarrado")
	if agarrado != null and not items.has(agarrado):
		items.append(agarrado)
	return items


func contar_item(data_buscada: ItemData) -> int:
	var total: int = 0
	for item in obtener_items():
		if item.data.es_mismo(data_buscada):
			total += item.cantidad if item.data.stackeable else 1
	return total


func llenar_data_casilla(item: Node, index: int) -> void:
	for y in item.dimensiones.y:
		for x in item.dimensiones.x:
			data_casilla[index + x + y * columns] = item


func sacar_item_de_data_casilla(item: Node) -> void:
	for i in data_casilla.size():
		if data_casilla[i] == item:
			data_casilla[i] = null


func item_entra(index: int, tamano_item: Vector2i, ignorar: Node = null) -> bool:
	if index % columns + tamano_item.x > columns:
		return false
	for y in tamano_item.y:
		for x in tamano_item.x:
			var index_actual = index + x + y * columns
			if index_actual >= data_casilla.size():
				return false
			var ocupante = data_casilla[index_actual]
			if ocupante != null and ocupante != ignorar:
				return false
	return true


func get_index_casilla_desde_coordenadas(coordenadas: Vector2i) -> int:
	var local = coordenadas - Vector2i(global_position)
	if local.x < 0 or local.y < 0:
		return -1
	var casilla = local / TAMAÑO_SLOT
	if casilla.x >= columns or casilla.y >= dimensiones.y:
		return -1
	return casilla.x + casilla.y * columns


func get_coordenadas_desde_index_casilla(index: int) -> Vector2i:
	var fila = index / columns
	var columna = index % columns
	return Vector2i(global_position) + Vector2i(columna * TAMAÑO_SLOT, fila * TAMAÑO_SLOT)
