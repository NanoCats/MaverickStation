/// Turns the lobby into the MaverickStation desktop. Off falls back to the old lobby menu.
/datum/config_entry/flag/maverick_lobby_desktop
	default = TRUE

/// Where on the wallpaper the CRT sits, as x, y, width, height in wallpaper pixels. Double-clicking it opens station.exe.
#define LOBBY_DESKTOP_CRT_HOTSPOT list(100, 105, 92, 96)

/// How far a lobby mob got sending its client the lobby files
#define LOBBY_FILES_NONE 0
#define LOBBY_FILES_BOOT 1
#define LOBBY_FILES_ALL 2
/// A send that started this long ago is treated as stuck, so a new one can go ahead.
#define LOBBY_SEND_TIMEOUT (30 SECONDS)

/// Which lobby files this mob sent its client: LOBBY_FILES_NONE, LOBBY_FILES_BOOT or LOBBY_FILES_ALL
/mob/dead/new_player/var/maverick_lobby_files_sent = LOBBY_FILES_NONE
/// world.time a page send started, while it waits for files. Null when no send is running.
/mob/dead/new_player/var/maverick_title_sending
/// What the last page sent was built for. A refresh for the same thing keeps the page as it is.
/mob/dead/new_player/var/maverick_page_key
/// The last page sent told us it started. Until then a refresh always sends a new page.
/mob/dead/new_player/var/maverick_page_alive = FALSE

/// The fonts the boot screens need. They go first, so a boot screen can show while the rest load.
GLOBAL_LIST_INIT(maverick_boot_files, list(
	"FixedsysExcelsior3.01Regular.ttf",
	"Pixellari.ttf",
	"Grand9K_Pixel.ttf",
	"TinyUnicode.ttf",
))

/**
 * Pictures the boot screens use, written into the page itself.
 * While the server starts it is too busy to send files quickly, and these
 * showed as broken images for a while. They are small, so the page carries them.
 */
GLOBAL_LIST_INIT(maverick_inline_images, list(
	"mav_blinds.png" = 'modular_~maverick/html/lobby_desktop/mav_blinds.png',
	"mav_chevron.png" = 'modular_~maverick/html/lobby_desktop/mav_chevron.png',
	"mav_clown_small.png" = 'modular_~maverick/html/lobby_desktop/mav_clown_small.png',
	"mav_icon_join.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_join.png',
	"mav_icon_station.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_station.png',
	"mav_icon_err.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_err.png',
	"mav_tbtn_glyphs.png" = 'modular_~maverick/html/lobby_desktop/mav_tbtn_glyphs.png',
))

/// The inline pictures as data URIs, by the name the page asks for. Built once.
/proc/maverick_inline_image_data()
	var/static/list/data
	if(!data)
		data = list()
		for(var/file_name in GLOB.maverick_inline_images)
			data[file_name] = "data:image/png;base64,[icon2base64(GLOB.maverick_inline_images[file_name])]"
	return data

