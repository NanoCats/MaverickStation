/// Turns the lobby into the MaverickStation desktop. Off falls back to the old lobby menu.
/datum/config_entry/flag/maverick_lobby_desktop
	default = TRUE

/// Where on the wallpaper the CRT sits, as x, y, width, height in wallpaper pixels. Double-clicking it opens station.exe.
#define LOBBY_DESKTOP_CRT_HOTSPOT list(100, 105, 92, 96)

/// Whether this lobby mob already sent its client the lobby files
/mob/dead/new_player/var/maverick_lobby_files_sent = FALSE

/// Every file the lobby page loads, by the name the page asks for.
GLOBAL_LIST_INIT(maverick_lobby_files, list(
	"mav_lobby.css" = 'modular_maverick/html/lobby_desktop/mav_lobby.css',
	"mav_lobby.js" = 'modular_maverick/html/lobby_desktop/mav_lobby.js',
	"FixedsysExcelsior3.01Regular.ttf" = 'html/browser/FixedsysExcelsior3.01Regular.ttf',
	"Pixellari.ttf" = 'interface/fonts/Pixellari.ttf',
	"Grand9K_Pixel.ttf" = 'interface/fonts/Grand9K_Pixel.ttf',
	"TinyUnicode.ttf" = 'interface/fonts/TinyUnicode.ttf',
	"mav_wall_night.png" = 'modular_maverick/html/lobby_desktop/mav_wall_night.png',
	"mav_wall_dawn.png" = 'modular_maverick/html/lobby_desktop/mav_wall_dawn.png',
	"mav_wall_day.png" = 'modular_maverick/html/lobby_desktop/mav_wall_day.png',
	"mav_wall_dusk.png" = 'modular_maverick/html/lobby_desktop/mav_wall_dusk.png',
	"mav_amp_glyphs.png" = 'modular_maverick/html/lobby_desktop/mav_amp_glyphs.png',
	"mav_tray_horn.png" = 'modular_maverick/html/lobby_desktop/mav_tray_horn.png',
	"mav_icon_power.png" = 'modular_maverick/html/lobby_desktop/mav_icon_power.png',
	"mav_tbtn_glyphs.png" = 'modular_maverick/html/lobby_desktop/mav_tbtn_glyphs.png',
	"mav_station.png" = 'modular_maverick/html/lobby_desktop/mav_station.png',
	"mav_setup_glitch.png" = 'modular_maverick/html/lobby_desktop/mav_setup_glitch.png',
	"mav_sky_glyphs.png" = 'modular_maverick/html/lobby_desktop/mav_sky_glyphs.png',
	"mav_blinds.png" = 'modular_maverick/html/lobby_desktop/mav_blinds.png',
	"mav_chevron.png" = 'modular_maverick/html/lobby_desktop/mav_chevron.png',
	"mav_clown_E.png" = 'modular_maverick/html/lobby_desktop/mav_clown_E.png',
	"mav_clown_S.png" = 'modular_maverick/html/lobby_desktop/mav_clown_S.png',
	"mav_clown_W.png" = 'modular_maverick/html/lobby_desktop/mav_clown_W.png',
	"mav_clown_small.png" = 'modular_maverick/html/lobby_desktop/mav_clown_small.png',
	"mav_paint_tools.png" = 'modular_maverick/html/lobby_desktop/mav_paint_tools.png',
	"mav_starfield.png" = 'modular_maverick/html/lobby_desktop/mav_starfield.png',
	"mav_wordmark.png" = 'modular_maverick/html/lobby_desktop/mav_wordmark.png',
	"mav_icon_clown.png" = 'modular_maverick/html/lobby_desktop/mav_icon_clown.png',
	"mav_icon_directory.png" = 'modular_maverick/html/lobby_desktop/mav_icon_directory.png',
	"mav_icon_horn.png" = 'modular_maverick/html/lobby_desktop/mav_icon_horn.png',
	"mav_icon_join.png" = 'modular_maverick/html/lobby_desktop/mav_icon_join.png',
	"mav_icon_manifest.png" = 'modular_maverick/html/lobby_desktop/mav_icon_manifest.png',
	"mav_icon_music.png" = 'modular_maverick/html/lobby_desktop/mav_icon_music.png',
	"mav_icon_observe.png" = 'modular_maverick/html/lobby_desktop/mav_icon_observe.png',
	"mav_icon_options.png" = 'modular_maverick/html/lobby_desktop/mav_icon_options.png',
	"mav_icon_paint.png" = 'modular_maverick/html/lobby_desktop/mav_icon_paint.png',
	"mav_icon_polls.png" = 'modular_maverick/html/lobby_desktop/mav_icon_polls.png',
	"mav_icon_readme.png" = 'modular_maverick/html/lobby_desktop/mav_icon_readme.png',
	"mav_icon_recycle.png" = 'modular_maverick/html/lobby_desktop/mav_icon_recycle.png',
	"mav_icon_servers.png" = 'modular_maverick/html/lobby_desktop/mav_icon_servers.png',
	"mav_icon_setup.png" = 'modular_maverick/html/lobby_desktop/mav_icon_setup.png',
	"mav_icon_station.png" = 'modular_maverick/html/lobby_desktop/mav_icon_station.png',
	"mav_icon_traits.png" = 'modular_maverick/html/lobby_desktop/mav_icon_traits.png',
))

