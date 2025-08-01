/obj/item/areaeditor
	name = "area modification item"
	icon_state = "blueprints"
	attack_verb = list("attacked", "bapped", "hit")
	/// Extra text added to the description.
	var/fluffnotice = "If you can read this, make an issue report on GitHub. Something done goofed!"

	var/const/AREA_ERRNONE = 0
	var/const/AREA_STATION = 1
	var/const/AREA_SPACE =   2
	var/const/AREA_SPECIAL = 3

	var/const/BORDER_ERROR = 0
	var/const/BORDER_NONE = 1
	var/const/BORDER_BETWEEN =   2
	var/const/BORDER_2NDTILE = 3
	var/const/BORDER_SPACE = 4

	var/const/ROOM_ERR_LOLWAT = 0
	var/const/ROOM_ERR_SPACE = -1
	var/const/ROOM_ERR_TOOLARGE = -2


/obj/item/areaeditor/attack_self__legacy__attackchain(mob/user as mob)
	add_fingerprint(user)
	var/text = "<BODY><HTML><meta charset='utf-8'><head><title>[src]</title></head> \
				<h2>[station_name()] [src.name]</h2> \
				<small>[fluffnotice]</small><hr>"
	switch(get_area_type())
		if(AREA_SPACE)
			text += "<p>According to [src], you are now in <b>outer space</b>. Hold your breath.</p> \
			<p><a href='byond://?src=[UID()];create_area=1'>Mark this place as new area.</a></p>"
		if(AREA_SPECIAL)
			text += "<p>This place is not noted on [src].</p>"
	return text


/obj/item/areaeditor/Topic(href, href_list)
	if(..())
		return
	if(href_list["create_area"])
		if(get_area_type()==AREA_SPACE)
			create_area()



//One-use area creation permits.
/obj/item/areaeditor/permit
	name = "construction permit"
	icon_state = "permit"
	desc = "This is a one-use permit that allows the user to officially declare a built room as an addition to the station."
	fluffnotice = "Nanotrasen Engineering requires all on-station construction projects to be approved by a head of staff, as detailed in Nanotrasen Company Regulation 512-C (Mid-Shift Modifications to Company Property). \
						By submitting this form, you accept any fines, fees, or personal injury/death that may occur during construction."
	w_class = WEIGHT_CLASS_TINY

/obj/item/areaeditor/permit/attack_self__legacy__attackchain(mob/user)
	. = ..()
	var/area/our_area = get_area(src)
	if(get_area_type() == AREA_STATION)
		. += "<p>According to [src], you are now in <b>\"[sanitize(our_area.name)]\"</b>.</p>"
	var/datum/browser/popup = new(user, "blueprints", "[src]", 700, 500)
	popup.set_content(.)
	popup.open()
	onclose(usr, "blueprints")


/obj/item/areaeditor/permit/create_area()
	if(..())
		qdel(src)

//Station blueprints!!!
/obj/item/areaeditor/blueprints
	name = "station blueprints"
	desc = "Blueprints of the station. There is a \"<b>CONFIDENTIAL</b>\" stamp and several coffee stains on it."
	fluffnotice = "Property of Nanotrasen. For heads of staff only. Store in high-security storage."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/list/showing = list()
	var/client/viewing

/obj/item/areaeditor/blueprints/Destroy()
	clear_viewer()
	return ..()


/obj/item/areaeditor/blueprints/attack_self__legacy__attackchain(mob/user)
	. = ..()
	var/area/our_area = get_area(src)
	if(get_area_type() == AREA_STATION)
		. += "<p>According to [src], you are now in <b>\"[sanitize(our_area.name)]\"</b>.</p>"
		. += "<p>You may <a href='byond://?src=[UID()];edit_area=1'> move an amendment</a> to the drawing.</p>"
	if(!viewing)
		. += "<p><a href='byond://?src=[UID()];view_blueprints=1'>View structural data</a></p>"
	else
		. += "<p><a href='byond://?src=[UID()];refresh=1'>Refresh structural data</a></p>"
		. += "<p><a href='byond://?src=[UID()];hide_blueprints=1'>Hide structural data</a></p>"
	var/datum/browser/popup = new(user, "blueprints", "[src]", 700, 500)
	popup.set_content(.)
	popup.open()
	onclose(user, "blueprints")


