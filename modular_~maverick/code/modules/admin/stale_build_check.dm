// Warns local hosts when the compiled game does not match the files on disk.
// GAGS reads its json configs and icons from disk at runtime. If the game was built before
// those files moved or were renamed, every item that uses them loses its sprite without a visible error.

/// GAGS files the build points at that are not on disk. Filled when SSgreyscale initializes.
GLOBAL_LIST_EMPTY(maverick_missing_build_files)

/datum/controller/subsystem/processing/greyscale/Initialize()
	. = ..()
	find_missing_build_files()

/// Records every GAGS json config and icon file that the build points at but that is not on disk
/datum/controller/subsystem/processing/greyscale/proc/find_missing_build_files()
	var/list/missing = list()
	for(var/greyscale_type in configurations)
		CHECK_TICK
		var/datum/greyscale_config/config = configurations[greyscale_type]
		for(var/file_path in list(config.string_json_config, config.string_icon_file))
			if(file_path && !fexists(file_path))
				missing |= file_path
	if(!length(missing))
		return
	GLOB.maverick_missing_build_files = missing
	log_world("Stale build: [length(missing)] GAGS file(s) the build points at are not on disk. First one: [missing[1]]")
	stack_trace("Stale build: [length(missing)] GAGS file(s) the build points at are not on disk, so items that use them will have no sprite. Rebuild the game. First one: [missing[1]]")

/client/New(TopicData)
	. = ..()
	if(QDELETED(src) || !holder || !length(GLOB.maverick_missing_build_files))
		return
	var/list/missing = GLOB.maverick_missing_build_files
	var/list/shown = missing.Copy(1, min(length(missing), 5) + 1)
	to_chat(src, custom_boxed_message("red_box", span_userdanger("This build is out of date.") + "<br>" + \
		span_warning("[length(missing)] GAGS file(s) the game was built with are not on disk, so items that use them will have no sprite. Rebuild the game and restart the server before you test.") + "<br>" + \
		span_notice(jointext(shown, "<br>")) + \
		(length(missing) > length(shown) ? "<br>" + span_notice("...and [length(missing) - length(shown)] more.") : "")), \
		confidential = TRUE)
