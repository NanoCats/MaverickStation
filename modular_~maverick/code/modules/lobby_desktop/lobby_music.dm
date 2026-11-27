/// How many played tracks SpaceAmp remembers per player.
#define MAVERICK_MUSIC_HISTORY_MAX 20
/// Shuffle avoids this many of the most recently played tracks when it can.
#define MAVERICK_MUSIC_SHUFFLE_AVOID 5

/// Display names for tracks we know the real title of. Anything else shows its file name.
GLOBAL_LIST_INIT(maverick_track_names, list(
	"sound/music/lobby_music/title0.ogg" = "Endless Space - Solus",
	"sound/music/lobby_music/title1.mod" = "Flip-flap - X-Ceed",
	"sound/music/lobby_music/title2.ogg" = "Robocop Theme (gameboy) - Eric Schumacker",
	"sound/music/lobby_music/title3.ogg" = "Tintin On The Moon - Cuboos",
	// Admiral Hippie's remix of Cboyardee's remix of the original by Jonathan Dunn
	"sound/music/lobby_music/clown.ogg" = "Clown.wmv - Admiral Hippie",
))

/// Every lobby track SpaceAmp can play, as file paths.
GLOBAL_LIST_EMPTY(maverick_lobby_tracks)
/// Each player's last track this round, by ckey, so reconnecting keeps it.
GLOBAL_LIST_EMPTY(maverick_music_round_tracks)
/// Rolls alert-limited tracks for lobby players when the station alert level changes.
GLOBAL_DATUM(maverick_lobby_alert_listener, /datum/maverick_lobby_alert_listener)

/client
	/// Track this player picked in SpaceAmp. Null means the round's lobby track.
	var/maverick_music_track
	/// The round lobby track at the time the player picked theirs. If an admin changes it, the pick resets.
	var/maverick_music_base
	/// The player pressed stop.
	var/maverick_music_stopped = FALSE
	/// The player pressed pause.
	var/maverick_music_paused = FALSE
	/// world.time the current track would have started at, if it had played from the top without pauses.
	var/maverick_music_started
	/// world.time the track was paused at.
	var/maverick_music_paused_at
	/// Whether we already picked this session's first track from the player's clock.
	var/maverick_music_greeted = FALSE
	/// The player's clock when the lobby first loaded: list(minute of day, month * 100 + day, world.realtime then).
	var/list/maverick_music_clock
	/// The player picked a track themselves, so alert changes leave their music alone.
	var/maverick_music_manual = FALSE
	/// The first track of this session is picked. It happens once, as soon as the page sends the player's clock.
	var/maverick_music_picked = FALSE
	/// A track was actually sent to the player this session. Until then, raising the volume has nothing to turn up.
	var/maverick_music_sent = FALSE
	/// Tracks this player heard this session, oldest first. Shuffle skips the recent ones; previous walks back through it.
	var/list/maverick_music_history = list()

/**
 * Same pool the round's lobby track is picked from: common config tracks plus this map's tracks.
 * With no config tracks at all, the stock list. Stock tracks marked "include" in names.txt join a config pool.
 */
/proc/maverick_lobby_tracks()
	var/list/tracks = GLOB.maverick_lobby_tracks
	if(length(tracks) && (!SSticker.login_music || (SSticker.login_music in tracks)))
		return tracks

	tracks = list()
	var/music_dir = "[global.config.directory]/title_music/sounds/"
	var/map_name = LOWER_TEXT(SSmapping.current_map?.map_name)
	for(var/file in flist(music_dir))
		if(!IS_SOUND_FILE("[music_dir][file]"))
			continue
		var/list/name_parts = splittext(LOWER_TEXT(file), "+")
		switch(length(name_parts))
			if(1)
				if(name_parts[1] != "exclude")
					tracks += "[music_dir][file]"
			if(2)
				// map tracks for this map are fair game; rare ones stay a surprise
				if(name_parts[1] == map_name)
					tracks += "[music_dir][file]"
	var/have_own_music = length(tracks) > 0
	for(var/line in world.file2list("strings/round_start_sounds.txt"))
		line = trim(line)
		if(!line || !IS_SOUND_FILE(line))
			continue
		// your own music pushes the stock tracks out, unless names.txt brings one back
		if(have_own_music && !maverick_track_entry(line)?["rules"]?["include"])
			continue
		tracks += line
	if(SSticker.login_music && !(SSticker.login_music in tracks))
		tracks.Insert(1, SSticker.login_music)

	GLOB.maverick_lobby_tracks = tracks
	if(!GLOB.maverick_lobby_alert_listener)
		GLOB.maverick_lobby_alert_listener = new
	return tracks

