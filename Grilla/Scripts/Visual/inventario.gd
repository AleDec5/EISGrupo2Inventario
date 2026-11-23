extends PanelContainer

@export var items: Array[ItemData] = []
@export var item_scene: PackedScene
@onready var grilla_item: GridContainer = %Grilla

var _debug_pocion: ItemData
var _debug_arma: ItemData

func _ready() -> void:
	add_to_group("inventario")
	for item_data in items:
		agregar_item(item_data)


func agregar_item(item_data: ItemData) -> void:
	var nuevo_item = item_scene.instantiate()
	nuevo_item.data = item_data
	nuevo_item.cantidad = mini(item_data.cantidad_inicial, item_data.cantidad_maxima)
	nuevo_item.tier = item_data.tier
	nuevo_item.nivel = item_data.nivel
	add_child(nuevo_item)
	var exito = grilla_item.intentar_agregar_item_data(nuevo_item)
	if not exito:
		nuevo_item.queue_free()

func _es_pila_de(item: Node, data_municion: ItemData) -> bool:
	return not item.esta_agarrado and item.data.es_municion() and item.data.es_mismo(data_municion)


func contar_municion(data_municion: ItemData) -> int:
	var total: int = 0
	for item in grilla_item.obtener_items():
		if _es_pila_de(item, data_municion):
			total += item.cantidad
	return total


func consumir_municion(data_municion: ItemData, cantidad_pedida: int) -> int:
	var pilas: Array[Node] = []
	for item in grilla_item.obtener_items():
		if _es_pila_de(item, data_municion):
			pilas.append(item)
	pilas.sort_custom(func(a: Node, b: Node) -> bool: return a.cantidad < b.cantidad)
	var restante: int = cantidad_pedida
	for pila in pilas:
		if restante <= 0:
			break
		var toma: int = mini(restante, pila.cantidad)
		restante -= toma
		if toma >= pila.cantidad:
			grilla_item.sacar_item_de_data_casilla(pila)
			pila.queue_free()
		else:
			pila.cantidad -= toma
	return cantidad_pedida - restante


func agregar_municion(data_municion: ItemData, total: int) -> bool:
	var restante: int = total
	var incrementos: Array = []
	for item in grilla_item.obtener_items():
		if restante <= 0:
			break
		if not _es_pila_de(item, data_municion):
			continue
		var cabe: int = mini(data_municion.cantidad_maxima - item.cantidad, restante)
		if cabe > 0:
			item.cantidad += cabe
			incrementos.append([item, cabe])
			restante -= cabe
	var nuevos: Array[Node] = []
	while restante > 0:
		var nuevo = item_scene.instantiate()
		nuevo.data = data_municion
		nuevo.cantidad = mini(restante, data_municion.cantidad_maxima)
		nuevo.tier = data_municion.tier
		nuevo.nivel = data_municion.nivel
		add_child(nuevo)
		if not grilla_item.intentar_agregar_item_data(nuevo):
			nuevo.queue_free()
			for creado in nuevos:
				grilla_item.sacar_item_de_data_casilla(creado)
				creado.queue_free()
			for par in incrementos:
				par[0].cantidad -= par[1]
			return false
		nuevos.append(nuevo)
		restante -= nuevo.cantidad
	return true


func municiones_compatibles(arma: ItemData) -> Array[ItemData]:
	var candidatas: Array[ItemData] = []
	candidatas.append_array(items)
	for item in grilla_item.obtener_items():
		candidatas.append(item.data)
	var resultado: Array[ItemData] = []
	for candidata in candidatas:
		if not arma.acepta_municion(candidata):
			continue
		var repetida := false
		for existente in resultado:
			if existente.es_mismo(candidata):
				repetida = true
				break
		if not repetida:
			resultado.append(candidata)
	return resultado


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F6:
			agregar_item(_obtener_debug_arma())
		KEY_F7:
			agregar_item(_obtener_debug_pocion())

func _obtener_debug_arma() -> ItemData:
	if _debug_arma == null:
		_debug_arma = ItemData.new()
		_debug_arma.nombre = "Espada Debug"
		_debug_arma.tipo = ItemData.Tipo.ARMA
		_debug_arma.texture = preload("res://Assets/Items/Equipables/Armas/EspadaDeSangre.tres")
		_debug_arma.dimensiones = Vector2i(1, 2)
		_debug_arma.categoria_icono = ItemData.CategoriaIcono.ARMA_MELEE
		_debug_arma.nivel = 1
		_debug_arma.stackeable = false
	return _debug_arma


func _obtener_debug_pocion() -> ItemData:
	if _debug_pocion == null:
		_debug_pocion = ItemData.new()
		_debug_pocion.nombre = "Poción Debug"
		_debug_pocion.tipo = ItemData.Tipo.CONSUMIBLE
		_debug_pocion.dimensiones = Vector2i(1, 1)
		_debug_pocion.texture = preload("res://Assets/Items/Consumibles/pocion_dracula.tres") 
		_debug_pocion.categoria_icono = ItemData.CategoriaIcono.CONSUMIBLE_SANACION
		_debug_pocion.stackeable = true
		_debug_pocion.cantidad_maxima = 8
		_debug_pocion.cantidad_inicial = 3
		_debug_pocion.esta_bloqueado = false
		_debug_pocion.regen_por_segundo = 20
		_debug_pocion.duracion_efecto = 2.0
	return _debug_pocion
