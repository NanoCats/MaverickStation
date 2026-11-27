/// A cyborg factory builds a working AMAS unit, and the unit's power jobs do what they say.
/datum/unit_test/amas_units

/datum/unit_test/amas_units/Run()
	var/obj/machinery/cyborg_factory/factory = allocate(/obj/machinery/cyborg_factory, run_loc_floor_bottom_left)
	var/mob/living/silicon/robot/unit = factory.build_amas_unit(/mob/living/silicon/robot/model/engineering, /datum/amas_brain/engineering)
	TEST_ASSERT_NOTNULL(unit, "The factory built nothing.")
	allocated += unit
	var/datum/amas_brain/brain = SSamas.units[unit]
	TEST_ASSERT(istype(brain, /datum/amas_brain/engineering), "The unit was not registered with its brain.")
	TEST_ASSERT_NULL(unit.connected_ai, "The unit linked to an AI.")
	TEST_ASSERT(findtext(unit.real_name, "AMAS ENG-") == 1, "The unit was named [unit.real_name].")

	var/obj/machinery/power/smes/smes = allocate(/obj/machinery/power/smes, run_loc_floor_top_right)
	smes.input_attempt = FALSE
	smes.output_attempt = FALSE
	var/datum/amas_task/smes_setup/smes_task = new(brain)
	smes_task.target = smes
	smes_task.do_job(unit)
	TEST_ASSERT(smes.input_attempt && smes.output_attempt, "The SMES job did not turn input and output on.")
	TEST_ASSERT_EQUAL(smes.input_level, smes.input_level_max, "The SMES job did not set full input.")
	qdel(smes_task)

	var/obj/machinery/power/solar_control/console = allocate(/obj/machinery/power/solar_control, run_loc_floor_top_right)
	var/datum/amas_task/solar_tracking/solar_task = new(brain)
	solar_task.target = console
	solar_task.do_job(unit)
	TEST_ASSERT_NOTEQUAL(console.track, SOLAR_TRACK_OFF, "The solar job did not turn tracking on.")
	qdel(solar_task)

	qdel(unit)
	TEST_ASSERT(QDELETED(brain), "The brain outlived its unit.")
	TEST_ASSERT(!(unit in SSamas.units), "The unit stayed on the AMAS roster after deletion.")
