class_name EstadisticasPersonaje
extends RefCounted

signal cambiaron

enum Stat { HP, VELOCIDAD, FUERZA, RESISTENCIA, DEFENSA, RANGO_DETECCION }

const NOMBRES: Dictionary = {
	Stat.HP: "HP",
	Stat.VELOCIDAD: "Velocidad de movimiento",
	Stat.FUERZA: "Fuerza",
	Stat.RESISTENCIA: "Resistencia",
	Stat.DEFENSA: "Defensa",
	Stat.RANGO_DETECCION: "Rango de detección",
}

const UNIDADES: Dictionary = {
	Stat.RANGO_DETECCION: " m",
}

const VALORES_BASE: Dictionary = {
	Stat.HP: 100.0,
	Stat.VELOCIDAD: 4.0,
	Stat.FUERZA: 10.0,
	Stat.RESISTENCIA: 100.0,
	Stat.DEFENSA: 0.0,
	Stat.RANGO_DETECCION: 8.0,
}


class Efecto extends RefCounted:
	var id: String = ""
	var nombre: String = ""
	var modificadores: Dictionary = {}
	var regen_por_segundo: int = 0
	var especial: String = ""
	var duracion: float = 0.0
	var tiempo_restante: float = 0.0


var hp_actual: int = 0

var _bonus_equipo: Dictionary = {}
var _efectos: Array = []
var _resto_regen: float = 0.0


func _init() -> void:
	hp_actual = hp_maximo()


func hp_maximo() -> int:
	return int(obtener(Stat.HP))


func obtener(stat: int) -> float:
	var fijo: float = VALORES_BASE[stat]
	var porcentaje: float = 0.0
	for fuente in _fuentes():
		var modificador: Dictionary = fuente.get(stat, {})
		fijo += modificador.get("fijo", 0.0)
		porcentaje += modificador.get("pct", 0.0)
	var total: float = fijo * (1.0 + porcentaje / 100.0)
	if stat == Stat.HP:
		return maxf(1.0, roundf(total))
	return maxf(0.0, snappedf(total, 0.1))


func efectos_activos() -> Array:
	return _efectos


func establecer_bonus_equipo(bonus: Dictionary) -> void:
	if bonus == _bonus_equipo:
		return
	_bonus_equipo = bonus.duplicate(true)
	hp_actual = mini(hp_actual, hp_maximo())
	cambiaron.emit()


func curar(cantidad: int) -> void:
	var antes := hp_actual
	hp_actual = clampi(hp_actual + cantidad, 0, hp_maximo())
	if hp_actual != antes:
		cambiaron.emit()


func aplicar_consumible(data: ItemData) -> void:
	if data.cura_instantanea > 0:
		curar(data.cura_instantanea)

	var modificadores := data.obtener_modificadores()
	var hay_efecto := not modificadores.is_empty() or data.regen_por_segundo != 0 or data.efecto_especial != ""
	if data.duracion_efecto <= 0.0 or not hay_efecto:
		return

	var id := data.nombre if data.nombre != "" else str(data.get_instance_id())
	var efecto = _buscar_efecto(id)
	if efecto == null:
		efecto = Efecto.new()
		efecto.id = id
		_efectos.append(efecto)
	efecto.nombre = data.nombre
	efecto.modificadores = modificadores
	efecto.regen_por_segundo = data.regen_por_segundo
	efecto.especial = data.efecto_especial
	efecto.duracion = data.duracion_efecto
	efecto.tiempo_restante = data.duracion_efecto
	cambiaron.emit()


func avanzar_tiempo(delta: float) -> void:
	if _efectos.is_empty():
		return

	var regen: float = 0.0
	for efecto in _efectos:
		regen += efecto.regen_por_segundo * minf(delta, efecto.tiempo_restante)
		efecto.tiempo_restante -= delta

	_resto_regen += regen
	var entero := int(_resto_regen)
	if entero != 0:
		_resto_regen -= entero
		curar(entero)

	var cantidad_antes := _efectos.size()
	_efectos = _efectos.filter(func(e): return e.tiempo_restante > 0.0)
	if _efectos.size() != cantidad_antes:
		hp_actual = mini(hp_actual, hp_maximo())
		cambiaron.emit()


func a_texto() -> String:
	var lineas := PackedStringArray()
	for stat in Stat.values():
		if stat == Stat.HP:
			lineas.append("HP: %d / %d" % [hp_actual, hp_maximo()])
		else:
			lineas.append("%s: %s%s" % [NOMBRES[stat], _num(obtener(stat)), UNIDADES.get(stat, "")])
	if not _efectos.is_empty():
		lineas.append("")
		lineas.append("Efectos activos:")
		for efecto in _efectos:
			lineas.append("- " + _describir(efecto))
	return "\n".join(lineas)


func _fuentes() -> Array:
	var fuentes: Array = [_bonus_equipo]
	for efecto in _efectos:
		fuentes.append(efecto.modificadores)
	return fuentes


func _buscar_efecto(id: String):
	for efecto in _efectos:
		if efecto.id == id:
			return efecto
	return null


func _describir(efecto) -> String:
	var partes := PackedStringArray()
	for stat in efecto.modificadores:
		var modificador: Dictionary = efecto.modificadores[stat]
		if modificador.get("fijo", 0.0) != 0.0:
			partes.append("%s %s" % [NOMBRES[stat], _signado(modificador["fijo"])])
		if modificador.get("pct", 0.0) != 0.0:
			partes.append("%s %s%%" % [NOMBRES[stat], _signado(modificador["pct"])])
	if efecto.regen_por_segundo != 0:
		partes.append("Regen %+d/s" % efecto.regen_por_segundo)
	if efecto.especial != "":
		partes.append(efecto.especial)
	return "%s: %s (%d s)" % [efecto.nombre, ", ".join(partes), ceili(efecto.tiempo_restante)]


func _num(valor: float) -> String:
	return ("%.1f" % valor).trim_suffix(".0")


func _signado(valor: float) -> String:
	return ("+" if valor > 0.0 else "") + _num(valor)
