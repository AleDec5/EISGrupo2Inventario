extends Control

@export var contenedor_tooltip: VBoxContainer
@export var panel_tooltip: PanelContainer
@export var escena_inventario: Control
var grilla_inventario = null
var gestor_equipamiento = null

# --- Variables para el Umbral de Arrastre ---
var _click_inicial_pos: Vector2 = Vector2.ZERO
var _item_potencial: Node = null
var _slot_potencial: SlotEquipamiento = null
var _esta_arrastrando: bool = false
const UMBRAL_ARRASTRE: float = 5.0 # Píxeles que debe moverse para considerar "arrastre"
const OPACIDAD_PANEL_INFO: float = 0.9

var _panel_info: PanelContainer
var _etiqueta_nombre: Label
var _etiqueta_descripcion: Label
var _etiqueta_detalle: Label

func _ready() -> void:
	panel_tooltip.top_level = true
	panel_tooltip.z_index = 100
	panel_tooltip.hide()
	_crear_panel_info()
	
	grilla_inventario = escena_inventario.find_child("Grilla", true, false)
	if grilla_inventario == null:
		print("ERROR CRÍTICO: No se encontró 'Grilla' dentro de la escena")
	
	gestor_equipamiento = get_tree().get_first_node_in_group("gestor_equipamiento")


func _input(event: InputEvent) -> void:
	var item_agarrado = get_tree().get_first_node_in_group("item_agarrado")

	# --- 0. CLIC DERECHO: ABRIR EL MENÚ DEL ITEM ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		ocultar_info()
		if item_agarrado == null and not _mouse_sobre_tooltip():
			var item = null
			var slot = _slot_bajo_el_mouse()
			if _mouse_esta_sobre(grilla_inventario):
				item = grilla_inventario.obtener_item_bajo_el_mouse()
			if item != null:
				mostrar_tooltip(item)
			elif slot != null and not slot.esta_vacio():
				mostrar_tooltip(slot)
			else:
				ocultar_tooltip()
		return

	# --- 1. CLIC IZQUIERDO (PRESIONAR O SOLTAR) ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		if event.pressed:
			# --- AL PRESIONAR ---
			
			# CASO RESCATE: Si ya tenemos un ítem en la mano (quedó flotando),
			# un nuevo clic intentará soltarlo en la grilla o devolverlo
			if item_agarrado != null:
				_soltar_item_agarrado(item_agarrado)
				return

			if _mouse_sobre_info():
				return
			ocultar_info()
			if not _mouse_esta_sobre(panel_tooltip):
				ocultar_tooltip()
			
			if item_agarrado == null and _mouse_esta_sobre(grilla_inventario) and not _mouse_sobre_tooltip():
				# Registramos dónde hizo clic y qué ítem tocó, pero NO lo arrastramos aún
				_click_inicial_pos = event.position
				_item_potencial = grilla_inventario.obtener_item_bajo_el_mouse()
				_esta_arrastrando = false

			var slot = _slot_bajo_el_mouse()
			if item_agarrado == null and slot != null and slot.item != null and not _mouse_sobre_tooltip():
				_click_inicial_pos = event.position
				_slot_potencial = slot
				_esta_arrastrando = false
				
		else:
			# --- AL SOLTAR ---
			if _esta_arrastrando and item_agarrado != null:
				# Intenta soltarlo al liberar el clic mantenido
				_soltar_item_agarrado(item_agarrado)
					
			elif not _esta_arrastrando and _item_potencial != null:
				# Si soltó el clic rápido sin mover el mouse, ABRIMOS EL MODAL
				mostrar_info(_item_potencial)
			elif not _esta_arrastrando and _slot_potencial != null:
				mostrar_info(_slot_potencial.item)
			
			# Limpiamos las variables tras soltar el clic
			_item_potencial = null
			_slot_potencial = null
			_esta_arrastrando = false

	# --- 2. MOVER EL MOUSE (DETECTAR ARRASTRE MANTENIDO) ---
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if not _esta_arrastrando and _item_potencial != null:
			if event.position.distance_to(_click_inicial_pos) > UMBRAL_ARRASTRE:
				if _item_potencial.data and not _item_potencial.data.esta_bloqueado:
					_esta_arrastrando = true
					ocultar_tooltip()
					ocultar_info()
					# Arrancamos el ítem para empezar el Drag & Drop
					grilla_inventario.agarrar_item(_item_potencial)
				else:
					print("Este ítem está bloqueado y no se puede arrastrar.")
					_item_potencial = null
		elif not _esta_arrastrando and _slot_potencial != null:
			if event.position.distance_to(_click_inicial_pos) > UMBRAL_ARRASTRE:
				_esta_arrastrando = true
				ocultar_tooltip()
				ocultar_info()
				gestor_equipamiento.agarrar_de_slot(_slot_potencial)


