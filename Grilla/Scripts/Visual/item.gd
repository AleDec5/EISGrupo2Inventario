extends Sprite2D

const TAMAÑO_SLOT: int = 32
const DURACION_ROTACION: float = 0.1

var data: ItemData = null
var esta_agarrado: bool = false
var pasos_rotacion: int = 0

var cantidad: int = 1:
	set(valor):
		cantidad = valor
		actualizar_etiqueta()

var _grados_objetivo: float = 0.0
var _tween: Tween

@onready var etiqueta: Label = $Cantidad

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
	etiqueta.top_level = true
	etiqueta.z_as_relative = false
	etiqueta.z_index = 1
	if data and data.texture:
		texture = data.texture
		scale = Vector2(data.dimensiones) * TAMAÑO_SLOT / texture.get_size()
	actualizar_etiqueta()


func _process(_delta: float) -> void:
	if esta_agarrado:
		global_position = get_global_mouse_position()
		actualizar_etiqueta()


func _unhandled_input(event: InputEvent) -> void:
	if esta_agarrado and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		rotar()


func rotar() -> void:
	pasos_rotacion = (pasos_rotacion + 1) % 4
	_grados_objetivo += 90.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation_degrees", _grados_objetivo, DURACION_ROTACION)
	actualizar_etiqueta()


func set_posicion_inicial(pos: Vector2) -> void:
	global_position = pos + tamaño / 2
	actualizar_etiqueta()


func agarrar() -> void:
	esta_agarrado = true
	z_index = 10
	etiqueta.z_index = 11
	add_to_group("item_agarrado")


func colocar(pos: Vector2i) -> void:
	esta_agarrado = false
	z_index = 0
	etiqueta.z_index = 1
	global_position = Vector2(pos) + tamaño / 2
	remove_from_group("item_agarrado")
	actualizar_etiqueta()


func actualizar_etiqueta() -> void:
	if not is_node_ready() or data == null:
		return
	etiqueta.visible = data.stackeable
	etiqueta.text = str(cantidad)
	etiqueta.global_position = ancla + tamaño - etiqueta.get_combined_minimum_size() - Vector2(4, 2)


func puede_apilar(otro: Node) -> bool:
	return otro != self and data.stackeable and otro.data == data and cantidad < data.cantidad_maxima


func apilar(otro: Node) -> void:
	var pasan = mini(data.cantidad_maxima - cantidad, otro.cantidad)
	cantidad += pasan
	otro.cantidad -= pasan
	if otro.cantidad == 0:
		otro.esta_agarrado = false
		otro.remove_from_group("item_agarrado")
		otro.queue_free()


func dividir_uno() -> Node:
	var nuevo = (load(scene_file_path) as PackedScene).instantiate()
	nuevo.data = data
	nuevo.cantidad = 1
	nuevo.global_position = global_position
	get_parent().add_child(nuevo)
	cantidad -= 1
	return nuevo
