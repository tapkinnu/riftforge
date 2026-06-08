extends Node

class_name RiftforgeData

static var _units: Dictionary = {}
static var _buildings: Dictionary = {}
static var _resources: Dictionary = {}
static var _loaded: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_units = _load_json("res://data/units.json", "units")
	_buildings = _load_json("res://data/buildings.json", "buildings")
	_resources = _load_json("res://data/resources.json", "resources")
	_loaded = true

static func _load_json(path: String, key: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open " + path)
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("JSON parse error in " + path + ": " + json.get_error_message())
		return {}
	var data := json.get_data() as Dictionary
	return data.get(key, {})

static func get_unit(role: String) -> Dictionary:
	_ensure_loaded()
	return _units.get(role, {}).duplicate(true)

static func get_building(btype: String) -> Dictionary:
	_ensure_loaded()
	return _buildings.get(btype, {}).duplicate(true)

static func get_resource(kind: String) -> Dictionary:
	_ensure_loaded()
	return _resources.get(kind, {}).duplicate(true)