/**
 * The round's main lobby track (the one everyone hears on login) must be a regular track.
 * The stock picker knows nothing about names.txt, so it can land on a track that only belongs
 * on red alert or on a holiday. Re-pick from the tracks without rules when that happens.
 */
/datum/controller/subsystem/ticker/Initialize()
	. = ..()
	maverick_regular_login_music()

/datum/controller/subsystem/ticker/proc/maverick_regular_login_music()
	if(!login_music || !maverick_track_window(login_music))
		return
	var/list/regular = list()
	for(var/track in maverick_lobby_tracks())
		if(!maverick_track_window(track))
			regular += track
	if(length(regular))
		login_music = pick(regular)
		GLOB.maverick_lobby_tracks = list() // rebuild around the new main track

/// Chance a special track wins when its rules match and the line gives no chance=.
#define TRACK_RULE_DEFAULT_CHANCE 50

/**
 * Lines from config/title_music/names.txt, keyed by lowercase file name.
 *
 * Format: "file name : Display Name | rule | rule". The file name can have its
 * extension or not, and case does not matter. Lines starting with # are skipped.
 * Each entry is list("name" = display name, "rules" = list of parsed rules).
 *
 * names_local.txt in the same folder is read after names.txt, and its lines win.
 * It is gitignored, so a server can keep its own tracks out of the repo.
 */
/proc/maverick_track_entries()
	var/static/list/entries
	if(entries)
		return entries
	entries = list()
	var/list/known_files = maverick_known_music_files()
	for(var/file_name in list("names.txt", "names_local.txt"))
		var/names_file = "[global.config.directory]/title_music/[file_name]"
		if(!fexists(names_file))
			continue
		var/list/problems = maverick_read_track_file(names_file, entries, known_files)
		for(var/problem in problems)
			log_config("title_music/[file_name] [problem]")
		if(length(problems))
			message_admins("title_music/[file_name] has [length(problems)] problem\s. Details are in the config log.")
	return entries

/**
 * Reads one track names file into entries. A line for a file name that is
 * already in entries replaces it, so later files override earlier ones.
 * Returns a list of problems found, for the config log.
 */
/proc/maverick_read_track_file(names_file, list/entries, list/known_files)
	var/list/problems = list()
	var/list/seen_here = list()
	var/line_number = 0
	for(var/line in world.file2list(names_file))
		line_number++
		line = trim(line)
		if(!line || line[1] == "#")
			continue
		var/list/segments = splittext(line, "|")
		var/head = segments[1]
		var/split = findtext(head, ":")
		if(!split)
			problems += "line [line_number]: no \":\" between the file name and the display name"
			continue
		var/key = LOWER_TEXT(trim(copytext(head, 1, split)))
		var/display = trim(copytext(head, split + 1))
		if(!key)
			problems += "line [line_number]: no file name before the \":\""
			continue
		if(!display)
			problems += "line [line_number]: no display name after the \":\""
		if(!(key in known_files))
			problems += "line [line_number]: \"[key]\" matches no lobby music file"
		if(seen_here[key])
			problems += "line [line_number]: \"[key]\" is listed twice, the later line wins"
		seen_here[key] = TRUE
		var/list/rules = list()
		for(var/i in 2 to length(segments))
			var/problem = maverick_parse_track_rule(trim(segments[i]), rules)
			if(problem)
				problems += "line [line_number]: [problem]"
		if(rules["exclusive"] && !(rules["time"] || rules["date"] || rules["holiday"] || rules["alert"]))
			problems += "line [line_number]: exclusive needs a time, date, holiday or alert rule, or it would take over every lobby"
		entries[key] = list("name" = display, "rules" = rules)
	return problems

