/obj/item/projectile/guardian
	name = "crystal spray"
	icon_state = "guardian"
	damage = 20
	armour_penetration_percentage = 100

/mob/living/simple_animal/hostile/guardian/ranged
	friendly = "quietly assesses"
	melee_damage_lower = 10
	melee_damage_upper = 10
	projectiletype = /obj/item/projectile/guardian
	ranged_cooldown_time = 5 //fast!
	projectilesound = 'sound/effects/hit_on_shattered_glass.ogg'
	ranged = TRUE
	range = 13
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	see_in_dark = 8
	playstyle_string = "As a <b>Ranged</b> type, you have only light damage resistance, but are capable of spraying shards of crystal at incredibly high speed. You can also deploy surveillance snares to monitor enemy movement. Finally, you can switch to scout mode, in which you can't attack, but can move without limit."
	magic_fluff_string = "..And draw the Sentinel, an alien master of ranged combat."
	tech_fluff_string = "Boot sequence complete. Ranged combat modules active. Holoparasite swarm online."
	bio_fluff_string = "Your scarab swarm finishes mutating and stirs to life, capable of spraying shards of crystal."
	var/list/snares = list()
	var/toggle = FALSE

/mob/living/simple_animal/hostile/guardian/ranged/Initialize(mapload, mob/living/host)
	. = ..()
	AddSpell(new /datum/spell/surveillance_snare(null))

/mob/living/simple_animal/hostile/guardian/ranged/ToggleMode()
	if(loc == summoner)
		if(toggle)
			ranged = TRUE
			melee_damage_lower = 10
			melee_damage_upper = 10
			obj_damage = initial(obj_damage)
			environment_smash = initial(environment_smash)
			alpha = 255
			range = 13
			incorporeal_move = NO_INCORPOREAL_MOVE
			ADD_TRAIT(src, TRAIT_CAN_STRIP, TRAIT_GENERIC)
			to_chat(src, "<span class='danger'>You switch to combat mode.</span>")
			toggle = FALSE
		else
			ranged = FALSE
			melee_damage_lower = 0
			melee_damage_upper = 0
			obj_damage = 0
			environment_smash = ENVIRONMENT_SMASH_NONE
			alpha = 60
			range = 255
			incorporeal_move = INCORPOREAL_MOVE_NORMAL
			REMOVE_TRAIT(src, TRAIT_CAN_STRIP, TRAIT_GENERIC) //spiritual pickpocketting is forbidden
			to_chat(src, "<span class='danger'>You switch to scout mode.</span>")
			toggle = TRUE
	else
		to_chat(src, "<span class='danger'>You have to be recalled to toggle modes!</span>")

/mob/living/simple_animal/hostile/guardian/ranged/ToggleLight()
	var/msg
	switch(lighting_alpha)
		if(LIGHTING_PLANE_ALPHA_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
			msg = "You activate your night vision."
		if(LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
			msg = "You increase your night vision."
		if(LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
			msg = "You maximize your night vision."
		else
			lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
			msg = "You deactivate your night vision."

	update_sight()

	to_chat(src, "<span class='notice'>[msg]</span>")

/mob/living/simple_animal/hostile/guardian/ranged/blob_act(obj/structure/blob/B)
	if(toggle)
		return // we don't want blob tiles to hurt us when we fly over them and trigger /Crossed(), this prevents ranged scouts from being insta killed
	return ..() // otherwise do normal damage!

/obj/effect/snare
	name = "snare"
	desc = "You shouldn't be seeing this!"
	var/mob/living/spawner
	invisibility = 101

/obj/effect/snare/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_atom_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/snare/singularity_act()
	return

/obj/effect/snare/singularity_pull()
	return

/obj/effect/snare/proc/on_atom_entered(datum/source, atom/movable/entered)
	if(isliving(entered))
		var/turf/snare_loc = get_turf(loc)
		if(spawner)
			to_chat(spawner, "<span class='danger'>[entered] has crossed your surveillance trap at [get_area(snare_loc)].</span>")
			if(isguardian(spawner))
				var/mob/living/simple_animal/hostile/guardian/G = spawner
				if(G.summoner)
					to_chat(G.summoner, "<span class='danger'>[entered] has crossed your surveillance trap at [get_area(snare_loc)].</span>")
