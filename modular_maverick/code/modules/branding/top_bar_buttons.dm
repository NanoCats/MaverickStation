/**
 * Top bar buttons we have nothing behind.
 * "Relays" sends players to the upstream server's connection relays, and we run none.
 * "Wiki" opens the wiki, and we have none.
 * Both are hidden rather than removed, so they can come back if that changes.
 */
/client/New(TopicData)
	. = ..()
	if(!QDELETED(src))
		winset(src, "relays", "is-visible=false")
		winset(src, "wiki", "is-visible=false")

/client/go2relay()
	to_chat(usr, span_notice("This server doesn't use connection relays."))
