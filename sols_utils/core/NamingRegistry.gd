class_name NamingRegistry
extends RefCounted

const ONES: Array[String] = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
const TENS: Array[String] = ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"]
const HUNDREDS: Array[String] = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"]
const THOUSANDS: Array[String] = ["", "M", "MM", "MMM"]

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
	return THOUSANDS[m] + HUNDREDS[c] + TENS[x] + ONES[i]

func register_existing_name(name: String) -> void:
	if not name.is_empty():
		assigned_names[name] = true

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
