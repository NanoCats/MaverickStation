/// Opens the welcome window (privacy policy and age gate) if this client still needs it. Can sleep.
/client/proc/prompt_age_gate()
	SSage_gate.sync_vetted(ckey)
	if(!SSage_gate.needs_check(src))
		return
	if(SSage_gate.lookup(ckey))
		return
	if(!mob)
		return
	SSage_gate.open_prompt(src)

/// Loads this client's stored answers into the cache without opening anything. Can sleep.
/client/proc/preload_age_gate()
	SSage_gate.sync_vetted(ckey)
	if(SSage_gate.needs_check(src))
		SSage_gate.lookup(ckey)

/// The lobby blocked a button because the welcome window is not finished.
/client/proc/age_gate_blocked()
	if(SSage_gate.lookup(ckey))
		return // the stored answers just hadn't loaded yet
	to_chat(src, span_warning("You need to finish the welcome window before you can play."))
	prompt_age_gate()

/mob/dead/new_player/Login()
	. = ..()
	if(!client)
		return
	if(!CONFIG_GET(flag/maverick_lobby_desktop))
		INVOKE_ASYNC(client, TYPE_PROC_REF(/client, prompt_age_gate))
		return
	// The desktop lobby asks for the window once the desktop is up (see "lobby_desktop_up"),
	// so it doesn't open on top of the boot screen. Until then, load the stored answers.
	INVOKE_ASYNC(client, TYPE_PROC_REF(/client, preload_age_gate))
	addtimer(CALLBACK(src, PROC_REF(age_gate_fallback)), 30 SECONDS)

/// The desktop page never came up (it failed and the plain menu is showing instead), so open the window anyway.
/mob/dead/new_player/proc/age_gate_fallback()
	if(!client || maverick_page_alive)
		return
	INVOKE_ASYNC(client, TYPE_PROC_REF(/client, prompt_age_gate))

// Lobby buttons on the title screen come in as hrefs. Joining, readying and observing wait for the age gate.
/client/Topic(href, href_list, hsrc, hsrc_command)
	if(isnewplayer(hsrc) && SSage_gate.needs_check(src))
		if(href_list["lobby_desktop_up"])
			INVOKE_ASYNC(src, PROC_REF(prompt_age_gate))
		if(href_list["toggle_ready"] || href_list["late_join"] || href_list["observe"])
			INVOKE_ASYNC(src, PROC_REF(age_gate_blocked))
			// Drop only the blocked actions. Anything sent with them, like the
			// "assigned_seen" from the job popup, still goes through.
			href_list -= list("toggle_ready", "late_join", "observe")
	return ..()

// The procs below cover the other ways out of the lobby (HUD buttons, the latejoin menu, verbs).
/mob/dead/new_player/make_me_an_observer()
	if(SSage_gate.needs_check(client))
		INVOKE_ASYNC(client, TYPE_PROC_REF(/client, prompt_age_gate))
		return FALSE
	return ..()

/mob/dead/new_player/AttemptLateSpawn(rank)
	if(SSage_gate.needs_check(client))
		INVOKE_ASYNC(client, TYPE_PROC_REF(/client, prompt_age_gate))
		return FALSE
	return ..()

// Bans placed while the database was off live in a data file, so they need their own login check.
/world/IsBanned(key, address, computer_id, type, real_bans_only = FALSE)
	. = ..()
	if(. || type == "world" || !key)
		return
	if(!CONFIG_GET(flag/maverick_age_gate) || !SSage_gate?.is_file_banned(ckey(key)))
		return
	log_access("Failed Login: [key] [address]-[computer_id] - banned by the age gate")
	return list("reason" = "age gate", "desc" = "\nReason: Age verification failed. This server is for adults only.")

ADMIN_VERB(test_age_gate, R_ADMIN, "Test Age Gate", "Opens the welcome window with the age check for yourself. Failing it as an admin does not ban you.", ADMIN_CATEGORY_DEBUG)
	SSage_gate.open_prompt(user, test_age = TRUE)
