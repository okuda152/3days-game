extends Control

const IsoBoard = preload("res://scripts/iso_board.gd")

const GRID_SIZE := 4
const TILE_W := 200.0
const TILE_H := 100.0
const GRID_Y_RATIO := 0.41
const PLACED_ITEM_SIZE := 190.0
const INITIAL_MATERIALS := {"枝": 4, "葉": 5, "草": 6, "わら": 4, "木": 3}
const RECIPES := {
	"ベッド": {"cost": {"草": 2, "わら": 2}, "symbol": "ベッド", "color": "b77b5d", "path": "res://assets/bed.png"},
	"餌おき": {"cost": {"枝": 1, "葉": 1}, "symbol": "餌", "color": "d6a94f", "path": "res://assets/feeder.png"},
	"水飲み場": {"cost": {"木": 1, "草": 1}, "symbol": "水", "color": "62a9c6", "path": "res://assets/water.png"},
	"テーブル": {"cost": {"木": 2}, "symbol": "机", "color": "9b6d43", "path": "res://assets/table.png"},
	"見晴らし台": {"cost": {"木": 1, "枝": 2}, "symbol": "台", "color": "79934d", "path": "res://assets/tower.png"},
	"花かざり": {"cost": {"葉": 2, "草": 1}, "symbol": "花", "color": "cf7c91", "path": "res://assets/flower.png"},
}
const ITEM_TEXTURES := {
	"ベッド": "res://assets/bed.png", "餌おき": "res://assets/feeder.png", "水飲み場": "res://assets/water.png",
	"テーブル": "res://assets/table.png", "見晴らし台": "res://assets/tower.png", "花かざり": "res://assets/flower.png",
}
const ANIMAL_TEXTURES := {
	"スズメ": "res://assets/animals/sparrow.png",
	"ハリネズミ": "res://assets/animals/hedgehog.png",
	"カエル": "res://assets/animals/frog.png",
	"モンシロチョウ": "res://assets/animals/butterfly.png",
	"リス": "res://assets/animals/squirrel.png",
	"ビーバー": "res://assets/animals/beaver.png",
	"ティラノサウルス": "res://assets/animals/tyrannosaurus.png",
	"ワイバーン": "res://assets/animals/wyvern.png",
	"スライム": "res://assets/animals/slime.png",
	"マグロ": "res://assets/animals/tuna.png",
}
const ITEM_DESCRIPTIONS := {
	"ベッド": "ふかふかの寝床。丸まって休みたい生きもの向け。",
	"餌おき": "木の実を置く小さな食卓。小鳥が寄りやすい。",
	"水飲み場": "水辺をつくる器。水を好む生きもの向け。",
	"テーブル": "みんなで使える木の机。大きな来客にも。",
	"見晴らし台": "外を見渡せる高台。景色が好きな生きもの向け。",
	"花かざり": "巣を華やかにする飾り。水辺の近くとも相性がいい。",
}
const VISITOR_COLORS := {
	"スズメ": "a77b42", "ハリネズミ": "9f7057", "カエル": "4d8c78", "モンシロチョウ": "b38a94",
	"リス": "a66e43", "ビーバー": "78624e", "ティラノサウルス": "8f5b50", "ワイバーン": "765e9c",
	"スライム": "4d9b80", "マグロ": "4d79a5",
}
const BESTIARY := [
	{"name":"スズメ", "hidden_hint":"木の実をついばめる場所を探しているみたい。", "hint":"餌おきを置くと来やすい。"},
	{"name":"ハリネズミ", "hidden_hint":"丸まって眠れる、ふかふかの場所が好きみたい。", "hint":"ベッドを置くと来やすい。"},
	{"name":"カエル", "hidden_hint":"しっとりした水辺を探しているみたい。", "hint":"水飲み場を置くと来やすい。"},
	{"name":"モンシロチョウ", "hidden_hint":"水のそばで、きれいなものを探しているみたい。", "hint":"水飲み場の隣に花かざりを置くと来やすい。"},
	{"name":"リス", "hidden_hint":"森を見渡せる、高い場所が好きみたい。", "hint":"見晴らし台を巣の端に置くと来やすい。"},
	{"name":"ビーバー", "hidden_hint":"仲間と使える、にぎやかな場所を探しているみたい。", "hint":"テーブルと、3種類以上の内装を置くと来やすい。"},
	{"name":"ティラノサウルス", "hidden_hint":"とても大きな来客。広く整った巣を探しているらしい。", "hint":"5種類以上の内装と、隣に2つ以上の内装があるテーブルが必要。"},
	{"name":"ワイバーン", "hidden_hint":"翼を休められる、十分に高い場所を探しているらしい。", "hint":"見晴らし台を2つ、隣同士に置くと来やすい。"},
	{"name":"スライム", "hidden_hint":"湿った場所と、やわらかい場所がどちらも好きみたい。", "hint":"水飲み場とベッドを隣同士に置くと来やすい。"},
	{"name":"マグロ", "hidden_hint":"なぜか、たっぷりの水を探しているみたい。", "hint":"水飲み場を3つ置くと来やすい。"},
]

