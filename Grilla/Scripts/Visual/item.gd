class_name ItemGrilla
extends Sprite2D

const ICONOS_CATEGORIA: Dictionary = {
	ItemData.CategoriaIcono.ARMA_DISTANCIA: preload("res://Assets/Items/Iconos/consumibles/arma_rango.tres"),
	ItemData.CategoriaIcono.ARMA_MELEE: preload("res://Assets/Items/Iconos/consumibles/arma_mele.tres"),
	ItemData.CategoriaIcono.CONSUMIBLE_HABILIDAD: preload("res://Assets/Items/Iconos/consumibles/consumible_habilidad.tres"),
	ItemData.CategoriaIcono.CONSUMIBLE_SANACION: preload("res://Assets/Items/Iconos/consumibles/consumible_sanacion.tres"),
	ItemData.CategoriaIcono.CONSUMIBLE_CREACION: preload("res://Assets/Items/Iconos/consumibles/consumible_creacion.tres"),
	ItemData.CategoriaIcono.ARMADURA: preload("res://Assets/Items/Iconos/consumibles/indumentaria.tres"),
}

const TEXTURAS_NIVEL: Array[Texture2D] = [
	preload("res://Assets/Items/Iconos/niveles/nivel_1.tres"),
	preload("res://Assets/Items/Iconos/niveles/nivel_2.tres"),
	preload("res://Assets/Items/Iconos/niveles/nivel_3.tres"),
	preload("res://Assets/Items/Iconos/niveles/nivel_4.tres"),
]

const TEXTURAS_TIER: Array[Texture2D] = [
	preload("res://Assets/Items/Iconos/tiers/verde.tres"),
	preload("res://Assets/Items/Iconos/tiers/cian.tres"),
	preload("res://Assets/Items/Iconos/tiers/violeta.tres"),
	preload("res://Assets/Items/Iconos/tiers/naranja.tres"),
]

const MARGEN_ESQUINA_CATEGORIA := Vector2(3, 1) 
const MARGEN_ESQUINA_TIER := Vector2(7, 7)      
const MARGEN_ESQUINA_INF_DER := Vector2(7, 7)

const MARGEN_INTERNO: float = 4.0
const ESCALA_MINIMA: float = 2.0

const TAMANIO_ICONO_CATEGORIA: int = 26
const TAMANIO_ICONO_TIER: int = 6
const TAMANIO_ICONO_NIVEL: int = 9

const TAMAÑO_SLOT: int = 64
const DURACION_ROTACION: float = 0.1
const TAMAÑO_FUENTE: int = 10
const GROSOR_CONTORNO: int = 3

var data: ItemData = null
var esta_agarrado: bool = false
var pasos_rotacion: int = 0

var cantidad: int = 1:
	set(valor):
		cantidad = valor
		actualizar_indicadores()

var nivel: int = 1:
	set(valor):
		nivel = clampi(valor, 1, ItemData.NIVEL_MAXIMO)
		actualizar_indicadores()

var tier: int = 1:
	set(valor):
		tier = clampi(valor, 1, ItemData.TIER_MAXIMO)
		actualizar_indicadores()

var _grados_objetivo: float = 0.0
var _tween: Tween

@onready var etiqueta: Label = $Cantidad
@onready var icono_categoria: TextureRect = $IconoCategoria
@onready var icono_nivel: TextureRect = $IconoNivel

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
	for nodo in [etiqueta, icono_categoria, icono_nivel]:
		nodo.top_level = true
		nodo.z_as_relative = false
		nodo.z_index = 1
		nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	etiqueta.add_theme_font_size_override("font_size", TAMAÑO_FUENTE)
	etiqueta.add_theme_constant_override("outline_size", GROSOR_CONTORNO)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)

	icono_nivel.custom_minimum_size = Vector2(TAMANIO_ICONO_NIVEL, TAMANIO_ICONO_NIVEL)
	icono_nivel.size = Vector2(TAMANIO_ICONO_NIVEL, TAMANIO_ICONO_NIVEL)

	if data and data.texture:
		_ajustar_textura_y_escala()

	actualizar_indicadores()


func _ajustar_textura_y_escala() -> void:
	var img := data.texture.get_image()
	var rect_usado := img.get_used_rect()

	if rect_usado.has_area():
		texture = ImageTexture.create_from_image(img.get_region(rect_usado))
	else:
		texture = data.texture

	var tamano_celdas := Vector2(data.dimensiones) * TAMAÑO_SLOT
	var area_disponible := tamano_celdas - Vector2.ONE * (MARGEN_INTERNO * 2.0)
	var factores := area_disponible / texture.get_size()
	var escala_uniforme := minf(factores.x, factores.y)

	if escala_uniforme >= 1.0:
		escala_uniforme = maxf(ESCALA_MINIMA, floorf(escala_uniforme))
		if (texture.get_size() * escala_uniforme).x > tamano_celdas.x or (texture.get_size() * escala_uniforme).y > tamano_celdas.y:
			escala_uniforme = 1.0

	scale = Vector2.ONE * escala_uniforme


func _process(_delta: float) -> void:
	if esta_agarrado:
		global_position = get_global_mouse_position()
	actualizar_indicadores()


func _unhandled_input(event: InputEvent) -> void:
	if esta_agarrado and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rotar()


