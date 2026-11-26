// Operation Elephant probes. Unit test builds only.
// These log extra detail for failures that show up at random in CI, so the next failing run
// says who caused it. They never fail a test on their own. tools/ci/elephant/harvest.py reads
// the "ELEPHANT" lines.

/// Builds a short call stack string from a callee frame.
/proc/elephant_stack(callee/frame, max_frames = 12)
	var/list/lines = list()
	// Skip the Destroy chain and qdel itself, so the first frame is whoever asked for the delete.
	while(frame && (findtext("[frame.proc]", "/Destroy") || "[frame.proc]" == "/proc/qdel"))
		frame = frame.caller
	while(frame && length(lines) < max_frames)
		var/datum/frame_src = frame.src
		lines += "[frame.proc] ([frame.file],[frame.line]) src=[frame_src ? "[frame_src.type]" : "null"]"
		frame = frame.caller
	return jointext(lines, " <- ")

// Atoms deleted before SSatoms initialized them show up later as
// "qdel'd before we could call Initialize()" with no hint of who deleted them.
/atom/Destroy(force)
	// Turfs get swapped before init all the time during map load, so only objects and mobs are logged.
	if(!isturf(src) && !(flags_1 & INITIALIZED_1))
		log_world("ELEPHANT early_qdel [type] at [AREACOORD(src)]: [elephant_stack(caller)]")
	return ..()
