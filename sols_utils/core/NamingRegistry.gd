class_name NamingRegistry
extends RefCounted

var counters: Dictionary = {}
var assigned_names: Dictionary = {}

func get_numeral(num: int, use_roman: bool) -> String:
	if not use_roman:
		return str(num)
	if num <= 0:
		return ""
	if num > 3999:
		return str(num)

	var m: int = int(num / 1000.0) % 10
	var c: int = int(num / 100.0) % 10
	var x: int = int(num / 10.0) % 10
	var i: int = num % 10

	return "M".repeat(m) \
		+ _digit_to_roman(c, "C", "D", "M") \
		+ _digit_to_roman(x, "X", "L", "C") \
		+ _digit_to_roman(i, "I", "V", "X")

func _digit_to_roman(d: int, unit: String, half: String, next: String) -> String:
	match d:
		1, 2, 3:
			return unit.repeat(d)
		4:
			return unit + half
		5:
			return half
		6, 7, 8:
			return half + unit.repeat(d - 5)
		9:
			return unit + next
		_:
			return ""

func register_existing_name(name: String) -> void:
	if not name.is_empty():
		assigned_names[name] = true

func populate_existing_names(names: Array) -> void:
	for n in names:
		register_existing_name(str(n))

func has_name(name: String) -> bool:
	return assigned_names.has(name)

func get_next_name(prefix: String, category: String, use_roman: bool, enumerate: bool, suffix: String = "") -> String:
	if not enumerate:
		var fixed_candidate: String = prefix + suffix
		assigned_names[fixed_candidate] = true
		return fixed_candidate

	var key: String = category + "_" + prefix
	var idx: int = counters.get(key, 1)
	var numeral: String = get_numeral(idx, use_roman)
	var candidate: String = prefix + numeral + suffix

	while assigned_names.has(candidate):
		idx += 1
		numeral = get_numeral(idx, use_roman)
		candidate = prefix + numeral + suffix

	assigned_names[candidate] = true
	counters[key] = idx + 1
	return candidate

func get_registry_path(c_sv: String, c_u: int) -> String:
	return "user://%s/Univ%d/sols_utils_naming_registry.json" % [c_sv, c_u]

func load_registry(c_sv: String, c_u: int) -> void:
	counters.clear()
	var path: String = get_registry_path(c_sv, c_u)
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		counters = parsed.get("counters", {})
		var loaded_names: Dictionary = parsed.get("assigned_names", {})
		for key in loaded_names:
			assigned_names[key] = true

func save_registry(c_sv: String, c_u: int) -> void:
	if c_sv.is_empty() or c_u < 0:
		return
	var path: String = get_registry_path(c_sv, c_u)
	var temp_path: String = path + "~"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		return
	var payload: Dictionary = {
		"counters": counters,
		"assigned_names": assigned_names
	}
	file.store_string(JSON.stringify(payload))
	file.close()
	DirAccess.copy_absolute(temp_path, path)
	DirAccess.remove_absolute(temp_path)
