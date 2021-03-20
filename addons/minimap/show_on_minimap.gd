tool
extends Node
class_name ShowOnMinimap, "show_on_minimap_icon.svg"

export var color := Color.white
export var icon : Texture = preload("icons/circle.svg")
export var rotating := false
export var use_sprite := false

func _ready():
	add_to_group("ShowInMinimap")