/// Lowercase names of every lobby music file, with and without extensions, for spotting typos in names.txt.
/proc/maverick_known_music_files()
	var/list/known = list()
	var/list/paths = list()
	for(var/file in flist("[global.config.directory]/title_music/sounds/"))
		paths += file
	for(var/line in world.file2list("strings/round_start_sounds.txt"))
		if(trim(line))
			paths += trim(line)
	for(var/path in paths)
		var/list/parts = splittext(path, "/")
		var/file = LOWER_TEXT(parts[length(parts)])
		known[file] = TRUE
		var/dot = findlasttext(file, ".")
		if(dot > 1)
			known[copytext(file, 1, dot)] = TRUE
	return known

/// Reads one "key=value" rule (or the "hidden", "include" or "exclusive" flag) into rules. Returns a problem description if it can't.
/proc/maverick_parse_track_rule(rule, list/rules)
	if(!rule)
		return "empty rule between two \"|\""
	var/split = findtext(rule, "=")
	if(!split)
		// hidden : keep the track out of the playlist while its rules don't match
		// include : bring a stock track back when the server has its own music
		// exclusive : while its rules match, only matching exclusive tracks play or show. Hidden otherwise.
		var/flag = LOWER_TEXT(rule)
		if(flag == "hidden" || flag == "include" || flag == "exclusive")
			rules[flag] = TRUE
			return null
		return "\"[rule]\" is not a rule (rules look like key=value, or the word hidden, include or exclusive)"
	var/key = LOWER_TEXT(trim(copytext(rule, 1, split)))
	var/value = trim(copytext(rule, split + 1))
	switch(key)
		// time=22-5 : from 22:00 up to 05:00, on the player's clock
		if("time")
			var/list/hours = splittext(value, "-")
			var/start = length(hours) == 2 ? text2num(hours[1]) : null
			var/finish = length(hours) == 2 ? text2num(hours[2]) : null
			if(!isnum(start) || !isnum(finish) || start < 0 || start > 24 || finish < 0 || finish > 24)
				return "\"time=[value]\" should be two hours from 0 to 24, like time=22-5"
			rules["time"] = list(start % 24, finish % 24)
		// date=08-01..08-07 or date=10-31 : month-day, both ends included, on the player's calendar
		if("date")
			var/list/ends = splittext(value, "..")
			var/first = maverick_parse_month_day(ends[1])
			var/last = length(ends) > 1 ? maverick_parse_month_day(ends[2]) : first
			if(!first || !last || length(ends) > 2)
				return "\"date=[value]\" should be month-day, like date=10-31 or date=08-01..08-07"
			rules["date"] = list(first, last)
		// holiday=Halloween : any holiday the game itself celebrates today
		if("holiday")
			if(!value)
				return "holiday= needs a holiday name"
			var/known = FALSE
			for(var/datum/holiday/holiday_type as anything in subtypesof(/datum/holiday))
				if(LOWER_TEXT(initial(holiday_type.name)) == LOWER_TEXT(value))
					known = TRUE
					break
			if(!known)
				return "\"[value]\" is not a holiday the game knows"
			rules["holiday"] = LOWER_TEXT(value)
		// alert=red or alert=red,delta : only while the station is at one of these alert levels
		// alert=amber+ : amber or any level ranked above it
		if("alert")
			var/list/known_levels = list() // name = rank
			for(var/datum/security_level/level_type as anything in subtypesof(/datum/security_level))
				known_levels[initial(level_type.name)] = initial(level_type.number_level)
			var/list/levels = list()
			for(var/level in splittext(LOWER_TEXT(value), ","))
				level = trim(level)
				if(!level)
					continue
				var/or_above = copytext(level, length(level)) == "+"
				if(or_above)
					level = trim(copytext(level, 1, length(level)))
				if(!(level in known_levels))
					return "\"[level]\" is not an alert level (known: [jointext(known_levels, ", ")])"
				if(!or_above)
					levels |= level
					continue
				for(var/other in known_levels)
					if(known_levels[other] >= known_levels[level])
						levels |= other
			if(!length(levels))
				return "alert= needs at least one alert level"
			rules["alert"] = levels
		// chance=25 : percent chance to win when the other rules match
		if("chance")
			var/chance = text2num(value)
			if(!isnum(chance) || chance < 0 || chance > 100)
				return "\"chance=[value]\" should be a number from 0 to 100"
			rules["chance"] = chance
		else
			return "unknown rule \"[key]\" (known: time, date, holiday, alert, chance, hidden, include, exclusive)"
	return null

