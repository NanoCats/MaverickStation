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
		if(COOLDOWN_FINISHED(client, maverick_honk_cooldown))
			COOLDOWN_START(client, maverick_honk_cooldown, 0.5 SECONDS)
			SEND_SOUND(src, sound('sound/items/bikehorn.ogg'))
		return TRUE

	if(href_list["music"])
		client.maverick_music_command(href_list["music"], href_list)
		return TRUE

	return FALSE

#undef LOBBY_DESKTOP_MAX_STATE_LENGTH
