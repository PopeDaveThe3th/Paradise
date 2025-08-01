// This is synced up to the poster placing animation.
#define PLACE_SPEED 30

// Any new `/obj/structure/sign/poster` is expected to also be added to `directional_posters.yml` which makes mappers' life easier. It's easy to do and .yml has plenty of examples inside
// Also don't forget to call for `MAPPING_DIRECTIONAL_HELPERS()` when you add a new poster, you can see examples down below

// The poster item
/obj/item/poster
	name = "rolled-up poster"
	desc = "The poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface. Its vulgar themes have marked it as contraband aboard Nanotrasen space facilities."
	icon = 'icons/obj/contraband.dmi'
	resistance_flags = FLAMMABLE
	var/poster_type
	var/obj/structure/sign/poster/poster_structure

/obj/item/poster/Initialize(mapload, obj/structure/sign/poster/new_poster_structure)
	. = ..()
	poster_structure = new_poster_structure
	if(!new_poster_structure && poster_type)
		poster_structure = new poster_type(src)

	// posters store what name and description they would like their rolled up form to take.
	if(poster_structure)
		name = poster_structure.poster_item_name
		desc = poster_structure.poster_item_desc
		icon_state = poster_structure.poster_item_icon_state

		name = "[name] - [poster_structure.original_name]"

/obj/item/poster/Destroy()
	poster_structure = null
	. = ..()

// These icon_states may be overriden, but are for mapper's convinence
/obj/item/poster/random_contraband
	name = "random contraband poster"
	poster_type = /obj/structure/sign/poster/contraband/random
	icon_state = "rolled_poster"

/obj/item/poster/random_official
	name = "random official poster"
	poster_type = /obj/structure/sign/poster/official/random
	icon_state = "rolled_poster_legit"

/obj/item/poster/syndicate_recruitment
	poster_type = /obj/structure/sign/poster/contraband/syndicate_recruitment
	icon_state = "rolled_poster"

//############################## THE ACTUAL DECALS ###########################

/obj/structure/sign/poster
	name = "poster"
	desc = "A large piece of space-resistant printed paper."
	icon = 'icons/obj/contraband.dmi'
	var/original_name
	var/random_basetype
	var/ruined = FALSE
	var/never_random = FALSE // used for the 'random' subclasses.

	var/poster_item_name = "hypothetical poster"
	var/poster_item_desc = "This hypothetical poster item should not exist, let's be honest here."
	var/poster_item_icon_state = "rolled_poster"

/obj/structure/sign/poster/Initialize(mapload)
	if(random_basetype)
		randomise(random_basetype)
	. = ..()
	if(!ruined)
		original_name = name
		name = "poster - [name]"
		desc = "A large piece of space-resistant printed paper. [desc]"

/obj/structure/sign/poster/proc/randomise(base_type)
	var/list/poster_types = subtypesof(base_type)
	var/list/approved_types = list()
	for(var/t in poster_types)
		var/obj/structure/sign/poster/T = t
		if(initial(T.icon_state) && !initial(T.never_random))
			approved_types |= T

	var/obj/structure/sign/poster/selected = pick(approved_types)

	name = initial(selected.name)
	desc = initial(selected.desc)
	icon_state = initial(selected.icon_state)
	poster_item_name = initial(selected.poster_item_name)
	poster_item_desc = initial(selected.poster_item_desc)
	poster_item_icon_state = initial(selected.poster_item_icon_state)
	ruined = initial(selected.ruined)

/obj/structure/sign/poster/screwdriver_act(mob/user, obj/item/I)
	return

/obj/structure/sign/poster/wirecutter_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(ruined)
		to_chat(user, "<span class='notice'>You remove the remnants of the poster.</span>")
		qdel(src)
	else
		to_chat(user, "<span class='notice'>You carefully remove the poster from the wall.</span>")
		roll_and_drop(user.loc)

