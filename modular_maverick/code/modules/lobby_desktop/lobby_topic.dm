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

	// Start > Shut Down. It really does shut down. Rejoining is one click.
	if(href_list["lobby_shutdown"])
		log_game("[key_name(src)] shut down their lobby desktop and was disconnected.")
		addtimer(CALLBACK(src, PROC_REF(maverick_shutdown_kick)), 2 SECONDS)
		return TRUE

	// Remember that this connection already saw the boot screens and the CRT power-on.
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
