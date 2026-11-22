/**
 * Export VV
 *
 * Adds "Export VV" to the View Variables "Select Action" dropdown.
 * It opens a small window with a plain text dump of the datum's variables,
 * ready to copy, plus a link to save the same dump as a .txt file.
 *
 * The dump is meant to be pasted into bug reports and chats, so a few
 * identifying vars are redacted. See GLOB.vv_export_redacted_vars.
 */

#define VV_HK_EXPORT_VV "export_vv"
#define VV_HK_EXPORT_VV_FILE "export_vv_file"

/// How many entries of a list we print before we stop.
#define VV_EXPORT_MAX_LIST_ENTRIES 50
/// How deep we go into lists inside lists.
#define VV_EXPORT_MAX_DEPTH 2
/// Longest text value we print in full.
#define VV_EXPORT_MAX_TEXT 300
/// How many locs up we walk for the location line.
#define VV_EXPORT_MAX_LOC_CHAIN 10

/// Vars that are replaced with "(redacted)" in exports.
GLOBAL_LIST_INIT(vv_export_redacted_vars, list(
	"computer_id" = TRUE,
	"lastKnownIP" = TRUE,
))

/datum/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION(VV_HK_EXPORT_VV, "Export VV")

/datum/vv_do_topic(list/href_list)
	. = ..()
	if(!.)
		return

	if(href_list[VV_HK_EXPORT_VV])
		open_vv_export(usr)

	if(href_list[VV_HK_EXPORT_VV_FILE])
		save_vv_export(usr)

/// Opens the export window for the user.
/datum/proc/open_vv_export(mob/user)
	var/export_text = build_vv_export()
	var/line_count = length(splittext(export_text, "\n"))

	var/list/html = list()
	html += "<div style='margin-bottom:4px;'>"
	html += "<button onclick=\"var box = document.getElementById('vv_export'); box.focus(); box.select(); document.execCommand('copy');\">Copy all</button> "
	html += "<a href='[VV_HREF_TARGET_INTERNAL(src, VV_HK_EXPORT_VV_FILE)]'>Save as .txt</a> | "
	html += "<a href='[VV_HREF_TARGET_INTERNAL(src, VV_HK_EXPORT_VV)]'>Refresh</a> "
	html += "<span style='opacity:0.7;'>([line_count] lines)</span>"
	html += "</div>"
	html += "<textarea id='vv_export' readonly wrap='off' style='width:100%; height:90%; font-family:monospace; font-size:11px; box-sizing:border-box;'>[html_encode(export_text)]</textarea>"

	var/datum/browser/popup = new(user, "vv_export", "Export VV: [type]", 720, 640)
	popup.set_content(jointext(html, ""))
	popup.open()

/// Sends the export to the user as a .txt download.
/datum/proc/save_vv_export(mob/user)
	if(!user?.client)
		return
	var/type_text = "[type]"
	var/short_type = copytext(type_text, findlasttext(type_text, "/") + 1)
	var/tmp_path = "tmp/vv_export_[user.ckey].txt"
	fdel(tmp_path)
	rustg_file_write(build_vv_export(), tmp_path)
	DIRECT_OUTPUT(user, ftp(file(tmp_path), "vv_[short_type]_round_[GLOB.round_id || "local"].txt"))
	fdel(tmp_path)

/// Builds the plain text dump of this datum.
/datum/proc/build_vv_export()
	var/list/lines = list()
	lines += "=== VV export ==="
	lines += "Type: [type]"
	lines += "Ref: [REF(src)]"
	if("name" in vars)
		lines += "Name: [vv_export_value(vars["name"])]"
	if(QDELETED(src))
		lines += "QDELETED: yes (gc_destroyed = [gc_destroyed])"
	if(isatom(src))
		var/atom/atom_self = src
		lines += "Location: [AREACOORD(atom_self)]"
		if(ismovable(atom_self) && atom_self.loc && !isturf(atom_self.loc))
			var/list/chain = list()
			var/atom/current = atom_self.loc
			while(current && !isturf(current) && length(chain) < VV_EXPORT_MAX_LOC_CHAIN)
				chain += vv_export_datum_line(current)
				current = current.loc
			if(length(chain))
				lines += "Inside: [jointext(chain, " -> ")]"
	lines += "Round: [GLOB.round_id || "none"], round clock [gameTimestamp()], world.time [world.time]"
	lines += ""

	var/list/var_lines = list()
	var/list/changed = list()
	for(var/var_name in sort_list(vars))
		if(!can_vv_get(var_name))
			continue
		if(GLOB.vv_export_redacted_vars[var_name])
			var_lines += "  [var_name] = (redacted)"
			continue
		var/value = vars[var_name]
		var/is_changed = !islist(value) && value != initial(src.vars[var_name])
		if(is_changed)
			changed += var_name
		var_lines += "[is_changed ? "* " : "  "][var_name] = [vv_export_value(value, 0)]"

	lines += "Changed from compile default ([length(changed)]): [length(changed) ? jointext(changed, ", ") : "none"]"
	lines += ""
	lines += "Vars ([length(var_lines)]). \"*\" means changed from compile default. Lists are not compared."
	lines += var_lines
	return jointext(lines, "\n")