/obj/structure/sign/poster/attack_hand(mob/user)
	if(ruined)
		return
	visible_message("[user] rips [src] in a single, decisive motion!" )
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 100, 1)

	var/obj/structure/sign/poster/ripped/R = new(loc)
	R.pixel_y = pixel_y
	R.pixel_x = pixel_x
	R.dir = dir
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/sign/poster/proc/roll_and_drop(loc)
	if(ruined)
		qdel(src)
		return
	pixel_x = 0
	pixel_y = 0
	var/obj/item/poster/P = new(loc, src)
	forceMove(P)
	return P

//seperated to reduce code duplication. Moved here for ease of reference and to unclutter r_wall/attackby()
/turf/simulated/wall/proc/place_poster(obj/item/poster/P, mob/user)
	if(!P.poster_structure)
		return
	var/stuff_on_wall = 0
	for(var/obj/O in contents) //Let's see if it already has a poster on it or too much stuff
		if(istype(O, /obj/structure/sign/poster))
			to_chat(user, "<span class='notice'>The wall is far too cluttered to place a poster!</span>")
			return
		stuff_on_wall++
		if(stuff_on_wall >= 4)
			to_chat(user, "<span class='notice'>The wall is far too cluttered to place a poster!</span>")
			return

		to_chat(user, "<span class='notice'>You start placing the poster on the wall...</span>")//Looks like it's uncluttered enough. Place the poster.

	var/obj/structure/sign/poster/D = P.poster_structure

	var/temp_loc = user.loc

	switch(getRelativeDirection(user, src))
		if(NORTH)
			D.dir = NORTH
			D.pixel_x = 0
			D.pixel_y = 32
		if(EAST)
			D.dir = EAST
			D.pixel_x = 32
			D.pixel_y = 0
		if(SOUTH)
			D.dir = SOUTH
			D.pixel_x = 0
			D.pixel_y = -32
		if(WEST)
			D.dir = WEST
			D.pixel_x = -32
			D.pixel_y = 0
		else
			to_chat(user, "<span class='notice'>You cannot reach the wall from here!</span>")
			return

	flick("poster_being_set", D)
	D.forceMove(temp_loc)
	qdel(P)	//delete it now to cut down on sanity checks afterwards. Agouri's code supports rerolling it anyway
	playsound(D.loc, 'sound/effects/rustle1.ogg', 100, 1)

	if(do_after(user, PLACE_SPEED, target = src))
		if(!D || QDELETED(D))
			return

		if(iswallturf(src) && user && user.loc == temp_loc)	//Let's check if everything is still there
			to_chat(user, "<span class='notice'>You place the poster!</span>")
			playsound(D.loc, 'sound/effects/pageturn3.ogg', 100, 1)
			return

	to_chat(user, "<span class='notice'>The poster falls down!</span>")
	D.roll_and_drop(temp_loc)


////////////////////////////////POSTER VARIATIONS////////////////////////////////

/obj/structure/sign/poster/ripped
	ruined = TRUE
	icon_state = "poster_ripped"
	name = "ripped poster"
	desc = "You can't make out anything from the poster's original print. It's ruined."

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/ripped, 32, 32)

/obj/structure/sign/poster/random
	name = "random poster" // could even be ripped
	icon_state = "random_anything"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/random, 32, 32)

/obj/structure/sign/poster/contraband
	poster_item_name = "contraband poster"
	poster_item_desc = "This poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface. Its vulgar themes have marked it as contraband aboard Nanotrasen space facilities."

/obj/structure/sign/poster/contraband/random
	name = "random contraband poster"
	icon_state = "random_contraband"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster/contraband

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/random, 32, 32)

/obj/structure/sign/poster/contraband/free_tonto
	name = "Free Tonto"
	desc = "A salvaged shred of a much larger flag, colors bled together and faded from age."
	icon_state = "poster1"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/free_tonto, 32, 32)

/obj/structure/sign/poster/contraband/atmosia_independence
	name = "Atmosia Declaration of Independence"
	desc = "A relic of a failed rebellion."
	icon_state = "poster2"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/atmosia_independence, 32, 32)

