/// Percent chance per round that one station logo gets the "Aeri" tag over SPACE
/datum/config_entry/number/maverick_aeri_graffiti_chance
	default = 50
	min_val = 0
	max_val = 100
	integer = TRUE

GLOBAL_DATUM(aeri_graffiti_tagger, /datum/aeri_graffiti_tagger)

/obj/effect/turf_decal/plaque/Initialize(mapload)
	if(icon_state == "L1" && isturf(loc))
		if(isnull(GLOB.aeri_graffiti_tagger))
			GLOB.aeri_graffiti_tagger = new
		GLOB.aeri_graffiti_tagger.spots += loc
	return ..()

/// Remembers every SPACE STATION 13 floor logo as it loads, then tags one of them at roundstart, on a roll.
/datum/aeri_graffiti_tagger
	/// The top-left tile (L1) of every logo
	var/list/turf/spots = list()

/datum/aeri_graffiti_tagger/New()
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(tag_one_logo))

/// The tag covers the six tiles under "SPACE": three columns, two rows, starting at the logo's L1 tile.
/datum/aeri_graffiti_tagger/proc/tag_one_logo()
	SIGNAL_HANDLER
	var/list/station_spots = list()
	for(var/turf/spot as anything in spots)
		if(is_station_level(spot.z))
			station_spots += spot
	spots.Cut()
	if(!length(station_spots) || !prob(CONFIG_GET(number/maverick_aeri_graffiti_chance)))
		return
	var/turf/top_left = pick(station_spots)
	for(var/piece in 1 to 6)
		var/column = (piece - 1) >> 1
		var/row = (piece - 1) % 2
		var/turf/target = locate(top_left.x + column, top_left.y - row, top_left.z)
		if(isopenturf(target))
			new /obj/effect/decal/aeri_graffiti(target, piece)

/**
 * One tile of the "Aeri" tag over the SPACE STATION 13 floor logo.
 *
 * Not a cleanable, so cleanbots never go looking for it. A person can still scrub it off
 * with soap or a mop, one tile at a time.
 */
/obj/effect/decal/aeri_graffiti
	name = "graffiti"
	desc = "Somebody tagged the station logo. Bold."
	icon = 'modular_~maverick/icons/effects/aeri_graffiti.dmi'
	icon_state = "aeri1"
	mouse_opacity = MOUSE_OPACITY_ICON

/obj/effect/decal/aeri_graffiti/Initialize(mapload, piece = 1)
	. = ..()
	icon_state = "aeri[clamp(piece, 1, 6)]"
	ADD_TRAIT(src, TRAIT_MOPABLE, INNATE_TRAIT)

/obj/effect/decal/aeri_graffiti/wash(clean_types)
	. = ..()
	if(clean_types & CLEAN_SCRUB)
		qdel(src)
		. |= COMPONENT_CLEANED
