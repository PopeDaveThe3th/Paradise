/obj/machinery/atmospherics/pipe/manifold
	icon = 'icons/atmos/manifold.dmi'
	icon_state = ""
	name = "pipe manifold"
	desc = "A manifold composed of regular pipes."

	volume = 105

	initialize_directions = EAST|NORTH|WEST

	var/obj/machinery/atmospherics/node1
	var/obj/machinery/atmospherics/node2
	var/obj/machinery/atmospherics/node3

	level = 1

/obj/machinery/atmospherics/pipe/manifold/New()
	..()

	alpha = 255
	icon = null
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|SOUTH|WEST
		if(SOUTH)
			initialize_directions = WEST|NORTH|EAST
		if(EAST)
			initialize_directions = SOUTH|WEST|NORTH
		if(WEST)
			initialize_directions = NORTH|EAST|SOUTH

/obj/machinery/atmospherics/pipe/manifold/examine(mob/user)
	. = ..()
	. += "<span class='notice'>A pipe with three ends to connect to.</span>"

/obj/machinery/atmospherics/pipe/manifold/atmos_init()
	..()
	for(var/D in GLOB.cardinal)
		if(D == dir)
			continue
		for(var/obj/machinery/atmospherics/target in get_step(src, D))
			if(target.initialize_directions & get_dir(target,src))
				var/c = check_connect_types(target,src)
				if(!c)
					continue
				if(turn(dir, 90) == D)
					target.connected_to = c
					connected_to = c
					node1 = target
				if(turn(dir, 270) == D)
					target.connected_to = c
					connected_to = c
					node2 = target
				if(turn(dir, 180) == D)
					target.connected_to = c
					connected_to = c
					node3 = target
				break
	var/turf/T = src.loc			// hide if turf is not intact
	if(T.transparent_floor)
		return
	hide(T.intact)
	update_icon()

/obj/machinery/atmospherics/pipe/manifold/hide(i)
	if(level == 1 && issimulatedturf(loc))
		invisibility = i ? INVISIBILITY_MAXIMUM : 0

/obj/machinery/atmospherics/pipe/manifold/pipeline_expansion()
	return list(node1, node2, node3)

/obj/machinery/atmospherics/pipe/manifold/Destroy()
	. = ..()

	if(node1)
		node1.disconnect(src)
		node1.defer_build_network()
		node1 = null
	if(node2)
		node2.disconnect(src)
		node2.defer_build_network()
		node2 = null
	if(node3)
		node3.disconnect(src)
		node3.defer_build_network()
		node3 = null

/obj/machinery/atmospherics/pipe/manifold/disconnect(obj/machinery/atmospherics/reference)
	if(reference == node1)
		if(istype(node1, /obj/machinery/atmospherics/pipe))
			qdel(parent)
		node1 = null
	if(reference == node2)
		if(istype(node2, /obj/machinery/atmospherics/pipe))
			qdel(parent)
		node2 = null
	if(reference == node3)
		if(istype(node3, /obj/machinery/atmospherics/pipe))
			qdel(parent)
		node3 = null
	check_nodes_exist()
	update_icon()
	..()

/obj/machinery/atmospherics/pipe/manifold/change_color(new_color)
	..()
	//for updating connected atmos device pipes (i.e. vents, manifolds, etc)
	if(node1)
		node1.update_underlays()
	if(node2)
		node2.update_underlays()
	if(node3)
		node3.update_underlays()

/obj/machinery/atmospherics/pipe/manifold/update_overlays()
	. = ..()
	alpha = 255
	. += GLOB.pipe_icon_manager.get_atmos_icon("manifold", null, pipe_color, "core" + icon_connect_type)
	. += GLOB.pipe_icon_manager.get_atmos_icon("manifold", null, null, "clamps" + icon_connect_type)
	update_underlays()

/obj/machinery/atmospherics/pipe/manifold/update_underlays()
	underlays.Cut()

	var/turf/T = get_turf(src)
	if(!istype(T)) return
	var/list/directions = list(NORTH, SOUTH, EAST, WEST)
	var/node1_direction = get_dir(src, node1)
	var/node2_direction = get_dir(src, node2)
	var/node3_direction = get_dir(src, node3)

	directions -= dir

	directions -= add_underlay(T,node1,node1_direction,icon_connect_type)
	directions -= add_underlay(T,node2,node2_direction,icon_connect_type)
	directions -= add_underlay(T,node3,node3_direction,icon_connect_type)

	for(var/D in directions)
		add_underlay(T, null,D,icon_connect_type)

// A check to make sure both nodes exist - self-delete if they aren't present
/obj/machinery/atmospherics/pipe/manifold/check_nodes_exist()
	if(!node1 && !node2 && !node3)
		deconstruct()
		return 0 // 0: No nodes exist
	// 1: 1-3 nodes exist, we continue existing
	return 1

/obj/machinery/atmospherics/pipe/manifold/visible
	icon_state = "map"
	level = 2
	layer = GAS_PIPE_VISIBLE_LAYER