/// Every file the lobby page loads, by the name the page asks for.
GLOBAL_LIST_INIT(maverick_lobby_files, list(
	"FixedsysExcelsior3.01Regular.ttf" = 'html/browser/FixedsysExcelsior3.01Regular.ttf',
	"Pixellari.ttf" = 'interface/fonts/Pixellari.ttf',
	"Grand9K_Pixel.ttf" = 'interface/fonts/Grand9K_Pixel.ttf',
	"TinyUnicode.ttf" = 'interface/fonts/TinyUnicode.ttf',
	"desktop_click.ogg" = 'modular_~maverick/sound/lobby_desktop/desktop_click.ogg',
	"desktop_error.ogg" = 'modular_~maverick/sound/lobby_desktop/desktop_error.ogg',
	"desktop_shutdown.ogg" = 'modular_~maverick/sound/lobby_desktop/desktop_shutdown.ogg',
	"mav_wall_night.png" = 'modular_~maverick/html/lobby_desktop/mav_wall_night.png',
	"mav_wall_dawn.png" = 'modular_~maverick/html/lobby_desktop/mav_wall_dawn.png',
	"mav_wall_day.png" = 'modular_~maverick/html/lobby_desktop/mav_wall_day.png',
	"mav_wall_dusk.png" = 'modular_~maverick/html/lobby_desktop/mav_wall_dusk.png',
	"mav_amp_glyphs.png" = 'modular_~maverick/html/lobby_desktop/mav_amp_glyphs.png',
	"mav_tray_horn.png" = 'modular_~maverick/html/lobby_desktop/mav_tray_horn.png',
	"mav_tray_sound.png" = 'modular_~maverick/html/lobby_desktop/mav_tray_sound.png',
	"mav_icon_power.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_power.png',
	"mav_station.png" = 'modular_~maverick/html/lobby_desktop/mav_station.png',
	"mav_id_parts.png" = 'modular_~maverick/html/lobby_desktop/mav_id_parts.png',
	"mav_sky_glyphs.png" = 'modular_~maverick/html/lobby_desktop/mav_sky_glyphs.png',
	"mav_clown_E.png" = 'modular_~maverick/html/lobby_desktop/mav_clown_E.png',
	"mav_clown_S.png" = 'modular_~maverick/html/lobby_desktop/mav_clown_S.png',
	"mav_clown_W.png" = 'modular_~maverick/html/lobby_desktop/mav_clown_W.png',
	"mav_paint_tools.png" = 'modular_~maverick/html/lobby_desktop/mav_paint_tools.png',
	"mav_starfield.png" = 'modular_~maverick/html/lobby_desktop/mav_starfield.png',
	"mav_wordmark.png" = 'modular_~maverick/html/lobby_desktop/mav_wordmark.png',
	"mav_icon_cheats.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_cheats.png',
	"mav_icon_clown.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_clown.png',
	"mav_icon_directory.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_directory.png',
	"mav_icon_horn.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_horn.png',
	"mav_icon_manifest.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_manifest.png',
	"mav_icon_music.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_music.png',
	"mav_icon_observe.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_observe.png',
	"mav_icon_options.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_options.png',
	"mav_icon_paint.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_paint.png',
	"mav_icon_polls.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_polls.png',
	"mav_icon_readme.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_readme.png',
	"mav_icon_recycle.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_recycle.png',
	"mav_icon_servers.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_servers.png',
	"mav_icon_setup.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_setup.png',
	"mav_icon_traits.png" = 'modular_~maverick/html/lobby_desktop/mav_icon_traits.png',
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
	/// The Clown.exe clown's footsteps, kept apart so they never eat a honk
	COOLDOWN_DECLARE(maverick_clown_step_cooldown)

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
 *
 * A refresh for the same kind of page (still starting, still in the lobby, and so on)
 * leaves a working page alone. Sending a new page resets the desktop, so things like
 * backing out of Observe should not do it.
 */
/mob/dead/new_player/proc/maverick_update_title_screen()
	if(!CONFIG_GET(flag/maverick_lobby_desktop) || !client)
		return FALSE
	var/key = maverick_page_kind()
	if(maverick_page_alive && key == maverick_page_key)
		return TRUE
	maverick_page_key = key
	maverick_page_alive = FALSE
	INVOKE_ASYNC(src, PROC_REF(maverick_send_title_screen))
	return TRUE

/// What kind of page this player should have. A new page is only needed when this changes.
/mob/dead/new_player/proc/maverick_page_kind()
	var/list/parts = list(
		SSticker.current_state == GAME_STATE_STARTUP ? "startup" : "lobby",
		SSticker.current_state > GAME_STATE_PREGAME,
		SSticker.current_state == GAME_STATE_PLAYING && client.maverick_assigned_round != GLOB.round_id,
		!!client.prefs?.read_preference(/datum/preference/toggle/maverick_classic_lobby),
		SStitle.current_notice,
	)
	return jointext(parts, "|")

/**
 * Sends the files the page needs, waits until the client has them, then sends the page.
 *
 * The page's own script and styles are written into the page itself, so they can never
 * arrive late. Pictures and fonts go in the browser cache by name with browse(file=),
 * the way the old lobby sends its title image.
 *
 * While the server starts, only the boot screen files go before the page, so the boot
 * screen shows quickly. The rest follow right after it.
 *
 * Only one send runs at a time. A refresh that comes in while one waits for files does
 * nothing more, because the running send builds its page after the wait and so picks up
 * the change.
 */
/mob/dead/new_player/proc/maverick_send_title_screen()
	if(!client)
		return
	if(maverick_title_sending && world.time - maverick_title_sending < LOBBY_SEND_TIMEOUT)
		return
	maverick_title_sending = world.time
	var/startup = SSticker.current_state == GAME_STATE_STARTUP
	// Per lobby mob, so a player coming back to the lobby (respawn, reconnect) gets them again.
	if(maverick_lobby_files_sent < LOBBY_FILES_BOOT)
		for(var/file_name in GLOB.maverick_boot_files)
			src << browse(GLOB.maverick_lobby_files[file_name], "file=[file_name];display=0")
		maverick_lobby_files_sent = LOBBY_FILES_BOOT
		client?.browse_queue_flush()
	if(!startup && maverick_lobby_files_sent < LOBBY_FILES_ALL)
		maverick_send_other_lobby_files()
		client?.browse_queue_flush()
	maverick_title_sending = null
	if(!client)
		return
	src << browse(maverick_title_html(), "window=title_browser")
	if(startup)
		// the desktop files can load while the boot screen shows
		maverick_send_other_lobby_files()
		maverick_broadcast_humans()
	// Once the client has every file, the page tries any picture that came up broken again
	if(!client?.browse_queue_flush())
		return
	client << output("", "title_browser:lobby_files_sent")

/// Sends every lobby file the boot screens did not already need.
/mob/dead/new_player/proc/maverick_send_other_lobby_files()
	if(maverick_lobby_files_sent >= LOBBY_FILES_ALL)
		return
	maverick_lobby_files_sent = LOBBY_FILES_ALL
	for(var/file_name in GLOB.maverick_lobby_files)
		if(file_name in GLOB.maverick_boot_files)
			continue
		src << browse(GLOB.maverick_lobby_files[file_name], "file=[file_name];display=0")

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
	// Cheat Engine icon, for admins who can use the playtest cheats
	settings["cheats"] = !!check_rights_for(client, R_DEBUG)
	settings["crt_hotspot"] = LOBBY_DESKTOP_CRT_HOTSPOT
	settings["inline"] = maverick_inline_image_data()
	settings["sfx"] = client.maverick_desktop_sound_mode()
	// The page plays the desktop sounds itself, at the lobby music volume
	settings["sfx_vol"] = client.prefs?.read_preference(/datum/preference/numeric/volume/sound_lobby_volume) || 0
	settings["startup_due"] = client.maverick_startup_due()
	settings["desktop"] = client.maverick_desktop_state
	settings["music"] = client.maverick_music_state()
	// A player's first page this connection plays the CRT power-on and a boot screen.
	// While the server is still starting, the boot screen shows the real progress instead.
	settings["intro"] = !client.maverick_intro_seen
	if(startup || !client.maverick_intro_seen)
		SStitle.maverick_pick_boot_gags()
		settings["boot"] = maverick_boot_info()
	// One boot screen per server start, so the page never switches to a different one
	// partway through, for example when the server reloads it after startup
	SStitle.maverick_pick_boot_gags()
	settings["splash"] = SStitle.maverick_splash
	// Skyrat's page tells the server it loaded with a link that runs while the page is
	// still loading, which can stop the page. Ours sends it once it has finished loading.
	settings["ready_ping"] = !title_screen_is_ready

	// Every "<" in the data becomes \u003c, so nothing a player types (a character name,
	// a notice) can close the script tag or open a new one. JSON reads it back as "<".
	var/settings_json = replacetext(json_encode(settings), "<", "\\u003c")
	var/dat = {"<!DOCTYPE html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<style>[maverick_lobby_code("css")]</style>
</head>
<body>
<div id="screen" class="screen_root"><div id="stage"></div></div>
[maverick_fallback_menu()]
<script>[maverick_fallback_script()]</script>
<script>window.MAV = [settings_json];</script>
<script>[maverick_lobby_code("js")]</script>
</body>
</html>"}
	return dat

/**
 * Shows the plain fallback menu if the desktop script fails or never starts.
 * Errors show on the fallback menu and go to the server log, once per page.
 */
/mob/dead/new_player/proc/maverick_fallback_script()
	return {"(function () {
	var reported = false;
	window.MAV_FAIL = function (message) {
		var fb = document.getElementById("mav_fallback");
		if (fb) {
			fb.style.display = "block";
			var why = document.getElementById("mav_fallback_why");
			if (why && message && !why.textContent) {
				why.textContent = "Error: " + message;
			}
		}
		if (!reported && message) {
			reported = true;
			var send = function () {
				location.href = "byond://?src=[text_ref(src)];lobby_js_error=" + encodeURIComponent(String(message).slice(0, 300));
			};
			// a link followed while the page still loads can stop it, so wait for the load
			if (document.readyState === "loading") {
				document.addEventListener("DOMContentLoaded", send);
			} else {
				send();
			}
		}
	};
	window.onerror = function (message, source, line) {
		if (!window.MAV_OK) {
			window.MAV_FAIL(message + " (line " + line + ")");
		}
	};
	setTimeout(function () {
		if (!window.MAV_OK) {
			window.MAV_FAIL("the desktop script did not start");
		}
	}, 8000);
})();"}

/// The desktop's stylesheet or script, read once from the compiled-in files.
/proc/maverick_lobby_code(kind)
	var/static/list/code = list(
		"css" = file2text('modular_~maverick/html/lobby_desktop/mav_lobby.css'),
		"js" = file2text('modular_~maverick/html/lobby_desktop/mav_lobby.js'),
	)
	return code[kind]

/**
 * A plain menu with the lobby actions that matter, as ordinary links with inline styles.
 * It stays hidden while the desktop works. If the desktop's script or styles fail to load,
 * or the script breaks while building the desktop, it appears after a few seconds, so
 * nobody is stuck in the lobby unable to join, observe or set up a character.
 */
/mob/dead/new_player/proc/maverick_fallback_menu()
	var/ref = text_ref(src)
	var/list/links = list()
	if(SSticker.current_state > GAME_STATE_PREGAME)
		links += "<a href='byond://?src=[ref];late_join=1'>Join Game</a>"
		links += "<a href='byond://?src=[ref];view_manifest=1'>Crew Manifest</a>"
	else
		links += "<a href='byond://?src=[ref];toggle_ready=1'>Toggle Ready</a>"
	links += "<a href='byond://?src=[ref];observe=1'>Observe</a>"
	links += "<a href='byond://?src=[ref];character_setup=1'>Setup Character</a>"
	links += "<a href='byond://?src=[ref];game_options=1'>Game Options</a>"
	links += "<a href='byond://?src=[ref];character_directory=1'>Character Directory</a>"
	var/link_style = "display:block;color:#ffe066;margin:6px 0;font-size:18px;"
	return {"<div id="mav_fallback" style="display:none;position:fixed;inset:0;z-index:5000;background:#05081a;color:#cde;font-family:sans-serif;padding:24px;">
<div style="font-size:22px;margin-bottom:6px;">MaverickStation</div>
<div style="margin-bottom:14px;">The lobby desktop did not load. Here is the plain menu.</div>
[replacetext(jointext(links, ""), "<a ", "<a style='[link_style]' ")]
<div id="mav_fallback_why" style="margin-top:18px;color:#7a86a8;font-size:12px;"></div>
</div>"}

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
#undef LOBBY_FILES_NONE
#undef LOBBY_FILES_BOOT
#undef LOBBY_FILES_ALL
#undef LOBBY_SEND_TIMEOUT
