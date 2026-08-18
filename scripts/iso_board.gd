extends Control

signal cell_pressed(x: int, y: int)

const GRID_SIZE := 6
const TILE_W := 128.0
const TILE_H := 64.0

var show_grid := false:
	set(value):
		show_grid = value
		queue_redraw()

var grid_data: Array = []:
	set(value):
		grid_data = value
		if is_node_ready():
			refresh_items()
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(0, 410)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(refresh_items)
	call_deferred("refresh_items")

func tile_center(x: int, y: int) -> Vector2:
	return Vector2(size.x * 0.5 + (x - y) * TILE_W * 0.5, size.y * 0.47 + (x + y) * TILE_H * 0.5)

func refresh_items() -> void:
	# Render from this Control itself. Sprite2D children can be obscured by the
	# full-screen Control layout; custom drawing stays on the board layer.
	queue_redraw()

func _draw() -> void:
	if not show_grid:
		return
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var p := tile_center(x, y)
			var points := PackedVector2Array([p + Vector2(0, -TILE_H * 0.5), p + Vector2(TILE_W * 0.5, 0), p + Vector2(0, TILE_H * 0.5), p + Vector2(-TILE_W * 0.5, 0)])
			draw_colored_polygon(points, Color(0.16, 0.10, 0.04, 0.15))
			for i in points.size():
				draw_line(points[i], points[(i + 1) % points.size()], Color(1.0, 0.86, 0.53, 0.56), 1.5)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
	var closest := Vector2i(-1, -1)
	var closest_distance := INF
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var distance: float = event.position.distance_squared_to(tile_center(x, y))
			if distance < closest_distance:
				closest_distance = distance
				closest = Vector2i(x, y)
	if closest_distance <= TILE_W * TILE_W * 0.25:
		cell_pressed.emit(closest.x, closest.y)