/obj/structure/sign/poster/contraband/fun_police
	name = "Fun Police"
	desc = "A poster condemning the station's security forces."
	icon_state = "poster3"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/fun_police, 32, 32)

/obj/structure/sign/poster/contraband/lusty_xenomorph
	name = "Lusty Xenomorph"
	desc = "A heretical poster depicting the titular star of an equally heretical book."
	icon_state = "poster4"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/lusty_xenomorph, 32, 32)

/obj/structure/sign/poster/contraband/syndicate_recruitment
	name = "Syndicate Recruitment"
	desc = "See the galaxy! Shatter corrupt megacorporations! Join today!"
	icon_state = "poster5"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/syndicate_recruitment, 32, 32)

/obj/structure/sign/poster/contraband/clown
	name = "Clown"
	desc = "Honk."
	icon_state = "poster6"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/clown, 32, 32)

/obj/structure/sign/poster/contraband/smoke
	name = "Smoke"
	desc = "A poster advertising a rival corporate brand of cigarettes."
	icon_state = "poster7"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/smoke, 32, 32)

/obj/structure/sign/poster/contraband/grey_tide
	name = "Grey Tide"
	desc = "A rebellious poster symbolizing assistant solidarity."
	icon_state = "poster8"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/grey_tide, 32, 32)

/obj/structure/sign/poster/contraband/missing_gloves
	name = "Missing Gloves"
	desc = "This poster references the uproar that followed Nanotrasen's financial cuts toward insulated-glove purchases."
	icon_state = "poster9"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/missing_gloves, 32, 32)

/obj/structure/sign/poster/contraband/hacking_guide
	name = "Hacking Guide"
	desc = "This poster details the internal workings of the common Nanotrasen airlock. Sadly, it appears out of date."
	icon_state = "poster10"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/hacking_guide, 32, 32)

/obj/structure/sign/poster/contraband/rip_badger
	name = "RIP Badger"
	desc = "This seditious poster references Nanotrasen's genocide of a space station full of badgers."
	icon_state = "poster11"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/rip_badger, 32, 32)

/obj/structure/sign/poster/contraband/ambrosia_vulgaris
	name = "Ambrosia Vulgaris"
	desc = "This poster is lookin' pretty trippy man."
	icon_state = "poster12"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/ambrosia_vulgaris, 32, 32)

/obj/structure/sign/poster/contraband/donut_corp
	name = "Donut Corp."
	desc = "This poster is an unauthorized advertisement for Donut Corp."
	icon_state = "poster13"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/donut_corp, 32, 32)

/obj/structure/sign/poster/contraband/eat
	name = "EAT."
	desc = "This poster promotes rank gluttony."
	icon_state = "poster14"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/eat, 32, 32)

/obj/structure/sign/poster/contraband/tools
	name = "Tools"
	desc = "This poster looks like an advertisement for tools, but is in fact a subliminal jab at the tools at CentComm."
	icon_state = "poster15"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/tools, 32, 32)

/obj/structure/sign/poster/contraband/power
	name = "Power"
	desc = "A poster that positions the seat of power outside Nanotrasen."
	icon_state = "poster16"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/power, 32, 32)

/obj/structure/sign/poster/contraband/power_people
	name = "Power to the people"
	desc = "Screw those EDF guys!"
	icon_state = "poster17"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/power_people, 32, 32)

/obj/structure/sign/poster/contraband/communist_state
	name = "Communist State"
	desc = "All hail the Communist party!"
	icon_state = "poster18"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/communist_state, 32, 32)

/obj/structure/sign/poster/contraband/lamarr
	name = "Lamarr"
	desc = "This poster depicts Lamarr. Probably made by a traitorous Research Director."
	icon_state = "poster19"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/lamarr, 32, 32)

/obj/structure/sign/poster/contraband/borg_fancy_1
	name = "Borg Fancy"
	desc = "Being fancy can be for any borg, just need a suit."
	icon_state = "poster20"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/borg_fancy_1, 32, 32)