/// "08-01" becomes 801, so dates compare as plain numbers. Null if it is not a date.
/proc/maverick_parse_month_day(text)
	var/list/parts = splittext(trim(text), "-")
	if(length(parts) != 2)
		return null
	var/month = text2num(parts[1])
	var/day = text2num(parts[2])
	if(!isnum(month) || !isnum(day) || month < 1 || month > 12 || day < 1 || day > 31)
		return null
	return month * 100 + day

/proc/maverick_track_entry(path)
	var/list/parts = splittext(path, "/")
	var/file = LOWER_TEXT(parts[length(parts)])
	var/base = file
	var/dot = findlasttext(base, ".")
	if(dot > 1)
		base = copytext(base, 1, dot)
	var/list/entries = maverick_track_entries()
	return entries[file] || entries[base]

/proc/maverick_track_name(path)
	var/name = maverick_track_base_name(path)
	// Like any media player: no artist on record means "Unknown Artist".
	if(!findtext(name, " - "))
		name += " - Unknown Artist"
	return name

/// The track's name from names.txt, the stock list, or its file name, without the artist fallback.
/proc/maverick_track_base_name(path)
	var/list/entry = maverick_track_entry(path)
	if(entry?["name"])
		return entry["name"]
	if(GLOB.maverick_track_names[path])
		return GLOB.maverick_track_names[path]

	// drop the "rare+" / "MapName+" sorting prefix the title music folder uses
	var/list/parts = splittext(path, "/")
	var/base = parts[length(parts)]
	var/dot = findlasttext(base, ".")
	if(dot > 1)
		base = copytext(base, 1, dot)
	var/list/sort_parts = splittext(base, "+")
	return replacetext(sort_parts[length(sort_parts)], "_", " ")

/// Rules that limit when a track may auto-play. Null for regular tracks.
/proc/maverick_track_window(path)
	var/list/rules = maverick_track_entry(path)?["rules"]
	if(!rules || !(rules["time"] || rules["date"] || rules["holiday"] || rules["alert"]))
		return null
	return rules

/// TRUE when every rule in the window matches. hour and month_day are the player's, null if unknown.
/proc/maverick_track_window_open(list/rules, hour, month_day)
	if(rules["time"])
		if(isnull(hour))
			return FALSE
		var/list/hours = rules["time"]
		var/start = hours[1]
		var/finish = hours[2]
		if(start < finish)
			if(hour < start || hour >= finish)
				return FALSE
		else if(start > finish)
			if(hour < start && hour >= finish)
				return FALSE
	if(rules["date"])
		if(isnull(month_day))
			return FALSE
		var/list/dates = rules["date"]
		var/first = dates[1]
		var/last = dates[2]
		if(first <= last)
			if(month_day < first || month_day > last)
				return FALSE
		else if(month_day < first && month_day > last)
			return FALSE
	if(rules["holiday"])
		var/found = FALSE
		for(var/holiday_name in GLOB.holidays)
			if(LOWER_TEXT(holiday_name) == rules["holiday"])
				found = TRUE
				break
		if(!found)
			return FALSE
	if(rules["alert"])
		var/list/levels = rules["alert"]
		if(!(SSsecurity_level.get_current_level_as_text() in levels))
			return FALSE
	return TRUE

/// The player's clock right now, worked out from what the lobby told us: list(hour, month * 100 + day).
/client/proc/maverick_player_clock()
	if(!maverick_music_clock)
		return list(null, null)
	var/minutes = maverick_music_clock[1] + round((world.realtime - maverick_music_clock[3]) / (1 MINUTES))
	return list(round(minutes / 60) % 24, maverick_music_clock[2])

