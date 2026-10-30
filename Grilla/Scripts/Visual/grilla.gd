extends GridContainer

signal fusion_bloqueada(motivo: String)

const TAMAÑO_SLOT: int = 32

@export var casilla_scene: PackedScene
@export var dimensiones: Vector2i

var data_casilla: Array[Node] = []


func _ready() -> void:
	crear_casillas()
	init_data_casilla()


func crear_casillas() -> void:
	self.columns = dimensiones.x
	for i in dimensiones.x * dimensiones.y:
		add_child(casilla_scene.instantiate())


func init_data_casilla() -> void:
	data_casilla.resize(dimensiones.x * dimensiones.y)
	data_casilla.fill(null)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.is_pressed()):
		return

	var item_agarrado = get_tree().get_first_node_in_group("item_agarrado")
	if item_agarrado != null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_soltar_item(item_agarrado)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		_agarrar_item_bajo_el_mouse(false)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_agarrar_item_bajo_el_mouse(true)


func _agarrar_item_bajo_el_mouse(solo_uno: bool) -> void:
	var index = get_index_casilla_desde_coordenadas(Vector2i(get_global_mouse_position()))
	if index == -1:
		return
	var item = data_casilla[index]
	if item == null:
		return

	if solo_uno and item.cantidad > 1:
		item.dividir_uno().agarrar()
		return

	sacar_item_de_data_casilla(item)
	item.agarrar()


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
	var index_casilla: int = 0
	while index_casilla < data_casilla.size():
		if item_entra(index_casilla, item.dimensiones):
			break
		index_casilla += 1
	if index_casilla >= data_casilla.size():
		return false

	llenar_data_casilla(item, index_casilla)
	item.set_posicion_inicial(get_coordenadas_desde_index_casilla(index_casilla))
	return true


func llenar_data_casilla(item: Node, index: int) -> void:
	for y in item.dimensiones.y:
		for x in item.dimensiones.x:
			data_casilla[index + x + y * columns] = item


func sacar_item_de_data_casilla(item: Node) -> void:
	for i in data_casilla.size():
		if data_casilla[i] == item:
			data_casilla[i] = null


func item_entra(index: int, tamano_item: Vector2i) -> bool:
	if index % columns + tamano_item.x > columns:
		return false
	for y in tamano_item.y:
		for x in tamano_item.x:
			var index_actual = index + x + y * columns
			if index_actual >= data_casilla.size():
				return false
			if data_casilla[index_actual] != null:
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
