/**
 * Runs an AMAS cyborg.
 *
 * The brain keeps a list of task types. Each tick it works the current task, or asks the task types for the next job.
 * It walks with the move manager's JPS loop and does the job once it stands next to the target.
 * A player taking control of the body pauses the brain.
 */
/datum/amas_brain
	/// The cyborg this brain runs
	var/mob/living/silicon/robot/body
	/// The factory that built us. We go back to it when there is nothing to do.
	var/obj/machinery/cyborg_factory/home
	/// Task types this unit knows, in order of priority
	var/list/task_types = list()
	/// The job we are on now
	var/datum/amas_task/current_task
	/// How often we failed to reach each target, keyed by REF() so we hold no hard references
	var/list/unreachable = list()
	/// The move loop walking us to the current target
	var/datum/move_loop/has_target/jps/move_loop
	/// Set once we reported that there is nothing left to do, so the radio is not spammed
	var/reported_idle = FALSE

/datum/amas_brain/New(mob/living/silicon/robot/new_body, obj/machinery/cyborg_factory/new_home)
	body = new_body
	home = new_home
	SSamas.register_unit(body, src)
	RegisterSignal(body, COMSIG_QDELETING, PROC_REF(on_body_deleted))
	START_PROCESSING(SSprocessing, src)

/datum/amas_brain/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	stop_moving()
	QDEL_NULL(current_task)
	body = null
	home = null
	return ..()

/datum/amas_brain/proc/on_body_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/amas_brain/process(seconds_per_tick)
	if(body.stat != STABLE || body.client || body.incapacitated)
		stop_moving()
		return
	if(!body.cell?.charge)
		stop_moving()
		return

	if(isnull(current_task))
		current_task = find_task()
		if(isnull(current_task))
			go_home()
			return
		reported_idle = FALSE

	if(!current_task.still_needed())
		finish_task()
		return

	if(!body.Adjacent(current_task.target))
		head_to(current_task.target)
		return

	stop_moving()
	body.face_atom(current_task.target)
	current_task.do_job(body)
	finish_task()

/// Asks each task type, in priority order, for a job. Returns a new task or null.
/datum/amas_brain/proc/find_task()
	for(var/task_type in task_types)
		var/datum/amas_task/task = new task_type(src)
		if(task.pick_target())
			return task
		qdel(task)
	return null

/datum/amas_brain/proc/finish_task()
	stop_moving()
	QDEL_NULL(current_task)

/// Starts walking to the target, or counts a failure if we are stuck
/datum/amas_brain/proc/head_to(atom/target)
	if(move_loop && move_loop.target == target)
		return
	stop_moving()
	move_loop = GLOB.move_manager.jps_move(body,
		target,
		delay = max(body.cached_multiplicative_slowdown, 1.5),
		repath_delay = 2 SECONDS,
		max_path_length = AMAS_MAX_PATH_LENGTH,
		minimum_distance = 1,
		access = SSid_access.get_region_access_list(list(REGION_ALL_STATION)),
		simulated_only = TRUE,
		subsystem = SSai_movement,
		diagonal_handling = DIAGONAL_REMOVE_CLUNKY,
	)
	if(isnull(move_loop))
		give_up(target)
		return
	RegisterSignal(move_loop, COMSIG_MOVELOOP_JPS_FINISHED_PATHING, PROC_REF(on_path_finished))
	RegisterSignal(move_loop, COMSIG_QDELETING, PROC_REF(on_loop_deleted))

/datum/amas_brain/proc/on_path_finished(datum/move_loop/has_target/jps/source, list/path)
	SIGNAL_HANDLER
	if(length(path))
		return
	var/atom/target = source.target
	INVOKE_ASYNC(src, PROC_REF(give_up), target)

/datum/amas_brain/proc/on_loop_deleted()
	SIGNAL_HANDLER
	move_loop = null

/// Counts a failed attempt to reach the target. Past AMAS_MAX_PATH_FAILURES we drop the job.
/datum/amas_brain/proc/give_up(atom/target)
	if(isnull(target))
		return
	unreachable[REF(target)] += 1
	if(unreachable[REF(target)] < AMAS_MAX_PATH_FAILURES)
		return
	log_game("AMAS: [body.real_name] could not reach [target] at [AREACOORD(target)] and gave up on it.")
	if(current_task?.target == target)
		finish_task()

/datum/amas_brain/proc/is_reachable(atom/target)
	return unreachable[REF(target)] < AMAS_MAX_PATH_FAILURES