/// Turns a value into a single readable string. Lists come back as several lines.
/proc/vv_export_value(value, depth = 0)
	if(isnull(value))
		return "null"
	if(isnum(value))
		return num2text(value, 12)
	if(istext(value))
		var/text_value = replacetext(replacetext(value, "\\", "\\\\"), "\n", "\\n")
		var/full_length = length(text_value)
		if(full_length > VV_EXPORT_MAX_TEXT)
			text_value = "[copytext(text_value, 1, VV_EXPORT_MAX_TEXT + 1)]... ([full_length] chars)"
		return "\"[text_value]\""
	if(ispath(value))
		return "[value]"
	if(isfile(value))
		return "'[value]'"
	if(isicon(value))
		return "/icon ([value])"
	if(islist(value))
		return vv_export_list(value, depth)
	if(istype(value, /matrix))
		var/matrix/matrix_value = value
		return "matrix([matrix_value.a], [matrix_value.b], [matrix_value.c], [matrix_value.d], [matrix_value.e], [matrix_value.f])"
	if(isappearance(value))
		return "/appearance ([value])"
	if(isweakref(value))
		var/datum/weakref/weak_value = value
		var/datum/target = weak_value.resolve()
		return "/datum/weakref -> [target ? vv_export_datum_line(target) : "(gone)"]"
	if(isdatum(value))
		return vv_export_datum_line(value)
	return "[value]"

/// One line summary of a datum: type, ref, name and qdel state.
/proc/vv_export_datum_line(datum/thing)
	. = "[thing.type] [REF(thing)]"
	if(("name" in thing.vars) && istext(thing.vars["name"]))
		. += " [vv_export_value(thing.vars["name"])]"
	if(QDELETED(thing))
		. += " (QDELETED)"

/// Prints a list, one entry per line, indented by depth.
/proc/vv_export_list(list/value, depth)
	var/list_length = length(value)
	var/list_name = isalist(value) ? "alist" : "list"
	if(!list_length)
		return "[list_name]() (empty)"
	if(depth >= VV_EXPORT_MAX_DEPTH)
		return "[list_name](len [list_length]) (not expanded)"

	var/indent = ""
	for(var/i in 0 to depth)
		indent += "    "

	var/can_read_assoc = IS_NORMAL_LIST(value) || isalist(value)
	var/list/lines = list("[list_name](len [list_length])")
	var/index = 0
	for(var/key in value)
		index++
		if(index > VV_EXPORT_MAX_LIST_ENTRIES)
			lines += "[indent]... ([list_length - VV_EXPORT_MAX_LIST_ENTRIES] more)"
			break
		var/entry = "[indent][index]: [vv_export_value(key, depth + 1)]"
		if(can_read_assoc && (isalist(value) || !isnum(key)))
			var/assoc_value = value[key]
			if(!isnull(assoc_value))
				entry += " = [vv_export_value(assoc_value, depth + 1)]"
		lines += entry
	return jointext(lines, "\n")

#undef VV_HK_EXPORT_VV
#undef VV_HK_EXPORT_VV_FILE
#undef VV_EXPORT_MAX_LIST_ENTRIES
#undef VV_EXPORT_MAX_DEPTH
#undef VV_EXPORT_MAX_TEXT
#undef VV_EXPORT_MAX_LOC_CHAIN
