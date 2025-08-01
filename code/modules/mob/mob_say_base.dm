/mob/proc/say()
	return

/mob/verb/whisper(message as text)
	set name = "Whisper"
	set category = "IC"
	return

/mob/verb/say_verb(message as text)
	set name = "Say"
	set category = "IC"

	//Let's try to make users fix their errors - we try to detect single, out-of-place letters and 'unintended' words
	/*
	var/first_letter = copytext(message,1,2)
	if((copytext(message,2,3) == " " && first_letter != "I" && first_letter != "A" && first_letter != ";") || cmptext(copytext(message,1,5), "say ") || cmptext(copytext(message,1,4), "me ") || cmptext(copytext(message,1,6), "looc ") || cmptext(copytext(message,1,5), "ooc ") || cmptext(copytext(message,2,6), "say "))
		var/response = alert(usr, "Do you really want to say this using the *say* verb?\n\n[message]\n", "Confirm your message", "Yes", "Edit message", "No")
		if(response == "Edit message")
			message = input(usr, "Please edit your message carefully:", "Edit message", message)
			if(!message)
				return
		else if(response == "No")
			return
	*/
	set_typing_indicator(FALSE)
	usr.say(message)

/mob/verb/me_verb(message as text)
	set name = "Me"
	set category = "IC"

	message = sanitize(message)

	set_typing_indicator(FALSE, TRUE)
	if(use_me)
		custom_emote(usr.emote_type, message, intentional = TRUE)
	else
		usr.emote(message, intentional = TRUE)


/mob/proc/say_dead(message)
	if(client)
		if(!check_rights(R_ADMIN, FALSE))
			if(!GLOB.dsay_enabled)
				to_chat(src, "<span class='danger'>Deadchat is globally muted.</span>")
				return

		if(check_mute(client.ckey, MUTE_DEADCHAT))
			to_chat(src, "<span class='warning'>You cannot talk in deadchat (muted).</span>")
			return

		if(!(client.prefs.toggles & PREFTOGGLE_CHAT_DEAD))
			to_chat(src, "<span class='danger'>You have deadchat muted.</span>")
			return

		if(client.handle_spam_prevention(message, MUTE_DEADCHAT))
			return

	if(SEND_SIGNAL(src, COMSIG_MOB_DEADSAY, message) & MOB_DEADSAY_SIGNAL_INTERCEPT)
		return

	if(message in USABLE_DEAD_EMOTES)
		emote(copytext(message, 2), intentional = TRUE)
		log_emote(message, src)
		create_log(DEADCHAT_LOG, message)
		return

	say_dead_direct("[pick("complains", "moans", "whines", "laments", "blubbers", "salts", "copes", "seethes", "malds")], <span class='message'>\"[message]\"</span>", src, raw_message=message)
	create_log(DEADCHAT_LOG, message)
	log_ghostsay(message, src)

/**
 * Checks if the mob can understand the other speaker
 *
 * If it return FALSE, then the message will have some letters replaced with stars from the heard message
*/
/mob/proc/say_understands(atom/movable/other, datum/language/speaking = null)
	if(stat == DEAD)
		return TRUE

	//Universal speak makes everything understandable, for obvious reasons.
	if(universal_speak || universal_understand)
		return TRUE

	//Languages are handled after.
	if(!speaking)
		if(!other || !ismob(other))
			return TRUE
		var/mob/other_mob = other
		if(other_mob.universal_speak)
			return TRUE
		if(is_ai(src) && ispAI(other_mob))
			return TRUE
		if(istype(other_mob, src.type) || istype(src, other_mob.type))
			return TRUE
		return FALSE

	if(speaking.flags & INNATE)
		return TRUE

	//Language check.
	for(var/datum/language/L in languages)
		if(speaking.name == L.name)
			return TRUE

	return FALSE

/mob/proc/say_quote(message, datum/language/speaking = null)
	var/verb = "says"
	var/ending = copytext(message, length(message))

	if(speaking)
		verb = speaking.get_spoken_verb(ending)
	else
		if(ending == "!")
			verb = pick("exclaims", "shouts", "yells")
		else if(ending == "?")
			verb = "asks"
	return verb

/mob/proc/get_ear()
	// returns an atom representing a location on the map from which this
	// mob can hear things

	// should be overloaded for all mobs whose "ear" is separate from their "mob"

	return get_turf(src)

/proc/say_test(text)
	var/ending = copytext(text, length(text))
	if(ending == "?")
		return "1"
	else if(ending == "!")
		return "2"
	return "0"

