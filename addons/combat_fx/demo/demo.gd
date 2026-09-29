extends Node2D
## Pick a colour and a hit, click to land it: on the dummy it flinches, and thrusts and blocks
## turn to come from the fighter's side. Left alone, the fighter lays into the dummy by itself.

const DUMMY := Vector2(760, 440)
const FIGHTER := Vector2(360, 470)
const SHAPES := ["slash", "cross", "claw", "thrust", "hit", "spark", "crit", "shockwave", "block", "splat"]
const IDLE := 3.0

var palette := ""
var shape := ""
var idle := IDLE
var palettes: Array[String] = []
var shapes: Array[String] = []
var flinch := 0.0


func _ready() -> void:
	var have := CombatFX.effects()
	for fx_name in have:
		var p := fx_name.get_slice("_", 0)
		if p not in palettes:
			palettes.append(p)
	for s: String in SHAPES:
		if palettes.any(func(p: String) -> bool: return (p + "_" + s) in have):
			shapes.append(s)
	palette = palettes[0]
	shape = shapes[0]
	var bar := VBoxContainer.new()
	bar.position = Vector2(16, 12)
	add_child(bar)
	bar.add_child(_choices(palettes, func(v: String) -> void: palette = v))
	bar.add_child(_choices(shapes, func(v: String) -> void: shape = v))
	var first: Dictionary = CombatFX.info(have[0])
	var sets := ["256", "128", "pixel"].filter(func(s: String) -> bool:  # the web build leaves 256 out
		return ResourceLoader.exists(CombatFX.sheets_dir.path_join(s).path_join(first.file)))
	CombatFX.default_set = sets[0]
	bar.add_child(_choices(sets, func(v: String) -> void: CombatFX.default_set = v))
	var hint := Label.new()
	hint.text = "Click to hit."
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	bar.add_child(hint)


func _choices(values: Array, pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var group := ButtonGroup.new()
	for v: String in values:
		var b := Button.new()
		b.text = v
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = v == values[0]
		b.pressed.connect(pick.bind(v))
		row.add_child(b)
	return row


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		idle = IDLE
		land(palette, shape, click.position)


func _process(delta: float) -> void:
	flinch = maxf(flinch - delta * 4.0, 0.0)
	queue_redraw()
	idle -= delta
	if idle > 0.0:
		return
	idle = 0.55
	land(palettes.pick_random(), shapes.pick_random(), DUMMY + Vector2(randf_range(-30, 30), randf_range(-90, 10)))


func land(p: String, what: String, at: Vector2) -> void:
	var fx_name := p + "_" + what
	if fx_name not in CombatFX.effects():
		return
	CombatFX.spawn(self, fx_name, at, (at - FIGHTER).angle() if what in ["thrust", "block"] else 0.0)
	if at.distance_to(DUMMY + Vector2(0, -50)) < 120:
		flinch = 1.0


func _draw() -> void:
	draw_rect(Rect2(0, 560, 1280, 160), Color(0.1, 0.09, 0.15))
	# the fighter and a training dummy, in flat shapes
	draw_colored_polygon(PackedVector2Array([FIGHTER + Vector2(-20, 90), FIGHTER + Vector2(0, -20),
		FIGHTER + Vector2(20, 90)]), Color(0.3, 0.32, 0.5))
	draw_circle(FIGHTER + Vector2(0, -34), 16, Color(0.85, 0.75, 0.6))
	draw_line(FIGHTER + Vector2(10, 10), FIGHTER + Vector2(90, -40), Color(0.75, 0.78, 0.85), 5)
	var lean := Vector2(14, 0) * flinch
	draw_line(DUMMY + Vector2(0, 120), DUMMY + Vector2(0, -20) + lean, Color(0.45, 0.32, 0.2), 10)
	draw_circle(DUMMY + Vector2(0, -40) + lean, 48, Color(0.7, 0.58, 0.38))
	draw_circle(DUMMY + Vector2(0, -110) + lean * 1.4, 28, Color(0.7, 0.58, 0.38))
	draw_line(DUMMY + Vector2(-60, -60) + lean, DUMMY + Vector2(60, -60) + lean, Color(0.45, 0.32, 0.2), 8)
