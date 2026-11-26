/// How far from the operating table we look for a free spot when there is no old kit to replace.
#define TRAY_SEARCH_RANGE 5

/// Something is in the way, the tray can't go here.
#define TRAY_SPOT_BLOCKED 0
/// Free floor.
#define TRAY_SPOT_FLOOR 1
/// Free table.
#define TRAY_SPOT_TABLE 2

/**
 * Makes sure robotics has a stocked surgery tray, whatever map is loaded.
 *
 * Station maps stock robotics surgery in different ways. Some map a surgery tray, some map a
 * robotics surgical duffelbag, and some leave the tools loose on a table. After the map loads,
 * this spawns a full surgery tray if robotics has no surgery kit, then removes the loose tools
 * and duffelbags the tray makes redundant.
 *
 * Robotics must have an operating table, so maps without a surgery setup in robotics are left alone.
 */
SUBSYSTEM_DEF(robotics_surgery_tray)
	name = "Robotics Surgery Tray"
	ss_flags = SS_NO_FIRE
	dependencies = list(
		// Tray spawners and the like must have run first, or we would miss what the map already has.
		/datum/controller/subsystem/atoms,
	)

	/// Set to FALSE to turn this off.
	var/enabled = TRUE
	/// The tray we spawn, and the source of the tools when we restock an empty one.
	var/obj/item/surgery_tray/tray_type = /obj/item/surgery_tray/full
	/// Loose items the tray makes redundant. Exact types only, so upgraded or special variants stay.
	var/list/redundant_types = list(
		/obj/item/blood_filter = TRUE,
		/obj/item/bonesetter = TRUE,
		/obj/item/cautery = TRUE,
		/obj/item/circular_saw = TRUE,
		/obj/item/hemostat = TRUE,
		/obj/item/retractor = TRUE,
		/obj/item/scalpel = TRUE,
		/obj/item/storage/backpack/duffelbag/science/robo/surgery = TRUE,
		/obj/item/surgical_drapes = TRUE,
		/obj/item/surgicaldrill = TRUE,
	)

/datum/controller/subsystem/robotics_surgery_tray/Initialize()
	if(!enabled)
		return SS_INIT_NO_NEED

	var/obj/structure/table/optable/surgery_table
	var/obj/item/surgery_tray/existing_tray
	var/obj/item/storage/toolbox/medical/existing_toolbox
	var/list/obj/item/redundant_items = list()

	for(var/turf/robotics_turf as anything in get_area_turfs(/area/station/science/robotics, subtypes = TRUE))
		if(!is_station_level(robotics_turf.z))
			continue
		for(var/obj/thing in robotics_turf)
			if(istype(thing, /obj/structure/table/optable))
				surgery_table ||= thing
			else if(istype(thing, /obj/item/surgery_tray))
				existing_tray ||= thing
			// The tray spawner rarely swaps the tray for a medical toolbox holding the same tools. That counts as the kit.
			else if(istype(thing, /obj/item/storage/toolbox/medical) && length(thing.contents))
				existing_toolbox ||= thing
			else if(redundant_types[thing.type])
				redundant_items += thing

	if(isnull(surgery_table))
		return SS_INIT_NO_NEED

	if(existing_tray)
		if(!length(existing_tray.contents))
			stock_tray(existing_tray)
	else if(isnull(existing_toolbox))
		var/turf/tray_spot = find_tray_spot(surgery_table, redundant_items)
		if(isnull(tray_spot))
			// No tray, so keep the old tools where they are.
			log_mapping("[name]: no free spot for a surgery tray near the robotics operating table at [AREACOORD(surgery_table)].")
			return SS_INIT_SUCCESS
		new tray_type(tray_spot)

	for(var/obj/item/redundant as anything in redundant_items)
		qdel(redundant)

	return SS_INIT_SUCCESS

/// Fills an empty tray with the tools a fresh tray_type would have.
/datum/controller/subsystem/robotics_surgery_tray/proc/stock_tray(obj/item/surgery_tray/tray)
	var/obj/item/surgery_tray/donor = new tray_type(null)
	for(var/obj/item/tool in donor)
		tool.forceMove(tray)
	qdel(donor)
	tray.update_appearance()

/**
 * Picks where the new tray goes.
 *
 * The spot that held the most of the old kit comes first, so the tray takes over where the tools were.
 * With no old kit, the nearest free table in the surgery room is used, then the nearest free floor.
 */
/datum/controller/subsystem/robotics_surgery_tray/proc/find_tray_spot(obj/structure/table/optable/surgery_table, list/obj/item/redundant_items)
	var/list/kit_spots = list()
	for(var/obj/item/redundant as anything in redundant_items)
		// A duffelbag counts for every tool inside it.
		kit_spots[redundant.loc] += 1 + length(redundant.contents)

	var/turf/best_spot
	for(var/turf/kit_spot as anything in kit_spots)
		if(rate_spot(kit_spot, allow_clutter = TRUE) == TRAY_SPOT_BLOCKED)
			continue
		if(isnull(best_spot) || kit_spots[kit_spot] > kit_spots[best_spot] \
			|| (kit_spots[kit_spot] == kit_spots[best_spot] && get_dist(kit_spot, surgery_table) < get_dist(best_spot, surgery_table)))
			best_spot = kit_spot
	if(best_spot)
		return best_spot

	var/area/surgery_room = get_area(surgery_table)
	var/turf/best_table
	var/turf/best_floor
	for(var/turf/candidate as anything in RANGE_TURFS(TRAY_SEARCH_RANGE, surgery_table))
		if(get_area(candidate) != surgery_room)
			continue
		switch(rate_spot(candidate, allow_clutter = FALSE))
			if(TRAY_SPOT_TABLE)
				if(isnull(best_table) || get_dist(candidate, surgery_table) < get_dist(best_table, surgery_table))
					best_table = candidate
			if(TRAY_SPOT_FLOOR)
				if(isnull(best_floor) || get_dist(candidate, surgery_table) < get_dist(best_floor, surgery_table))
					best_floor = candidate
	return best_table || best_floor

/**
 * Checks if a tray can go on a turf.
 *
 * Arguments:
 * * spot - The turf to check.
 * * allow_clutter - If FALSE, loose items on the turf block it.
 *
 * Returns TRAY_SPOT_TABLE, TRAY_SPOT_FLOOR or TRAY_SPOT_BLOCKED.
 */
/datum/controller/subsystem/robotics_surgery_tray/proc/rate_spot(turf/spot, allow_clutter)
	if(!isfloorturf(spot))
		return TRAY_SPOT_BLOCKED

	var/has_table = FALSE
	for(var/atom/movable/thing as anything in spot)
		if(iseffect(thing))
			continue
		if(istype(thing, /obj/structure/table))
			// Never on the operating table itself.
			if(istype(thing, /obj/structure/table/optable))
				return TRAY_SPOT_BLOCKED
			has_table = TRUE
			continue
		// Directional windows and the like sit on the edge of the tile, not on it.
		if(thing.flags_1 & ON_BORDER_1)
			continue
		if(thing.density || isliving(thing))
			return TRAY_SPOT_BLOCKED
		if(!allow_clutter && isitem(thing) && !thing.anchored)
			return TRAY_SPOT_BLOCKED

	return has_table ? TRAY_SPOT_TABLE : TRAY_SPOT_FLOOR

#undef TRAY_SEARCH_RANGE
#undef TRAY_SPOT_BLOCKED
#undef TRAY_SPOT_FLOOR
#undef TRAY_SPOT_TABLE
