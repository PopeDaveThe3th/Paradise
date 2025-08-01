/obj/item/projectile/hivebotbullet

/mob/living/simple_animal/hostile/hivebot
	name = "Hivebot"
	desc = "A small robot."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "basic"
	icon_living = "basic"
	icon_dead = "basic"
	mob_biotypes = MOB_ROBOTIC
	health = 15
	maxHealth = 15
	melee_damage_lower = 2
	melee_damage_upper = 3
	attacktext = "claws"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	projectilesound = 'sound/weapons/gunshots/gunshot.ogg'
	projectiletype = /obj/item/projectile/hivebotbullet
	faction = list("hivebot")
	check_friendly_fire = TRUE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speak_emote = list("states")
	gold_core_spawnable = HOSTILE_SPAWN
	loot = list(/obj/effect/decal/cleanable/blood/gibs/robot)
	deathmessage = "blows apart!"
	bubble_icon = "machine"
	del_on_death = TRUE
	footstep_type = FOOTSTEP_MOB_CLAW

/mob/living/simple_animal/hostile/hivebot/range
	desc = "A smallish robot, this one is armed!"
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 5

/mob/living/simple_animal/hostile/hivebot/rapid
	ranged = TRUE
	rapid = 3
	retreat_distance = 5
	minimum_distance = 5

/mob/living/simple_animal/hostile/hivebot/strong
	name = "Strong Hivebot"
	desc = "A robot, this one is armed and looks tough!"
	health = 80
	maxHealth = 80
	ranged = TRUE

/mob/living/simple_animal/hostile/hivebot/death(gibbed)
	// Only execute the below if we successfully died
	. = ..(gibbed)
	if(!.)
		return FALSE
	do_sparks(3, 1, src)

/mob/living/simple_animal/hostile/hivebot/tele
	name = "Beacon"
	desc = "Some odd beacon thing."
	icon_state = "def_radar-off"
	icon_living = "def_radar-off"
	health = 200
	maxHealth = 200
	status_flags = 0
	anchored = TRUE
	stop_automated_movement = TRUE
	var/bot_type = "norm"
	var/bot_amt = 10
	var/spawn_delay = 600

/mob/living/simple_animal/hostile/hivebot/tele/Initialize(mapload)
	. = ..()
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(5, FALSE, loc)
	smoke.start()
	visible_message("<span class='danger'>[src] warps in!</span>")
	playsound(src.loc, 'sound/effects/empulse.ogg', 25, 1)

/mob/living/simple_animal/hostile/hivebot/tele/proc/warpbots()
	icon_state = "def_radar"
	visible_message("<span class='warning'>[src] turns on!</span>")
	while(bot_amt > 0)
		bot_amt--
		switch(bot_type)
			if("norm")
				var/mob/living/simple_animal/hostile/hivebot/H = new /mob/living/simple_animal/hostile/hivebot(get_turf(src))
				H.faction = faction
			if("range")
				var/mob/living/simple_animal/hostile/hivebot/range/R = new /mob/living/simple_animal/hostile/hivebot/range(get_turf(src))
				R.faction = faction
			if("rapid")
				var/mob/living/simple_animal/hostile/hivebot/rapid/F = new /mob/living/simple_animal/hostile/hivebot/rapid(get_turf(src))
				F.faction = faction
	spawn(100)
		qdel(src)
	return

/mob/living/simple_animal/hostile/hivebot/tele/handle_automated_action()
	if(!..())
		return
	if(prob(2))//Might be a bit low, will mess with it likely
		warpbots()
