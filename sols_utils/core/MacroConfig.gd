class_name MacroConfig
extends RefCounted

var star_prefix: String = ""
var star_enumerate: bool = true
var star_abbrev: String = ""
var star_append_galaxy: bool = false

var planet_prefix: String = ""
var planet_enumerate: bool = true
var planet_append_star: bool = true

var galaxy_prefix: String = ""
var galaxy_enumerate: bool = true
var galaxy_abbrev: String = ""

var cluster_prefix: String = ""
var cluster_enumerate: bool = true

var use_roman: bool = true
var rename_prev: bool = false
var rename_unconquered: bool = false

func to_dict() -> Dictionary:
	return {
		"star_prefix": star_prefix,
		"star_enumerate": star_enumerate,
		"star_abbrev": star_abbrev,
		"star_append_galaxy": star_append_galaxy,
		"planet_prefix": planet_prefix,
		"planet_enumerate": planet_enumerate,
		"planet_append_star": planet_append_star,
		"galaxy_prefix": galaxy_prefix,
		"galaxy_enumerate": galaxy_enumerate,
		"galaxy_abbrev": galaxy_abbrev,
		"cluster_prefix": cluster_prefix,
		"cluster_enumerate": cluster_enumerate,
		"use_roman": use_roman,
		"rename_prev": rename_prev,
		"rename_unconquered": rename_unconquered
	}

func from_dict(dict: Dictionary) -> void:
	star_prefix = dict.get("star_prefix", star_prefix)
	star_enumerate = dict.get("star_enumerate", star_enumerate)
	star_abbrev = dict.get("star_abbrev", star_abbrev)
	star_append_galaxy = dict.get("star_append_galaxy", star_append_galaxy)
	planet_prefix = dict.get("planet_prefix", planet_prefix)
	planet_enumerate = dict.get("planet_enumerate", planet_enumerate)
	planet_append_star = dict.get("planet_append_star", planet_append_star)
	galaxy_prefix = dict.get("galaxy_prefix", galaxy_prefix)
	galaxy_enumerate = dict.get("galaxy_enumerate", galaxy_enumerate)
	galaxy_abbrev = dict.get("galaxy_abbrev", galaxy_abbrev)
	cluster_prefix = dict.get("cluster_prefix", cluster_prefix)
	cluster_enumerate = dict.get("cluster_enumerate", cluster_enumerate)
	use_roman = dict.get("use_roman", use_roman)
	rename_prev = dict.get("rename_prev", rename_prev)
	rename_unconquered = dict.get("rename_unconquered", rename_unconquered)

func save_to_disk(file_path: String = "user://sols_utils_config.json") -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_dict(), "\t"))
		file.close()

func load_from_disk(file_path: String = "user://sols_utils_config.json") -> void:
	if not FileAccess.file_exists(file_path):
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			from_dict(parsed)
