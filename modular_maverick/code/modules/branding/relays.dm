/**
 * The top bar's "Relays" button sends players to the upstream server's connection relays.
 * MaverickStation runs no relays, so the button is hidden and the verb says so.
 * Switched off rather than removed, so it can come back if we ever run relays.
 */
/client/New(TopicData)
	. = ..()
	if(!QDELETED(src))
		winset(src, "relays", "is-visible=false")

/client/go2relay()
	to_chat(usr, span_notice("This server doesn't use connection relays."))
