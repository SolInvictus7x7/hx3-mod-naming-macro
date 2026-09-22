class_name MacroRunner
extends RefCounted

const NamingRegistryScript = preload("res://sols_utils/core/NamingRegistry.gd")
const SaveIOScript = preload("res://sols_utils/core/SaveIO.gd")

var is_running: bool = false
var registry: RefCounted

func execute(config: RefCounted) -> void:
	if is_running:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var game: Node = tree.root.get_node_or_null("Game")
	if not game or str(game.c_sv).is_empty() or int(game.c_u) < 0:
		return

	if not config.is_valid_for_execution():
		if game.has_method("popup"):
			game.popup("Star and Planet names must not be empty.", 3.0)
		return

	is_running = true
	registry = NamingRegistryScript.new()
	registry.load_registry(str(game.c_sv), int(game.c_u))

	var cluster_data: Array = game.u_i.get("cluster_data", [])
	await pre_populate_existing_names(game, cluster_data, tree)

	var rename_clusters: bool = not config.cluster_prefix.strip_edges().is_empty()
	var rename_galaxies: bool = not config.galaxy_prefix.strip_edges().is_empty()
	var rename_stars: bool = not config.star_prefix.strip_edges().is_empty()
	var rename_planets: bool = not config.planet_prefix.strip_edges().is_empty()

	var stats: Dictionary = {"clusters": 0, "galaxies": 0, "systems": 0, "planets": 0}
	var yield_step: int = 0

	for c_id: int in len(cluster_data):
		var c_i: Dictionary = cluster_data[c_id]
		if rename_clusters and is_entity_eligible(c_i, config.rename_unconquered, config.rename_prev, is_default_cluster_name(c_i.get("name", ""), c_id)):
			var new_cluster_name: String = registry.get_next_name(config.cluster_prefix, "cluster", config.use_roman, config.cluster_enumerate)
			c_i["name"] = new_cluster_name
			stats["clusters"] += 1
			sync_bookmark(game, "cluster", str(c_id), new_cluster_name)

	for c_id: int in len(cluster_data):
		if not SaveIOScript.sols_obj_exists(game, "Clusters", c_id):
			continue
		var galaxies: Array = SaveIOScript.load_obj(game, "Clusters", c_id)
		var cluster_dirty: bool = false

		for g_idx: int in len(galaxies):
			var g_i: Dictionary = galaxies[g_idx]
			var g_id: int = g_i.get("id", g_idx)
			var galaxy_name: String = g_i.get("name", "")

			if rename_galaxies and is_entity_eligible(g_i, config.rename_unconquered, config.rename_prev, is_default_galaxy_name(galaxy_name, g_idx)):
				galaxy_name = registry.get_next_name(config.galaxy_prefix, "galaxy", config.use_roman, config.galaxy_enumerate)
				g_i["name"] = galaxy_name
				cluster_dirty = true
				stats["galaxies"] += 1
				sync_bookmark(game, "galaxy", str(g_id), galaxy_name)
				if c_id == int(game.c_c) and g_idx < len(game.galaxy_data):
					game.galaxy_data[g_idx]["name"] = galaxy_name
					if g_idx < len(game.galaxy_data_persistent):
						game.galaxy_data_persistent[g_idx]["name"] = galaxy_name

			yield_step += 1
			if yield_step % 25 == 0:
				await tree.process_frame

			if not SaveIOScript.sols_obj_exists(game, "Galaxies", g_id):
				continue
			var systems: Array = SaveIOScript.load_obj(game, "Galaxies", g_id)
			var galaxy_dirty: bool = false

			for s_idx: int in len(systems):
				var s_i: Dictionary = systems[s_idx]
				var s_id: int = s_i.get("id", s_idx)
				var system_name: String = s_i.get("name", "")

				if rename_stars and is_entity_eligible(s_i, config.rename_unconquered, config.rename_prev, is_default_system_name(system_name, s_idx)):
					var sys_suffix: String = ""
					if config.star_append_galaxy and not galaxy_name.is_empty():
						var g_label: String = config.galaxy_abbrev if not config.galaxy_abbrev.is_empty() else galaxy_name
						sys_suffix = "•" + g_label
					system_name = registry.get_next_name(config.star_prefix, "system", config.use_roman, config.star_enumerate, sys_suffix)
					s_i["name"] = system_name
					galaxy_dirty = true
					stats["systems"] += 1
					sync_bookmark(game, "system", str(s_id), system_name)
					if g_id == int(game.c_g_g) and s_idx < len(game.system_data):
						game.system_data[s_idx]["name"] = system_name
						if s_idx < len(game.system_data_persistent):
							game.system_data_persistent[s_idx]["name"] = system_name

				yield_step += 1
				if yield_step % 25 == 0:
					await tree.process_frame

				var planets: Array = []
				if SaveIOScript.sols_obj_exists(game, "Systems", s_id):
					planets = SaveIOScript.load_obj(game, "Systems", s_id)
				elif s_id == int(game.c_s_g) and not game.planet_data.is_empty():
					planets = game.planet_data.duplicate(true)
				else:
					continue
				var system_dirty: bool = false

				for p_idx: int in len(planets):
					var p_i: Dictionary = planets[p_idx]
					var p_id: int = p_i.get("id", p_idx)
					var planet_name: String = p_i.get("name", "")

					if rename_planets and is_entity_eligible(p_i, config.rename_unconquered, config.rename_prev, is_default_planet_name(planet_name, p_id)):
						var pl_numeral: String = registry.get_numeral(p_idx + 1, config.use_roman) if config.planet_enumerate else ""
						var pl_prefix: String = ""
						if config.planet_append_star and not system_name.is_empty():
							var s_label: String = ""
							if not config.star_abbrev.is_empty():
								var star_num: String = registry.get_numeral(s_idx + 1, config.use_roman) if config.star_enumerate else ""
								s_label = config.star_abbrev + ("•" + star_num if not star_num.is_empty() else "")
							else:
								s_label = system_name
							pl_prefix = s_label + "•"
						planet_name = pl_prefix + config.planet_prefix + pl_numeral
						registry.register_existing_name(planet_name)
						p_i["name"] = planet_name
						system_dirty = true
						stats["planets"] += 1
						sync_bookmark(game, "planet", str(p_id), planet_name)
						if s_id == int(game.c_s_g) and p_idx < len(game.planet_data):
							game.planet_data[p_idx]["name"] = planet_name
							if p_idx < len(game.planet_data_persistent):
								game.planet_data_persistent[p_idx]["name"] = planet_name

					yield_step += 1
					if yield_step % 25 == 0:
						await tree.process_frame

				if system_dirty:
					SaveIOScript.save_obj(game, "Systems", s_id, planets)

			if galaxy_dirty:
				SaveIOScript.save_obj(game, "Galaxies", g_id, systems)

		if cluster_dirty:
			SaveIOScript.save_obj(game, "Clusters", c_id, galaxies)

	registry.save_registry(str(game.c_sv), int(game.c_u))
	if game.has_method("fn_save_game"):
		game.fn_save_game()
	sync_hud_display(game)
	is_running = false

	var toast: String = "Renamed: %d clusters, %d galaxies, %d systems, %d planets" % [stats.clusters, stats.galaxies, stats.systems, stats.planets]
	if game.has_method("popup"):
		game.popup(toast, 3.5)

