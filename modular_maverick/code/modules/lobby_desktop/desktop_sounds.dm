/// Which lobby desktop sounds a player hears: all of them, clicks and errors only, or none.
/datum/preference/choiced/maverick_desktop_sounds
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "maverick_desktop_sounds"
	savefile_identifier = PREFERENCE_PLAYER

/datum/preference/choiced/maverick_desktop_sounds/init_possible_values()
	return list(LOBBY_DESKTOP_SOUNDS_ALL, LOBBY_DESKTOP_SOUNDS_QUIET, LOBBY_DESKTOP_SOUNDS_OFF)

/datum/preference/choiced/maverick_desktop_sounds/create_default_value()
	return LOBBY_DESKTOP_SOUNDS_ALL

/datum/preference/choiced/maverick_desktop_sounds/apply_to_client(client/client, value)
	return

/// Ckeys that already heard the startup sound this round. The startup plays once per round at most.
GLOBAL_LIST_EMPTY(maverick_startup_heard)

/client
	/// When each desktop sound may play again, by kind, so mashing the mouse doesn't stack them
	var/list/maverick_sfx_next

/client/proc/maverick_desktop_sound_mode()
	return prefs?.read_preference(/datum/preference/choiced/maverick_desktop_sounds) || LOBBY_DESKTOP_SOUNDS_ALL

/// TRUE until this player's first desktop of the round has come up.
/client/proc/maverick_startup_due()
	return !GLOB.maverick_startup_heard[ckey]

/**
 * Plays one desktop sound for this player only. kind: click, error, startup or shutdown.
 * The desktop sounds follow the lobby music volume, so the one slider sets both.
 * Returns TRUE if a sound played.
 */
/mob/dead/new_player/proc/maverick_desktop_sfx(kind)
	if(!client)
		return FALSE
	var/static/list/sounds = list(
		"click" = 'modular_maverick/sound/lobby_desktop/desktop_click.ogg',
		"error" = 'modular_maverick/sound/lobby_desktop/desktop_error.ogg',
		"startup" = 'modular_maverick/sound/lobby_desktop/desktop_startup.ogg',
		"shutdown" = 'modular_maverick/sound/lobby_desktop/desktop_shutdown.ogg',
	)
	var/static/list/gaps = list("click" = 0.05 SECONDS, "error" = 0.15 SECONDS)
	var/file = sounds[kind]
	if(!file)
		return FALSE
	// The first desktop of the round uses up the startup sound, even when it is muted,
	// so it never turns up later in the round on a refresh or a reconnect.
	if(kind == "startup")
		if(!client.maverick_startup_due())
			return FALSE
		GLOB.maverick_startup_heard[client.ckey] = TRUE
	var/mode = client.maverick_desktop_sound_mode()
	if(mode == LOBBY_DESKTOP_SOUNDS_OFF)
		return FALSE
	if((kind == "startup" || kind == "shutdown") && mode != LOBBY_DESKTOP_SOUNDS_ALL)
		return FALSE
	var/volume = client.prefs?.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	if(!volume)
		return FALSE
	if(gaps[kind])
		LAZYINITLIST(client.maverick_sfx_next)
		if(world.time < client.maverick_sfx_next[kind])
			return FALSE
		client.maverick_sfx_next[kind] = world.time + gaps[kind]
	var/sound/played = sound(file, volume = volume)
	played.environment = LOBBY_DESKTOP_DRY_ENVIRONMENT
	SEND_SOUND(src, played)
	return TRUE

/// The old lobby menu's button sound. The desktop plays its own clicks, so this only clicks for the old menu.
/mob/dead/new_player/proc/maverick_lobby_button_sound()
	if(CONFIG_GET(flag/maverick_lobby_desktop))
		return
	maverick_desktop_sfx("click")

/// Start menu > Sounds. Steps to the next setting and saves it.
/mob/dead/new_player/proc/maverick_cycle_desktop_sounds()
	if(!client?.prefs)
		return
	var/static/list/order = list(LOBBY_DESKTOP_SOUNDS_ALL, LOBBY_DESKTOP_SOUNDS_QUIET, LOBBY_DESKTOP_SOUNDS_OFF)
	var/next = order[(order.Find(client.maverick_desktop_sound_mode()) % length(order)) + 1]
	client.prefs.write_preference(GLOB.preference_entries[/datum/preference/choiced/maverick_desktop_sounds], next)

/**
 * BYOND keeps the last reverb a client heard until a sound changes it. A ghost that
 * respawns back to the lobby kept echoing like whatever room it left, so the lobby
 * switches the reverb off when a player arrives.
 */
/mob/dead/new_player/proc/maverick_dry_sound()
	var/sound/dry = sound(null)
	dry.environment = LOBBY_DESKTOP_DRY_ENVIRONMENT
	SEND_SOUND(src, dry)

/mob/dead/new_player/Login()
	. = ..()
	maverick_dry_sound()