func rotar(instantaneo: bool = false) -> void:
	pasos_rotacion = (pasos_rotacion + 1) % 4
	_grados_objetivo += 90.0
	if _tween:
		_tween.kill()
	if instantaneo:
		rotation_degrees = _grados_objetivo
	else:
		_tween = create_tween()
		_tween.tween_property(self, "rotation_degrees", _grados_objetivo, DURACION_ROTACION)


func reiniciar_rotacion() -> void:
	if _tween:
		_tween.kill()
	pasos_rotacion = 0
	_grados_objetivo = 0.0
	rotation_degrees = 0.0


func set_posicion_inicial(pos: Vector2) -> void:
	global_position = pos + tamaño / 2


func agarrar() -> void:
	esta_agarrado = true
	top_level = true
	global_position = get_global_mouse_position()
	z_index = 10
	etiqueta.z_index = 11
	icono_categoria.z_index = 11
	icono_nivel.z_index = 11
	add_to_group("item_agarrado")


func colocar(pos: Vector2i) -> void:
	esta_agarrado = false
	top_level = false
	z_index = 0
	etiqueta.z_index = 1
	icono_categoria.z_index = 1
	icono_nivel.z_index = 1
	global_position = Vector2(pos) + tamaño / 2
	remove_from_group("item_agarrado")


func guardar_en_slot() -> void:
	esta_agarrado = false
	remove_from_group("item_agarrado")
	top_level = false
	reiniciar_rotacion()
	z_index = 0
	etiqueta.z_index = 1
	icono_categoria.z_index = 1
	icono_nivel.z_index = 1
	etiqueta.hide()
	icono_categoria.hide()
	icono_nivel.hide()
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED


func sacar_de_slot() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	show()
	actualizar_indicadores()


func actualizar_indicadores() -> void:
	if not is_node_ready() or data == null:
		return

	var es_municion := data.tipo == ItemData.Tipo.MUNICION
	var es_arma := data.tipo == ItemData.Tipo.ARMA

	var tex_sup_izq: Texture2D = null
	var tamano_sup_izq: int = TAMANIO_ICONO_CATEGORIA

	if es_municion:
		tex_sup_izq = TEXTURAS_TIER[tier - 1]
		tamano_sup_izq = TAMANIO_ICONO_TIER
	else:
		tex_sup_izq = ICONOS_CATEGORIA.get(data.categoria_icono, null)
	
	var margen_sup_izq := MARGEN_ESQUINA_TIER if es_municion else MARGEN_ESQUINA_CATEGORIA

	icono_categoria.texture = tex_sup_izq
	icono_categoria.visible = tex_sup_izq != null
	icono_categoria.custom_minimum_size = Vector2(tamano_sup_izq, tamano_sup_izq)
	icono_categoria.size = Vector2(tamano_sup_izq, tamano_sup_izq)
	icono_categoria.global_position = ancla + margen_sup_izq

	icono_nivel.texture = TEXTURAS_NIVEL[nivel - 1]
	icono_nivel.visible = es_arma
	icono_nivel.global_position = _pos_abajo_derecha(icono_nivel.size)

	etiqueta.text = str(cantidad)
	etiqueta.visible = data.stackeable and not es_arma
	etiqueta.global_position = _pos_abajo_derecha(etiqueta.get_combined_minimum_size())

func es_mismo_item(otro: Node) -> bool:
	return data.es_mismo(otro.data)


func puede_apilar(otro: Node) -> bool:
	return otro != self and data.stackeable and es_mismo_item(otro) and otro.tier == tier and cantidad < data.cantidad_maxima


func apilar(otro: Node) -> void:
	var pasan = mini(data.cantidad_maxima - cantidad, otro.cantidad)
	cantidad += pasan
	otro.cantidad -= pasan
	if otro.cantidad == 0:
		otro.esta_agarrado = false
		otro.remove_from_group("item_agarrado")
		otro.queue_free()


func puede_fusionar(otro: Node) -> bool:
	return otro != self and data.tipo == ItemData.Tipo.ARMA and es_mismo_item(otro) and otro.nivel == nivel and nivel < ItemData.NIVEL_MAXIMO


func fusionar(otro: Node) -> void:
	nivel += 1
	otro.esta_agarrado = false
	otro.remove_from_group("item_agarrado")
	otro.queue_free()


func dividir(cantidad_a_separar: int) -> Node:
	var nuevo = (load(scene_file_path) as PackedScene).instantiate()
	nuevo.data = data
	nuevo.tier = tier
	nuevo.nivel = nivel
	nuevo.cantidad = cantidad_a_separar
	nuevo.global_position = global_position
	get_parent().add_child(nuevo)
	cantidad -= cantidad_a_separar
	return nuevo


func obtener_opciones() -> Array[String]:
	var opciones: Array[String] = []
	opciones.append_array(data.opciones_descripcion)
	if data.es_consumible() and not data.esta_bloqueado:
		opciones.append("Consumir")
	if data.se_puede_equipar() and not data.esta_bloqueado:
		if not opciones.has("Equipar"):
			opciones.append("Equipar")
	if data.stackeable and cantidad > 1 and not data.esta_bloqueado:
		opciones.append("Agarrar uno")
		opciones.append("Dividir a la mitad")
	return opciones


func _pos_arriba_izquierda(margen: Vector2 = MARGEN_ESQUINA_CATEGORIA) -> Vector2:
	return ancla + margen


func _pos_abajo_derecha(tamaño_nodo: Vector2) -> Vector2:
	return ancla + tamaño - tamaño_nodo - MARGEN_ESQUINA_INF_DER
