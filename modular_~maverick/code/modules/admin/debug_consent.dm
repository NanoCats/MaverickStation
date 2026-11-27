/**
 * Debug consent: a local testing tool, never for a live server.
 *
 * Leadership tests alone, so every mob she tests consent-gated content on has no player behind it,
 * and a mob with no player fails every consent check. With debug consent on:
 * - Mobs without a player answer yes to consent checks that go through mob_consents().
 * - Every ERP consent pref reads as yes, for players too.
 * Only works while game debugging (Debug-Game) is on, and turns itself off when debugging does.
 */
GLOBAL_VAR_INIT(maverick_debug_consent, FALSE)

/// TRUE while debug consent is on and game debugging is still on
/proc/debug_consent_active()
	return GLOB.maverick_debug_consent && GLOB.debugging_enabled

ADMIN_VERB(debug_consent, R_DEBUG, "Debug-Consent", "TESTING ONLY. Treat every consent check as a yes, including on mobs with no player.", ADMIN_CATEGORY_DEBUG)
	if(!GLOB.maverick_debug_consent && !GLOB.debugging_enabled)
		to_chat(user, span_warning("Turn on Debug-Game first. Debug consent only works while game debugging is on."))
		return
	if(!GLOB.maverick_debug_consent)
		var/answer = tgui_alert(user, "Debug consent makes every consent check answer yes, for everyone, including mobs with no player. It is for local testing only. NEVER use it on a live server.", "Debug-Consent", list("Turn it on", "Cancel"))
		if(answer != "Turn it on")
			return
	GLOB.maverick_debug_consent = !GLOB.maverick_debug_consent
	var/message = "turned debug consent [GLOB.maverick_debug_consent ? "ON. Every consent check now answers yes" : "OFF"]."
	message_admins(span_boldannounce("[key_name_admin(user)] [message]"))
	log_admin("[key_name(user)] [message]")
	BLACKBOX_LOG_ADMIN_VERB("Debug Consent")

/**
 * Whether this mob agrees to the given consent preference.
 *
 * A player answers with their own preference. A mob with no player says no, unless debug consent is on.
 * Use this in place of `client?.prefs?.read_preference(pref)` for consent checks.
 */
/mob/proc/mob_consents(datum/preference/pref)
	if(client?.prefs)
		return client.prefs.read_preference(pref)
	return debug_consent_active()

// With debug consent on, every ERP consent pref reads as yes. This covers checks made against a player's prefs.
/datum/preferences/read_preference(preference_type)
	if(debug_consent_active() && ispath(preference_type, /datum/preference/toggle/erp))
		return TRUE
	return ..()

// Skyrat's logged consent check. Mobs with no player pass while debug consent is on.
/mob/living/check_erp_prefs(datum/preference/toggle/pref_to_check, mob/living/mechanic_user = null, obj/item/used_item = FALSE)
	if(!client && debug_consent_active() && ispath(pref_to_check, /datum/preference/toggle/erp))
		return TRUE
	return ..()
