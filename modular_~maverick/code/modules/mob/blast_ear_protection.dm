// Upstream explosions damage ears without checking ear protection, so headsets and sealed helmets did nothing against blasts.
// Ear protection now reduces blast ear damage and deafness. Each level divides it: normal halves it, full blocks it.

/// Ear damage and deafness from an explosion, reduced by ear protection
/mob/living/carbon/human/proc/blast_sound_damage(damage, deafen)
	var/protection = get_ear_protection()
	if(protection >= EAR_PROTECTION_FULL)
		return
	var/divisor = 1 + max(protection, 0)
	sound_damage(damage / divisor, deafen / divisor)