/obj/structure/sign/poster/contraband/borg_fancy_2
	name = "Borg Fancy v2"
	desc = "Borg Fancy, Now only taking the most fancy."
	icon_state = "poster21"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/borg_fancy_2, 32, 32)

/obj/structure/sign/poster/contraband/kss13
	name = "Kosmicheskaya Stantsiya 13 Does Not Exist"
	desc = "A poster mocking CentComm's denial of the existence of the derelict station near Space Station 13."
	icon_state = "poster22"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/kss13, 32, 32)

/obj/structure/sign/poster/contraband/rebels_unite
	name = "Rebels Unite"
	desc = "A poster urging the viewer to rebel against Nanotrasen."
	icon_state = "poster23"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/rebels_unite, 32, 32)

/obj/structure/sign/poster/contraband/c20r
	name = "C-20r"
	desc = "A poster advertising the Scarborough Arms C-20r."
	icon_state = "poster24"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/c20r, 32, 32)

/obj/structure/sign/poster/contraband/have_a_puff
	name = "Have a Puff"
	desc = "Who cares about lung cancer when you're high as a kite?"
	icon_state = "poster25"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/have_a_puff, 32, 32)

/obj/structure/sign/poster/contraband/revolver
	name = "Revolver"
	desc = "Because seven shots are all you need."
	icon_state = "poster26"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/revolver, 32, 32)

/obj/structure/sign/poster/contraband/d_day_promo
	name = "D-Day Promo"
	desc = "A promotional poster for some rapper."
	icon_state = "poster27"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/d_day_promo, 32, 32)

/obj/structure/sign/poster/contraband/syndicate_pistol
	name = "Syndicate Pistol"
	desc = "A poster advertising syndicate pistols as being 'classy as fuck'. It is covered in faded gang tags."
	icon_state = "poster28"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/syndicate_pistol, 32, 32)

/obj/structure/sign/poster/contraband/energy_swords
	name = "Energy Swords"
	desc = "All the colors of the bloody murder rainbow."
	icon_state = "poster29"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/energy_swords, 32, 32)

/obj/structure/sign/poster/contraband/red_rum
	name = "Red Rum"
	desc = "Looking at this poster makes you want to kill."
	icon_state = "poster30"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/red_rum, 32, 32)

/obj/structure/sign/poster/contraband/cc64k_ad
	name = "CC 64K Ad"
	desc = "The latest portable computer from Comrade Computing, with a whole 64kB of ram!"
	icon_state = "poster31"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/cc64k_ad, 32, 32)

/obj/structure/sign/poster/contraband/punch_shit
	name = "Punch Shit"
	desc = "Fight things for no reason, like a man!"
	icon_state = "poster32"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/punch_shit, 32, 32)

/obj/structure/sign/poster/contraband/the_griffin
	name = "The Griffin"
	desc = "The Griffin commands you to be the worst you can be. Will you?"
	icon_state = "poster33"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/contraband/the_griffin, 32, 32)

/obj/structure/sign/poster/official
	poster_item_name = "motivational poster"
	poster_item_desc = "An official Nanotrasen-issued poster to foster a compliant and obedient workforce. It comes with state-of-the-art adhesive backing, for easy pinning to any vertical surface."
	poster_item_icon_state = "rolled_poster_legit"

/obj/structure/sign/poster/official/random
	name = "random official poster"
	random_basetype = /obj/structure/sign/poster/official
	icon_state = "random_official"
	never_random = TRUE

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/random, 32, 32)

/obj/structure/sign/poster/official/here_for_your_safety
	name = "Here For Your Safety"
	desc = "A poster glorifying the station's security force."
	icon_state = "poster1_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/here_for_your_safety, 32, 32)

/obj/structure/sign/poster/official/nanotrasen_logo
	name = "Nanotrasen Logo"
	desc = "A poster depicting the Nanotrasen logo."
	icon_state = "poster2_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/nanotrasen_logo, 32, 32)