/obj/item/areaeditor/blueprints/Topic(href, href_list)
	..()
	if(href_list["edit_area"])
		if(get_area_type()!=AREA_STATION)
			return
		edit_area()
	if(href_list["view_blueprints"])
		set_viewer(usr, "<span class='notice'>You flip the blueprints over to view the complex information diagram.</span>")
	if(href_list["hide_blueprints"])
		clear_viewer(usr, "<span class='notice'>You flip the blueprints over to view the simple information diagram.</span>")
	if(href_list["refresh"])
		clear_viewer(usr)
		set_viewer(usr)

	attack_self__legacy__attackchain(usr)

/obj/item/areaeditor/blueprints/proc/get_images(turf/central_turf, viewsize)
	. = list()
	var/list/dimensions = getviewsize(viewsize)
	var/horizontal_radius = dimensions[1] / 2
	var/vertical_radius = dimensions[2] / 2
	for(var/turf/nearby_turf as anything in RECT_TURFS(horizontal_radius, vertical_radius, central_turf))
		if(nearby_turf.blueprint_data)
			. += nearby_turf.blueprint_data

/obj/item/areaeditor/blueprints/proc/set_viewer(mob/user, message = "")
	if(user && user.client)
		if(viewing)
			clear_viewer()
		viewing = user.client
		showing = get_images(get_turf(viewing.eye || user), viewing.view)
		viewing.images |= showing
		if(message)
			to_chat(user, message)

/obj/item/areaeditor/blueprints/proc/clear_viewer(mob/user, message = "")
	if(viewing)
		viewing.images -= showing
		viewing = null
	showing.Cut()
	if(message)
		to_chat(user, message)

/obj/item/areaeditor/blueprints/dropped(mob/user)
	..()
	clear_viewer()

/obj/item/areaeditor/proc/get_area_type(area/A)
	if(!A)
		A = get_area(src)
	if(A.outdoors)
		return AREA_SPACE
	var/list/SPECIALS = list(
		/area/shuttle,
		/area/admin,
		/area/centcom,
		/area/tdome,
		/area/wizard_station
	)
	for(var/type in SPECIALS)
		if(istype(A,type))
			return AREA_SPECIAL
	return AREA_STATION


/obj/item/areaeditor/proc/create_area()
	var/area_created = FALSE
	var/res = detect_room(get_turf(usr))
	if(!istype(res,/list))
		switch(res)
			if(ROOM_ERR_SPACE)
				to_chat(usr, "<span class='warning'>The new area must be completely airtight.</span>")
				return area_created
			if(ROOM_ERR_TOOLARGE)
				to_chat(usr, "<span class='warning'>The new area is too large.</span>")
				return area_created
			else
				to_chat(usr, "<span class='warning'>Error! Please notify administration.</span>")
				return area_created
	var/list/turf/turfs = res
	var/str = tgui_input_text(usr, "New area name:", "Blueprint Editing", max_length = MAX_NAME_LEN, encode = FALSE)
	if(!str || !length(str)) // Cancel
		return area_created
	var/area/A = new
	A.name = str
	A.powernet.equipment_powered = FALSE
	A.powernet.lighting_powered = FALSE
	A.powernet.environment_powered = FALSE
	A.always_unpowered = FALSE
	A.set_dynamic_lighting()

	for(var/i in 1 to length(turfs))
		var/turf/thing = turfs[i]
		var/area/old_area = thing.loc
		A.contents += thing
		thing.change_area(old_area, A)

	var/area/oldA = get_area(get_turf(usr))
	var/list/firedoors = oldA.firedoors
	for(var/door in firedoors)
		var/obj/machinery/door/firedoor/FD = door
		FD.CalculateAffectingAreas()

	interact()
	message_admins("A new room was made by [key_name_admin(usr)] at [ADMIN_VERBOSEJMP(usr)] with the name [str]")
	log_game("A new room was made by [key_name(usr)] at [AREACOORD(usr)] with the name [str]")
	area_created = TRUE
	return area_created