/datum/amas_brain/proc/stop_moving()
	if(move_loop)
		qdel(move_loop)
	move_loop = null

/// Walks back to the factory and parks there
/datum/amas_brain/proc/go_home()
	if(!reported_idle)
		reported_idle = TRUE
		body.say("All assigned tasks complete. Returning to standby.")
	if(QDELETED(home) || get_turf(body) == get_turf(home))
		stop_moving()
		return
	if(get_dist(body, home) <= 1)
		stop_moving()
		body.Move(get_turf(home), get_dir(body, home))
		return
	head_to(home)

/// The engineering unit: brings station power up
/datum/amas_brain/engineering
	task_types = list(
		/datum/amas_task/solar_tracking,
		/datum/amas_task/smes_setup,
	)

/**
 * One job for an AMAS unit: a target, and something to do to it once we stand next to it.
 */
/datum/amas_task
	/// The brain doing this task
	var/datum/amas_brain/brain
	/// What we walk to and work on
	var/atom/target

/datum/amas_task/New(datum/amas_brain/new_brain)
	brain = new_brain

/datum/amas_task/Destroy()
	brain = null
	target = null
	return ..()

/// Finds the closest target that needs this job. Returns TRUE if one was found.
/datum/amas_task/proc/pick_target()
	var/closest_distance = INFINITY
	for(var/atom/candidate as anything in get_candidates())
		if(!is_station_level(candidate.z) || candidate.z != brain.body.z || !brain.is_reachable(candidate) || !needs_job(candidate))
			continue
		var/distance = get_dist(brain.body, candidate)
		if(distance < closest_distance)
			closest_distance = distance
			target = candidate
	return !isnull(target)

/// Everything this task could work on
/datum/amas_task/proc/get_candidates()
	return list()

/// Whether this candidate needs the job done
/datum/amas_task/proc/needs_job(atom/candidate)
	return FALSE

/datum/amas_task/proc/still_needed()
	return !QDELETED(target) && needs_job(target)

/// Does the job. The unit is standing next to the target.
/datum/amas_task/proc/do_job(mob/living/silicon/robot/worker)
	return

/// Turns on sun tracking at a solar control console
/datum/amas_task/solar_tracking

/datum/amas_task/solar_tracking/get_candidates()
	return SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/solar_control)

/datum/amas_task/solar_tracking/needs_job(obj/machinery/power/solar_control/console)
	return console.track == SOLAR_TRACK_OFF && !(console.machine_stat & (BROKEN|NOPOWER))

/datum/amas_task/solar_tracking/do_job(mob/living/silicon/robot/worker)
	var/obj/machinery/power/solar_control/console = target
	console.search_for_connected()
	if(console.connected_tracker)
		console.track = SOLAR_TRACK_AUTO
		console.connected_tracker.sun_update(SSsun, SSsun.azimuth)
	else
		console.track = SOLAR_TRACK_TIMED
	console.update_appearance()
	worker.visible_message(span_notice("[worker] sets [console] to track the sun."))
	playsound(console, 'sound/machines/terminal/terminal_button07.ogg', 45, TRUE)
	log_game("AMAS: [worker.real_name] turned on solar tracking at [AREACOORD(console)].")

/// Sets an SMES to charge and output at full rate
/datum/amas_task/smes_setup

/datum/amas_task/smes_setup/get_candidates()
	return SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/smes)

/datum/amas_task/smes_setup/needs_job(obj/machinery/power/smes/smes)
	if(isnull(smes.terminal) || (smes.machine_stat & BROKEN) || smes.panel_open)
		return FALSE
	return !smes.input_attempt || !smes.output_attempt || smes.input_level < smes.input_level_max || smes.output_level < smes.output_level_max

/datum/amas_task/smes_setup/do_job(mob/living/silicon/robot/worker)
	var/obj/machinery/power/smes/smes = target
	smes.input_attempt = TRUE
	smes.input_level = smes.input_level_max
	smes.output_attempt = TRUE
	smes.output_level = smes.output_level_max
	smes.update_appearance(UPDATE_OVERLAYS)
	worker.visible_message(span_notice("[worker] sets [smes] to full input and output."))
	playsound(smes, 'sound/machines/terminal/terminal_button07.ogg', 45, TRUE)
	log_game("AMAS: [worker.real_name] set [smes] to full input and output at [AREACOORD(smes)].")
