extends TextureProgressBar

var estadisticas_ref: EstadisticasPersonaje

func _ready() -> void:
	await get_tree().process_frame 
	
	var gestor = get_tree().get_first_node_in_group("gestor_equipamiento")
	
	if gestor != null:
		estadisticas_ref = gestor.estadisticas
		estadisticas_ref.cambiaron.connect(_actualizar_barra)
		_actualizar_barra()

func _actualizar_barra() -> void:
	if estadisticas_ref == null:
		return

	max_value = estadisticas_ref.hp_maximo()
	value = estadisticas_ref.hp_actual
