tool
extends Panel
class_name Minimap, "minimap_icon.svg"

"""
A rectangular minimap

Displays the area visible to the camera.
ShowOnMinimap nodes can be added to nodes to make them show on the minimap.
The camera can be moved around by clicking and dragging on the minimap.
"""

export var camera_path : NodePath
# The StyleBox used to draw the camera bounds.
export var camera_style : StyleBox = preload("default_camera_style.tres")
# How large the world area is.
export var world_size := Vector2(5000, 5000)
# The top left corner of the world.
export var world_origin := Vector2(0, 0)
# Scale of the displayed icons.
export var icon_scale := 1.0
# Number of frames between map updates.
export(int, 1, 50) var update_rate := 4

# Transform from minimap to world space.
var minimap_transform : Transform2D
# Transform from world to minimap space.
var inv_minimap_transform : Transform2D

onready var camera : Camera2D = get_node(camera_path)

func _process(_delta):
	if Engine.get_frames_drawn() % update_rate == 0:
		minimap_transform = Transform2D().scaled(Vector2.ONE / world_size * rect_size).translated(-world_origin)
		inv_minimap_transform = Transform2D().translated(world_origin).scaled(Vector2.ONE / rect_size * world_size)
		inv_minimap_transform.origin = world_origin
		update()


func _draw():
	for show_in_minimap in get_tree().get_nodes_in_group("ShowInMinimap"):
		var object : Node2D = show_in_minimap.get_parent()
		if not object.visible:
			continue
		var pos_on_minimap : Vector2 = minimap_transform.xform(object.global_position)
		if not Rect2(Vector2(), rect_size).has_point(pos_on_minimap):
			continue
		var rotation : float = object.global_rotation if\
				show_in_minimap.rotating else 0
		var texture : Texture
		var scale : Vector2
		var centered : bool
		if show_in_minimap.use_sprite:
			# Emulate drawing a Sprite node.
			texture = object.texture
			scale = rect_size / world_size * object.global_scale
			centered = object.centered
		else:
			texture = show_in_minimap.icon
			scale = Vector2.ONE * icon_scale
			centered = true
		draw_set_transform(pos_on_minimap, rotation, scale)
		draw_texture(texture, (-texture.get_size() / 2) if centered else\
				Vector2.ZERO, show_in_minimap.color)
	if not camera:
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	camera_style.draw(get_canvas_item(), Rect2(minimap_transform.xform(
		camera.position - get_viewport().size / 2 * camera.zoom),
		get_viewport().size / world_size * rect_size * camera.zoom))


func _gui_input(event):
	if get_viewport().gui_is_dragging():
		return
	
	# Move the camera when clicking on the minimap.
	if camera and event is InputEventMouse and\
			Input.is_mouse_button_pressed(BUTTON_LEFT):
		var minimap_pos : Vector2 = event.position
		var camera_size : Vector2 = minimap_transform.basis_xform(get_viewport().size / 2 * camera.zoom)
		minimap_pos.x = clamp(minimap_pos.x, camera_size.x, rect_size.x - camera_size.x)
		minimap_pos.y = clamp(minimap_pos.y, camera_size.y, rect_size.y - camera_size.y)
		camera.position = inv_minimap_transform.xform(minimap_pos)
		update()
