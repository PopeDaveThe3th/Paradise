/obj/structure/reflector
	name = "reflector frame"
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "box_0"
	desc = "A frame to create a reflector.\n<span class='notice'>Use <b>5</b> sheets of <b>glass</b> to create a 1 way reflector.\nUse <b>10</b> sheets of <b>reinforced glass</b> to create a 2 way reflector.\nUse <b>1 diamond</b> to create a reflector cube.</span>"
	density = TRUE
	max_integrity = 50
	var/finished = FALSE
	var/obj/item/stack/sheet/build_stack_type
	var/build_stack_amount

/obj/structure/reflector/Initialize(mapload)
	. = ..()
	if(mapload)
		anchored = TRUE

/obj/structure/reflector/bullet_act(obj/item/projectile/P)
	var/turf/reflector_turf = get_turf(src)
	var/turf/reflect_turf
	if(!istype(P, /obj/item/projectile/beam))
		return ..()
	var/new_dir = get_reflection(dir, P.dir)
	if(new_dir && anchored)
		reflect_turf = get_step(reflect_turf, new_dir)
	else
		visible_message("<span class='notice'>[src] is hit by [P]!</span>")
		new_dir = 0
		return ..() //Hits as normal, explodes or emps or whatever

	reflect_turf = get_step(loc, new_dir)

	P.original = reflect_turf
	P.starting = reflector_turf
	P.ignore_source_check = TRUE		//If shot by a laser, will now hit the mob that fired it
	var/reflect_angle = dir2angle(new_dir)
	P.set_angle_centered(reflect_angle)
	P.trajectory.set_location(reflect_turf.x, reflect_turf.y, reflect_turf.z)

	new_dir = 0
	return -1


/obj/structure/reflector/attackby__legacy__attackchain(obj/item/W, mob/user, params)
	//Finishing the frame
	if(istype(W,/obj/item/stack/sheet))
		if(finished)
			return
		var/obj/item/stack/sheet/S = W
		if(istype(W, /obj/item/stack/sheet/glass))
			if(S.get_amount() < 5)
				to_chat(user, "<span class='warning'>You need five sheets of glass to create a reflector!</span>")
				return
			else
				S.use(5)
				new /obj/structure/reflector/single(loc)
				qdel(src)
		if(istype(W,/obj/item/stack/sheet/rglass))
			if(S.get_amount() < 10)
				to_chat(user, "<span class='warning'>You need ten sheets of reinforced glass to create a double reflector!</span>")
				return
			else
				S.use(10)
				new /obj/structure/reflector/double(loc)
				qdel(src)
		if(istype(W, /obj/item/stack/sheet/mineral/diamond))
			if(S.get_amount() >= 1)
				S.use(1)
				new /obj/structure/reflector/box(loc)
				qdel(src)
		return
	return ..()

/obj/structure/reflector/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(anchored)
		to_chat(user, "Unweld [src] first!")
		return
	if(!I.tool_use_check(user, 0))
		return
	TOOL_ATTEMPT_DISMANTLE_MESSAGE
	if(!I.use_tool(src, user, 80, volume = I.tool_volume))
		return
	playsound(user, 'sound/items/Ratchet.ogg', 50, 1)
	TOOL_DISMANTLE_SUCCESS_MESSAGE
	new /obj/item/stack/sheet/metal(loc, 5)
	if(build_stack_type)
		new build_stack_type(loc, build_stack_amount)
	qdel(src)

/obj/structure/reflector/welder_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	if(anchored)
		WELDER_ATTEMPT_FLOOR_SLICE_MESSAGE
		if(!I.use_tool(src, user, 5 SECONDS, volume = I.tool_volume))
			return
		WELDER_FLOOR_SLICE_SUCCESS_MESSAGE
		anchored = FALSE
	else
		WELDER_ATTEMPT_FLOOR_WELD_MESSAGE
		if(!I.use_tool(src, user, 5 SECONDS, volume = I.tool_volume))
			return
		WELDER_FLOOR_WELD_SUCCESS_MESSAGE
		anchored = TRUE