/// TRUE if the track has no rules, or all its rules match for this player now.
/client/proc/maverick_track_open(track)
	var/list/rules = maverick_track_window(track)
	if(!rules)
		return TRUE
	var/list/clock = maverick_player_clock()
	return maverick_track_window_open(rules, clock[1], clock[2])

/// Exclusive tracks whose rules match for this player now. While any exist, nothing else plays.
/client/proc/maverick_open_exclusive_tracks()
	var/list/open = list()
	for(var/track in maverick_lobby_tracks())
		var/list/rules = maverick_track_window(track)
		if(rules?["exclusive"] && maverick_track_open(track))
			open += track
	return open

/**
 * The tracks this player sees in SpaceAmp. While an exclusive track is open, only the open
 * exclusive tracks. Otherwise everything except hidden or exclusive tracks whose rules don't match.
 */
/client/proc/maverick_visible_tracks()
	var/list/exclusive = maverick_open_exclusive_tracks()
	if(length(exclusive))
		return exclusive
	var/current = maverick_current_track()
	var/list/visible = list()
	for(var/track in maverick_lobby_tracks())
		var/list/rules = maverick_track_window(track)
		if((rules?["hidden"] || rules?["exclusive"]) && track != current && !maverick_track_open(track))
			continue
		visible += track
	return visible

/// Rolls special tracks from candidates. Returns the first winner, or null.
/client/proc/maverick_roll_special_tracks(list/candidates)
	for(var/track in shuffle(candidates))
		var/list/rules = maverick_track_window(track)
		var/chance = isnull(rules["chance"]) ? TRACK_RULE_DEFAULT_CHANCE : rules["chance"]
		if(prob(chance))
			return track
	return null

/// Whether we may start a track on our own for this player right now.
/client/proc/maverick_music_may_autoplay()
	if(CONFIG_GET(flag/disallow_title_music) || maverick_music_stopped)
		return FALSE
	return !!prefs?.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)

/**
 * Picks this player's first lobby track from their own clock, without playing it.
 *
 * Special tracks whose rules match get a roll each. If none wins and the
 * round's track is special but outside its window for this player, they get
 * a regular track instead. Runs once per session, as soon as the lobby page loads,
 * so SpaceAmp shows the right track before the desktop appears.
 */
/client/proc/maverick_music_pick(hour, minute, month, day)
	if(maverick_music_picked)
		return
	maverick_music_picked = TRUE
	if(isnum(hour) && isnum(minute) && isnum(month) && isnum(day))
		maverick_music_clock = list(clamp(hour, 0, 23) * 60 + clamp(minute, 0, 59), month * 100 + day, world.realtime)
	var/choice = maverick_music_kept_track() || maverick_music_first_track()
	if(choice && choice != SSticker.login_music)
		maverick_music_track = choice
		maverick_music_base = SSticker.login_music
	maverick_music_push()

/// The track this player last had this round, if it can still play for them. Null otherwise.
/client/proc/maverick_music_kept_track()
	var/list/kept = GLOB.maverick_music_round_tracks[ckey]
	if(!kept || kept[2] != SSticker.login_music)
		return null // an admin changed the round's track since
	var/track = kept[1]
	if(!(track in maverick_lobby_tracks()))
		return null
	var/list/exclusive = maverick_open_exclusive_tracks()
	if(length(exclusive) ? !(track in exclusive) : !maverick_track_open(track))
		return null
	return track

/client/proc/maverick_music_first_track()
	var/current = maverick_current_track()
	var/list/exclusive = maverick_open_exclusive_tracks()
	if(length(exclusive))
		return (current in exclusive) ? current : pick(exclusive)

	var/list/open_specials = list()
	var/list/regulars = list()
	for(var/track in maverick_lobby_tracks())
		if(!maverick_track_window(track))
			regulars += track
		else if(maverick_track_open(track))
			open_specials += track
	var/special = maverick_roll_special_tracks(open_specials)
	if(special)
		return special

	if(current && !maverick_track_open(current) && length(regulars))
		return pick(regulars)
	return current

