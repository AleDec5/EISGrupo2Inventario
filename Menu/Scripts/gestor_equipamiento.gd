class_name GestorEquipamiento
extends MarginContainer

const MARGEN_BOTON_DEBUG := Vector2(8, 8)
const OPACIDAD_PANEL_DEBUG: float = 0.85

@onready var capa_pantalon: TextureRect = $Equipamiento2/PersonajeYSalud/ContenerdorPersonaje/CapaPantalon
@onready var capa_torso: TextureRect = $Equipamiento2/PersonajeYSalud/ContenerdorPersonaje/CapaTorso
@onready var capa_botas: TextureRect = $Equipamiento2/PersonajeYSalud/ContenerdorPersonaje/CapaBotas
@onready var capa_sombrero: TextureRect = $Equipamiento2/PersonajeYSalud/ContenerdorPersonaje/CapaSombrero
@onready var capa_arma: TextureRect = $Equipamiento2/PersonajeYSalud/ContenerdorPersonaje/CapaArma

var capas_por_rol: Dictionary = {}

var estadisticas := EstadisticasPersonaje.new()
var simulando_tiempo: bool = false

var _panel_stats: PanelContainer
var _etiqueta_stats: Label
var _etiqueta_municion: Label
var _etiqueta_mensaje: Label
var _mensaje_debug: String = ""
var _boton_debug: Button
var _texto_anterior: String = ""


func _ready() -> void:
	add_to_group("gestor_equipamiento")
	_crear_panel_stats()
	_crear_boton_debug()
	_conectar_grilla.call_deferred()
	
	capas_por_rol = {
		SlotEquipamiento.Rol.SOMBRERO: capa_sombrero,
		SlotEquipamiento.Rol.TORSO: capa_torso,
		SlotEquipamiento.Rol.PANTALON: capa_pantalon,
		SlotEquipamiento.Rol.CALZADO: capa_botas,
		SlotEquipamiento.Rol.ARMA_PRINCIPAL: capa_arma
	}
	
	_conectar_slots_visuales.call_deferred()

func _conectar_slots_visuales() -> void:
	for slot in _slots():
		if not slot.is_connected("equipo_cambiado", _on_slot_equipo_cambiado):
			slot.equipo_cambiado.connect(_on_slot_equipo_cambiado)

func _on_slot_equipo_cambiado(rol: SlotEquipamiento.Rol, item_data: ItemData) -> void:
	if not capas_por_rol.has(rol):
		return
		
	var capa_target: TextureRect = capas_por_rol[rol]
	
	if item_data != null and item_data.textura_personaje != null:
		capa_target.texture = item_data.textura_personaje
	else:
		capa_target.texture = null

func _conectar_grilla() -> void:
	var grilla = _grilla()
	if grilla != null:
		grilla.item_consumido.connect(estadisticas.aplicar_consumible)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F4:
			simulando_tiempo = not simulando_tiempo
		KEY_F5:
			estadisticas.curar(-20)


func _process(delta: float) -> void:
	if simulando_tiempo:
		estadisticas.avanzar_tiempo(delta)
	_actualizar_bonus_equipo()
	_actualizar_panel_stats()
	_posicionar_debug()
	var grilla = _grilla()
	if grilla == null:
		return
	for slot in _slots():
		if slot.esta_vacio():
			continue
		if slot.item != null:
			if slot.item.data.capacidad_cargador > 0:
				slot.mostrar_cargador(slot.item.balas_cargadas, slot.item.data.capacidad_cargador)
			else:
				slot.mostrar_cantidad(slot.item.cantidad)
		elif slot.es_atajo():
			var total: int = grilla.contar_item(slot.data)
			if total == 0:
				slot.vaciar()
			else:
				slot.mostrar_cantidad(total)