func pre_populate_existing_names(game: Node, cluster_data: Array, tree: SceneTree) -> void:
	var yield_cnt: int = 0
	for c_id: int in len(cluster_data):
		registry.register_existing_name(cluster_data[c_id].get("name", ""))
		if not SaveIOScript.sols_obj_exists(game, "Clusters", c_id):
			continue
		var galaxies: Array = SaveIOScript.load_obj(game, "Clusters", c_id)
		for g_i: Dictionary in galaxies:
			registry.register_existing_name(g_i.get("name", ""))
			var g_id: int = g_i.get("id", -1)
			if g_id < 0 or not SaveIOScript.sols_obj_exists(game, "Galaxies", g_id):
				continue
			var systems: Array = SaveIOScript.load_obj(game, "Galaxies", g_id)
			for s_i: Dictionary in systems:
				registry.register_existing_name(s_i.get("name", ""))
				var s_id: int = s_i.get("id", -1)
				if s_id < 0 or not SaveIOScript.sols_obj_exists(game, "Systems", s_id):
					continue
				var planets: Array = SaveIOScript.load_obj(game, "Systems", s_id)
				for p_i: Dictionary in planets:
					registry.register_existing_name(p_i.get("name", ""))
				yield_cnt += 1
				if yield_cnt % 30 == 0:
					await tree.process_frame

