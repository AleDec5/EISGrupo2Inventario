class_name GestorEquipamiento
extends MarginContainer

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
var _texto_anterior: String = ""


func _ready() -> void:
	add_to_group("gestor_equipamiento")
	_crear_panel_stats()
	_conectar_grilla.call_deferred()
	
	capas_por_rol = {
		SlotEquipamiento.Rol.SOMBRERO: capa_sombrero,
		SlotEquipamiento.Rol.TORSO: capa_torso,
		SlotEquipamiento.Rol.PANTALON: capa_pantalon,
		SlotEquipamiento.Rol.CALZADO: capa_botas,
		SlotEquipamiento.Rol.ARMA: capa_arma
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
		KEY_F3:
			_panel_stats.visible = not _panel_stats.visible
		KEY_F4:
			simulando_tiempo = not simulando_tiempo
		KEY_F5:
			estadisticas.curar(-20)


func _process(delta: float) -> void:
	if simulando_tiempo:
		estadisticas.avanzar_tiempo(delta)
	_actualizar_bonus_equipo()
	_actualizar_panel_stats()
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
	_etiqueta_stats = Label.new()
	_etiqueta_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_etiqueta_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_etiqueta_stats.custom_minimum_size.x = 260
	_etiqueta_stats.add_theme_font_size_override("font_size", 12)
	_panel_stats.add_child(_etiqueta_stats)
	add_child(_panel_stats)


func _actualizar_panel_stats() -> void:
	var texto := estadisticas.a_texto()
	texto += "\n\nTiempo: %s\n(F3 panel, F4 tiempo, F5 -20 HP)" % ("simulando" if simulando_tiempo else "en pausa")
	if texto != _texto_anterior:
		_texto_anterior = texto
		_etiqueta_stats.text = texto
		_panel_stats.reset_size()
	_panel_stats.global_position = Vector2(80, get_viewport_rect().size.y - _panel_stats.size.y - 60)


func _actualizar_bonus_equipo() -> void:
	var bonus: Dictionary = {}
	for slot in _slots():
		if slot.item == null:
			continue
		if slot.es_atajo() and slot.data.tipo == ItemData.Tipo.ARMA:
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


func slot_principal_para(d: ItemData) -> SlotEquipamiento:
	for slot in _slots():
		if not slot.es_atajo() and slot.acepta(d):
			return slot
	return null


func _atajo_con(d: ItemData) -> SlotEquipamiento:
	for slot in _slots():
		if slot.es_atajo() and slot.item == null and not slot.esta_vacio() and slot.data.es_mismo(d):
			return slot
	return null


func atajo_libre_para(d: ItemData) -> SlotEquipamiento:
	if d.es_consumible() and _atajo_con(d) != null:
		return null
	for slot in _slots():
		if slot.es_atajo() and slot.acepta(d) and slot.esta_vacio():
			return slot
	return null


func puede_equipar(item: Node) -> bool:
	var d: ItemData = item.data
	if not d.se_puede_equipar() or d.esta_bloqueado:
		return false
	var slot := slot_principal_para(d)
	if slot != null:
		var ocupante = slot.item
		return ocupante == null or _grilla().hay_lugar_para(ocupante, item)
	return atajo_libre_para(d) != null


func puede_poner_en_atajo(item: Node) -> bool:
	return atajo_libre_para(item.data) != null


func puede_desequipar(slot: SlotEquipamiento) -> bool:
	if slot.item == null:
		return slot.es_atajo()
	return _grilla().hay_lugar_para(slot.item)


func equipar(item: Node) -> bool:
	var slot := slot_principal_para(item.data)
	if slot != null:
		return _equipar_en_slot(slot, item)
	return poner_en_atajo(item)


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

	if not item.data.es_consumible():
		return _equipar_en_slot(slot, item)

	var otro := _atajo_con(item.data)
	if otro != null and otro != slot:
		return false

	var grilla = _grilla()
	var ocupante = slot.item
	var venia_en_mano: bool = item.esta_agarrado
	if venia_en_mano and not grilla.devolver_item(item):
		return false
	if ocupante != null:
		if not grilla.hay_lugar_para(ocupante):
			if venia_en_mano:
				grilla.agarrar_item(item)
			return false
		ocupante.sacar_de_slot()
		grilla.intentar_agregar_item_data(ocupante)
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