/// The desktop is up: start the picked track. Runs once per session.
/client/proc/maverick_music_hello(hour, minute, month, day)
	if(maverick_music_greeted)
		return
	maverick_music_greeted = TRUE
	maverick_music_pick(hour, minute, month, day)
	if(!maverick_music_may_autoplay())
		maverick_music_push()
		return
	// Nothing plays before this point (see playtitlemusic below).
	maverick_music_play(maverick_current_track())

/**
 * With the desktop lobby on, the stock lobby music waits for the desktop: nothing plays on login
 * until the page loads and says hello. After that, anything that would restart the stock track
 * (coming back to the lobby, changing the lobby volume, an admin changing the lobby song)
 * replays SpaceAmp's own track instead, so the two stay in sync.
 */
/client/playtitlemusic(volume_multiplier = 1)
	if(!CONFIG_GET(flag/maverick_lobby_desktop) || !isnewplayer(mob))
		return ..()
	if(!maverick_music_greeted)
		return
	if(!maverick_music_may_autoplay())
		SEND_SOUND(src, sound(null, channel = CHANNEL_LOBBYMUSIC))
		return
	maverick_music_play(maverick_current_track())

/**
 * The station alert changed. An exclusive track that just opened takes over, even over the player's own pick,
 * since their pick is no longer in the playlist. Otherwise alert-limited tracks get a roll, unless the player picked their own music.
 */
/client/proc/maverick_music_alert_changed()
	if(!isnewplayer(mob))
		return
	var/list/exclusive = maverick_open_exclusive_tracks()
	if(length(exclusive) && maverick_music_may_autoplay())
		if(!(maverick_current_track() in exclusive))
			maverick_music_play(pick(exclusive))
			return
	else if(!maverick_music_manual && maverick_music_may_autoplay())
		var/current = maverick_current_track()
		var/list/candidates = list()
		for(var/track in maverick_lobby_tracks())
			var/list/rules = maverick_track_window(track)
			if(rules?["alert"] && track != current && maverick_track_open(track))
				candidates += track
		var/won = maverick_roll_special_tracks(candidates)
		if(won)
			maverick_music_play(won)
			return
	// the playlist may have gained or lost hidden alert tracks
	maverick_music_push()

/datum/maverick_lobby_alert_listener/New()
	. = ..()
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(on_alert_changed))

/datum/maverick_lobby_alert_listener/proc/on_alert_changed(datum/source, level)
	SIGNAL_HANDLER
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.client)
			INVOKE_ASYNC(player.client, TYPE_PROC_REF(/client, maverick_music_alert_changed))

#undef TRACK_RULE_DEFAULT_CHANCE

/// Length in seconds, or 0 when we can't tell (tracker formats like .mod).
/proc/maverick_track_length(path)
	var/static/list/measurable = list("ogg", "wav", "mp3")
	var/list/parts = splittext(path, ".")
	if(!(LOWER_TEXT(parts[length(parts)]) in measurable))
		return 0
	return round(rustg_sound_length(path) / 10)

/client/proc/maverick_current_track()
	if(maverick_music_track && maverick_music_base == SSticker.login_music)
		return maverick_music_track
	return SSticker.login_music

/client/proc/maverick_music_state()
	var/list/tracks = maverick_visible_tracks()
	var/current = maverick_current_track()
	var/list/titles = list()
	for(var/track in tracks)
		titles += list(list("title" = maverick_track_name(track)))
	var/enabled = !CONFIG_GET(flag/disallow_title_music) && length(tracks)
	var/volume = prefs?.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	// Once a track is going, it keeps going at 0%. Before that, 0% means lobby music is off.
	var/playing = enabled && !maverick_music_stopped && (volume > 0 || maverick_music_sent)
	// Nothing plays until the desktop says hello (after the boot screen and the startup
	// sound), so until then the track sits at 0:00. Starting the clock any earlier made
	// SpaceAmp open partway into the song, then jump back to the start.
	var/elapsed = 0
	if(maverick_music_greeted)
		if(isnull(maverick_music_started))
			maverick_music_started = world.time
		elapsed = ((maverick_music_paused ? maverick_music_paused_at : world.time) - maverick_music_started) / 10
	return list(
		"enabled" = enabled,
		"tracks" = titles,
		"index" = max(0, tracks.Find(current) - 1),
		"playing" = playing,
		"paused" = playing && maverick_music_paused,
		"vol" = volume,
		"len" = current ? maverick_track_length(current) : 0,
		"elapsed" = elapsed,
		"offset" = elapsed,
		"needs_hello" = !maverick_music_greeted,
		"shuffle" = maverick_music_shuffle_on(),
	)