/obj/item/areaeditor/proc/edit_area()
	var/area/our_area = get_area(src)
	var/prevname = "[sanitize(our_area.name)]"
	var/str = tgui_input_text(usr, "New area name:", "Blueprint Editing", prevname, MAX_NAME_LEN, encode = FALSE)
	if(!str || !length(str) || str == prevname) // Cancel
		return
	set_area_machinery_title(our_area, str, prevname)
	our_area.name = str
	if(our_area.firedoors)
		for(var/D in our_area.firedoors)
			var/obj/machinery/door/firedoor/FD = D
			FD.CalculateAffectingAreas()
	to_chat(usr, "<span class='notice'>You rename the '[prevname]' to '[str]'.</span>")
	interact()
	message_admins("A room was renamed by [key_name_admin(usr)] at [ADMIN_VERBOSEJMP(usr)] changing the name from [prevname] to [str]")
	log_game("A room was renamed by [key_name(usr)] at [AREACOORD(usr)] changing the name from [prevname] to [str] ")
	return TRUE

/obj/item/areaeditor/proc/set_area_machinery_title(area/A, title, oldtitle)
	if(!oldtitle) // or replacetext goes to infinite loop
		return
	for(var/obj/machinery/alarm/M in A)
		M.name = replacetext(M.name,oldtitle,title)
	for(var/obj/machinery/power/apc/M in A)
		M.name = replacetext(M.name,oldtitle,title)
	for(var/obj/machinery/atmospherics/unary/vent_scrubber/M in A)
		M.name = replacetext(M.name,oldtitle,title)
	for(var/obj/machinery/atmospherics/unary/vent_pump/M in A)
		M.name = replacetext(M.name,oldtitle,title)
	for(var/obj/machinery/door/M in A)
		M.name = replacetext(M.name,oldtitle,title)
	//TODO: much much more. Unnamed airlocks, cameras, etc.

/obj/item/areaeditor/proc/check_tile_is_border(turf/T2, dir)
	if(isspaceturf(T2))
		return BORDER_SPACE //omg hull breach we all going to die here
	if(get_area_type(T2.loc)!=AREA_SPACE)
		return BORDER_BETWEEN
	if(iswallturf(T2))
		return BORDER_2NDTILE
	if(ismineralturf(T2))
		return BORDER_2NDTILE
	if(!issimulatedturf(T2))
		return BORDER_BETWEEN

	for(var/obj/structure/window/W in T2)
		if(turn(dir,180) == W.dir)
			return BORDER_BETWEEN
		if(W.dir in list(NORTHEAST,SOUTHEAST,NORTHWEST,SOUTHWEST))
			return BORDER_2NDTILE
	for(var/obj/machinery/door/window/D in T2)
		if(turn(dir,180) == D.dir)
			return BORDER_BETWEEN
	if(locate(/obj/machinery/door) in T2)
		return BORDER_2NDTILE
	if(locate(/obj/structure/falsewall) in T2)
		return BORDER_2NDTILE

	return BORDER_NONE


/obj/item/areaeditor/proc/detect_room(turf/first)
	var/list/turf/found = list()
	var/list/turf/pending = list(first)
	while(length(pending))
		if(found.len+length(pending) > 300)
			return ROOM_ERR_TOOLARGE
		var/turf/T = pending[1] //why byond havent list::pop()?
		pending -= T
		for(var/dir in GLOB.cardinal)
			var/skip = 0
			for(var/obj/structure/window/W in T)
				if(dir == W.dir || (W.dir in list(NORTHEAST,SOUTHEAST,NORTHWEST,SOUTHWEST)))
					skip = 1; break
			if(skip) continue
			for(var/obj/machinery/door/window/D in T)
				if(dir == D.dir)
					skip = 1; break
			if(skip) continue

			var/turf/NT = get_step(T,dir)
			if(!isturf(NT) || (NT in found) || (NT in pending))
				continue

			switch(check_tile_is_border(NT,dir))
				if(BORDER_NONE)
					pending+=NT
				if(BORDER_2NDTILE)
					found+=NT //tile included to new area, but we dont seek more
				if(BORDER_SPACE)
					return ROOM_ERR_SPACE
		found+=T
	return found

//Blueprint Subtypes

/obj/item/areaeditor/blueprints/cyborg
	name = "station schematics"
	desc = "A digital copy of the station blueprints stored in your memory."
	fluffnotice = "Intellectual Property of Nanotrasen. For use in engineering cyborgs only. Wipe from memory upon departure from the station."

/obj/item/areaeditor/blueprints/ce

/obj/item/areaeditor/blueprints/ce/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_SHOW_WIRE_INFO, ROUNDSTART_TRAIT)
	AddElement(/datum/element/high_value_item)