func _crear_panel_stats() -> void:
	_panel_stats = PanelContainer.new()
	_panel_stats.top_level = true
	_panel_stats.z_index = 90
	_panel_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_stats.hide()
	var caja := VBoxContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_stats.add_child(caja)
	_etiqueta_stats = _crear_etiqueta_debug()
	caja.add_child(_etiqueta_stats)
	caja.add_child(HSeparator.new())
	_etiqueta_municion = _crear_etiqueta_debug()
	caja.add_child(_etiqueta_municion)
	var boton_recargar := Button.new()
	boton_recargar.text = "Recargar arma equipada"
	boton_recargar.focus_mode = Control.FOCUS_NONE
	boton_recargar.pressed.connect(recargar_arma_principal)
	caja.add_child(boton_recargar)
	var boton_tipo := Button.new()
	boton_tipo.text = "Cambiar tipo de bala"
	boton_tipo.focus_mode = Control.FOCUS_NONE
	boton_tipo.pressed.connect(cambiar_tipo_bala)
	caja.add_child(boton_tipo)
	_etiqueta_mensaje = _crear_etiqueta_debug()
	_etiqueta_mensaje.add_theme_color_override("font_color", Color.YELLOW)
	_etiqueta_mensaje.hide()
	caja.add_child(_etiqueta_mensaje)
	add_child(_panel_stats)
	_subir_opacidad_panel_debug()


func _subir_opacidad_panel_debug() -> void:
	var base := _panel_stats.get_theme_stylebox("panel")
	var estilo: StyleBoxFlat
	if base is StyleBoxFlat:
		estilo = base.duplicate()
	else:
		estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.1, 0.1, 0.1)
	estilo.bg_color.a = OPACIDAD_PANEL_DEBUG
	_panel_stats.add_theme_stylebox_override("panel", estilo)


func _crear_etiqueta_debug() -> Label:
	var etiqueta := Label.new()
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size.x = 260
	etiqueta.add_theme_font_size_override("font_size", 12)
	return etiqueta


func _crear_boton_debug() -> void:
	_boton_debug = Button.new()
	_boton_debug.top_level = true
	_boton_debug.z_index = 90
	_boton_debug.text = "Debug menu"
	_boton_debug.toggle_mode = true
	_boton_debug.focus_mode = Control.FOCUS_NONE
	_boton_debug.toggled.connect(func(activado: bool): _panel_stats.visible = activado)
	add_child(_boton_debug)


func _posicionar_debug() -> void:
	var pantalla := get_viewport_rect().size
	var tamaño_boton := _boton_debug.get_combined_minimum_size()
	_boton_debug.global_position = Vector2(MARGEN_BOTON_DEBUG.x, pantalla.y - tamaño_boton.y - MARGEN_BOTON_DEBUG.y)
	_panel_stats.global_position = Vector2(MARGEN_BOTON_DEBUG.x, _boton_debug.global_position.y - _panel_stats.size.y - 8)


func _actualizar_panel_stats() -> void:
	if not _panel_stats.visible:
		return
	var texto := estadisticas.a_texto()
	texto += "\n\nTiempo: %s\n(F4 tiempo, F5 -20 HP, F6 +Arma, F7 +Poción)" % ("simulando" if simulando_tiempo else "en pausa")
	var texto_municion := _texto_municion()
	var combinado := texto + "\n" + texto_municion + "\n" + _mensaje_debug
	if combinado != _texto_anterior:
		_texto_anterior = combinado
		_etiqueta_stats.text = texto
		_etiqueta_municion.text = texto_municion
		_etiqueta_mensaje.text = _mensaje_debug
		_etiqueta_mensaje.visible = _mensaje_debug != ""
		_panel_stats.reset_size()


func _actualizar_bonus_equipo() -> void:
	var bonus: Dictionary = {}
	for slot in _slots():
		if slot.item == null or slot.rol == SlotEquipamiento.Rol.ARMA_SECUNDARIA:
			continue
		var modificadores: Dictionary = slot.data.obtener_modificadores()
		for stat in modificadores:
			var acumulado: Dictionary = bonus.get(stat, {"fijo": 0.0, "pct": 0.0})
			acumulado["fijo"] += modificadores[stat]["fijo"]
			acumulado["pct"] += modificadores[stat]["pct"]
			bonus[stat] = acumulado
	estadisticas.establecer_bonus_equipo(bonus)


func mouse_sobre_debug() -> bool:
	var mouse := get_global_mouse_position()
	if _boton_debug.get_global_rect().has_point(mouse):
		return true
	return _panel_stats.visible and _panel_stats.get_global_rect().has_point(mouse)