func is_entity_eligible(entity: Dictionary, rename_unconquered: bool, rename_prev: bool, is_default: bool) -> bool:
	if not rename_unconquered and not entity.get("conquered", false):
		return false
	if not rename_prev and not is_default:
		return false
	return true

func is_default_cluster_name(name: String, id: int) -> bool:
	if name.is_empty() or name == tr("LOCAL_GROUP"):
		return true
	var g_group: String = tr("GALAXY_GROUP")
	var g_cluster: String = tr("GALAXY_CLUSTER")
	if name == "%s %d" % [g_group, id] or name.begins_with(g_group + " "):
		return true
	if name == "%s %d" % [g_cluster, id] or name.begins_with(g_cluster + " "):
		return true
	return name == "%s %d" % [tr("CLUSTER"), id] or name.begins_with("Cluster ")

func is_default_galaxy_name(name: String, id: int) -> bool:
	if name.is_empty() or name == tr("MILKY_WAY"):
		return true
	var g_prefix: String = tr("GALAXY")
	return name == "%s %d" % [g_prefix, id] or name.begins_with(g_prefix + " ") or name.begins_with("Galaxy ")

func is_default_system_name(name: String, id: int) -> bool:
	if name.is_empty():
		return true
	var prefixes: Array[String] = [tr("SYSTEM"), tr("BINARY_SYSTEM"), tr("TERNARY_SYSTEM"), tr("QUADRUPLE_SYSTEM"), tr("QUINTUPLE_SYSTEM"), "System"]
	for p: String in prefixes:
		if name == "%s %d" % [p, id] or name.begins_with(p + " "):
			return true
	return false

func is_default_planet_name(name: String, id: int) -> bool:
	if name.is_empty():
		return true
	var p_label: String = tr("PLANET")
	var g_label: String = tr("GAS_GIANT")
	return name == "%s %d" % [p_label, id] or name == "%s %d" % [g_label, id] or name.begins_with(p_label + " ") or name.begins_with(g_label + " ") or name.begins_with("Planet ")

func sync_bookmark(game: Node, category: String, key: String, new_name: String) -> void:
	if not game.get("bookmarks") is Dictionary:
		return
	var cat_dict: Variant = game.bookmarks.get(category, null)
	if cat_dict is Dictionary and cat_dict.has(key):
		cat_dict[key]["name"] = new_name

func sync_hud_display(game: Node) -> void:
	var hud: Node = game.get("HUD")
	if not hud:
		return
	if hud.has_method("refresh_bookmarks"):
		hud.refresh_bookmarks()
	var name_label: Label = hud.get_node_or_null("Top/Name/Name")
	if not name_label:
		return
	match str(game.c_v):
		"planet":
			if int(game.c_p) < len(game.planet_data):
				name_label.text = game.planet_data[int(game.c_p)].get("name", name_label.text)
		"system":
			if int(game.c_s) < len(game.system_data):
				name_label.text = game.system_data[int(game.c_s)].get("name", name_label.text)
		"galaxy":
			if int(game.c_g) < len(game.galaxy_data):
				name_label.text = game.galaxy_data[int(game.c_g)].get("name", name_label.text)
		"cluster":
			var clusters: Array = game.u_i.get("cluster_data", [])
			if int(game.c_c) < len(clusters):
				name_label.text = clusters[int(game.c_c)].get("name", name_label.text)