# --- FUNCIONES AUXILIARES ---

func _mouse_esta_sobre(nodo_control: Control) -> bool:
	if nodo_control == null:
		return false
	return nodo_control.get_global_rect().has_point(get_global_mouse_position())

func _mouse_sobre_tooltip() -> bool:
	return panel_tooltip.visible and _mouse_esta_sobre(panel_tooltip)

func _mouse_sobre_info() -> bool:
	return _panel_info.visible and _mouse_esta_sobre(_panel_info)

func _slot_bajo_el_mouse() -> SlotEquipamiento:
	if gestor_equipamiento == null:
		return null
	return gestor_equipamiento.obtener_slot_bajo_el_mouse()

func _soltar_item_agarrado(item: Node) -> void:
	var slot = _slot_bajo_el_mouse()
	if slot != null:
		gestor_equipamiento.soltar_en_slot(slot, item)
	else:
		grilla_inventario._soltar_item(item)

func _opcion_habilitada(opcion: String, origen: Node) -> bool:
	if gestor_equipamiento == null:
		return not (opcion in ["Equipar", "Poner en atajo", "Desequipar", "Quitar atajo"])
	match opcion:
		"Equipar":
			return gestor_equipamiento.puede_equipar(origen)
		"Poner en atajo":
			return gestor_equipamiento.puede_poner_en_atajo(origen)
		"Desequipar":
			return gestor_equipamiento.puede_desequipar(origen)
	return true

func mostrar_tooltip(item: Node) -> void:
	if not item or not item.data:
		return
		
	for child in contenedor_tooltip.get_children():
		contenedor_tooltip.remove_child(child)
		child.queue_free()

	# Cabecera
	var header_hbox = HBoxContainer.new()
	var icon_rect = TextureRect.new()
	icon_rect.texture = item.data.texture  
	icon_rect.custom_maximum_size = Vector2(32,32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var name_label = Label.new()
	name_label.text = item.data.nombre 
	
	header_hbox.add_child(icon_rect)
	header_hbox.add_child(name_label)
	contenedor_tooltip.add_child(header_hbox)
	
	# Opciones dinámicas
	if "opciones_descripcion" in item.data:
		for option_text in item.obtener_opciones():
			var opt_button = Button.new()
			opt_button.text = str(option_text)
			opt_button.disabled = not _opcion_habilitada(str(option_text), item)
			opt_button.pressed.connect(_on_opcion_elegida.bind(option_text, item))
			contenedor_tooltip.add_child(opt_button)
	
	panel_tooltip.show()
	panel_tooltip.reset_size()
	var limite = (get_viewport_rect().size - panel_tooltip.size).max(Vector2.ZERO)
	panel_tooltip.global_position = get_global_mouse_position().clamp(Vector2.ZERO, limite)

func ocultar_tooltip() -> void:
	panel_tooltip.hide()

func _on_opcion_elegida(opcion: String, item: Node) -> void:
	ocultar_tooltip()
	if not is_instance_valid(item):
		return
	match opcion:
		"Agarrar uno":
			grilla_inventario.agarrar_uno(item)
		"Dividir a la mitad":
			grilla_inventario.dividir_a_la_mitad(item)
		"Mover":
			if not item.data.esta_bloqueado:
				grilla_inventario.agarrar_item(item)
		"Consumir":
			grilla_inventario.consumir_item(item)
		"Equipar":
			gestor_equipamiento.equipar(item)
		"Poner en atajo":
			gestor_equipamiento.poner_en_atajo(item)
		"Desequipar", "Quitar atajo":
			gestor_equipamiento.desequipar(item)
		_:
			print("Opción sin implementar: ", opcion)


# --- PANEL DE INFORMACIÓN (CLIC IZQUIERDO) ---

func _crear_panel_info() -> void:
	_panel_info = PanelContainer.new()
	_panel_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_info.custom_minimum_size.x = 260
	_panel_info.z_index = 100

	var margen := MarginContainer.new()
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 8)
	_panel_info.add_child(margen)

	var caja := VBoxContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(caja)

	var cabecera := HBoxContainer.new()
	cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(cabecera)

	_etiqueta_nombre = Label.new()
	_etiqueta_nombre.add_theme_font_size_override("font_size", 16)
	_etiqueta_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(_etiqueta_nombre)

	var boton_cerrar := Button.new()
	boton_cerrar.text = "X"
	boton_cerrar.flat = true
	boton_cerrar.focus_mode = Control.FOCUS_NONE
	boton_cerrar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	boton_cerrar.pressed.connect(ocultar_info)
	cabecera.add_child(boton_cerrar)

	_etiqueta_descripcion = Label.new()
	_etiqueta_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_etiqueta_descripcion.custom_minimum_size.x = 244
	caja.add_child(_etiqueta_descripcion)

	_etiqueta_detalle = Label.new()
	caja.add_child(_etiqueta_detalle)

	_panel_info.hide()
	$CanvasLayer.add_child(_panel_info)
	_subir_opacidad_panel_info()

