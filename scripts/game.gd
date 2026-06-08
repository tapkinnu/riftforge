extends Node3D

const TEAM_PLAYER := 0
const TEAM_ENEMY := 1
const GROUND_Y := 0.0

var rng := RandomNumberGenerator.new()
var camera: Camera3D
var camera_pivot: Node3D
var hud: CanvasLayer
var selection_rect: ColorRect
var info_label: Label
var resource_label: Label
var objective_label: Label
var command_label: Label
var portrait: TextureRect
var units: Array[Node3D] = []
var buildings: Array[Node3D] = []
var resources: Array[Node3D] = []
var selected: Array[Node3D] = []
var damage_numbers: Array[Label3D] = []
var player_aether: int = 420
var player_crystal: int = 160
var enemy_aether: int = 360
var enemy_crystal: int = 120
var mission_time: float = 0.0
var ai_timer: float = 0.0
var drag_start := Vector2.ZERO
var dragging := false
var command_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var harvest_audio: AudioStreamPlayer

func _ready() -> void:
	rng.seed = 948231
	_setup_world()
	_setup_audio()
	_create_terrain()
	_create_camera()
	_create_bases()
	_create_neutral_resources()
	_create_decorations()
	_create_hud()
	_select([units[0], units[1], units[2]])
	objective_label.text = "MISSION: Gather aether, rally the Ironward, and destroy the Thornborne elder hall."

func _setup_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.17, 0.24, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.78, 1.0)
	env.ambient_light_energy = 0.62
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmStrategySun"
	sun.light_color = Color(1.0, 0.86, 0.62, 1.0)
	sun.light_energy = 2.4
	sun.rotation_degrees = Vector3(-54, -38, 0)
	add_child(sun)

func _setup_audio() -> void:
	command_audio = _audio("res://assets/audio/command_chime.wav", false)
	hit_audio = _audio("res://assets/audio/sword_hit.wav", false)
	harvest_audio = _audio("res://assets/audio/harvest.wav", false)
	var ambience := _audio("res://assets/audio/battle_drone.wav", true)
	ambience.volume_db = -14.0
	ambience.play()