/// Sends SpaceAmp the new state. started tells it the track changed.
/client/proc/maverick_music_push(started = FALSE)
	var/list/state = maverick_music_state()
	if(started)
		state["started"] = TRUE
	src << output(url_encode(json_encode(state)), "title_browser:music_state")

/**
 * Starts a track for this player. At 0% volume it plays silently, like any music player.
 * wake: the player pressed play. At 0% that means "I want music", so the volume goes to 50%.
 */
/client/proc/maverick_music_play(path, offset = 0, wake = FALSE)
	if(!path || CONFIG_GET(flag/disallow_title_music))
		return
	var/datum/preference/volume_pref = GLOB.preference_entries[/datum/preference/numeric/volume/sound_lobby_volume]
	var/volume = prefs.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	if(!volume && wake)
		// Pressing play with the volume at zero means "I want music". Don't restart it through the pref's own hook.
		volume = 50
		prefs.write_preference(volume_pref, volume)
		prefs.save_preferences() // write_preference only changes the copy in memory
	var/sound/music = sound(path, repeat = 0, wait = 0, volume = volume, channel = CHANNEL_LOBBYMUSIC)
	music.offset = offset
	music.environment = LOBBY_DESKTOP_DRY_ENVIRONMENT // no leftover echo from the round
	SEND_SOUND(src, music)
	maverick_music_sent = TRUE
	GLOB.maverick_music_round_tracks[ckey] = list(path, SSticker.login_music)
	maverick_music_track = path
	maverick_music_base = SSticker.login_music
	maverick_music_stopped = FALSE
	if(!length(maverick_music_history) || maverick_music_history[length(maverick_music_history)] != path)
		maverick_music_history += path
		if(length(maverick_music_history) > MAVERICK_MUSIC_HISTORY_MAX)
			maverick_music_history.Cut(1, 2)
	maverick_music_paused = FALSE
	maverick_music_started = world.time - offset * 10
	maverick_music_push(started = TRUE)

