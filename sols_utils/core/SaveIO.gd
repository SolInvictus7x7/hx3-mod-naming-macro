class_name SaveIO
extends RefCounted

const VALID_TYPES: Dictionary = {
	"clusters": "Clusters",
	"galaxies": "Galaxies",
	"systems": "Systems",
	"planets": "Planets"
}

static func get_sanitized_type(type: String) -> String:
	return VALID_TYPES.get(type.to_lower(), type)

static func get_obj_path(game: Node, type: String, id: int) -> String:
	return "user://%s/Univ%s/%s/%d.hx3" % [game.c_sv, game.c_u, get_sanitized_type(type), id]

static func sols_obj_exists(game: Node, type: String, id: int) -> bool:
	if not game or str(game.c_sv).is_empty():
		return false
	var path: String = get_obj_path(game, type, id)
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + "~")

static func is_file_valid_for_read(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var valid: bool = file.get_length() >= 4
	file.close()
	return valid

static func load_obj(game: Node, type: String, id: int) -> Array:
	if not game or str(game.c_sv).is_empty():
		return []
	var path: String = get_obj_path(game, type, id)
	var target_path: String = path
	if not is_file_valid_for_read(target_path):
		target_path = path + "~"
		if not is_file_valid_for_read(target_path):
			return []

	var file := FileAccess.open(target_path, FileAccess.READ)
	if not file:
		return []
	var data: Variant = file.get_var()
	file.close()
	return data if data is Array else []

static func save_obj(game: Node, type: String, id: int, data: Array) -> void:
	if not game or str(game.c_sv).is_empty():
		return
	var path: String = get_obj_path(game, type, id)
	var temp_path: String = path + "~"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		return
	file.store_var(data)
	file.close()
	DirAccess.copy_absolute(temp_path, path)
