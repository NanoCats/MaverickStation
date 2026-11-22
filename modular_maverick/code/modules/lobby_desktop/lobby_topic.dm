/// Longest desktop layout string we keep for a client. Real layouts are a few hundred characters.
#define LOBBY_DESKTOP_MAX_STATE_LENGTH 4000

/**
 * Handles the links only the desktop lobby sends.
 *
 * Called at the top of /mob/dead/new_player/Topic(). Returns TRUE when the link
 * was fully handled here. "assigned_seen" returns FALSE on purpose, because the
 * popup's OK buttons send it together with "late_join".
 */
/mob/dead/new_player/proc/maverick_lobby_topic(list/href_list)
	if(href_list["desktop_state"])
		var/state = href_list["desktop_state"]
		if(length(state) <= LOBBY_DESKTOP_MAX_STATE_LENGTH)
			client.maverick_desktop_state = state
		return TRUE

	if(href_list["assigned_seen"])
		client.maverick_assigned_round = GLOB.round_id
		return FALSE

	if(href_list["lobby_honk"])
		var/kind = href_list["lobby_honk"]
		// "rift" is the Clown.exe icon: five rising honks, on its own cooldown
		if(kind == "rift")
			if(COOLDOWN_FINISHED(client, maverick_icon_honk_cooldown))
				COOLDOWN_START(client, maverick_icon_honk_cooldown, 1.2 SECONDS)
				SEND_SOUND(src, sound('modular_zubbers/sound/effects/clown/clown_rift_high.ogg'))
			return TRUE
		// The Clown.exe clown's shoes, one squeak per step
		if(kind == "step")
			if(COOLDOWN_FINISHED(client, maverick_clown_step_cooldown))
				COOLDOWN_START(client, maverick_clown_step_cooldown, 0.1 SECONDS)
				SEND_SOUND(src, sound(pick('sound/effects/footstep/clownstep1.ogg', 'sound/effects/footstep/clownstep2.ogg'), volume = 50))
			return TRUE
		// Clown.exe's error windows each make one silly noise as they pop up
		var/static/list/clown_noises = list(
			"bikehorn" = 'sound/items/bikehorn.ogg',
			"squeak1" = 'sound/items/toy_squeak/toysqueak1.ogg',
			"squeak2" = 'sound/items/toy_squeak/toysqueak2.ogg',
			"squeak3" = 'sound/items/toy_squeak/toysqueak3.ogg',
			"slip" = 'sound/misc/slip.ogg',
			"clownstep" = 'sound/effects/footstep/clownstep1.ogg',
			"partyhorn" = 'sound/items/party_horn.ogg',
			"carhorn" = 'sound/items/carhorn.ogg',
			"trombone" = 'sound/misc/sadtrombone.ogg',
		)
		var/noise = clown_noises[kind] || clown_noises["bikehorn"]
		if(COOLDOWN_FINISHED(client, maverick_honk_cooldown))
			COOLDOWN_START(client, maverick_honk_cooldown, 0.08 SECONDS)
			SEND_SOUND(src, sound(noise))
		return TRUE

	// The BIOS boot screen dares you to touch a button. Touching one gets you an explosion,
	// for your ears only. Every touch, no cooldown: mash it and you get what you asked for.
	if(href_list["lobby_kaboom"])
		SEND_SOUND(src, sound(pick('sound/effects/explosion/explosion1.ogg', 'sound/effects/explosion/explosion2.ogg')))
		return TRUE

	// Start > Shut Down. It really does shut down. Rejoining is one click.
	// With the shutdown sound on, the kick waits for the sound to finish.
	if(href_list["lobby_shutdown"])
		log_game("[key_name(src)] shut down their lobby desktop and was disconnected.")
		// the page plays the shutdown sound itself when it has it, and says so with "local"
		var/played = href_list["local"] ? maverick_shutdown_audible() : maverick_desktop_sfx("shutdown")
		addtimer(CALLBACK(src, PROC_REF(maverick_shutdown_kick)), played ? 4.6 SECONDS : 2 SECONDS)
		return TRUE

	// Desktop clicks, error chimes and the startup sound
	if(href_list["lobby_sfx"])
		maverick_desktop_sfx(href_list["lobby_sfx"], record_only = !!href_list["record"])
		return TRUE

	// Start > Sounds
	if(href_list["lobby_sfx_mode"])
		maverick_cycle_desktop_sounds()
		return TRUE

	// Remember that this connection already saw the boot screens and the CRT power-on.
	if(href_list["lobby_alive"])
		maverick_page_alive = TRUE
		return TRUE

	if(href_list["lobby_js_error"])
		// once per page, and the page caps the text; the cap here is for anyone sending it by hand
		log_runtime("Lobby desktop page failed for [key_name(src)]: [copytext(href_list["lobby_js_error"], 1, 301)]")
		return TRUE

	if(href_list["lobby_intro_seen"])
		client.maverick_intro_seen = TRUE
		return TRUE

	if(href_list["music"])
		client.maverick_music_command(href_list["music"], href_list)
		return TRUE

	return FALSE

/**
 * Start > Shut Down. You clicked Shut Down, so the game closes. What did you think would happen?
 * The client quits itself, which closes the game window. If that somehow doesn't take,
 * the server drops the connection a moment later instead.
 */
/mob/dead/new_player/proc/maverick_shutdown_kick()
	if(!client)
		return
	winset(client, null, "command=.quit")
	addtimer(CALLBACK(src, PROC_REF(maverick_shutdown_drop)), 1 SECONDS)

/mob/dead/new_player/proc/maverick_shutdown_drop()
	if(client)
		qdel(client)

#undef LOBBY_DESKTOP_MAX_STATE_LENGTH
