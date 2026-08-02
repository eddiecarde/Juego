extends Node
## Goods (singleton autoload)
## Registro central de tipos de mercancía. Es la ÚNICA fuente de verdad de
## qué objetos existen en el juego: su etiqueta, su color de respaldo y la
## ruta a su ícono SVG.
##
## Para añadir una mercancía nueva:
##   1. Coloca su SVG en res://assets/goods/<id>.svg
##   2. Agrega una entrada a DEFS con ese mismo id.
## No hace falta tocar ninguna otra parte del código.

## Definición de cada tipo. La clave es el id usado en los JSON de nivel.
const DEFS := {
	"apple":  {"label": "Manzana", "color": Color("e74c3c"), "icon": "res://assets/goods/apple.svg"},
	"banana": {"label": "Plátano", "color": Color("f1c40f"), "icon": "res://assets/goods/banana.svg"},
	"grapes": {"label": "Uvas",    "color": Color("9b59b6"), "icon": "res://assets/goods/grapes.svg"},
	"milk":   {"label": "Leche",   "color": Color("bdc3c7"), "icon": "res://assets/goods/milk.svg"},
	"bread":  {"label": "Pan",     "color": Color("d98a3d"), "icon": "res://assets/goods/bread.svg"},
	"cheese": {"label": "Queso",   "color": Color("f2c14e"), "icon": "res://assets/goods/cheese.svg"},
	"box":    {"label": "Caja",    "color": Color("c0873f"), "icon": "res://assets/goods/box.svg"},
	"bottle": {"label": "Botella", "color": Color("2ecc71"), "icon": "res://assets/goods/bottle.svg"},
}

## Caché de texturas ya cargadas (evita recargar el mismo SVG).
var _tex_cache: Dictionary = {}

## Lista de ids disponibles (usada como fallback si un nivel no declara tipos).
func default_ids() -> PackedStringArray:
	return PackedStringArray(DEFS.keys())

## ¿Existe este tipo?
func has_good(id: String) -> bool:
	return DEFS.has(id)

## Etiqueta legible del tipo.
func label(id: String) -> String:
	return String(DEFS.get(id, {}).get("label", id))

## Color de respaldo (se usa si el SVG no está disponible).
func color(id: String) -> Color:
	return DEFS.get(id, {}).get("color", Color.WHITE)

## Devuelve la textura del tipo, o null si el SVG aún no existe.
## Es tolerante a assets faltantes: la UI dibuja un respaldo de color.
func texture(id: String) -> Texture2D:
	if _tex_cache.has(id):
		return _tex_cache[id]
	var path := String(DEFS.get(id, {}).get("icon", ""))
	var tex: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tex_cache[id] = tex
	return tex
