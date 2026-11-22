// Local test servers get game debugging on by default, so runtimes show up in the Debug Log chat tab.

/client/New(TopicData)
	. = ..()
	if(QDELETED(src) || GLOB.debugging_enabled)
		return
	// Same test as the localhost admin rank, so this never turns on for remote players
	if(!CONFIG_GET(flag/enable_localhost_rank) || !is_localhost())
		return
	GLOB.debugging_enabled = TRUE
	// Sent as a debug message so it shows in the same chat tab as runtimes
	to_chat(GLOB.admins,
		type = MESSAGE_TYPE_DEBUG,
		html = span_notice("Game debugging turned ON automatically because [key_name_admin(src)] connected from localhost. Use Debug-Game to turn it off."),
		confidential = TRUE)
	log_admin("Game debugging turned ON automatically because [key_name(src)] connected from localhost.")