func _audio(path: String, looped: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
	player.stream = stream
	add_child(player)
	return player

func _create_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "RTSCameraPivot"
	camera_pivot.position = Vector3(0, 0, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 165, 178)
	camera.rotation_degrees = Vector3(-58, 0, 0)
	camera.fov = 55.0
	camera.current = true
	camera_pivot.add_child(camera)

func _create_terrain() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(900, 900)
	var mi := MeshInstance3D.new()
	mi.name = "FALBattlefieldTerrain"
	mi.mesh = mesh
	var mat := _mat(Color(0.7, 0.9, 0.55, 1.0), Color(0, 0, 0, 1.0), 0.0)
	mat.albedo_texture = load("res://assets/textures/fal_battlefield.png") as Texture2D
	mat.roughness = 0.92
	mi.material_override = mat
	add_child(mi)
	# raised cliffs/frame pieces
	for i in range(18):
		var ang: float = TAU * float(i) / 18.0
		var pos := Vector3(cos(ang) * 350.0, 2.0, sin(ang) * 350.0)
		var rock := _box("BorderCrag", Vector3(rng.randf_range(18, 42), rng.randf_range(8, 25), rng.randf_range(18, 42)), _mat(Color(0.28, 0.27, 0.22, 1.0)), pos)
		rock.rotation_degrees.y = rng.randf_range(0, 180)
		add_child(rock)

func _create_bases() -> void:
	var keep := _create_building("Ironward Keep", TEAM_PLAYER, Vector3(-118, 0, 72), "hall")
	var forge := _create_building("Runesmith Forge", TEAM_PLAYER, Vector3(-58, 0, 116), "barracks")
	var tower := _create_building("Aether Spire", TEAM_PLAYER, Vector3(-174, 0, 30), "tower")
	buildings.append_array([keep, forge, tower])
	units.append(_create_unit("Rift Marshal", TEAM_PLAYER, Vector3(-76, 0, 38), "hero"))
	for i in range(5):
		units.append(_create_unit("Ironward Shieldbearer", TEAM_PLAYER, Vector3(-62 + i * 16, 0, 6 + (i % 2) * 15), "soldier"))
	units.append(_create_unit("Aether Mason", TEAM_PLAYER, Vector3(-116, 0, 8), "worker"))
	units.append(_create_unit("Aether Mason", TEAM_PLAYER, Vector3(-144, 0, 20), "worker"))
	var elder := _create_building("Thornborne Elder Hall", TEAM_ENEMY, Vector3(118, 0, -72), "hall")
	var lodge := _create_building("Briar War Lodge", TEAM_ENEMY, Vector3(58, 0, -116), "barracks")
	var rootspire := _create_building("Root Spire", TEAM_ENEMY, Vector3(174, 0, -30), "tower")
	buildings.append_array([elder, lodge, rootspire])
	units.append(_create_unit("Grove Matriarch", TEAM_ENEMY, Vector3(76, 0, -38), "hero"))
	for i in range(7):
		units.append(_create_unit("Briar Warden", TEAM_ENEMY, Vector3(44 + i * 14, 0, -4 - (i % 3) * 15), "soldier"))


func _create_neutral_resources() -> void:
	for p in [Vector3(-258, 0, 4), Vector3(-205, 0, -22), Vector3(0, 0, -8), Vector3(232, 0, -6)]:
		resources.append(_create_resource("Aether Bloom", p, "aether"))
	for p in [Vector3(-56, 0, 220), Vector3(52, 0, -222), Vector3(280, 0, -148)]:
		resources.append(_create_resource("Moon Crystal", p, "crystal"))

func _create_decorations() -> void:
	for i in range(95):
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var x: float = rng.randf_range(-330, 330)
		var z: float = side * rng.randf_range(205, 335)
		_create_tree(Vector3(x, 0, z), rng.randf_range(0.8, 1.6))
	for i in range(45):
		var p := Vector3(rng.randf_range(-315, 315), 0.4, rng.randf_range(-315, 315))
		add_child(_sphere("FieldStone", rng.randf_range(1.2, 3.5), _mat(Color(0.28, 0.27, 0.24, 1.0)), p))

func _create_tree(pos: Vector3, s: float) -> void:
	var trunk := _cylinder("TreeTrunk", 1.2 * s, 7.0 * s, _mat(Color(0.28, 0.16, 0.07, 1.0)), pos + Vector3(0, 3.5 * s, 0))
	add_child(trunk)
	var cone := _cone("PineCanopy", 6.0 * s, 14.0 * s, _mat(Color(0.06, 0.28, 0.11, 1.0)), pos + Vector3(0, 12.0 * s, 0))
	add_child(cone)

func _create_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.name = "HUDRoot"
	root.size = Vector2(1280, 720)
	hud.add_child(root)
	var top := ColorRect.new()
	top.color = Color(0.02, 0.025, 0.035, 0.78)
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 72)
	root.add_child(top)
	resource_label = _label(Vector2(20, 14), 18, Color(0.9, 0.86, 0.65, 1.0), "")
	root.add_child(resource_label)
	info_label = _label(Vector2(850, 12), 15, Color(0.82, 0.96, 1.0, 1.0), "")
	root.add_child(info_label)
	var objective_panel := ColorRect.new()
	objective_panel.color = Color(0.02, 0.025, 0.035, 0.82)
	objective_panel.position = Vector2(205, 668)
	objective_panel.size = Vector2(870, 42)
	root.add_child(objective_panel)
	objective_label = _label(Vector2(220, 676), 18, Color(1.0, 0.86, 0.42, 1.0), "")
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.size = Vector2(840, 30)
	root.add_child(objective_label)
	var command_panel := ColorRect.new()
	command_panel.color = Color(0.02, 0.025, 0.035, 0.82)
	command_panel.position = Vector2(900, 556)
	command_panel.size = Vector2(354, 132)
	root.add_child(command_panel)
	command_label = _label(Vector2(914, 566), 14, Color(0.85, 1.0, 0.78, 1.0), "")
	command_label.size = Vector2(326, 116)
	root.add_child(command_label)
	var control_panel := ColorRect.new()
	control_panel.color = Color(0.02, 0.025, 0.035, 0.82)
	control_panel.position = Vector2(18, 564)
	control_panel.size = Vector2(315, 112)
	root.add_child(control_panel)
	for text_pos in [["Q: train / hero ability", Vector2(34, 580)], ["Right click: move / attack / harvest", Vector2(34, 606)], ["WASD + wheel: command camera", Vector2(34, 632)], ["Drag-select squads; buildings train units", Vector2(34, 658)]]:
		root.add_child(_label(text_pos[1], 13, Color(0.75, 0.85, 0.95, 1.0), text_pos[0]))
	selection_rect = ColorRect.new()
	selection_rect.color = Color(0.2, 0.75, 1.0, 0.22)
	selection_rect.visible = false
	root.add_child(selection_rect)

