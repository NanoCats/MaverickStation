/**
 * The space law book opened the upstream server's wiki. MaverickStation has no wiki: space law
 * will get its own in-game handbook. Until then the book is blank, with a note saying why.
 * It still teaches Legalese when read, like before.
 */
/obj/item/book/manual/wiki/security_space_law/display_content(mob/living/user)
	credit_book_to_reader(user)
	to_chat(user, span_notice("The pages are blank, apart from a sticky note on the first one: \"New edition at the printers. Until then, use common sense and ask the Head of Security.\""))
