/**
 * A watchdog measures one vital station function.
 *
 * When the function stays below its threshold for longer than the grace period, the watchdog reports a shortfall to AMAS.
 * It does not care who holds which job. A slot filled by someone who is not doing the work counts the same as an empty slot.
 */
/datum/amas_watchdog
	/// Shown in the AMAS status readout
	var/name = "Unnamed function"
	/// The job AMAS staffs to fix a shortfall here
	var/datum/job/dispatch_job
	/// Health below this counts as a shortfall. 1 means the target is fully met.
	var/shortfall_threshold = 0.5
	/// How long a shortfall must last before it is reported
	var/grace_period = 10 MINUTES
	/// No measuring until this much of the round has passed, so the roundstart crew gets a head start
	var/warmup = 15 MINUTES
	/// Health from the last evaluation, from 0 to 1
	var/health = 1
	/// world.time when the current shortfall started, or null if there is none
	var/shortfall_started
	/// Set once the current shortfall has been reported, so it is reported only once
	var/shortfall_reported = FALSE
	/// Human readable result of the last measurement
	var/status_text = "Not measured yet"

/datum/amas_watchdog/proc/evaluate()
	if(STATION_TIME_PASSED() < warmup)
		status_text = "Warming up"
		return

	health = clamp(measure(), 0, 1)
	if(health >= shortfall_threshold)
		shortfall_started = null
		shortfall_reported = FALSE
		return

	if(isnull(shortfall_started))
		shortfall_started = world.time
		return

	if(world.time - shortfall_started >= grace_period)
		SSamas.report_shortfall(src)

/// Returns how well this function is doing, from 0 (dead) to 1 (target met), and updates status_text. Override this.
/datum/amas_watchdog/proc/measure()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("[type] does not override measure()")

/// One line for the AMAS status readout
/datum/amas_watchdog/proc/get_status_line()
	if(STATION_TIME_PASSED() < warmup)
		return "[name]: warming up, starts measuring in [DisplayTimeText(warmup - STATION_TIME_PASSED())]"
	var/state = "OK"
	if(shortfall_reported)
		state = "SHORTFALL"
	else if(shortfall_started)
		state = "short for [DisplayTimeText(world.time - shortfall_started)]"
	return "[name]: [round(health * 100)]% ([state]) - [status_text]"