/obj/structure/sign/poster/official/cleanliness
	name = "Cleanliness"
	desc = "A poster warning of the dangers of poor hygiene."
	icon_state = "poster3_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/cleanliness, 32, 32)

/obj/structure/sign/poster/official/help_others
	name = "Help Others"
	desc = "A poster encouraging you to help fellow crewmembers."
	icon_state = "poster4_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/help_others, 32, 32)

/obj/structure/sign/poster/official/build
	name = "Build"
	desc = "A poster glorifying the engineering team."
	icon_state = "poster5_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/build, 32, 32)

/obj/structure/sign/poster/official/bless_this_spess
	name = "Bless This Spess"
	desc = "A poster blessing this area."
	icon_state = "poster6_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/bless_this_spess, 32, 32)

/obj/structure/sign/poster/official/science
	name = "Science"
	desc = "A poster depicting an atom."
	icon_state = "poster7_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/science, 32, 32)

/obj/structure/sign/poster/official/ian
	name = "Ian"
	desc = "Arf arf. Yap."
	icon_state = "poster8_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/ian, 32, 32)

/obj/structure/sign/poster/official/obey
	name = "Obey"
	desc = "A poster instructing the viewer to obey authority."
	icon_state = "poster9_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/obey, 32, 32)

/obj/structure/sign/poster/official/walk
	name = "Walk"
	desc = "A poster instructing the viewer to walk instead of running."
	icon_state = "poster10_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/walk, 32, 32)

/obj/structure/sign/poster/official/state_laws
	name = "State Laws"
	desc = "A poster instructing cyborgs to state their laws."
	icon_state = "poster11_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/state_laws, 32, 32)

/obj/structure/sign/poster/official/love_ian
	name = "Love Ian"
	desc = "Ian is love, Ian is life."
	icon_state = "poster12_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/love_ian, 32, 32)

/obj/structure/sign/poster/official/space_cops
	name = "Space Cops."
	desc = "A poster advertising the television show Space Cops."
	icon_state = "poster13_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/space_cops, 32, 32)

/obj/structure/sign/poster/official/ue_no
	name = "Ue No."
	desc = "This thing is all in Japanese."
	icon_state = "poster14_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/ue_no, 32, 32)

/obj/structure/sign/poster/official/get_your_legs
	name = "Get Your LEGS"
	desc = "LEGS: Leadership, Experience, Genius, Subordination."
	icon_state = "poster15_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/get_your_legs, 32, 32)

/obj/structure/sign/poster/official/do_not_question
	name = "Do Not Question"
	desc = "A poster instructing the viewer not to ask about things they aren't meant to know."
	icon_state = "poster16_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/do_not_question, 32, 32)

/obj/structure/sign/poster/official/work_for_a_future
	name = "Work For A Future"
	desc = "A poster encouraging you to work for your future."
	icon_state = "poster17_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/work_for_a_future, 32, 32)

/obj/structure/sign/poster/official/soft_cap_pop_art
	name = "Soft Cap Pop Art"
	desc = "A poster reprint of some cheap pop art."
	icon_state = "poster18_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/soft_cap_pop_art, 32, 32)

/obj/structure/sign/poster/official/safety_internals
	name = "Safety: Internals"
	desc = "A poster instructing the viewer to wear internals in the rare environments where there is no oxygen or the air has been rendered toxic."
	icon_state = "poster19_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/safety_internals, 32, 32)

/obj/structure/sign/poster/official/safety_eye_protection
	name = "Safety: Eye Protection"
	desc = "A poster instructing the viewer to wear eye protection when dealing with chemicals, smoke, or bright lights."
	icon_state = "poster20_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/safety_eye_protection, 32, 32)

/obj/structure/sign/poster/official/safety_report
	name = "Safety: Report"
	desc = "A poster instructing the viewer to report suspicious activity to the security force."
	icon_state = "poster21_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/safety_report, 32, 32)

/obj/structure/sign/poster/official/report_crimes
	name = "Report Crimes"
	desc = "A poster encouraging the swift reporting of crime or seditious behavior to station security."
	icon_state = "poster22_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/report_crimes, 32, 32)

