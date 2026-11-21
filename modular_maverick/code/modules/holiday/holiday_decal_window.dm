// Holiday floor colors get their own date window.
// The holiday itself (mail, hats, station name, events) keeps its full dates.
// Only the tile recolor is limited to the days set here.

/datum/holiday
	/// First day the holiday recolors floor decals. 0 means use the holiday's own dates.
	var/decal_begin_day = 0
	/// Month of decal_begin_day.
	var/decal_begin_month = 0
	/// Last day the holiday recolors floor decals.
	var/decal_end_day = 0
	/// Month of decal_end_day.
	var/decal_end_month = 0

/datum/holiday/celebrate()
	. = ..()
	if(holiday_colors && !decals_in_window())
		holiday_colors = null // Lets the next active holiday with colors take over, if any.

/// Returns TRUE if today is inside the decal window in any of this holiday's timezones.
/datum/holiday/proc/decals_in_window()
	if(always_celebrate || !decal_begin_month)
		return TRUE
	var/start = decal_begin_month * 100 + decal_begin_day
	var/finish = (decal_end_month || decal_begin_month) * 100 + (decal_end_day || decal_begin_day)
	for(var/timezone in timezones)
		var/time_in_timezone = world.realtime + timezone HOURS
		var/today = text2num(time2text(time_in_timezone, "MM", world.timezone)) * 100 + text2num(time2text(time_in_timezone, "DD", world.timezone))
		if(start <= finish)
			if(today >= start && today <= finish)
				return TRUE
		else if(today >= start || today <= finish) // Window wraps over the new year.
			return TRUE
	return FALSE

// Holiday runs all June. Tiles only for the week around Stonewall.
/datum/holiday/pride_week
	decal_begin_month = JUNE
	decal_begin_day = 23
	decal_end_month = JUNE
	decal_end_day = 29

// Holiday runs Oct 1 to Nov 2. Tiles only for the last week.
/datum/holiday/halloween
	decal_begin_month = OCTOBER
	decal_begin_day = 27
	decal_end_month = NOVEMBER
	decal_end_day = 2

// Holiday runs Dec 18 to 27. Tiles only for the week around Christmas.
/datum/holiday/xmas
	decal_begin_month = DECEMBER
	decal_begin_day = 21
	decal_end_month = DECEMBER
	decal_end_day = 27

// Red and gold on every tile reads as a fast food chain. Holiday stays, tiles do not.
/datum/holiday/october_revolution
	holiday_colors = null