var materials: Dictionary
var inventory: Dictionary = {}
var grid: Array = []
var selected_item := ""
var discovered: Dictionary = {}
var last_observed_visitors: Array[Dictionary] = []
var encyclopedia_from_title := false
var root_box: VBoxContainer
var title_label: Label
var is_building := false

func _ready() -> void:
	reset_build(false)
	show_title_screen()

func reset_build(keep_discoveries: bool = true) -> void:
	materials = INITIAL_MATERIALS.duplicate()
	inventory = {}
	for item in RECIPES: inventory[item] = 0
	grid = []
	for y in GRID_SIZE:
		var row: Array = []
		for x in GRID_SIZE: row.append("")
		grid.append(row)
	selected_item = ""
	if not keep_discoveries: discovered = {}

func make_label(value: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func make_button(value: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.disabled = disabled
	button.custom_minimum_size = Vector2(0, 42)
	skin_button(button, Color("67442d"), Color("8b6040"))
	button.pressed.connect(callback)
	return button

func make_craft_card(item: String) -> Button:
	var card := make_button("", craft_from_menu.bind(item), not can_craft(item))
	card.custom_minimum_size = Vector2(548, 132)
	card.clip_contents = true
	skin_button(card, Color(RECIPES[item].color).darkened(0.45), Color(RECIPES[item].color).darkened(0.15))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var preview := TextureRect.new()
	preview.texture = load(ITEM_TEXTURES[item])
	preview.custom_minimum_size = Vector2(112, 112)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item == "ベッド":
		preview.material = bed_background_key_material()
	row.add_child(preview)
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 3)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)
	var name_label := make_label(item, 23)
	name_label.add_theme_color_override("font_color", Color("fff3d6"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)
	var detail_label := make_label(ITEM_DESCRIPTIONS[item], 16)
	detail_label.add_theme_color_override("font_color", Color("f3dfb5"))
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(detail_label)
	var costs: Array[String] = []
	for material in RECIPES[item].cost:
		costs.append("%s%d" % [material, RECIPES[item].cost[material]])
	var cost_label := make_label("必要：%s　 所持：%d" % ["・".join(costs), inventory[item]], 16)
	cost_label.add_theme_color_override("font_color", Color("fff0c8"))
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(cost_label)
	return card

func add_animal_preview(row: HBoxContainer, animal_name: String, preview_size: Vector2 = Vector2(76, 76)) -> void:
	if not ANIMAL_TEXTURES.has(animal_name):
		return
	var preview := TextureRect.new()
	preview.texture = load(ANIMAL_TEXTURES[animal_name])
	preview.custom_minimum_size = preview_size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(preview)

func make_inventory_card(item: String) -> Button:
	var card := make_button("", select_item.bind(item))
	card.custom_minimum_size = Vector2(104, 102)
	var base_color := Color(RECIPES[item].color).darkened(0.30)
	var hover_color := Color(RECIPES[item].color)
	skin_button(card, base_color, hover_color)
	if item == selected_item:
		card.add_theme_stylebox_override("normal", make_style(hover_color, 10, Color("fff0b0")))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var preview := TextureRect.new()
	preview.texture = load(ITEM_TEXTURES[item])
	preview.custom_minimum_size = Vector2(88, 66)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item == "ベッド":
		preview.material = bed_background_key_material()
	box.add_child(preview)
	var name := make_label("%s ×%d" % [item, inventory[item]], 14)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_color_override("font_color", Color("fff3d6"))
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	return card

func make_style(color: Color, radius: int = 10, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	return style

func bed_background_key_material() -> ShaderMaterial:
	var shader := Shader.new()
	# Only the bed PNG has a baked neutral checkerboard. Keep warm cream pixels
	# in the cushion while removing the near-neutral white/grey background.
	shader.code = "shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV); float lo = min(min(c.r, c.g), c.b); float hi = max(max(c.r, c.g), c.b); if (lo > 0.91 && (hi - lo) < 0.04) { discard; } COLOR = c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func skin_button(button: Button, normal: Color, hover: Color) -> void:
	button.add_theme_stylebox_override("normal", make_style(normal, 10, Color(1, 0.9, 0.68, 0.28)))
	button.add_theme_stylebox_override("hover", make_style(hover, 10, Color("ffe6ad")))
	button.add_theme_stylebox_override("pressed", make_style(hover.darkened(0.2), 10, Color("ffe6ad")))
	button.add_theme_stylebox_override("disabled", make_style(Color(0.12, 0.12, 0.10, 0.62), 10))
	button.add_theme_color_override("font_color", Color("fff3d6"))
	button.add_theme_color_override("font_disabled_color", Color("938b7e"))

func clear_screen() -> void:
	for child in get_children(): child.queue_free()
	var background := TextureRect.new()
	background.texture = load("res://assets/nest_iso_clean.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.08, 0.05, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	# The margin is only for layout. It must not block clicks intended for the
	# full-screen board beneath it; actual buttons remain interactive children.
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 14)
	margin.add_child(root_box)
	title_label = make_label("巣箱、できました。", 32)
	title_label.add_theme_color_override("font_color", Color("f5e6bd"))
	root_box.add_child(title_label)

func show_title_screen() -> void:
	is_building = false
	clear_screen()
	title_label.visible = false
	root_box.alignment = BoxContainer.ALIGNMENT_CENTER
	# タイトルは見た目の中心へ、開始ボタンは少しだけ下に離す。
	var title_spacer := Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 40)
	root_box.add_child(title_spacer)
	var title := make_label("巣箱、できました。", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("fff0c8"))
	root_box.add_child(title)
	var start_margin := MarginContainer.new()
	start_margin.add_theme_constant_override("margin_top", 24)
	root_box.add_child(start_margin)
	var start_row := HBoxContainer.new()
	start_row.alignment = BoxContainer.ALIGNMENT_CENTER
	start_margin.add_child(start_row)
	var start_column := VBoxContainer.new()
	start_column.alignment = BoxContainer.ALIGNMENT_CENTER
	start_column.add_theme_constant_override("separation", 14)
	start_row.add_child(start_column)
	var start := make_button("巣づくりをはじめる", reset_and_show)
	start.custom_minimum_size = Vector2(300, 62)
	start.add_theme_font_size_override("font_size", 22)
	start_column.add_child(start)
	var title_bestiary := make_button("いきもの図鑑", open_title_encyclopedia)
	title_bestiary.custom_minimum_size = Vector2(300, 62)
	title_bestiary.add_theme_font_size_override("font_size", 22)
	start_column.add_child(title_bestiary)

func show_build_screen() -> void:
	is_building = true
	# Make the first available interior immediately placeable. The compact HUD
	# can otherwise make the selection button easy to miss.
	if selected_item.is_empty():
		for item in RECIPES:
			if inventory[item] > 0:
				selected_item = item
				break
	clear_screen()
	var selection_text := "内装を選んで、巣の中をクリックして置こう" if selected_item.is_empty() else "選択中：%s　置きたい場所をクリック" % selected_item
	var selection := make_label(selection_text, 18)
	selection.add_theme_color_override("font_color", Color("fff0c8"))
	root_box.add_child(selection)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_box.add_child(header)
	var craft_button := make_button("クラフト", show_craft_screen)
	craft_button.custom_minimum_size = Vector2(132, 52)
	craft_button.add_theme_font_size_override("font_size", 20)
	header.add_child(craft_button)
	var reset_button := make_button("最初から", reset_and_show)
	reset_button.custom_minimum_size = Vector2(132, 52)
	reset_button.add_theme_font_size_override("font_size", 20)
	header.add_child(reset_button)
	var encyclopedia_button := make_button("図鑑", open_build_encyclopedia)
	encyclopedia_button.custom_minimum_size = Vector2(96, 52)
	encyclopedia_button.add_theme_font_size_override("font_size", 20)
	header.add_child(encyclopedia_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var observe_button := make_button("観察する", show_observation)
	observe_button.custom_minimum_size = Vector2(178, 64)
	observe_button.add_theme_font_size_override("font_size", 24)
	skin_button(observe_button, Color("8f6039"), Color("a97646"))
	# 観察はメイン操作なので、ほかの管理ボタンから分けて右上に固定する。
	observe_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	observe_button.offset_left = -222
	observe_button.offset_right = -44
	observe_button.offset_top = 30
	observe_button.offset_bottom = 94
	observe_button.z_index = 20
	add_child(observe_button)
	var board := IsoBoard.new()
	board.grid_data = grid
	board.show_grid = false # The visible guide is drawn on the root overlay.
	board.cell_pressed.connect(click_cell)
	# The background already contains the 6x6 floor. Put interaction and item
	# sprites in the same full-screen coordinate system as that floor, below UI.
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(board)
	move_child(board, 2)
	if not selected_item.is_empty():
		add_placement_grid()
	# The root Control's dimensions settle on the next frame. Defer item
	# placement so their screen coordinates are not calculated as (0, 0).
	call_deferred("add_placed_item_visuals")
	var inventory_bar := HBoxContainer.new()
	inventory_bar.add_theme_constant_override("separation", 8)
	inventory_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	inventory_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	inventory_bar.offset_left = -370
	inventory_bar.offset_right = 370
	inventory_bar.offset_top = -122
	inventory_bar.offset_bottom = -20
	inventory_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_bar.z_index = 20
	add_child(inventory_bar)
	var has_inventory := false
	for item in RECIPES:
		if inventory[item] <= 0: continue
		has_inventory = true
		inventory_bar.add_child(make_inventory_card(item))

func show_craft_screen() -> void:
	is_building = false
	clear_screen()
	title_label.text = "クラフト"
	var material_text := "素材　"
	for material in INITIAL_MATERIALS: material_text += "%s: %d　" % [material, materials[material]]
	root_box.add_child(make_label(material_text, 20))
	root_box.add_child(make_label("作った内装は、巣づくり画面の手持ちから選べます。", 16))
	var recipes_grid := GridContainer.new()
	recipes_grid.columns = 2
	recipes_grid.add_theme_constant_override("h_separation", 16)
	recipes_grid.add_theme_constant_override("v_separation", 12)
	root_box.add_child(recipes_grid)
	for item in RECIPES:
		recipes_grid.add_child(make_craft_card(item))
	root_box.add_child(make_button("巣づくりへ戻る", show_build_screen))

func can_craft(item: String) -> bool:
	for material in RECIPES[item].cost:
		if materials[material] < RECIPES[item].cost[material]: return false
	return true

func craft(item: String) -> void:
	if not can_craft(item): return
	for material in RECIPES[item].cost: materials[material] -= RECIPES[item].cost[material]
	inventory[item] += 1
	selected_item = item
	show_build_screen()

func craft_from_menu(item: String) -> void:
	if not can_craft(item): return
	for material in RECIPES[item].cost: materials[material] -= RECIPES[item].cost[material]
	inventory[item] += 1
	selected_item = item
	show_craft_screen()

func select_item(item: String) -> void:
	if inventory[item] <= 0: return
	selected_item = item
	show_build_screen()

func click_cell(x: int, y: int) -> void:
	if not grid[y][x].is_empty():
		inventory[grid[y][x]] += 1
		grid[y][x] = ""
	elif not selected_item.is_empty() and inventory[selected_item] > 0:
		grid[y][x] = selected_item
		inventory[selected_item] -= 1
		if inventory[selected_item] == 0: selected_item = ""
	show_build_screen()

func add_placed_item_visuals() -> void:
	# Display each asset as a normal UI texture on the root canvas. This avoids
	# the custom board draw path that was making placed assets disappear.
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var item: String = grid[y][x]
			if item.is_empty():
				continue
			var icon := TextureRect.new()
			icon.texture = load(ITEM_TEXTURES[item])
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2.ZERO
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.z_index = 10
			if item == "ベッド":
				icon.material = bed_background_key_material()
			add_child(icon)
			var screen_size := get_viewport_rect().size
			var item_offset := Vector2(-PLACED_ITEM_SIZE * 0.5, -PLACED_ITEM_SIZE * 0.60)
			# 見晴らし台は背が高いので、足元がマスの中心に見えるよう少し上へ寄せる。
			if item == "見晴らし台":
				item_offset.y -= 20.0
			icon.position = Vector2(screen_size.x * 0.5 + (x - y) * TILE_W * 0.5, screen_size.y * GRID_Y_RATIO + (x + y) * TILE_H * 0.5) + item_offset
			icon.size = Vector2(PLACED_ITEM_SIZE, PLACED_ITEM_SIZE)

func add_placement_grid() -> void:
	# Draw above the background rather than inside it, so the placement guide is
	# visible only while an interior item is held.
	var screen_size := get_viewport_rect().size
	var base := Vector2(screen_size.x * 0.5, screen_size.y * GRID_Y_RATIO)
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var p := base + Vector2((x - y) * TILE_W * 0.5, (x + y) * TILE_H * 0.5)
			var line := Line2D.new()
			line.points = PackedVector2Array([p + Vector2(0, -TILE_H * 0.5), p + Vector2(TILE_W * 0.5, 0), p + Vector2(0, TILE_H * 0.5), p + Vector2(-TILE_W * 0.5, 0), p + Vector2(0, -TILE_H * 0.5)])
			line.width = 2.0
			line.default_color = Color(1.0, 0.90, 0.60, 0.82)
			line.z_index = 8
			add_child(line)

func nest_slot_position(x: int, y: int) -> Vector2:
	return Vector2(145 + x * 132 + (y % 2) * 20, 14 + y * 62)

func on_nest_canvas_input(event: InputEvent, _canvas: Control) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed or selected_item.is_empty():
		return
	var closest := Vector2i(-1, -1)
	var closest_distance := INF
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var slot_center := nest_slot_position(x, y) + Vector2(59, 39)
			var distance: float = event.position.distance_squared_to(slot_center)
			if distance < closest_distance:
				closest_distance = distance
				closest = Vector2i(x, y)
	if closest.x >= 0 and grid[closest.y][closest.x].is_empty() and inventory[selected_item] > 0:
		grid[closest.y][closest.x] = selected_item
		inventory[selected_item] -= 1
		if inventory[selected_item] == 0:
			selected_item = ""
		show_build_screen()

func placed_count(item: String) -> int:
	var count := 0
	for row in grid:
		for cell in row:
			if cell == item: count += 1
	return count

func has_item(item: String) -> bool: return placed_count(item) > 0

func distinct_placed_count() -> int:
	var count := 0
	for item in RECIPES:
		if has_item(item): count += 1
	return count

func has_adjacent(a: String, b: String) -> bool:
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			if grid[y][x] != a: continue
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var pos: Vector2i = Vector2i(x, y) + offset
				if pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE and grid[pos.y][pos.x] == b: return true
	return false

func lookout_on_edge() -> bool:
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			if grid[y][x] == "見晴らし台" and (x == 0 or y == 0 or x == GRID_SIZE - 1 or y == GRID_SIZE - 1): return true
	return false

func table_has_two_neighbors() -> bool:
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			if grid[y][x] != "テーブル": continue
			var count := 0
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var pos: Vector2i = Vector2i(x, y) + offset
				if pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE and not grid[pos.y][pos.x].is_empty(): count += 1
			if count >= 2: return true
	return false

func evaluate_visitors() -> Array[Dictionary]:
	var visitors: Array[Dictionary] = []
	if has_item("餌おき"): visitors.append({"name":"スズメ", "count":clampi(placed_count("餌おき") + 1, 1, 5), "comment":"葉っぱの餌おきが落ち着くね！ 高い場所もあったら、もっと仲間を呼べそう！"})
	if has_item("ベッド"): visitors.append({"name":"ハリネズミ", "count":1, "comment":"ふかふかで昼寝にぴったり。"})
	if has_item("水飲み場"): visitors.append({"name":"カエル", "count":clampi(placed_count("水飲み場"), 1, 5), "comment":"水飲み場を発見。近くにきれいなものがあったら、もっとにぎやかかも。"})
	if has_adjacent("花かざり", "水飲み場"): visitors.append({"name":"モンシロチョウ", "count":2, "comment":"花かざりの周りを飛んでいます。"})
	if lookout_on_edge(): visitors.append({"name":"リス", "count":1, "comment":"高いところから森がよく見える！"})
	if has_item("テーブル") and distinct_placed_count() >= 3: visitors.append({"name":"ビーバー", "count":1, "comment":"このテーブル、作りがしっかりしているな。"})
	if distinct_placed_count() >= 5 and table_has_two_neighbors(): visitors.append({"name":"ティラノサウルス", "count":1, "comment":"広くて使いやすいと好評です。"})
	if has_adjacent("見晴らし台", "見晴らし台"): visitors.append({"name":"ワイバーン", "count":1, "comment":"この高さなら翼を休められる。なかなか悪くない巣だ！"})
	if has_adjacent("水飲み場", "ベッド"): visitors.append({"name":"スライム", "count":3, "comment":"ぷるぷる……しっとり、ふかふか。ここ、好き。"})
	if placed_count("水飲み場") >= 3: visitors.append({"name":"マグロ", "count":1, "comment":"この水量！ 海じゃないけど、気に入ったぜ！"})
	return visitors

func make_observation_card(visitor: Dictionary, is_new: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(548, 106)
	var accent := Color(VISITOR_COLORS.get(visitor.name, "765b45"))
	card.add_theme_stylebox_override("panel", make_style(accent.darkened(0.48), 12, accent.lightened(0.15)))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	add_animal_preview(row, visitor.name)
	var visitor_name := make_label("%s\n%d匹" % [visitor.name, visitor.count], 22)
	visitor_name.custom_minimum_size = Vector2(120, 0)
	visitor_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visitor_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	visitor_name.add_theme_color_override("font_color", Color("fff0c8"))
	row.add_child(visitor_name)
	var detail_box := VBoxContainer.new()
	detail_box.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_box)
	if is_new:
		var new_label := make_label("NEW DISCOVERY", 14)
		new_label.add_theme_color_override("font_color", Color("ffe08a"))
		detail_box.add_child(new_label)
	var comment := make_label(visitor.comment, 17)
	comment.add_theme_color_override("font_color", Color("fff3d6"))
	detail_box.add_child(comment)
	return card

func make_bestiary_card(entry: Dictionary) -> PanelContainer:
	var found := discovered.has(entry.name)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(548, 104)
	var accent := Color(VISITOR_COLORS.get(entry.name, "765b45")) if found else Color("51493d")
	card.add_theme_stylebox_override("panel", make_style(accent.darkened(0.48), 12, accent.lightened(0.10)))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	if found:
		add_animal_preview(row, entry.name, Vector2(70, 70))
	var name_label := make_label(entry.name if found else "？？？", 23)
	name_label.custom_minimum_size = Vector2(150 if not found else 110, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("fff0c8") if found else Color("b8ae9d"))
	row.add_child(name_label)
	var detail_box := VBoxContainer.new()
	detail_box.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_box)
	var state_label := make_label("発見済み" if found else "まだ出会っていない", 14)
	state_label.add_theme_color_override("font_color", Color("ffe08a") if found else Color("a79b88"))
	detail_box.add_child(state_label)
	var hint_label := make_label(entry.hint if found else entry.hidden_hint, 16)
	hint_label.add_theme_color_override("font_color", Color("fff3d6") if found else Color("cdc3b2"))
	detail_box.add_child(hint_label)
	return card

func show_encyclopedia(page: int = 0) -> void:
	is_building = false
	clear_screen()
	title_label.text = "いきもの図鑑"
	root_box.add_child(make_label("発見した生きもの　%d / %d" % [discovered.size(), BESTIARY.size()], 19))
	var entries_per_page := 5
	var total_pages := ceili(float(BESTIARY.size()) / float(entries_per_page))
	var safe_page := clampi(page, 0, total_pages - 1)
	var page_label := make_label("%d / %d ページ" % [safe_page + 1, total_pages], 16)
	page_label.add_theme_color_override("font_color", Color("f3dfb5"))
	root_box.add_child(page_label)
	var entry_grid := GridContainer.new()
	entry_grid.columns = 2
	entry_grid.add_theme_constant_override("h_separation", 16)
	entry_grid.add_theme_constant_override("v_separation", 10)
	root_box.add_child(entry_grid)
	var start_index := safe_page * entries_per_page
	var end_index := mini(start_index + entries_per_page, BESTIARY.size())
	for index in range(start_index, end_index):
		entry_grid.add_child(make_bestiary_card(BESTIARY[index]))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root_box.add_child(footer)
	if safe_page > 0:
		footer.add_child(make_button("← 前のページ", show_encyclopedia.bind(safe_page - 1)))
	if safe_page < total_pages - 1:
		footer.add_child(make_button("次のページ →", show_encyclopedia.bind(safe_page + 1)))
	footer.add_child(make_button("タイトルへ戻る" if encyclopedia_from_title else "巣づくりへ戻る", show_title_screen if encyclopedia_from_title else show_build_screen))

func open_title_encyclopedia() -> void:
	encyclopedia_from_title = true
	show_encyclopedia()

func open_build_encyclopedia() -> void:
	encyclopedia_from_title = false
	show_encyclopedia()

func show_observation() -> void:
	is_building = false
	var visitors := evaluate_visitors()
	last_observed_visitors = visitors.duplicate(true)
	var new_visitors: Dictionary = {}
	for visitor in visitors:
		if not discovered.has(visitor.name):
			new_visitors[visitor.name] = true
		discovered[visitor.name] = true
	clear_screen()
	title_label.text = "いきもの観察ログ"
	var summary_text := "今日の巣箱には、%d種類の生きものが訪れました。　発見 %d / %d" % [visitors.size(), discovered.size(), BESTIARY.size()]
	root_box.add_child(make_label(summary_text, 19))
	if visitors.is_empty():
		var empty_card := PanelContainer.new()
		empty_card.custom_minimum_size = Vector2(0, 150)
		empty_card.add_theme_stylebox_override("panel", make_style(Color("332a20"), 12, Color("8f704c")))
		empty_card.add_child(make_label("今日は、まだ誰も来ていないみたい。\n内装を置いたり、置く場所を変えたりして、もう一度観察してみよう。", 21))
		root_box.add_child(empty_card)
	else:
		var log_grid := GridContainer.new()
		log_grid.columns = 2
		log_grid.add_theme_constant_override("h_separation", 16)
		log_grid.add_theme_constant_override("v_separation", 12)
		root_box.add_child(log_grid)
		for visitor in visitors:
			log_grid.add_child(make_observation_card(visitor, new_visitors.has(visitor.name)))
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(footer)
	var view_button := make_button("作った巣を見る", show_nest_view)
	view_button.custom_minimum_size = Vector2(260, 56)
	view_button.add_theme_font_size_override("font_size", 22)
	footer.add_child(view_button)

func show_nest_view() -> void:
	is_building = false
	clear_screen()
	title_label.text = "巣のようす"
	root_box.add_child(make_label("今日、ここを訪れた生きものたち", 18))
	var title_button := make_button("タイトルへ戻る", show_title_screen)
	title_button.custom_minimum_size = Vector2(220, 52)
	title_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	title_button.offset_left = -110
	title_button.offset_right = 110
	title_button.offset_top = -88
	title_button.offset_bottom = -36
	title_button.z_index = 20
	add_child(title_button)
	call_deferred("add_placed_item_visuals")
	call_deferred("add_visiting_animal_visuals")

func add_visiting_animal_visuals() -> void:
	var anchors := [
		Vector2(0.34, 0.58), Vector2(0.54, 0.52), Vector2(0.70, 0.60),
		Vector2(0.44, 0.72), Vector2(0.63, 0.72), Vector2(0.78, 0.50),
	]
	var count := mini(last_observed_visitors.size(), anchors.size())
	for index in range(count):
		var visitor: Dictionary = last_observed_visitors[index]
		var animal_name: String = visitor.name
		if not ANIMAL_TEXTURES.has(animal_name):
			continue
		var animal := TextureRect.new()
		animal.texture = load(ANIMAL_TEXTURES[animal_name])
		animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		animal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		animal.z_index = 12
		var visual_size := Vector2(116, 116)
		if animal_name == "ティラノサウルス" or animal_name == "ワイバーン":
			visual_size = Vector2(142, 142)
		animal.size = visual_size
		var start: Vector2 = get_viewport_rect().size * anchors[index] - visual_size * 0.5
		animal.position = start
		add_child(animal)
		var distance := 24.0 + float(index % 3) * 8.0
		var duration := 1.4 + float(index) * 0.12
		var movement := create_tween().set_loops()
		movement.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		movement.tween_property(animal, "position", start + Vector2(distance, 0), duration)
		movement.tween_property(animal, "position", start - Vector2(distance, 0), duration)

func reset_and_show() -> void:
	reset_build(true)
	show_build_screen()

func _input(event: InputEvent) -> void:
	# Layout containers cover the whole screen. Handle only non-button board
	# clicks here so the visible 6x6 floor always remains placeable.
	if not is_building or not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if get_viewport().gui_get_hovered_control() is Button:
		return
	var closest := Vector2i(-1, -1)
	var closest_distance := INF
	var base := Vector2(size.x * 0.5, size.y * GRID_Y_RATIO)
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var center := base + Vector2((x - y) * TILE_W * 0.5, (x + y) * TILE_H * 0.5)
			var distance: float = event.position.distance_squared_to(center)
			if distance < closest_distance:
				closest_distance = distance
				closest = Vector2i(x, y)
	if closest_distance <= TILE_W * TILE_W * 0.25:
		click_cell(closest.x, closest.y)
		get_viewport().set_input_as_handled()

func show_end_screen() -> void:
	is_building = false
	clear_screen()
	title_label.text = "観察を終える"
	root_box.add_child(make_label("今日の巣箱には、%d種類の生き物が訪れました。\nまた新しいすみかを作ってみよう。" % discovered.size(), 22))
	root_box.add_child(make_button("タイトルへ戻る", reset_to_title))

func reset_to_title() -> void:
	reset_build(false)
	show_title_screen()
