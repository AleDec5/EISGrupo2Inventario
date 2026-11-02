extends Control

@export var contenedor_tooltip: VBoxContainer
@export var panel_tooltip: PanelContainer
@export var escena_inventario: Control
var grilla_inventario = null

# --- Variables para el Umbral de Arrastre ---
var _click_inicial_pos: Vector2 = Vector2.ZERO
var _item_potencial: Node = null
var _esta_arrastrando: bool = false
const UMBRAL_ARRASTRE: float = 5.0 # Píxeles que debe moverse para considerar "arrastre"

func _ready() -> void:
	panel_tooltip.top_level = true
	panel_tooltip.z_index = 100
	panel_tooltip.hide()
	
	# Buscamos la grilla interna de forma segura
	grilla_inventario = escena_inventario.find_child("Grilla", true, false)
	if grilla_inventario == null:
		print("ERROR CRÍTICO: No se encontró 'Grilla' dentro de la escena")


func _input(event: InputEvent) -> void:
	var item_agarrado = get_tree().get_first_node_in_group("item_agarrado")

	# --- 0. CLIC DERECHO: ABRIR EL MENÚ DEL ITEM ---
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if item_agarrado == null and not _mouse_sobre_tooltip():
			var item = null
			if _mouse_esta_sobre(grilla_inventario):
				item = grilla_inventario.obtener_item_bajo_el_mouse()
			if item != null:
				mostrar_tooltip(item)
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
				grilla_inventario._soltar_item(item_agarrado)
				return

			if not _mouse_sobre_tooltip():
				ocultar_tooltip()
			
			if item_agarrado == null and _mouse_esta_sobre(grilla_inventario) and not _mouse_sobre_tooltip():
				# Registramos dónde hizo clic y qué ítem tocó, pero NO lo arrastramos aún
				_click_inicial_pos = event.position
				_item_potencial = grilla_inventario.obtener_item_bajo_el_mouse()
				_esta_arrastrando = false
				
		else:
			# --- AL SOLTAR ---
			if _esta_arrastrando and item_agarrado != null:
				# Intenta soltarlo al liberar el clic mantenido
				grilla_inventario._soltar_item(item_agarrado)
			
			# Limpiamos las variables tras soltar el clic
			_item_potencial = null
			_esta_arrastrando = false

	# --- 2. MOVER EL MOUSE (DETECTAR ARRASTRE MANTENIDO) ---
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if not _esta_arrastrando and _item_potencial != null:
			if event.position.distance_to(_click_inicial_pos) > UMBRAL_ARRASTRE:
				if _item_potencial.data and not _item_potencial.data.esta_bloqueado:
					_esta_arrastrando = true
					ocultar_tooltip()
					# Arrancamos el ítem para empezar el Drag & Drop
					grilla_inventario.agarrar_item(_item_potencial)
				else:
					print("Este ítem está bloqueado y no se puede arrastrar.")
					_item_potencial = null


# --- FUNCIONES AUXILIARES ---

func _mouse_esta_sobre(nodo_control: Control) -> bool:
	if nodo_control == null:
		return false
	return nodo_control.get_global_rect().has_point(get_global_mouse_position())

func _mouse_sobre_tooltip() -> bool:
	return panel_tooltip.visible and _mouse_esta_sobre(panel_tooltip)

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
	for opcion in item.obtener_opciones():
		var boton = Button.new()
		boton.text = opcion
		boton.pressed.connect(_on_opcion_elegida.bind(opcion, item))
		contenedor_tooltip.add_child(boton)
	
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
		_:
			print("Opción sin implementar: ", opcion)