func _inventario() -> Node:
	return get_tree().get_first_node_in_group("inventario")


func _slot_principal() -> SlotEquipamiento:
	for slot in _slots():
		if slot.rol == SlotEquipamiento.Rol.ARMA_PRINCIPAL:
			return slot
	return null


func _arma_principal() -> ItemGrilla:
	var slot := _slot_principal()
	if slot == null or slot.item == null:
		return null
	return slot.item as ItemGrilla


func _municiones_compatibles(arma: ItemGrilla) -> Array[ItemData]:
	var inventario := _inventario()
	if inventario == null:
		return []
	return inventario.municiones_compatibles(arma.data)


func _preparar_municion(arma: ItemGrilla) -> void:
	if arma.municion_cargada != null:
		return
	var compatibles := _municiones_compatibles(arma)
	if not compatibles.is_empty():
		arma.municion_cargada = compatibles[0]


func _texto_municion() -> String:
	var arma := _arma_principal()
	if arma == null:
		return "Arma principal: ninguna equipada.\nEquipá un arma con cargador para ver su munición."
	if not arma.data.es_arma_recargable():
		return "%s no tiene cargador." % arma.data.nombre
	_preparar_municion(arma)
	var nombre_bala := "sin munición compatible"
	var disponibles: int = 0
	if arma.municion_cargada != null:
		nombre_bala = arma.municion_cargada.nombre
		var inventario := _inventario()
		if inventario != null:
			disponibles = inventario.contar_municion(arma.municion_cargada)
	return "Arma: %s\nBala: %s\nCargador: %d/%d\nEn inventario: %d" % [arma.data.nombre, nombre_bala, arma.balas_cargadas, arma.data.capacidad_cargador, disponibles]


func recargar_arma_principal() -> void:
	var arma := _arma_principal()
	if arma == null:
		_mensaje_debug = "No hay un arma equipada en el slot principal."
		return
	if not arma.data.es_arma_recargable():
		_mensaje_debug = "%s no tiene cargador." % arma.data.nombre
		return
	_preparar_municion(arma)
	if arma.municion_cargada == null:
		_mensaje_debug = "No hay un tipo de munición compatible con %s." % arma.data.nombre
		return
	var falta: int = arma.data.capacidad_cargador - arma.balas_cargadas
	if falta <= 0:
		_mensaje_debug = "El cargador ya está lleno."
		return
	var inventario := _inventario()
	if inventario == null:
		return
	var consumidas: int = inventario.consumir_municion(arma.municion_cargada, falta)
	if consumidas == 0:
		_mensaje_debug = "No hay %s en el inventario." % arma.municion_cargada.nombre
		return
	arma.balas_cargadas += consumidas
	_mensaje_debug = "Se recargaron %d balas. Cargador %d/%d." % [consumidas, arma.balas_cargadas, arma.data.capacidad_cargador]
	if consumidas < falta:
		_mensaje_debug += " No alcanzaron las balas para llenarlo."


func cambiar_tipo_bala() -> void:
	var arma := _arma_principal()
	if arma == null:
		_mensaje_debug = "No hay un arma equipada en el slot principal."
		return
	if not arma.data.es_arma_recargable():
		_mensaje_debug = "%s no tiene cargador." % arma.data.nombre
		return
	_preparar_municion(arma)
	var compatibles := _municiones_compatibles(arma)
	if compatibles.size() < 2:
		_mensaje_debug = "No hay otro tipo de bala compatible con %s." % arma.data.nombre
		return
	var indice: int = 0
	for i in compatibles.size():
		if compatibles[i].es_mismo(arma.municion_cargada):
			indice = i
	var siguiente: ItemData = compatibles[(indice + 1) % compatibles.size()]
	var devueltas: int = arma.balas_cargadas
	if devueltas > 0:
		var inventario := _inventario()
		if inventario == null or not inventario.agregar_municion(arma.municion_cargada, devueltas):
			_mensaje_debug = "No hay lugar en el inventario para devolver las balas del cargador."
			return
		arma.balas_cargadas = 0
	arma.municion_cargada = siguiente
	_mensaje_debug = "Tipo de bala: %s." % siguiente.nombre
	if devueltas > 0:
		_mensaje_debug += " Se devolvieron %d balas al inventario." % devueltas


