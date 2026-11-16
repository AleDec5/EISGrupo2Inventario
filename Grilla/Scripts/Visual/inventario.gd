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