func _label(pos: Vector2, size: int, color: Color, text: String) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _process(delta: float) -> void:
	mission_time += delta
	_update_camera(delta)
	_update_units(delta)
	_update_ai(delta)
	_update_damage_numbers(delta)
	_update_hud()
	_update_drag_rect()

func _update_camera(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): dir.z += 1.0
	if Input.is_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): dir.x += 1.0
	if dir.length() > 0.1:
		dir = dir.normalized()
		camera_pivot.position += dir * 145.0 * delta
		camera_pivot.position.x = clamp(camera_pivot.position.x, -245.0, 245.0)
		camera_pivot.position.z = clamp(camera_pivot.position.z, -245.0, 245.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			camera.position = camera.position.lerp(Vector3(0, 72, 82), 0.18)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			camera.position = camera.position.lerp(Vector3(0, 145, 170), 0.18)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				dragging = true
				drag_start = mb.position
			else:
				if dragging and drag_start.distance_to(mb.position) > 12.0:
					_box_select(drag_start, mb.position)
				else:
					_click_select(mb.position)
				dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_issue_command(mb.position)
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key := event as InputEventKey
		if key.keycode == KEY_Q:
			_train_from_selection("warrior")
		elif key.keycode == KEY_E:
			_train_from_selection("hero")

func _update_drag_rect() -> void:
	if not dragging:
		selection_rect.visible = false
		return
	var now := get_viewport().get_mouse_position()
	selection_rect.visible = true
	selection_rect.position = Vector2(min(drag_start.x, now.x), min(drag_start.y, now.y))
	selection_rect.size = Vector2(abs(now.x - drag_start.x), abs(now.y - drag_start.y))

func _click_select(screen_pos: Vector2) -> void:
	var node := _pick_node(screen_pos, true, true)
	if node != null and int(node.get_meta("team", -1)) == TEAM_PLAYER:
		_select([node])
	else:
		_select([])

func _box_select(a: Vector2, b: Vector2) -> void:
	var rect := Rect2(Vector2(min(a.x, b.x), min(a.y, b.y)), Vector2(abs(a.x - b.x), abs(a.y - b.y)))
	var found: Array[Node3D] = []
	for u in units:
		if _alive(u) and int(u.get_meta("team")) == TEAM_PLAYER and not camera.is_position_behind(u.global_position):
			if rect.has_point(camera.unproject_position(u.global_position)):
				found.append(u)
	_select(found)

func _select(nodes: Array) -> void:
	for n in selected:
		_set_selected(n, false)
	selected.clear()
	for n in nodes:
		if n is Node3D and _alive(n):
			selected.append(n)
			_set_selected(n, true)
	if selected.size() > 0:
		command_audio.play()

func _set_selected(n: Node3D, on: bool) -> void:
	var s := n.get_node_or_null("Selection") as MeshInstance3D
	if s != null:
		s.visible = on

func _issue_command(screen_pos: Vector2) -> void:
	if selected.is_empty():
		return
	var target := _pick_node(screen_pos, true, true)
	if target != null and int(target.get_meta("team", -1)) != TEAM_PLAYER and target.has_meta("hp"):
		for n in selected:
			if _alive(n) and n.has_meta("role"):
				n.set_meta("attack_target", target)
				n.set_meta("harvest_target", null)
	elif target != null and target.has_meta("resource_type"):
		for n in selected:
			if _alive(n) and str(n.get_meta("role")) == "worker":
				n.set_meta("harvest_target", target)
				n.set_meta("attack_target", null)
	else:
		var ground := _screen_to_ground(screen_pos)
		for i in range(selected.size()):
			var n := selected[i] as Node3D
			if _alive(n) and n.has_meta("role"):
				var offset := Vector3(float(i % 3) * 8.0 - 8.0, 0, float(i / 3) * 8.0)
				n.set_meta("target_pos", ground + offset)
				n.set_meta("attack_target", null)
				n.set_meta("harvest_target", null)
	command_audio.play()

func _pick_node(screen_pos: Vector2, include_units: bool, include_buildings: bool) -> Node3D:
	var best: Node3D = null
	var best_dist: float = 99999.0
	var pool: Array[Node3D] = []
	if include_units: pool.append_array(units)
	if include_buildings: pool.append_array(buildings)
	pool.append_array(resources)
	for n in pool:
		if not is_instance_valid(n): continue
		if n.has_meta("hp") and float(n.get_meta("hp")) <= 0.0: continue
		if camera.is_position_behind(n.global_position): continue
		var sp := camera.unproject_position(n.global_position)
		var radius: float = float(n.get_meta("pick_radius", 28.0))
		var d: float = sp.distance_to(screen_pos)
		if d < radius and d < best_dist:
			best = n
			best_dist = d
	return best

func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if abs(dir.y) < 0.001:
		return Vector3.ZERO
	var t: float = (GROUND_Y - origin.y) / dir.y
	return origin + dir * t

func _update_units(delta: float) -> void:
	for u in units.duplicate():
		if not _alive(u):
			units.erase(u)
			continue
		var hp: float = float(u.get_meta("hp"))
		var max_hp: float = float(u.get_meta("max_hp"))
		_update_health_bar(u, hp / max_hp)
		var harvest_target: Variant = u.get_meta("harvest_target") if u.has_meta("harvest_target") else null
		if harvest_target != null and is_instance_valid(harvest_target):
			_update_harvester(u, harvest_target as Node3D, delta)
			continue
		var atk: Variant = u.get_meta("attack_target") if u.has_meta("attack_target") else null
		if atk != null and is_instance_valid(atk) and _alive(atk as Node3D):
			_update_attacker(u, atk as Node3D, delta)
			continue
		var target_pos: Vector3 = u.get_meta("target_pos", u.global_position) as Vector3
		_move_toward(u, target_pos, delta)

func _update_harvester(u: Node3D, res: Node3D, delta: float) -> void:
	if u.global_position.distance_to(res.global_position) > 12.0:
		_move_toward(u, res.global_position, delta)
		return
	var timer: float = float(u.get_meta("harvest_timer", 0.0)) - delta
	if timer <= 0.0:
		u.set_meta("harvest_timer", 1.0)
		var team: int = int(u.get_meta("team"))
		var kind: String = str(res.get_meta("resource_type"))
		if team == TEAM_PLAYER:
			if kind == "aether": player_aether += 12
			else: player_crystal += 6
		else:
			if kind == "aether": enemy_aether += 10
			else: enemy_crystal += 5
		harvest_audio.play()
		_spawn_float_text(u.global_position + Vector3(0, 13, 0), "+" + ("12" if kind == "aether" else "6"), Color(0.4, 0.9, 1.0, 1.0))
	else:
		u.set_meta("harvest_timer", timer)

func _update_attacker(u: Node3D, target: Node3D, delta: float) -> void:
	var range: float = float(u.get_meta("range"))
	if u.global_position.distance_to(target.global_position) > range:
		_move_toward(u, target.global_position, delta)
		return
	_face(u, target.global_position)
	var cd: float = float(u.get_meta("cooldown", 0.0)) - delta
	if cd <= 0.0:
		u.set_meta("cooldown", float(u.get_meta("attack_speed")))
		_damage(target, float(u.get_meta("damage")), u)
	else:
		u.set_meta("cooldown", cd)

func _move_toward(u: Node3D, pos: Vector3, delta: float) -> void:
	var flat := Vector3(pos.x, u.global_position.y, pos.z)
	var v := flat - u.global_position
	if v.length() < 1.5:
		return
	v = v.normalized()
	u.global_position += v * float(u.get_meta("speed", 25.0)) * delta
	_face(u, flat)

func _face(n: Node3D, pos: Vector3) -> void:
	var flat := Vector3(pos.x, n.global_position.y, pos.z)
	if n.global_position.distance_to(flat) > 0.5:
		n.look_at(flat, Vector3.UP)

func _damage(target: Node3D, amount: float, source: Node3D) -> void:
	var hp: float = float(target.get_meta("hp")) - amount
	target.set_meta("hp", hp)
	_spawn_hit_sparks(target.global_position + Vector3(0, 5, 0), int(target.get_meta("team", 0)))
	_spawn_float_text(target.global_position + Vector3(0, 14, 0), "-%d" % int(amount), Color(1.0, 0.45, 0.18, 1.0))
	hit_audio.play()
	if hp <= 0.0:
		_spawn_float_text(target.global_position + Vector3(0, 20, 0), "FELLED", Color(1.0, 0.85, 0.25, 1.0))
		if selected.has(target): selected.erase(target)
		if units.has(target): units.erase(target)
		if buildings.has(target): buildings.erase(target)
		target.queue_free()
		_check_victory()

func _update_ai(delta: float) -> void:
	ai_timer -= delta
	if ai_timer > 0.0:
		return
	ai_timer = 2.2
	var player_targets := _team_targets(TEAM_PLAYER)
	if player_targets.is_empty(): return
	for u in units:
		if _alive(u) and int(u.get_meta("team")) == TEAM_ENEMY:
			var closest := player_targets[0]
			var best: float = 999999.0
			for t in player_targets:
				var d: float = u.global_position.distance_to((t as Node3D).global_position)
				if d < best:
					best = d
					closest = t
			u.set_meta("attack_target", closest)
			u.set_meta("harvest_target", null)

func _team_targets(team: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for u in units:
		if _alive(u) and int(u.get_meta("team")) == team: out.append(u)
	for b in buildings:
		if _alive(b) and int(b.get_meta("team")) == team: out.append(b)
	return out

func _train_from_selection(kind: String) -> void:
	for b in selected:
		if b.has_meta("building_type") and int(b.get_meta("team")) == TEAM_PLAYER:
			var bt: String = str(b.get_meta("building_type"))
			if kind == "hero" and bt != "hall": continue
			if kind == "warrior" and bt == "tower": continue
			var cost_a: int = 90 if kind == "warrior" else 180
			var cost_c: int = 15 if kind == "warrior" else 80
			if player_aether >= cost_a and player_crystal >= cost_c:
				player_aether -= cost_a
				player_crystal -= cost_c
				var spawn := b.global_position + Vector3(-24, 0, 24)
				var unit := _create_unit("Rift Marshal" if kind == "hero" else "Shieldbearer", TEAM_PLAYER, spawn, kind)
				units.append(unit)
				_select([unit])
				return

func _check_victory() -> void:
	var enemy_hall_alive := false
	var player_hall_alive := false
	for b in buildings:
		if str(b.get_meta("building_type", "")) == "hall" and _alive(b):
			if int(b.get_meta("team")) == TEAM_ENEMY: enemy_hall_alive = true
			if int(b.get_meta("team")) == TEAM_PLAYER: player_hall_alive = true
	if not enemy_hall_alive:
		objective_label.text = "VICTORY: The Thornborne elder hall has fallen. Riftforge is secured."
	elif not player_hall_alive:
		objective_label.text = "DEFEAT: The Ironward keep has been shattered."

func _update_health_bar(n: Node3D, pct: float) -> void:
	var bar := n.get_node_or_null("Health/Fill") as MeshInstance3D
	if bar != null:
		bar.scale.x = clamp(pct, 0.02, 1.0)

func _update_damage_numbers(delta: float) -> void:
	for d in damage_numbers.duplicate():
		if not is_instance_valid(d):
			damage_numbers.erase(d)
			continue
		var ttl: float = float(d.get_meta("ttl")) - delta
		d.set_meta("ttl", ttl)
		d.position.y += 12.0 * delta
		d.modulate.a = clamp(ttl, 0.0, 1.0)
		if ttl <= 0.0:
			damage_numbers.erase(d)
			d.queue_free()

func _spawn_float_text(pos: Vector3, text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 26
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	l.set_meta("ttl", 1.0)
	add_child(l)
	damage_numbers.append(l)

func _spawn_hit_sparks(pos: Vector3, team: int) -> void:
	var color := Color(1.0, 0.45, 0.1, 1.0) if team == TEAM_ENEMY else Color(0.35, 1.0, 0.35, 1.0)
	for i in range(5):
		var s := _sphere("ImpactSpark", rng.randf_range(0.8, 1.6), _mat(color, color, 1.8), pos + Vector3(rng.randf_range(-4,4), rng.randf_range(0,5), rng.randf_range(-4,4)))
		add_child(s)
		_spawn_float_text(s.global_position, "✦", color)

func _update_hud() -> void:
	var sec: int = int(mission_time)
	resource_label.text = "RIFTFORGE  |  Aether %d   Crystal %d   Time %02d:%02d" % [player_aether, player_crystal, sec / 60, sec % 60]
	if selected.is_empty():
		info_label.text = "No selection"
		command_label.text = "Select Ironward units.\nDrag-select squads.\nRight-click to command."
		return
	var first := selected[0]
	var hp: float = float(first.get_meta("hp", 0.0))
	var max_hp: float = float(first.get_meta("max_hp", 1.0))
	info_label.text = "%s  |  %d selected  |  HP %d/%d" % [first.name, selected.size(), int(hp), int(max_hp)]
	if first.has_meta("building_type"):
		command_label.text = "BUILDING COMMANDS\nQ: train Shieldbearer\nE: summon Rift Marshal\nProtect the hall."
	else:
		command_label.text = "UNIT COMMANDS\nRight-click ground: move\nRight-click enemy: attack\nWorkers harvest crystals/aether."

func _alive(n: Node) -> bool:
	return is_instance_valid(n) and n.has_meta("hp") and float(n.get_meta("hp")) > 0.0

func _create_unit(name: String, team: int, pos: Vector3, role: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	n.set_meta("team", team)
	n.set_meta("role", role)
	var hp: float = 190.0 if role == "hero" else (92.0 if role == "worker" else 130.0)
	n.set_meta("hp", hp)
	n.set_meta("max_hp", hp)
	n.set_meta("speed", 30.0 if role == "hero" else (36.0 if role == "worker" else 32.0))
	n.set_meta("range", 22.0 if role == "hero" else 16.0)
	n.set_meta("damage", 26.0 if role == "hero" else (8.0 if role == "worker" else 15.0))
	n.set_meta("attack_speed", 0.9 if role == "hero" else 1.1)
	n.set_meta("target_pos", pos)
	n.set_meta("attack_target", null)
	n.set_meta("harvest_target", null)
	n.set_meta("harvest_timer", 0.0)
	n.set_meta("cooldown", 0.25)
	n.set_meta("pick_radius", 32.0)
	var base_col := Color(0.85, 0.66, 0.25, 1.0) if team == TEAM_PLAYER else Color(0.12, 0.48, 0.16, 1.0)
	var glow_col := Color(0.2, 0.75, 1.0, 1.0) if team == TEAM_PLAYER else Color(0.6, 1.0, 0.22, 1.0)
	var body := _cylinder("Body", 4.0 if role != "hero" else 5.2, 12.0 if role != "hero" else 16.0, _mat(base_col), Vector3(0, 6, 0))
	n.add_child(body)
	var head := _sphere("Head", 3.0 if role != "hero" else 3.7, _mat(Color(0.78, 0.62, 0.45, 1.0)), Vector3(0, 14.0 if role != "hero" else 18.0, 0))
	n.add_child(head)
	if role == "hero":
		n.add_child(_cylinder("CrownGlow", 5.5, 0.7, _mat(glow_col, glow_col, 1.9), Vector3(0, 22, 0)))
		n.add_child(_box("Banner", Vector3(1.0, 18.0, 1.0), _mat(glow_col, glow_col, 1.3), Vector3(-5, 14, 0)))
	elif role == "worker":
		n.add_child(_box("Hammer", Vector3(1.3, 7.0, 1.3), _mat(Color(0.55, 0.45, 0.32, 1.0)), Vector3(5, 8, 0)))
	else:
		n.add_child(_box("Blade", Vector3(1.2, 10.0, 1.2), _mat(Color(0.78, 0.82, 0.86, 1.0), glow_col, 0.35), Vector3(5, 11, 0)))
	_add_selection(n, 8.5, Color(0.2, 0.8, 1.0, 0.42) if team == TEAM_PLAYER else Color(1.0, 0.2, 0.12, 0.36))
	_add_health(n, 13.0 if role != "hero" else 18.0)
	add_child(n)
	return n

func _create_building(name: String, team: int, pos: Vector3, btype: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	n.set_meta("team", team)
	n.set_meta("building_type", btype)
	var hp: float = 620.0 if btype == "hall" else (340.0 if btype == "tower" else 430.0)
	n.set_meta("hp", hp)
	n.set_meta("max_hp", hp)
	n.set_meta("pick_radius", 58.0)
	var main_col := Color(0.54, 0.44, 0.28, 1.0) if team == TEAM_PLAYER else Color(0.20, 0.34, 0.16, 1.0)
	var roof_col := Color(0.68, 0.34, 0.14, 1.0) if team == TEAM_PLAYER else Color(0.16, 0.48, 0.18, 1.0)
	if btype == "hall":
		n.add_child(_box("GreatHall", Vector3(34, 24, 34), _mat(main_col), Vector3(0, 12, 0)))
		n.add_child(_cone("HighRoof", 25, 18, _mat(roof_col), Vector3(0, 34, 0)))
		n.add_child(_cylinder("AetherOrb", 5, 5, _mat(Color(0.2, 0.75, 1.0, 1.0), Color(0.2, 0.75, 1.0, 1.0), 1.8), Vector3(0, 48, 0)))
	elif btype == "barracks":
		n.add_child(_box("WarLodge", Vector3(42, 16, 26), _mat(main_col), Vector3(0, 8, 0)))
		n.add_child(_box("AngledRoof", Vector3(46, 8, 30), _mat(roof_col), Vector3(0, 22, 0)))
		n.add_child(_box("TrainingBanner", Vector3(2, 18, 2), _mat(roof_col, roof_col, 1.0), Vector3(18, 24, 0)))
	else:
		n.add_child(_cylinder("TowerBase", 11, 34, _mat(main_col), Vector3(0, 17, 0)))
		n.add_child(_cone("Spire", 14, 18, _mat(roof_col), Vector3(0, 42, 0)))
		n.add_child(_sphere("WatchGlow", 4, _mat(Color(1.0, 0.4, 0.1, 1.0), Color(1.0, 0.3, 0.05, 1.0), 2.2), Vector3(0, 52, 0)))
	_add_selection(n, 24.0 if btype != "tower" else 16.0, Color(0.2, 0.8, 1.0, 0.30) if team == TEAM_PLAYER else Color(1.0, 0.2, 0.12, 0.30))
	_add_health(n, 38.0 if btype == "hall" else 28.0)
	add_child(n)
	return n

func _create_resource(name: String, pos: Vector3, kind: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	n.set_meta("resource_type", kind)
	n.set_meta("pick_radius", 36.0)
	var col := Color(0.2, 0.85, 1.0, 1.0) if kind == "aether" else Color(0.72, 0.28, 1.0, 1.0)
	for i in range(5):
		var c := _cone("Crystal", rng.randf_range(3.5, 6.5), rng.randf_range(12, 24), _mat(col, col, 1.6), Vector3(rng.randf_range(-8, 8), 8, rng.randf_range(-8, 8)))
		c.rotation_degrees.y = rng.randf_range(0, 180)
		n.add_child(c)
	add_child(n)
	return n

func _add_selection(n: Node3D, radius: float, color: Color) -> void:
	var sel := _cylinder("Selection", radius, 0.18, _mat(color, color, 0.3), Vector3(0, 0.15, 0))
	var mat := sel.material_override as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sel.visible = false
	n.add_child(sel)

func _add_health(n: Node3D, y: float) -> void:
	var root := Node3D.new()
	root.name = "Health"
	root.position = Vector3(0, y + 8, 0)
	var bg := _box("BG", Vector3(14, 1.2, 1.0), _mat(Color(0.08, 0.03, 0.03, 1.0)), Vector3.ZERO)
	var fill := _box("Fill", Vector3(13.4, 1.4, 1.1), _mat(Color(0.1, 0.92, 0.22, 1.0), Color(0.1, 0.7, 0.12, 1.0), 0.2), Vector3(0, 0.1, 0))
	root.add_child(bg)
	root.add_child(fill)
	n.add_child(root)

func _box(name: String, size: Vector3, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi

func _sphere(name: String, radius: float, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi

func _cylinder(name: String, radius: float, height: float, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi

func _cone(name: String, radius: float, height: float, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi

func _mat(albedo: Color, emission: Color = Color(0, 0, 0, 1), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = 0.78
	if albedo.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m
