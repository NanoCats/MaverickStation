#define LOBBY_DESKTOP_SOUNDS_ALL "All"
#define LOBBY_DESKTOP_SOUNDS_QUIET "Clicks only"
#define LOBBY_DESKTOP_SOUNDS_OFF "Off"
/// Reverb switched off: room, reflections and reverb all at their minimum
#define LOBBY_DESKTOP_DRY_ENVIRONMENT list(1.8, 0.5, -10000, -4000, 0, 5, 0.1, 1, -10000, 0.007, -10000, 0.05, 0.25, 1, 1.18, 0.348, -5, 2000, 250, 0, 3, 100, 63)

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
	/// Keeps clicks and error chimes from stacking up when someone mashes the mouse
	COOLDOWN_DECLARE(maverick_desktop_sfx_cooldown)

/client/proc/maverick_desktop_sound_mode()
	return prefs?.read_preference(/datum/preference/choiced/maverick_desktop_sounds) || LOBBY_DESKTOP_SOUNDS_ALL

/// TRUE if this player should hear the startup sound when their desktop comes up.
/client/proc/maverick_startup_due()
	return maverick_desktop_sound_mode() == LOBBY_DESKTOP_SOUNDS_ALL && !GLOB.maverick_startup_heard[ckey]

/**
 * Plays one desktop sound for this player only. kind: click, error, startup or shutdown.
 * The desktop sounds follow the lobby music volume, so the one slider sets both.
 * Returns TRUE if a sound played.
 */
/mob/dead/new_player/proc/maverick_desktop_sfx(kind)
	if(!client)
		return FALSE
	var/mode = client.maverick_desktop_sound_mode()
	if(mode == LOBBY_DESKTOP_SOUNDS_OFF)
		return FALSE
	var/volume = client.prefs?.read_preference(/datum/preference/numeric/volume/sound_lobby_volume)
	if(!volume)
		return FALSE
	var/static/list/sounds = list(
		"click" = 'modular_maverick/sound/lobby_desktop/desktop_click.ogg',
		"error" = 'modular_maverick/sound/lobby_desktop/desktop_error.ogg',
		"startup" = 'modular_maverick/sound/lobby_desktop/desktop_startup.ogg',
		"shutdown" = 'modular_maverick/sound/lobby_desktop/desktop_shutdown.ogg',
	)
	var/file = sounds[kind]
	if(!file)
		return FALSE
	switch(kind)
		if("click", "error")
			if(!COOLDOWN_FINISHED(client, maverick_desktop_sfx_cooldown))
				return FALSE
			COOLDOWN_START(client, maverick_desktop_sfx_cooldown, 0.15 SECONDS)
		if("startup")
			if(!client.maverick_startup_due())
				return FALSE
			GLOB.maverick_startup_heard[client.ckey] = TRUE
		if("shutdown")
			if(mode != LOBBY_DESKTOP_SOUNDS_ALL)
				return FALSE
	var/sound/played = sound(file, volume = volume)
	played.environment = LOBBY_DESKTOP_DRY_ENVIRONMENT
	SEND_SOUND(src, played)
	return TRUE

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