/obj/structure/sign/poster/official/ion_rifle
	name = "Ion Rifle"
	desc = "A poster displaying an Ion Rifle."
	icon_state = "poster23_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/ion_rifle, 32, 32)

/obj/structure/sign/poster/official/foam_force_ad
	name = "Foam Force Ad"
	desc = "Foam Force, it's Foam or be Foamed!"
	icon_state = "poster24_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/foam_force_ad, 32, 32)

/obj/structure/sign/poster/official/cohiba_robusto_ad
	name = "Cohiba Robusto Ad"
	desc = "Cohiba Robusto, the classy cigar."
	icon_state = "poster25_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/cohiba_robusto_ad, 32, 32)

/obj/structure/sign/poster/official/anniversary_vintage_reprint
	name = "50th Anniversary Vintage Reprint"
	desc = "A reprint of a poster from 2505, commemorating the 50th Anniversery of Nanoposters Manufacturing, a subsidiary of Nanotrasen."
	icon_state = "poster26_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/anniversary_vintage_reprint, 32, 32)

/obj/structure/sign/poster/official/fruit_bowl
	name = "Fruit Bowl"
	desc = "Simple, yet awe-inspiring."
	icon_state = "poster27_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/fruit_bowl, 32, 32)

/obj/structure/sign/poster/official/pda_ad
	name = "PDA Ad"
	desc = "A poster advertising the latest PDA from Nanotrasen suppliers."
	icon_state = "poster28_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/pda_ad, 32, 32)

/obj/structure/sign/poster/official/enlist
	name = "Enlist"
	desc = "Enlist in the Nanotrasen ERT reserves today!"
	icon_state = "poster29_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/enlist, 32, 32)

/obj/structure/sign/poster/official/nanomichi_ad
	name = "Nanomichi Ad"
	desc = "A poster advertising Nanomichi brand audio cassettes."
	icon_state = "poster30_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/nanomichi_ad, 32, 32)

/obj/structure/sign/poster/official/twelve_gauge
	name = "12 Gauge"
	desc = "A poster boasting about the superiority of 12 gauge shotgun shells."
	icon_state = "poster31_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/twelve_gauge, 32, 32)

/obj/structure/sign/poster/official/high_class_martini
	name = "High-Class Martini"
	desc = "I told you to shake it, no stirring."
	icon_state = "poster32_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/high_class_martini, 32, 32)

/obj/structure/sign/poster/official/the_owl
	name = "The Owl"
	desc = "The Owl would do his best to protect the station. Will you?"
	icon_state = "poster33_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/the_owl, 32, 32)

/obj/structure/sign/poster/official/spiders
	name = "Spider Risk"
	desc = "A poster detailing what to do when giant spiders are seen."
	icon_state = "poster34_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/spiders, 32, 32)

/obj/structure/sign/poster/official/kill_syndicate
	name = "Kill Syndicate"
	desc = "A poster demanding that all crew should be ready to fight the Syndicate."
	icon_state = "poster35_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/kill_syndicate, 32, 32)

/obj/structure/sign/poster/official/air1
	name = "Information on Air"
	desc = "A poster providing visual aid to remind crew of air canisters."
	icon_state = "poster36_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/air1, 32, 32)

/obj/structure/sign/poster/official/air2
	name = "Information on Air"
	desc = "A poster providing visual aid to remind crew of air canisters."
	icon_state = "poster37_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/air2, 32, 32)

/obj/structure/sign/poster/official/dig
	name = "Dig for Glory!"
	desc = "A poster trying to convince the crew to mine for ore."
	icon_state = "poster38_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/dig, 32, 32)

/obj/structure/sign/poster/official/religious
	name = "Religious Poster"
	desc = "A generic religious poster telling you to believe."
	icon_state = "poster39_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/religious, 32, 32)

/obj/structure/sign/poster/official/healthy
	name = "Stay Healthy!"
	desc = "A healthy crew is a happy crew!"
	icon_state = "poster40_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/healthy, 32, 32)

