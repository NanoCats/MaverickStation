/// Watches how many materials flow into the station's ore silo
/datum/amas_watchdog/materials
	name = "Materials"
	dispatch_job = /datum/job/shaft_miner
	/// Only deposits newer than this count toward the target
	var/window = 20 MINUTES
	/// Sheets per window the station wants with nobody aboard
	var/base_target_sheets = 50
	/// Extra sheets per window for each living player
	var/sheets_per_player = 15
	/// Silo total from the last measurement, to find what came in since then
	var/last_silo_total
	/// Deposits seen inside the window, as list(world.time, sheets) pairs
	var/list/deposits = list()

/datum/amas_watchdog/materials/measure()
	var/obj/machinery/ore_silo/silo = GLOB.ore_silo_default
	if(isnull(silo))
		status_text = "No station ore silo"
		return 0

	// Polling the total catches every way materials reach the silo. Withdrawals made at the same time hide some inflow, which is fine for a rough measure.
	var/silo_total = silo.materials.total_amount()
	if(!isnull(last_silo_total) && silo_total > last_silo_total)
		deposits += list(list(world.time, (silo_total - last_silo_total) / SHEET_MATERIAL_AMOUNT))
	last_silo_total = silo_total

	var/sheets_in_window = 0
	for(var/list/deposit as anything in deposits.Copy())
		if(world.time - deposit[1] > window)
			deposits -= list(deposit)
			continue
		sheets_in_window += deposit[2]

	var/target = base_target_sheets + sheets_per_player * living_player_count()
	status_text = "[round(sheets_in_window)] of [target] sheets in the last [DisplayTimeText(window)]"
	return sheets_in_window / target