/client
	/// The player's desktop window layout, as the JSON string the page sent us. Kept for the session.
	var/maverick_desktop_state
	/// Round ID for which this client already saw the "You have been assigned a STATION" popup.
	var/maverick_assigned_round
	/// This connection already sat through the boot screens and the CRT power-on
	var/maverick_intro_seen = FALSE
	COOLDOWN_DECLARE(maverick_honk_cooldown)
	/// Separate from the honk cooldown so clicking the Clown.exe icon never mutes the honks right after it.
	COOLDOWN_DECLARE(maverick_icon_honk_cooldown)

/datum/controller/subsystem/title
	/// Which boot screen this server start shows: "bios", "setup" or "bsod".
	var/maverick_splash
	/// Stop code on the ";)" boot screen.
	var/maverick_stop_code
	/// Threat at the bottom of the BIOS boot screen.
	var/maverick_explode_line

/// Picks the boot screen gags once per server start, so page reloads stay consistent.
/datum/controller/subsystem/title/proc/maverick_pick_boot_gags()
	if(!maverick_splash)
		maverick_splash = pick("bios", "setup", "bsod")
	if(!maverick_stop_code)
		maverick_stop_code = pick("SHIT_FUCK", "HELP_ME", "OH_NO")
	if(!maverick_explode_line)
		maverick_explode_line = pick("TOUCH ANY BUTTON TO EXPLODE", "DON'T FUCKING TOUCH ANYTHING IT'LL EXPLODE")

/**
 * Sends the desktop lobby to this player.
 *
 * Called from update_title_screen(). Returns FALSE when the desktop is switched
 * off, so the old lobby menu runs instead.
 */
/mob/dead/new_player/proc/maverick_update_title_screen()
	if(!CONFIG_GET(flag/maverick_lobby_desktop) || !client)
		return FALSE
	// browse() with file= puts each file in the client's browser cache under its own name,
	// the same way the old lobby sends its title image. browse_rsc assets did not reach the page.
	// Once per lobby mob, so a player coming back to the lobby (respawn, reconnect) gets them again.
	if(!maverick_lobby_files_sent)
		maverick_lobby_files_sent = TRUE
		for(var/file_name in GLOB.maverick_lobby_files)
			src << browse(GLOB.maverick_lobby_files[file_name], "file=[file_name];display=0")
	src << browse(maverick_title_html(), "window=title_browser")
	if(SSticker.current_state == GAME_STATE_STARTUP)
		maverick_broadcast_humans()
	return TRUE

