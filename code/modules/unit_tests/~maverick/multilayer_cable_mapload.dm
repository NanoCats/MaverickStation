/// A multilayer cable hub mapped on top of a plain cable deletes that cable.
/// At mapload this must wait until the plain cable has initialized, or create_and_destroy
/// reports "qdel'd before we could call Initialize()". Seen with The Lizard's Gas ruin.
/datum/unit_test/multilayer_cable_mapload

/datum/unit_test/multilayer_cable_mapload/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/had_flags = SSatoms.BadInitializeCalls[/obj/structure/cable/layer1]
	SSatoms.BadInitializeCalls -= /obj/structure/cable/layer1

	// Make both cables the way the map loader does: created, not yet initialized. The hub goes first.
	SSatoms.map_loader_begin(REF(src))
	var/obj/structure/cable/multilayer/hub = new(spot)
	hub.cable_layer = CABLE_LAYER_1
	var/obj/structure/cable/layer1/plain = new(spot)
	SSatoms.map_loader_stop(REF(src))
	SSatoms.InitializeAtoms(list(hub, plain))

	var/flags = SSatoms.BadInitializeCalls[/obj/structure/cable/layer1]
	TEST_ASSERT(!(flags & BAD_INIT_QDEL_BEFORE), "The hub deleted the plain cable before it initialized.")
	TEST_ASSERT(QDELETED(plain), "The hub did not remove the plain cable on its layer.")

	// Leave the global as we found it, so a real early delete elsewhere still fails create_and_destroy.
	if(had_flags)
		SSatoms.BadInitializeCalls[/obj/structure/cable/layer1] = had_flags
	else
		SSatoms.BadInitializeCalls -= /obj/structure/cable/layer1
	qdel(hub)
