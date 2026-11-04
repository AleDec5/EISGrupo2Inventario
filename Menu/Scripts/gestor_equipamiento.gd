class_name GestorEquipamiento
extends MarginContainer


func _ready() -> void:
	add_to_group("gestor_equipamiento")


func _process(_delta: float) -> void:
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
