/// Shows a plain lobby (wallpaper and one menu window) instead of the full desktop.
/datum/preference/toggle/maverick_classic_lobby
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES
	savefile_key = "maverick_classic_lobby"
	savefile_identifier = PREFERENCE_PLAYER
	default_value = FALSE

/datum/preference/toggle/maverick_classic_lobby/apply_to_client_updated(client/client, value)
	var/mob/dead/new_player/player = client?.mob
	if(istype(player))
		INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, show_title_screen))