//parses the message mode code (e.g. :h, :w) from text, such as that supplied to say.
//returns the message mode string or null for no message mode.
//standard mode is the mode returned for the special ';' radio code.
/mob/proc/parse_message_mode(message, standard_mode = "headset")
	if(length(message) >= 1 && copytext(message, 1, 2) == ";")
		return standard_mode

	if(length(message) >= 2)
		var/channel_prefix = copytext_char(message, 1, 3)
		return GLOB.department_radio_keys[channel_prefix]

	return null

/datum/multilingual_say_piece
	var/datum/language/speaking = null
	var/message = ""

/datum/multilingual_say_piece/New(datum/language/new_speaking, new_message)
	. = ..()
	speaking = new_speaking
	if(new_message)
		message = new_message

/mob/proc/find_valid_prefixes(message)
	var/list/prefixes = list() // [["Common", start, end], ["Gutter", start, end]]
	var/lower_message = lowertext(message)
	var/is_alphanumeric = FALSE
	var/was_alphanumeric = FALSE
	for(var/i in 1 to length(message))
		was_alphanumeric = is_alphanumeric
		is_alphanumeric = GLOB.is_alphanumeric.Find(lower_message[i])
		if(was_alphanumeric)
			// Language prefixes should not activate in the middle of a word or number.
			continue

		var/selection = trim_right(copytext(lower_message, i, i + 3))
		var/datum/language/L = GLOB.language_keys[selection]
		if(L != null && can_speak_language(L)) // What the fuck... remove the L != null check if you ever find out what the fuck is adding `null` to the languages list on absolutely random mobs... seriously what the hell...
			prefixes[++prefixes.len] = list(L, i, i + length(selection))
		else if(!L && i == 1)
			prefixes[++prefixes.len] = list(get_default_language(), i, i)

	return prefixes

/proc/strip_prefixes(message)
	. = ""
	var/last_index = 1
	for(var/i in 1 to length(message))
		var/selection = trim_right(lowertext(copytext(message, i, i + 3)))
		var/datum/language/L = GLOB.language_keys[selection]
		if(L)
			. += copytext(message, last_index, i)
			last_index = i + 3
		if(i + 1 > length(message))
			. += copytext(message, last_index)

// this returns a structured message with language sections
// list(/datum/multilingual_say_piece(common, "hi"), /datum/multilingual_say_piece(farwa, "squik"), /datum/multilingual_say_piece(common, "meow!"))
/mob/proc/parse_languages(message)
	. = list()

	// Noise language is a snowflake
	if(copytext(message, 1, 2) == "!" && length(message) > 1)
		return list(new /datum/multilingual_say_piece(GLOB.all_languages["Noise"], trim(strip_prefixes(copytext(message, 2)))))

	// Scan the message for prefixes
	var/list/prefix_locations = find_valid_prefixes(message)
	if(!LAZYLEN(prefix_locations)) // There are no prefixes... or at least, no _valid_ prefixes.
		. += new /datum/multilingual_say_piece(get_default_language(), trim(strip_prefixes(message))) // So we'll just strip those pesky things and still make the message.

	for(var/i in 1 to length(prefix_locations))
		var/current = prefix_locations[i] // ["Common", keypos]

		// There are a few things that will make us want to ignore all other languages in - namely, HIVEMIND languages.
		var/datum/language/L = current[1]
		if(L && L.flags & HIVEMIND)
			. = new /datum/multilingual_say_piece(L, trim(strip_prefixes(message)))
			break

		if(i + 1 > length(prefix_locations)) // We are out of lookaheads, that means the rest of the message is in cur lang
			var/spoke_message = handle_autohiss(trim(copytext(message, current[3])), L)
			. += new /datum/multilingual_say_piece(current[1], spoke_message)
		else
			var/next = prefix_locations[i + 1] // We look ahead at the next message to see where we need to stop.
			var/spoke_message = handle_autohiss(trim(copytext(message, current[3], next[2])), L)
			. += new /datum/multilingual_say_piece(current[1], spoke_message)

/* These are here purely because it would be hell to try to convert everything over to using the multi-lingual system at once */
/proc/message_to_multilingual(message, datum/language/speaking = null)
	. = list(new /datum/multilingual_say_piece(speaking, message))

/proc/multilingual_to_message(list/message_pieces)
	. = ""
	for(var/datum/multilingual_say_piece/S in message_pieces)
		. += S.message + " "
	. = trim_right(.)
