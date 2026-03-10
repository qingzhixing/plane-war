extends CanvasLayer

@export var player_path: NodePath

const HP_ICON_PATH := "res://art/ui/icon_hp.png"

@export var max_icons: int = 3

var _player: Node = null
var _icon_texture: Texture2D
var _icons: Array[TextureRect] = []

func _ready() -> void:
	_icon_texture = load(HP_ICON_PATH)

	if player_path != NodePath(""):
		_player = get_node(player_path)
		if _player != null and _player.has_method("get_max_hp"):
			max_icons = _player.get_max_hp()

	var root := Control.new()
	add_child(root)
	root.anchor_left = 0.0
	root.anchor_top = 0.0
	root.anchor_right = 1.0
	root.anchor_bottom = 0.0

	var hbox := HBoxContainer.new()
	root.add_child(hbox)
	hbox.anchor_left = 1.0
	hbox.anchor_right = 1.0
	hbox.anchor_top = 0.0
	hbox.anchor_bottom = 0.0
	hbox.add_theme_constant_override("separation", 4)

	for i in range(max_icons):
		var rect := TextureRect.new()
		rect.texture = _icon_texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = _icon_texture.get_size()
		hbox.add_child(rect)
		_icons.append(rect)

	var texture_size := _icon_texture.get_size()
	var spacing := hbox.get_theme_constant("separation")
	var total_width := texture_size.x * max_icons + spacing * (max_icons - 1)
	var viewport_size := get_viewport().get_visible_rect().size
	hbox.position = Vector2(-total_width - 16.0, 16.0)

func _process(_delta: float) -> void:
	if _player == null:
		return

	var current_hp := max_icons
	if _player.has_method("get_hp"):
		current_hp = _player.get_hp()

	for i in range(_icons.size()):
		_icons[i].visible = i < current_hp