func mostrar_info(item: Node) -> void:
	if not item or not item.data:
		return

	var casillas: Vector2i = item.dimensiones
	var total: int = casillas.x * casillas.y
	var detalle := PackedStringArray()
	detalle.append("Tipo: %s" % item.data.nombre_tipo())
	if item.data.stackeable:
		detalle.append("Cantidad: %d / %d" % [item.cantidad, item.data.cantidad_maxima])
	else:
		detalle.append("Tier: %d" % item.tier)
	detalle.append("Ocupa: %d×%d (%d %s)" % [casillas.x, casillas.y, total, "casilla" if total == 1 else "casillas"])
	var efectos := _lineas_efectos(item.data)
	if not efectos.is_empty():
		detalle.append("")
		detalle.append("Al consumir:" if item.data.es_consumible() else "Al equipar:")
		detalle.append_array(efectos)

	_etiqueta_nombre.text = item.data.nombre
	_etiqueta_descripcion.text = item.data.descripcion if item.data.descripcion != "" else "Sin descripción."
	_etiqueta_detalle.text = "\n".join(detalle)

	_panel_info.show()
	_panel_info.reset_size()
	var limite = (get_viewport_rect().size - _panel_info.size).max(Vector2.ZERO)
	_panel_info.global_position = (get_global_mouse_position() + Vector2(16, 16)).clamp(Vector2.ZERO, limite)

func ocultar_info() -> void:
	_panel_info.hide()
	
func _lineas_efectos(data: ItemData) -> PackedStringArray:
	var lineas := PackedStringArray()
	var modificadores := data.obtener_modificadores()
	for stat in modificadores:
		var m: Dictionary = modificadores[stat]
		var nombre: String = EstadisticasPersonaje.NOMBRES[stat]
		var unidad: String = EstadisticasPersonaje.UNIDADES.get(stat, "")
		if m["fijo"] != 0.0:
			lineas.append("%s %s%s" % [nombre, _num_signado(m["fijo"]), unidad])
		if m["pct"] != 0.0:
			lineas.append("%s %s%%" % [nombre, _num_signado(m["pct"])])

	if data.es_consumible():
		var hay_efecto := not modificadores.is_empty() or data.regen_por_segundo != 0 or data.efecto_especial != ""
		if data.cura_instantanea > 0:
			lineas.append("Cura %d HP al instante" % data.cura_instantanea)
		if data.regen_por_segundo != 0:
			lineas.append("Regenera %+d HP por segundo" % data.regen_por_segundo)
		if data.efecto_especial != "":
			lineas.append(data.efecto_especial)
		if hay_efecto and data.duracion_efecto > 0.0:
			lineas.append("Dura %s s" % _num_signado(data.duracion_efecto).trim_prefix("+"))
	return lineas


func _num_signado(valor: float) -> String:
	return ("+" if valor > 0.0 else "") + ("%.1f" % valor).trim_suffix(".0")


func _subir_opacidad_panel_info() -> void:
	var base := _panel_info.get_theme_stylebox("panel")
	var estilo: StyleBoxFlat
	if base is StyleBoxFlat:
		estilo = base.duplicate()
	else:
		estilo = StyleBoxFlat.new()
		estilo.bg_color = Color(0.1, 0.1, 0.1)
	estilo.bg_color.a = OPACIDAD_PANEL_INFO
	_panel_info.add_theme_stylebox_override("panel", estilo)