/obj/structure/reflector/proc/get_reflection(srcdir,pdir)
	return 0

/obj/structure/reflector/AltClick(mob/user)
	if(user.stat || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || !Adjacent(user))
		return

	if(anchored)
		to_chat(user, "<span class='warning'>You cannot rotate [src] right now. It is fastened to the floor!</span>")
		return
	dir = turn(dir, 90)


//TYPES OF REFLECTORS, SINGLE, DOUBLE, BOX

//SINGLE

/obj/structure/reflector/single
	name = "reflector"
	icon = 'icons/obj/reflector.dmi'
	icon_state = "reflector"
	desc = "A double sided angled mirror for reflecting lasers. This one does so at a 90 degree angle."
	finished = TRUE
	build_stack_type = /obj/item/stack/sheet/glass
	build_stack_amount = 5
	var/static/list/rotations = list("[NORTH]" = list("[SOUTH]" = WEST, "[EAST]" = NORTH),
"[EAST]" = list("[SOUTH]" = EAST, "[WEST]" = NORTH),
"[SOUTH]" = list("[NORTH]" = EAST, "[WEST]" = SOUTH),
"[WEST]" = list("[NORTH]" = WEST, "[EAST]" = SOUTH) )

/obj/structure/reflector/single/get_reflection(srcdir,pdir)
	var/new_dir = rotations["[srcdir]"]["[pdir]"]
	return new_dir

//DOUBLE

/obj/structure/reflector/double
	name = "double sided reflector"
	icon = 'icons/obj/reflector.dmi'
	icon_state = "reflector_double"
	desc = "A double sided angled mirror for reflecting lasers. This one does so at a 90 degree angle."
	finished = TRUE
	build_stack_type = /obj/item/stack/sheet/rglass
	build_stack_amount = 10
	var/static/list/double_rotations = list("[NORTH]" = list("[NORTH]" = WEST, "[EAST]" = SOUTH, "[SOUTH]" = EAST, "[WEST]" = NORTH),
"[EAST]" = list("[NORTH]" = EAST, "[WEST]" = SOUTH, "[SOUTH]" = WEST, "[EAST]" = NORTH),
"[SOUTH]" = list("[NORTH]" = EAST, "[WEST]" = SOUTH, "[SOUTH]" = WEST, "[EAST]" = NORTH),
"[WEST]" = list("[NORTH]" = WEST, "[EAST]" = SOUTH, "[SOUTH]" = EAST, "[WEST]" = NORTH) )

/obj/structure/reflector/double/get_reflection(srcdir,pdir)
	var/new_dir = double_rotations["[srcdir]"]["[pdir]"]
	return new_dir

//BOX

/obj/structure/reflector/box
	name = "reflector box"
	icon = 'icons/obj/reflector.dmi'
	icon_state = "reflector_box"
	desc = "A box with an internal set of mirrors that reflects all laser fire in a single direction."
	finished = TRUE
	build_stack_type = /obj/item/stack/sheet/mineral/diamond
	build_stack_amount = 1
	var/static/list/box_rotations = list("[NORTH]" = list("[SOUTH]" = NORTH, "[EAST]" = NORTH, "[WEST]" = NORTH, "[NORTH]" = NORTH),
"[EAST]" = list("[SOUTH]" = EAST, "[EAST]" = EAST, "[WEST]" = EAST, "[NORTH]" = EAST),
"[SOUTH]" = list("[SOUTH]" = SOUTH, "[EAST]" = SOUTH, "[WEST]" = SOUTH, "[NORTH]" = SOUTH),
"[WEST]" = list("[SOUTH]" = WEST, "[EAST]" = WEST, "[WEST]" = WEST, "[NORTH]" = WEST) )

/obj/structure/reflector/box/get_reflection(srcdir,pdir)
	var/new_dir = box_rotations["[srcdir]"]["[pdir]"]
	return new_dir