/// Builds the lobby page: an empty stage, the settings object, and the desktop script.
/mob/dead/new_player/proc/maverick_title_html()
	var/startup = SSticker.current_state == GAME_STATE_STARTUP
	var/list/settings = list()
	settings["ref"] = text_ref(src)
	settings["mode"] = startup ? "startup" : "lobby"
	settings["classic"] = !!client.prefs?.read_preference(/datum/preference/toggle/maverick_classic_lobby)
	settings["playing"] = SSticker.current_state > GAME_STATE_PREGAME
	settings["assigned"] = SSticker.current_state == GAME_STATE_PLAYING && client.maverick_assigned_round != GLOB.round_id
	settings["notice"] = SStitle.current_notice
	settings["ready_value"] = PLAYER_READY_TO_PLAY
	settings["ready"] = ready == PLAYER_READY_TO_PLAY
	settings["antag"] = !!client.prefs?.read_preference(/datum/preference/toggle/be_antag)
	settings["name"] = client.prefs?.read_preference(/datum/preference/name/real_name)
	settings["servers"] = LAZYLEN(CONFIG_GET(keyed_list/cross_server)) > 0
	settings["traits"] = length(GLOB.lobby_station_traits) > 0
	settings["polls"] = maverick_poll_state()
	settings["crt_hotspot"] = LOBBY_DESKTOP_CRT_HOTSPOT
	settings["desktop"] = client.maverick_desktop_state
	settings["music"] = client.maverick_music_state()
	// A player's first page this connection plays the CRT power-on and a boot screen.
	// While the server is still starting, the boot screen shows the real progress instead.
	settings["intro"] = !client.maverick_intro_seen
	if(startup || !client.maverick_intro_seen)
		SStitle.maverick_pick_boot_gags()
		settings["boot"] = maverick_boot_info()
	// everyone sees the same boot screen while the server starts; later intros pick their own
	if(startup)
		settings["splash"] = SStitle.maverick_splash

	// "</" would close the script tag early if it showed up in a name or notice.
	var/settings_json = replacetext(json_encode(settings), "</", "<\\/")
	var/dat = {"<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<link rel="stylesheet" type="text/css" href="mav_lobby.css">
</head>
<body>
<div id="screen" class="screen_root"><div id="stage"></div></div>
<script>window.MAV = [settings_json];</script>
<script src="mav_lobby.js"></script>
"}
	if(!title_screen_is_ready)
		dat += {"<script>location.href = "byond://?src=[text_ref(src)];title_is_ready=1";</script>"}
	dat += "</body></html>"
	return dat

/// Real numbers for the boot screens.
/mob/dead/new_player/proc/maverick_boot_info()
	return list(
		"map" = SSmapping.current_map?.map_name || "Unknown Station",
		"byond" = "[world.byond_version].[world.byond_build]",
		"fps" = world.fps,
		"humans" = length(GLOB.clients),
		"progress_time" = world.timeofday - SStitle.progress_reference_time,
		"progress_total" = SStitle.average_completion_time,
		"messages" = GLOB.startup_messages,
		"explode_line" = SStitle.maverick_explode_line,
		"stop_code" = SStitle.maverick_stop_code,
	)

/// "new" if there are unvoted polls, "yes" if there are polls, null if there are none or no database.
/mob/dead/new_player/proc/maverick_poll_state()
	if(is_guest_key(key))
		return null
	var/polls_html = playerpolls()
	if(!polls_html)
		return null
	return findtext(polls_html, "menu_newpoll") ? "new" : "yes"

/// Updates the "Humans detected" line on every boot screen.
/mob/dead/new_player/proc/maverick_broadcast_humans()
	var/count = length(GLOB.clients)
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.client)
			player.client << output("[count]", "title_browser:update_humans")

#undef LOBBY_DESKTOP_CRT_HOTSPOT
