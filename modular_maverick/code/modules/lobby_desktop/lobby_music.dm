/// Display names for tracks we know the real title of. Anything else shows its file name.
GLOBAL_LIST_INIT(maverick_track_names, list(
	"sound/music/lobby_music/title0.ogg" = "Endless Space - Solus",
	"sound/music/lobby_music/title1.mod" = "Flip-flap - X-Ceed",
	"sound/music/lobby_music/title2.ogg" = "Robocop Theme (gameboy) - Eric Schumacker",
	"sound/music/lobby_music/title3.ogg" = "Tintin On The Moon - Cuboos",
	"sound/music/lobby_music/clown.ogg" = "clown.ogg (you know what this is)",
))

/// Every lobby track SpaceAmp can play, as file paths.
GLOBAL_LIST_EMPTY(maverick_lobby_tracks)

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

/// Same pool the round's lobby track is picked from: common config tracks plus this map's tracks, else the stock list.
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
	if(!length(tracks))
		for(var/line in world.file2list("strings/round_start_sounds.txt"))
			line = trim(line)
			if(line && IS_SOUND_FILE(line))
				tracks += line
	if(SSticker.login_music && !(SSticker.login_music in tracks))
		tracks.Insert(1, SSticker.login_music)

	GLOB.maverick_lobby_tracks = tracks
	return tracks

/**
 * Display names from config/title_music/names.txt.
 *
 * One track per line, "file name : Display Name". The file name can have its
 * extension or not, and case does not matter. Lines starting with # are skipped.
 */
/proc/maverick_track_name_overrides()
	var/static/list/overrides
	if(overrides)
		return overrides
	overrides = list()
	var/names_file = "[global.config.directory]/title_music/names.txt"
	if(!fexists(names_file))
		return overrides
	for(var/line in world.file2list(names_file))
		line = trim(line)
		if(!line || line[1] == "#")
			continue
		var/split = findtext(line, ":")
		if(!split)
			continue
		var/key = LOWER_TEXT(trim(copytext(line, 1, split)))
		var/display = trim(copytext(line, split + 1))
		if(key && display)
			overrides[key] = display
	return overrides

/proc/maverick_track_name(path)
	var/list/parts = splittext(path, "/")
	var/file = parts[length(parts)]
	var/base = file
	var/dot = findlasttext(base, ".")
	if(dot > 1)
		base = copytext(base, 1, dot)

	var/list/overrides = maverick_track_name_overrides()
	var/display = overrides[LOWER_TEXT(file)] || overrides[LOWER_TEXT(base)]
	if(display)
		return display
	if(GLOB.maverick_track_names[path])
		return GLOB.maverick_track_names[path]

	// drop the "rare+" / "MapName+" sorting prefix the title music folder uses
	var/list/sort_parts = splittext(base, "+")
	return replacetext(sort_parts[length(sort_parts)], "_", " ")

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
	var/list/tracks = maverick_lobby_tracks()
	var/current = maverick_current_track()
	var/list/titles = list()
	for(var/track in tracks)
		titles += list(list("title" = maverick_track_name(track)))
	var/enabled = !CONFIG_GET(flag/disallow_title_music) && length(tracks)
	var/volume = prefs?.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	// The lobby starts the round track on login; treat our first look as its start.
	if(isnull(maverick_music_started))
		maverick_music_started = world.time
	var/playing = enabled && !maverick_music_stopped && volume > 0
	var/elapsed = ((maverick_music_paused ? maverick_music_paused_at : world.time) - maverick_music_started) / 10
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
	)

/// Sends SpaceAmp the new state. started tells it the track changed.
/client/proc/maverick_music_push(started = FALSE)
	var/list/state = maverick_music_state()
	if(started)
		state["started"] = TRUE
	src << output(url_encode(json_encode(state)), "title_browser:music_state")

/client/proc/maverick_music_play(path, offset = 0)
	if(!path || CONFIG_GET(flag/disallow_title_music))
		return
	var/datum/preference/volume_pref = GLOB.preference_entries[/datum/preference/numeric/volume/sound_lobby_volume]
	var/volume = prefs.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	if(!volume)
		// Pressing play with the volume at zero means "I want music". Don't restart it through the pref's own hook.
		volume = 50
		prefs.write_preference(volume_pref, volume)
	var/sound/music = sound(path, repeat = 0, wait = 0, volume = volume, channel = CHANNEL_LOBBYMUSIC)
	music.offset = offset
	SEND_SOUND(src, music)
	maverick_music_track = path
	maverick_music_base = SSticker.login_music
	maverick_music_stopped = FALSE
	maverick_music_paused = FALSE
	maverick_music_started = world.time - offset * 10
	maverick_music_push(started = TRUE)

/client/proc/maverick_music_command(command, list/href_list)
	if(!isnewplayer(mob))
		return
	var/list/tracks = maverick_lobby_tracks()
	if(!length(tracks))
		return
	var/current = maverick_current_track()
	var/index = max(1, tracks.Find(current))
	switch(command)
		if("play")
			maverick_music_play(current)
		if("pause")
			if(maverick_music_stopped || maverick_music_paused)
				return
			var/sound/pause = sound(null, repeat = 0, wait = 0, channel = CHANNEL_LOBBYMUSIC)
			pause.status = SOUND_PAUSED | SOUND_UPDATE
			SEND_SOUND(src, pause)
			maverick_music_paused = TRUE
			maverick_music_paused_at = world.time
			maverick_music_push()
		if("resume")
			if(!maverick_music_paused)
				return
			var/sound/resume = sound(null, repeat = 0, wait = 0, channel = CHANNEL_LOBBYMUSIC)
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
			maverick_music_play(tracks[(index % length(tracks)) + 1])
		if("prev")
			maverick_music_play(tracks[((index - 2 + length(tracks)) % length(tracks)) + 1])
		if("track")
			var/pick = text2num(href_list["track"])
			if(isnum(pick) && pick >= 1 && pick <= length(tracks))
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
			mob.set_sound_channel_volume(CHANNEL_LOBBYMUSIC, volume)
			maverick_music_push()
		if("ended")
			switch(href_list["repeat"])
				if("one")
					maverick_music_play(current)
				if("all")
					maverick_music_play(tracks[(index % length(tracks)) + 1])
				else
					maverick_music_stopped = TRUE
					maverick_music_push()
