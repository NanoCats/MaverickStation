/// Opt-out for the pink arousal overlay. Lives with the other ERP prefs and follows the ERP toggle.
/datum/preference/toggle/erp/arousal_overlay
	savefile_key = "maverick_arousal_overlay"
	default_value = TRUE

/datum/preference/toggle/erp/arousal_overlay/apply_to_client_updated(client/client, value)
	var/mob/living/carbon/human/target = client?.mob
	if(!value && istype(target))
		target.clear_fullscreen("maverick_arousal", animated = FALSE)

/// The brute damage vignette, recolored pink. The color matrix turns the red of the base sprite into pink.
/atom/movable/screen/fullscreen/brute/arousal
	color = list(
		1.3, 0.5, 0.85,
		0, 0, 0,
		0, 0, 0,
		0, 0, 0,
	)

/datum/status_effect/aroused/tick(seconds_between_ticks)
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/aroused_mob = owner
		aroused_mob.update_arousal_overlay()

/datum/status_effect/aroused/on_remove()
	. = ..()
	owner.clear_fullscreen("maverick_arousal")

/// Shows the pink vignette from AROUSAL_LOW up, getting stronger as arousal rises.
/mob/living/carbon/human/proc/update_arousal_overlay()
	if(stat == DEAD || arousal < AROUSAL_LOW || !client?.prefs?.read_preference(/datum/preference/toggle/erp/arousal_overlay))
		clear_fullscreen("maverick_arousal")
		return
	var/severity
	switch(arousal)
		if(-INFINITY to 45)
			severity = 1
		if(45 to 60)
			severity = 2
		if(60 to 70)
			severity = 3
		if(70 to 80)
			severity = 4
		if(80 to 90)
			severity = 5
		else
			severity = 6
	overlay_fullscreen("maverick_arousal", /atom/movable/screen/fullscreen/brute/arousal, severity)
