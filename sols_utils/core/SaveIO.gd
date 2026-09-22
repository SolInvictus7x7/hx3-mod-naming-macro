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


const GALAXY_PROPERTIES: Array[String] = [
	"id", "l_id", "name", "pos", "diff", "parent", "planet_num", "planets", "view", "stars", "discovered", "conquered", "closest_planet_distance"
]

const CLUSTER_PROPERTIES: Array[String] = [
	"id", "l_id", "name", "pos", "diff", "parent", "system_num", "view", "type", "discovered", "conquered", "rotation", "B_strength", "dark_matter"
]

const STAR_PROPERTIES: Array[String] = [
	"type", "class", "size", "pos", "temperature", "mass", "luminosity"
]

static func decompress_if_needed(arr: Array, type: String) -> Array:
	if arr.is_empty() or not (arr[0] is Array):
		return arr
	var sanitized_type: String = get_sanitized_type(type)
	var properties: Array[String] = []
	if sanitized_type == "Galaxies":
		properties = GALAXY_PROPERTIES
	elif sanitized_type == "Clusters":
		properties = CLUSTER_PROPERTIES
	else:
		return arr

	var decompressed_arr: Array = []
	for compressed_obj in arr:
		if not (compressed_obj is Array):
			decompressed_arr.append(compressed_obj)
			continue
		var decompressed_obj: Dictionary = {}
		for i: int in len(properties):
			if i < len(compressed_obj) and compressed_obj[i] != null:
				if properties[i] == "stars" and compressed_obj[i] is Array:
					var stars_decompressed: Array = []
					for star_compressed in compressed_obj[i]:
						if star_compressed is Array:
							var star_decompressed: Dictionary = {}
							if not star_compressed.is_empty() and star_compressed[-1] is Dictionary:
								star_decompressed = (star_compressed[-1] as Dictionary).duplicate()
							for j: int in len(STAR_PROPERTIES):
								if j < len(star_compressed) - 1:
									star_decompressed[STAR_PROPERTIES[j]] = star_compressed[j]
							stars_decompressed.append(star_decompressed)
						elif star_compressed is Dictionary:
							stars_decompressed.append(star_compressed)
					decompressed_obj["stars"] = stars_decompressed
				else:
					decompressed_obj[properties[i]] = compressed_obj[i]
		if not compressed_obj.is_empty() and compressed_obj[-1] is Dictionary:
			for key in (compressed_obj[-1] as Dictionary).keys():
				decompressed_obj[key] = compressed_obj[-1][key]
		decompressed_arr.append(decompressed_obj)
	return decompressed_arr

static func load_obj(game: Node, type: String, id: int) -> Array:
	if not game or str(game.c_sv).is_empty():
		return []
	var path: String = get_obj_path(game, type, id)
	var target_path: String = path
	var file := FileAccess.open(target_path, FileAccess.READ)
	if not file or file.get_length() < 4:
		if file:
			file.close()
		target_path = path + "~"
		file = FileAccess.open(target_path, FileAccess.READ)
		if not file or file.get_length() < 4:
			if file:
				file.close()
			return []
	var data: Variant = file.get_var()
	file.close()
	if not (data is Array):
		return []
	return decompress_if_needed(data, type)

static func save_obj(game: Node, type: String, id: int, data: Array) -> void:
	if not game or str(game.c_sv).is_empty():
		return
	var path: String = get_obj_path(game, type, id)
	var stage_path: String = path + ".sols_tmp"
	var file := FileAccess.open(stage_path, FileAccess.WRITE)
	if not file:
		return
	file.store_var(data)
	file.close()
	DirAccess.copy_absolute(stage_path, path + "~")
	DirAccess.copy_absolute(stage_path, path)
	DirAccess.remove_absolute(stage_path)
