/// Watches whether the station's power is set up: solars tracking the sun and SMES units charging at full rate
/datum/amas_watchdog/power
	name = "Power"
	dispatch_job = /datum/job/station_engineer
	dispatch_unit_model = /mob/living/silicon/robot/model/engineering
	dispatch_brain = /datum/amas_brain/engineering
	shortfall_threshold = 1
	grace_period = 5 MINUTES
	warmup = 10 MINUTES

/datum/amas_watchdog/power/measure()
	var/total = 0
	var/done = 0
	var/consoles_tracking = 0
	var/consoles_total = 0
	for(var/obj/machinery/power/solar_control/console as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/solar_control))
		if(!is_station_level(console.z) || (console.machine_stat & (BROKEN|NOPOWER)))
			continue
		consoles_total++
		if(console.track != SOLAR_TRACK_OFF)
			consoles_tracking++
	var/smes_ready = 0
	var/smes_total = 0
	for(var/obj/machinery/power/smes/smes as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/smes))
		if(!is_station_level(smes.z) || isnull(smes.terminal) || (smes.machine_stat & BROKEN))
			continue
		smes_total++
		if(smes.input_attempt && smes.output_attempt && smes.input_level >= smes.input_level_max / 2)
			smes_ready++
	total = consoles_total + smes_total
	done = consoles_tracking + smes_ready
	status_text = "[consoles_tracking] of [consoles_total] solar arrays tracking, [smes_ready] of [smes_total] SMES charging"
	if(!total)
		return 1
	return done / total
