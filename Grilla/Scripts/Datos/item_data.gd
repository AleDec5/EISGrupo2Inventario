class_name ItemData extends Resource

@export var nombre: String
@export var texture: Texture2D
@export var dimensiones: Vector2i
@export var opciones_descripcion: Array[String] = [] # Agregado para el Tooltip
@export var esta_bloqueado: bool = false # Agregado para validar interacciones

#aca cuando tengamos definido que van a tener los items
#digo, por ejemplo el RE que las armas tienen equipar, combinar etc
#definir que cosas va a tener cada items, y agregarlo en las 
#"opciones_descripcion" y que traiga -> los consumibles "usar" "mover" "combinar"
# voy a modificar solo el naranja para probar
