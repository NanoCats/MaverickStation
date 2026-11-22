/// Opens the welcome window (privacy policy and age gate) if this client still needs it. Can sleep.
/client/proc/prompt_age_gate()
	if(!SSage_gate.needs_check(src))
		return
	if(SSage_gate.lookup(ckey))
		return
	if(!mob)
		return
	SSage_gate.open_prompt(src)

/mob/dead/new_player/Login()
	. = ..()
	if(client)
		INVOKE_ASYNC(client, TYPE_PROC_REF(/client, prompt_age_gate))

// Lobby buttons on the title screen come in as hrefs. Joining, readying and observing wait for the age gate.
/client/Topic(href, href_list, hsrc, hsrc_command)
	if(isnewplayer(hsrc) && (href_list["toggle_ready"] || href_list["late_join"] || href_list["observe"]) && SSage_gate.needs_check(src))
		to_chat(src, span_warning("You need to finish the welcome window before you can play."))
		INVOKE_ASYNC(src, PROC_REF(prompt_age_gate))
		return
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