func _grilla() -> Node:
	return get_tree().get_first_node_in_group("grilla_inventario")


func _slots() -> Array[SlotEquipamiento]:
	var slots: Array[SlotEquipamiento] = []
	for nodo in get_tree().get_nodes_in_group("slots_equipamiento"):
		slots.append(nodo as SlotEquipamiento)
	return slots


func obtener_slot_bajo_el_mouse() -> SlotEquipamiento:
	var mouse := get_global_mouse_position()
	for slot in _slots():
		if slot.is_visible_in_tree() and slot.get_global_rect().has_point(mouse):
			return slot
	return null


func _candidatos(d: ItemData) -> Array[SlotEquipamiento]:
	var candidatos: Array[SlotEquipamiento] = []
	for slot in _slots():
		if slot.acepta(d):
			candidatos.append(slot)
	return candidatos


func slot_para_equipar(d: ItemData) -> SlotEquipamiento:
	if d.es_consumible():
		return atajo_libre_para(d)
	var candidatos := _candidatos(d)
	for slot in candidatos:
		if slot.esta_vacio():
			return slot
	if candidatos.size() == 1:
		return candidatos[0]
	return null


func _atajo_con(d: ItemData) -> SlotEquipamiento:
	for slot in _slots():
		if slot.es_atajo() and slot.item == null and not slot.esta_vacio() and slot.data.es_mismo(d):
			return slot
	return null


func atajo_libre_para(d: ItemData) -> SlotEquipamiento:
	if _atajo_con(d) != null:
		return null
	for slot in _slots():
		if slot.es_atajo() and slot.acepta(d) and slot.esta_vacio():
			return slot
	return null


func puede_equipar(item: Node) -> bool:
	var d: ItemData = item.data
	if not d.se_puede_equipar() or d.esta_bloqueado:
		return false
	var slot := slot_para_equipar(d)
	if slot == null:
		return false
	if slot.es_atajo():
		return true
	var ocupante = slot.item
	return ocupante == null or _grilla().hay_lugar_para(ocupante, item)


func puede_desequipar(slot: SlotEquipamiento) -> bool:
	if slot.item == null:
		return slot.es_atajo()
	return _grilla().hay_lugar_para(slot.item)


func equipar(item: Node) -> bool:
	var slot := slot_para_equipar(item.data)
	if slot == null:
		return false
	return soltar_en_slot(slot, item)


func soltar_en_slot(slot: SlotEquipamiento, item: Node) -> bool:
	if not slot.acepta(item.data):
		return false
	if slot.es_atajo():
		return poner_en_atajo(item, slot)
	return _equipar_en_slot(slot, item)


func poner_en_atajo(item: Node, slot: SlotEquipamiento = null) -> bool:
	if slot == null:
		slot = atajo_libre_para(item.data)
	if slot == null or not slot.es_atajo() or not slot.acepta(item.data):
		return false
	var otro := _atajo_con(item.data)
	if otro != null and otro != slot:
		return false
	if item.esta_agarrado and not _grilla().devolver_item(item):
		return false
	slot.poner_atajo(item.data)
	return true


func _equipar_en_slot(slot: SlotEquipamiento, item: Node) -> bool:
	var grilla = _grilla()
	var ocupante = slot.item
	if ocupante != null and not grilla.hay_lugar_para(ocupante, item):
		return false
	grilla.sacar_item_de_data_casilla(item)
	if ocupante != null:
		ocupante.sacar_de_slot()
		grilla.intentar_agregar_item_data(ocupante)
	item.guardar_en_slot()
	slot.poner_item(item)
	return true


func desequipar(slot: SlotEquipamiento) -> bool:
	if slot.item == null:
		slot.vaciar()
		return true
	var item = slot.item
	var grilla = _grilla()
	if not grilla.hay_lugar_para(item):
		return false
	slot.vaciar()
	item.sacar_de_slot()
	grilla.intentar_agregar_item_data(item)
	return true


func agarrar_de_slot(slot: SlotEquipamiento) -> void:
	if slot.item == null:
		return
	var item = slot.item
	slot.vaciar()
	item.sacar_de_slot()
	item.set_meta("casilla_origen", -1)
	item.agarrar()
