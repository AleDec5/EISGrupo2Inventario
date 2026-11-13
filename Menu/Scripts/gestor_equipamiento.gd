class_name GestorEquipamiento
extends MarginContainer

const MARGEN_BOTON_DEBUG := Vector2(8, 8)

var estadisticas := EstadisticasPersonaje.new()
var simulando_tiempo: bool = false

var _panel_stats: PanelContainer
var _etiqueta_stats: Label
var _boton_debug: Button
var _texto_anterior: String = ""


func _ready() -> void:
	add_to_group("gestor_equipamiento")
	_crear_panel_stats()
	_crear_boton_debug()
	_conectar_grilla.call_deferred()


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
	_etiqueta_stats = Label.new()
	_etiqueta_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_etiqueta_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_etiqueta_stats.custom_minimum_size.x = 260
	_etiqueta_stats.add_theme_font_size_override("font_size", 12)
	_panel_stats.add_child(_etiqueta_stats)
	add_child(_panel_stats)


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
	texto += "\n\nTiempo: %s\n(F4 tiempo, F5 -20 HP)" % ("simulando" if simulando_tiempo else "en pausa")
	if texto != _texto_anterior:
		_texto_anterior = texto
		_etiqueta_stats.text = texto
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
