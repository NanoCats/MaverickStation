// Lets the Maverick config switch off automapper templates by name, without touching the upstream TOML.
// Template names are the [templates.<name>] keys in _maps/bubber/automapper/automapper_config.toml.

/// Automapper templates that never load, by template name
/datum/config_entry/keyed_list/maverick_automapper_disabled
	key_mode = KEY_MODE_TEXT
	value_mode = VALUE_MODE_FLAG

/datum/controller/subsystem/automapper/preload_templates_from_toml(map_names)
	. = ..()
	var/list/disabled = CONFIG_GET(keyed_list/maverick_automapper_disabled)
	if(!length(disabled))
		return
	for(var/datum/map_template/automap_template/template as anything in preloaded_map_templates)
		if(!(template.name in disabled))
			continue
		preloaded_map_templates -= template
		log_world("AUTOMAPPER: Skipped template [template.name], switched off in the Maverick config.")