/obj/structure/sign/poster/official/darkpurpl
	name = "Dark Purp-L"
	desc = "A poster for the band \"Dark Purp-L\". They label their music 'Plasmawave'; mixed from various space age sounds like creaking hulls and plasma emitters, it's gained traction in recent years amongst bored ship engineers. "
	icon_state = "poster41_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/darkpurpl, 32, 32)

/obj/structure/sign/poster/official/root
	name = "Root Song"
	desc = "A poster for all-Diona Jazz band \"Root Song\". When a travelling jazz band's ship crashed on a Diona overgrowth planet, a whole host of musically-inclined Dionea sprung forth. Though the beloved band members sadly perished in the crash, their love of Jazz lived on with these Dionea, who travel the galaxy in the repaired wreck of that ship, under the moniker \"Root Song\"."
	icon_state = "poster42_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/root, 32, 32)

/obj/structure/sign/poster/official/core
	name = "CO!RE"
	desc = "A poster for the all-Slime melodic rap label CO!RE. Known for their unique blend of hard-hitting vocals and traditional Xarxis woodwind instruments, CO!RE took the Federation R&B scene by storm during their debut, and has since engaged in several high-intensity tours across the sector."
	icon_state = "poster43_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/core, 32, 32)

/obj/structure/sign/poster/official/metal
	name = "METAL"
	desc = "A poster for an IPC metal band, aptly named \"METAL\". Though their chassis are dated and badly damaged, they rage on evermore! The electric guitarist, SKULL, has an amp built into their head."
	icon_state = "poster44_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/metal, 32, 32)

/obj/structure/sign/poster/official/kpop
	name = "Kidan Pop"
	desc = "A poster for a Kidan boyband known as \"K-Pop\". Though other species find their chittering vocals grating and tuneless, they're wildly popular among young Kidan living in the TSF."
	icon_state = "poster45_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/kpop, 32, 32)

/obj/structure/sign/poster/official/graydays
	name = "Gray Days"
	desc = "A poster for an emo band of greys. They're known to play a form of Death Metal, but it's so quiet you can only barely hear the words. If you turn the speaker way up, the lyrics are mournful and deep; just remember to turn it back down once you're finished listening."
	icon_state = "poster46_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/graydays, 32, 32)

/obj/structure/sign/poster/official/unathicrush
	name = "CRUSH"
	desc = "A poster for a unathi band called \"Heart Crush\". They mostly write diss tracks about their bitter rivals, the band \"Heart Smash\". Never tell one of their fans you like the other band, or you can expect a violent argument."
	icon_state = "poster47_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/unathicrush, 32, 32)

/obj/structure/sign/poster/official/unathismash
	name = "SMASH"
	desc = "A poster for a unathi band called \"Heart Smash\". They're famously bitter rivals with a very similar band, \"Heart Crush\", who they constantly accuse of copying their style. After multiple assaults and restraining orders, the two are back on tour."
	icon_state = "poster48_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/unathismash, 32, 32)

/obj/structure/sign/poster/official/star
	name = "Star"
	desc = "A poster for a musical called \"Star\". The lead singer and actor searches across the galaxy in a cruise ship for his one true love - the titular \"Star\"."
	icon_state = "poster49_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/star, 32, 32)

/obj/structure/sign/poster/official/soul
	name = "Kindred Soul"
	desc = "A poster for a rarely-seen orchestral band known as \"Kindred Soul\". Those who have been lucky enough to catch a performance say their vocals are deeply moving."
	icon_state = "poster50_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/soul, 32, 32)

/obj/structure/sign/poster/official/choir
	name = "\"Skreethoven's\" Choir"
	desc = "A poster for a classical Vox performance group including a full choir and orchestra. The chorists have a great harmony. Despite his violent protestation, the star organist can't shake his popular nickname, \"Skreethoven\"."
	icon_state = "poster51_legit"

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/sign/poster/official/choir, 32, 32)

#undef PLACE_SPEED
