// *vibe: "[Name] vibes", with the stasis bed's ripple and a low chime.

#define VIBE_FILTER "vibe_ripple"
#define VIBE_FILTER_PRIORITY 2
#define VIBE_RIPPLE_SIZE 2
#define VIBE_RIPPLE_RADIUS 32
#define VIBE_PULSES 2
#define VIBE_PULSE_RESET_TIME (0.2 SECONDS)
#define VIBE_PULSE_TIME (1.5 SECONDS)
#define VIBE_DURATION (VIBE_PULSES * (VIBE_PULSE_RESET_TIME + VIBE_PULSE_TIME))
#define VIBE_VOLUME 25
#define VIBE_FREQUENCY_MIN 5120
#define VIBE_FREQUENCY_MAX 8800

/datum/emote/living/vibe
	key = "vibe"
	key_third_person = "vibes"
	message = "vibes."
	emote_type = EMOTE_VISIBLE
	cooldown = VIBE_DURATION

/datum/emote/living/vibe/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()
	// the stasis bed's chime, played by hand since the emote sound system can't pitch it this low
	if(TIMER_COOLDOWN_FINISHED(user, MANUAL_GENERAL_EMOTE_AUDIO_COOLDOWN))
		TIMER_COOLDOWN_START(user, MANUAL_GENERAL_EMOTE_AUDIO_COOLDOWN, manual_general_emote_audio_cooldown)
		playsound(user, 'sound/machines/synth/synth_yes.ogg', VIBE_VOLUME, TRUE, SILENCED_SOUND_EXTRARANGE, frequency = rand(VIBE_FREQUENCY_MIN, VIBE_FREQUENCY_MAX), volume_preference = /datum/preference/numeric/volume/sound_emote)
	// clear any leftover ripple so they never stack
	user.remove_filter(VIBE_FILTER)
	user.add_filter(VIBE_FILTER, VIBE_FILTER_PRIORITY, list("type" = "ripple", "flags" = WAVE_BOUNDED, "radius" = 0, "size" = VIBE_RIPPLE_SIZE))
	var/filter = user.get_filter(VIBE_FILTER)
	animate(filter, radius = 0, time = VIBE_PULSE_RESET_TIME, size = VIBE_RIPPLE_SIZE, easing = JUMP_EASING, loop = VIBE_PULSES, flags = ANIMATION_PARALLEL)
	animate(radius = VIBE_RIPPLE_RADIUS, time = VIBE_PULSE_TIME, size = 0)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/datum, remove_filter), VIBE_FILTER), VIBE_DURATION, TIMER_UNIQUE | TIMER_OVERRIDE)

#undef VIBE_FILTER
#undef VIBE_FILTER_PRIORITY
#undef VIBE_RIPPLE_SIZE
#undef VIBE_RIPPLE_RADIUS
#undef VIBE_PULSE_RESET_TIME
#undef VIBE_DURATION
#undef VIBE_PULSES
#undef VIBE_PULSE_TIME
#undef VIBE_VOLUME
#undef VIBE_FREQUENCY_MIN
#undef VIBE_FREQUENCY_MAX