/client/proc/maverick_music_command(command, list/href_list)
	if(!isnewplayer(mob))
		return
	var/list/tracks = maverick_visible_tracks()
	if(!length(tracks))
		return
	var/current = maverick_current_track()
	// 0 when the current track is not in the playlist, which happens while an exclusive track is open
	var/index = tracks.Find(current)
	var/next_track = tracks[(index % length(tracks)) + 1]
	switch(command)
		if("clock")
			maverick_music_pick(text2num(href_list["hour"]), text2num(href_list["minute"]), text2num(href_list["month"]), text2num(href_list["day"]))
		if("hello")
			maverick_music_hello(text2num(href_list["hour"]), text2num(href_list["minute"]), text2num(href_list["month"]), text2num(href_list["day"]))
		if("play")
			maverick_music_play(index ? current : next_track, wake = TRUE)
		if("pause")
			if(maverick_music_stopped || maverick_music_paused)
				return
			// an update without a volume resets the channel to full volume, so always send it
			var/sound/pause = sound(null, repeat = 0, wait = 0, volume = prefs.read_preference(/datum/preference/numeric/volume/sound_lobby_volume), channel = CHANNEL_LOBBYMUSIC)
			pause.status = SOUND_PAUSED | SOUND_UPDATE
			SEND_SOUND(src, pause)
			maverick_music_paused = TRUE
			maverick_music_paused_at = world.time
			maverick_music_push()
		if("resume")
			if(!maverick_music_paused)
				return
			var/sound/resume = sound(null, repeat = 0, wait = 0, volume = prefs.read_preference(/datum/preference/numeric/volume/sound_lobby_volume), channel = CHANNEL_LOBBYMUSIC)
			resume.status = SOUND_UPDATE
			SEND_SOUND(src, resume)
			maverick_music_started += world.time - maverick_music_paused_at
			maverick_music_paused = FALSE
			maverick_music_push()
		if("stop")
			mob.stop_sound_channel(CHANNEL_LOBBYMUSIC)
			maverick_music_stopped = TRUE
			maverick_music_paused = FALSE
			maverick_music_push()
		if("next")
			maverick_music_manual = TRUE
			maverick_music_play(maverick_music_shuffle_on() ? maverick_music_shuffle_pick(tracks, current) : next_track)
		if("prev")
			maverick_music_manual = TRUE
			var/previous = maverick_music_shuffle_on() ? maverick_music_previous(tracks, current) : null
			maverick_music_play(previous || (index ? tracks[((index - 2 + length(tracks)) % length(tracks)) + 1] : tracks[length(tracks)]))
		if("shuffle")
			var/datum/preference/shuffle_pref = GLOB.preference_entries[/datum/preference/toggle/maverick_lobby_shuffle]
			prefs.write_preference(shuffle_pref, !maverick_music_shuffle_on())
			prefs.save_preferences() // write_preference only changes the copy in memory
			maverick_music_push()
		if("track")
			var/pick = text2num(href_list["track"])
			if(isnum(pick) && pick >= 1 && pick <= length(tracks))
				maverick_music_manual = TRUE
				maverick_music_play(tracks[pick])
		if("seek")
			var/position = text2num(href_list["pos"])
			var/track_length = maverick_track_length(current)
			if(isnum(position) && track_length)
				maverick_music_play(current, clamp(round(position), 0, track_length - 1))
		if("vol")
			var/volume = text2num(href_list["vol"])
			if(!isnum(volume))
				return
			volume = clamp(round(volume), 0, 100)
			prefs.write_preference(GLOB.preference_entries[/datum/preference/numeric/volume/sound_lobby_volume], volume)
			prefs.save_preferences() // write_preference only changes the copy in memory
			// Nothing has played yet (the volume was 0 when the desktop came up), so there is
			// nothing to turn up. Start the track instead.
			if(volume && !maverick_music_sent && maverick_music_greeted && !maverick_music_stopped)
				maverick_music_play(current)
				return
			mob.set_sound_channel_volume(CHANNEL_LOBBYMUSIC, volume)
			maverick_music_push()
		if("ended")
			switch(href_list["repeat"])
				if("one")
					maverick_music_play(index ? current : next_track)
				if("all")
					maverick_music_play(maverick_music_shuffle_on() ? maverick_music_shuffle_pick(tracks, current) : next_track)
				else
					maverick_music_stopped = TRUE
					maverick_music_push()

/// Whether this player has shuffle on. On by default.
/client/proc/maverick_music_shuffle_on()
	return !!prefs?.read_preference(/datum/preference/toggle/maverick_lobby_shuffle)

/// A random track from the playlist, skipping the current one and the last few played when it can.
/client/proc/maverick_music_shuffle_pick(list/tracks, current)
	var/list/recent = maverick_music_history.Copy(max(1, length(maverick_music_history) - MAVERICK_MUSIC_SHUFFLE_AVOID + 1))
	var/list/candidates = tracks - current - recent
	if(!length(candidates))
		candidates = tracks - current
	if(!length(candidates))
		candidates = tracks
	return pick(candidates)

/// The track played before this one, if it can still play. Steps the history back so pressing previous again keeps going.
/client/proc/maverick_music_previous(list/tracks, current)
	for(var/i in length(maverick_music_history) - 1 to 1 step -1)
		var/track = maverick_music_history[i]
		if(track == current || !(track in tracks))
			continue
		maverick_music_history.Cut(i)
		return track
	return null

/datum/preference/toggle/maverick_lobby_shuffle
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "maverick_lobby_shuffle"
	savefile_identifier = PREFERENCE_PLAYER
	default_value = TRUE

#undef MAVERICK_MUSIC_HISTORY_MAX
#undef MAVERICK_MUSIC_SHUFFLE_AVOID
