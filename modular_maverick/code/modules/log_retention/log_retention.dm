/// Round logs and player-linked database history older than this many days are deleted at server start.
/datum/config_entry/number/log_retention_days
	default = 90
	integer = TRUE
	min_val = 1

/// Writes PDA messages to a separate log meant for public release. Off by default, because we do not publish logs.
/datum/config_entry/flag/public_logging

/**
 * Deletes old round logs and player-linked database history once per server start.
 *
 * The privacy policy promises LOG_RETENTION_DAYS, and this is what keeps that promise.
 * Ban records, admin notes, characters and preferences are not touched.
 */
SUBSYSTEM_DEF(log_retention)
	name = "Log Retention"
	ss_flags = SS_NO_FIRE

/datum/controller/subsystem/log_retention/Initialize()
	INVOKE_ASYNC(src, PROC_REF(purge_old_history))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/log_retention/proc/purge_old_history()
	var/days = CONFIG_GET(number/log_retention_days)
	// Log folders are named by UTC date, so the cutoff is a UTC date too.
	var/cutoff = text2num(time2text(world.realtime - (days DAYS), "YYYYMMDD", TIMEZONE_UTC))
	var/deleted = 0
	for(var/root in list("data/logs/", "data/picture_logs/", "data/public/logs/"))
		deleted += purge_log_folders(root, cutoff)
	if(deleted)
		log_world("Log retention: deleted [deleted] day folder\s of logs older than [days] days.")
	purge_database(days)

/// Deletes day folders under root (laid out as YYYY/MM/DD/) dated before cutoff (YYYYMMDD). Returns how many were deleted.
/datum/controller/subsystem/log_retention/proc/purge_log_folders(root, cutoff)
	. = 0
	var/static/regex/number_folder = regex(@"^\d+/$")
	for(var/year in flist(root))
		if(!number_folder.Find(year))
			continue
		for(var/month in flist("[root][year]"))
			if(!number_folder.Find(month))
				continue
			for(var/day in flist("[root][year][month]"))
				if(!number_folder.Find(day))
					continue
				var/folder_date = replacetext("[year][month][day]", "/", "")
				if(length(folder_date) != 8 || text2num(folder_date) >= cutoff)
					continue
				fdel("[root][year][month][day]")
				.++

/// Deletes player-linked history rows older than the retention window.
/datum/controller/subsystem/log_retention/proc/purge_database(days)
	if(!SSdbcore.IsConnected())
		return
	var/list/statements = list(
		"DELETE FROM [format_table_name("connection_log")] WHERE datetime < NOW() - INTERVAL :days DAY",
		"DELETE FROM [format_table_name("game_log")] WHERE datetime < NOW() - INTERVAL :days DAY",
		"DELETE FROM [format_table_name("death")] WHERE tod < NOW() - INTERVAL :days DAY",
		"DELETE FROM [format_table_name("manifest")] WHERE timestamp < NOW() - INTERVAL :days DAY",
		"DELETE telemetry FROM [format_table_name("telemetry_connections")] AS telemetry \
			JOIN [format_table_name("round")] AS round_data ON round_data.id = telemetry.latest_round_id \
			WHERE round_data.initialize_datetime < NOW() - INTERVAL :days DAY",
	)
	for(var/statement in statements)
		var/datum/db_query/query = SSdbcore.NewQuery(statement, list("days" = days))
		query.warn_execute()
		qdel(query)