/obj/machinery/atmospherics/pipe/manifold/visible/scrubbers
	name="Scrubbers pipe manifold"
	desc = "A manifold composed of scrubbers pipes."
	icon_state = "map-scrubbers"
	connect_types = list(CONNECT_TYPE_SCRUBBER)
	layer = GAS_PIPE_VISIBLE_LAYER + GAS_PIPE_SCRUB_OFFSET
	layer_offset = GAS_PIPE_SCRUB_OFFSET
	icon_connect_type = "-scrubbers"
	color = PIPE_COLOR_RED

/obj/machinery/atmospherics/pipe/manifold/visible/scrubbers/examine(mob/user)
	. = ..()
	. += "<span class='notice'>This is a special 'scrubber' pipe, which does not connect to 'normal' pipes. If you want to connect it, use \
			a Universal Adapter pipe.</span>"

/obj/machinery/atmospherics/pipe/manifold/visible/supply
	name="Air supply pipe manifold"
	desc = "A manifold composed of supply pipes."
	icon_state = "map-supply"
	connect_types = list(CONNECT_TYPE_SUPPLY)
	layer = GAS_PIPE_VISIBLE_LAYER + GAS_PIPE_SUPPLY_OFFSET
	layer_offset = GAS_PIPE_SUPPLY_OFFSET
	icon_connect_type = "-supply"
	color = PIPE_COLOR_BLUE

/obj/machinery/atmospherics/pipe/manifold/visible/supply/examine(mob/user)
	. = ..()
	. += "<span class='notice'>This is a special 'supply' pipe, which does not connect to 'normal' pipes. If you want to connect it, use \
			a Universal Adapter pipe.</span>"

/obj/machinery/atmospherics/pipe/manifold/visible/yellow
	color = PIPE_COLOR_YELLOW

/obj/machinery/atmospherics/pipe/manifold/visible/cyan
	color = PIPE_COLOR_CYAN

/obj/machinery/atmospherics/pipe/manifold/visible/green
	color = PIPE_COLOR_GREEN

/obj/machinery/atmospherics/pipe/manifold/visible/purple
	color = PIPE_COLOR_PURPLE

/obj/machinery/atmospherics/pipe/manifold/visible/red
	color = PIPE_COLOR_RED

/obj/machinery/atmospherics/pipe/manifold/visible/blue
	color = PIPE_COLOR_BLUE

/obj/machinery/atmospherics/pipe/manifold/hidden
	icon_state = "map"
	alpha = 128		//set for the benefit of mapping - this is reset to opaque when the pipe is spawned in game
	plane = FLOOR_PLANE

/obj/machinery/atmospherics/pipe/manifold/hidden/scrubbers
	name="Scrubbers pipe manifold"
	desc = "A manifold composed of scrubbers pipes."
	icon_state = "map-scrubbers"
	connect_types = list(CONNECT_TYPE_SCRUBBER)
	layer = GAS_PIPE_HIDDEN_LAYER + GAS_PIPE_SCRUB_OFFSET
	layer_offset = GAS_PIPE_SCRUB_OFFSET
	icon_connect_type = "-scrubbers"
	color = PIPE_COLOR_RED

/obj/machinery/atmospherics/pipe/manifold/hidden/scrubbers/examine(mob/user)
	. = ..()
	. += "<span class='notice'>This is a special 'scrubber' pipe, which does not connect to 'normal' pipes. If you want to connect it, use \
			a Universal Adapter pipe.</span>"

/obj/machinery/atmospherics/pipe/manifold/hidden/supply
	name="Air supply pipe manifold"
	desc = "A manifold composed of supply pipes."
	icon_state = "map-supply"
	connect_types = list(CONNECT_TYPE_SUPPLY)
	layer = GAS_PIPE_HIDDEN_LAYER + GAS_PIPE_SUPPLY_OFFSET
	layer_offset = GAS_PIPE_SUPPLY_OFFSET
	icon_connect_type = "-supply"
	color = PIPE_COLOR_BLUE

/obj/machinery/atmospherics/pipe/manifold/hidden/supply/examine(mob/user)
	. = ..()
	. += "<span class='notice'>This is a special 'supply' pipe, which does not connect to 'normal' pipes. If you want to connect it, use \
			a Universal Adapter pipe.</span>"

/obj/machinery/atmospherics/pipe/manifold/hidden/yellow
	color = PIPE_COLOR_YELLOW

/obj/machinery/atmospherics/pipe/manifold/hidden/cyan
	color = PIPE_COLOR_CYAN

/obj/machinery/atmospherics/pipe/manifold/hidden/green
	color = PIPE_COLOR_GREEN

/obj/machinery/atmospherics/pipe/manifold/hidden/purple
	color = PIPE_COLOR_PURPLE

/obj/machinery/atmospherics/pipe/manifold/hidden/red
	color = PIPE_COLOR_RED

/obj/machinery/atmospherics/pipe/manifold/hidden/blue
	color = PIPE_COLOR_BLUE
