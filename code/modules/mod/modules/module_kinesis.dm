///Kinesis - Gives you the ability to move and launch objects.
/obj/item/mod/module/anomaly_locked/kinesis
	name = "MOD kinesis module"
	desc = "A modular plug-in to the forearm, this module was presumed lost for many years, \
		despite the suits it used to be mounted on still seeing some circulation. \
		This piece of technology allows the user to generate precise anti-gravity fields, \
		letting them move objects as small as a titanium rod to as large as industrial machinery. \
		It does seem to work on living creatures, but not well."
	icon_state = "kinesis"
	module_type = MODULE_ACTIVE
	complexity = 3
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	incompatible_modules = list(/obj/item/mod/module/anomaly_locked/kinesis)
	cooldown_time = 0.5 SECONDS
	overlay_state_inactive = "module_kinesis"
	overlay_state_active = "module_kinesis_on"
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/grav)
	/// Range of the kinesis grab.
	var/grab_range = 5
	/// Time between us hitting objects with kinesis.
	var/hit_cooldown_time = 1 SECONDS
	/// Stat required for us to grab a mob.
	var/stat_required = CONSCIOUS //Honestly. It's grav core locked. We'll try it, but I am going to need you to stun the mod. No fucking holding a poor terror prince in the air
	/// Is incapitated required for us to grab a mob?
	var/incapacitated_required = TRUE
	/// How long we stun a mob for.
	var/mob_stun_time = 0
	/// Atom we grabbed with kinesis.
	var/atom/movable/grabbed_atom
	/// Overlay we add to each grabbed atom.
	var/image/kinesis_icon
	/// Our mouse movement catcher.
	var/atom/movable/screen/fullscreen/stretch/cursor_catcher/kinesis/kinesis_catcher
	/// The sounds playing while we grabbed an object.
	var/datum/looping_sound/kinesis/soundloop
	///The pixel_X of whatever we were grabbing before hand.
	var/pre_pixel_x
	///The pixel_y of whatever we were grabbing before hand.
	var/pre_pixel_y
	/// The special snowflake effect we need to get beams to work
	var/obj/effect/abstract/kinesis/beam = null
	/// The cooldown between us hitting objects with kinesis.
	COOLDOWN_DECLARE(hit_cooldown)

/obj/item/mod/module/anomaly_locked/kinesis/Initialize(mapload)
	. = ..()
	soundloop = new(src)
	kinesis_icon = image(icon = 'icons/effects/effects.dmi', icon_state = "kinesis", layer = EFFECTS_LAYER)

/obj/item/mod/module/anomaly_locked/kinesis/Destroy()
	QDEL_NULL(soundloop)
	QDEL_NULL(beam)
	QDEL_NULL(kinesis_catcher)
	QDEL_NULL(kinesis_icon)
	grabbed_atom = null
	return ..()

/obj/item/mod/module/anomaly_locked/kinesis/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(!mod.wearer.client)
		return
	if(grabbed_atom)
		launch()
		clear_grab(playsound = FALSE)
		return
	if(!range_check(target))
		to_chat(mod.wearer, "<span class='warning'>[target] is too far away!</span>")
		return
	if(!can_grab(target))
		to_chat(mod.wearer, "<span class='warning'>[target] can not be grabbed!</span>")
		return
	drain_power(use_power_cost)
	grabbed_atom = target
	if(isliving(grabbed_atom))
		var/mob/living/grabbed_mob = grabbed_atom
		grabbed_mob.Stun(mob_stun_time)
	playsound(grabbed_atom, 'sound/weapons/contractorbatonhit.ogg', 75, TRUE)
	beam = new /obj/effect/abstract/kinesis(get_turf(mod.wearer))
	kinesis_icon.layer = grabbed_atom.layer - 0.1
	grabbed_atom.add_overlay(kinesis_icon)
	pre_pixel_x = grabbed_atom.pixel_x
	pre_pixel_y = grabbed_atom.pixel_y
	beam.chain = beam.Beam(grabbed_atom, icon_state = "kinesis", icon='icons/effects/beam.dmi', time = 100 SECONDS, maxdistance = 15, beam_type = /obj/effect/ebeam)
	kinesis_catcher = mod.wearer.overlay_fullscreen("kinesis", /atom/movable/screen/fullscreen/stretch/cursor_catcher/kinesis, 0)
	kinesis_catcher.assign_to_mob(mod.wearer)
	soundloop.start()
	START_PROCESSING(SSfastprocess, src)

/obj/item/mod/module/anomaly_locked/kinesis/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	clear_grab(playsound = !deleting)

/obj/item/mod/module/anomaly_locked/kinesis/process()
	if(!mod.wearer.client || mod.wearer.incapacitated(ignore_grab = TRUE))
		clear_grab()
		return
	if(!range_check(grabbed_atom))
		to_chat(mod.wearer, "<span class='warning'>[grabbed_atom] is too far away!</span>")
		clear_grab()
		return
	beam.forceMove(get_turf(mod.wearer))
	drain_power(use_power_cost / 10)
	if(kinesis_catcher.mouse_params)
		kinesis_catcher.calculate_params()
	if(!kinesis_catcher.given_turf)
		return
	mod.wearer.setDir(get_dir(mod.wearer, grabbed_atom))
	if(grabbed_atom.loc == kinesis_catcher.given_turf)
		if(grabbed_atom.pixel_x == kinesis_catcher.given_x - world.icon_size/2 && grabbed_atom.pixel_y == kinesis_catcher.given_y - world.icon_size/2)
			return //spare us redrawing if we are standing still
		animate(grabbed_atom, 0.2 SECONDS, pixel_x = pre_pixel_x + kinesis_catcher.given_x - world.icon_size/2, pixel_y = pre_pixel_y + kinesis_catcher.given_y - world.icon_size/2)
		beam.chain.redrawing()
		return
	animate(grabbed_atom, 0.2 SECONDS, pixel_x = pre_pixel_x + kinesis_catcher.given_x - world.icon_size/2, pixel_y = pre_pixel_y + kinesis_catcher.given_y - world.icon_size/2)
	var/turf/next_turf = get_step_towards(grabbed_atom, kinesis_catcher.given_turf)
	if(grabbed_atom.Move(next_turf, get_dir(grabbed_atom, next_turf), 8))
		if(isitem(grabbed_atom) && (mod.wearer in next_turf))
			var/obj/item/grabbed_item = grabbed_atom
			clear_grab()
			grabbed_item.pickup(mod.wearer)
			mod.wearer.put_in_hands(grabbed_item)
		return
	var/pixel_x_change = 0
	var/pixel_y_change = 0
	var/direction = get_dir(grabbed_atom, next_turf)
	if(direction & NORTH)
		pixel_y_change = world.icon_size / 2
	else if(direction & SOUTH)
		pixel_y_change = -world.icon_size / 2
	if(direction & EAST)
		pixel_x_change = world.icon_size / 2
	else if(direction & WEST)
		pixel_x_change = -world.icon_size / 2
	animate(grabbed_atom, 0.2 SECONDS, pixel_x = pre_pixel_x + pixel_x_change, pixel_y = pre_pixel_y + pixel_y_change) //Not as smooth as I would like, will look into this in the future
	beam.chain.redrawing()
	if(!isitem(grabbed_atom) || !COOLDOWN_FINISHED(src, hit_cooldown))
		return
	var/atom/hitting_atom
	if(next_turf.density)
		hitting_atom = next_turf
	for(var/atom/movable/movable_content as anything in next_turf.contents)
		if(ismob(movable_content))
			continue
		if(movable_content.density)
			hitting_atom = movable_content
			break
	var/obj/item/grabbed_item = grabbed_atom
	grabbed_item.melee_attack_chain(mod.wearer, hitting_atom)
	COOLDOWN_START(src, hit_cooldown, hit_cooldown_time)

/obj/item/mod/module/anomaly_locked/kinesis/proc/can_grab(atom/target)
	if(mod.wearer == target)
		return FALSE
	if(!ismovable(target))
		return FALSE
	if(iseffect(target))
		return FALSE
	if(locate(mod.wearer) in target)
		return FALSE
	var/atom/movable/movable_target = target
	if(movable_target.anchored)
		return FALSE
	if(movable_target.throwing)
		return FALSE
	if(movable_target.move_resist >= MOVE_FORCE_OVERPOWERING)
		return FALSE
	if(locate(mod.wearer) in movable_target.buckled_mobs)
		return FALSE
	if(ismob(movable_target))
		if(!isliving(movable_target))
			return FALSE
		var/mob/living/living_target = movable_target
		if(living_target.stat < stat_required)
			return FALSE
		if(!living_target.incapacitated() && incapacitated_required)
			return FALSE
	else if(isitem(movable_target))
		var/obj/item/item_target = movable_target
		if(item_target.w_class >= WEIGHT_CLASS_GIGANTIC)
			return FALSE
		if(item_target.flags & ABSTRACT)
			return FALSE
	return TRUE

/obj/item/mod/module/anomaly_locked/kinesis/proc/clear_grab(playsound = TRUE)
	if(!grabbed_atom)
		return
	if(playsound)
		playsound(grabbed_atom, 'sound/effects/empulse.ogg', 75, TRUE)
	STOP_PROCESSING(SSfastprocess, src)
	kinesis_catcher = null
	mod.wearer.clear_fullscreen("kinesis")
	grabbed_atom.cut_overlay(kinesis_icon)
	QDEL_NULL(beam)
	if(!isitem(grabbed_atom))
		animate(grabbed_atom, 0.2 SECONDS, pixel_x = pre_pixel_x, pixel_y = pre_pixel_y)
	grabbed_atom = null
	soundloop.stop()

/obj/item/mod/module/anomaly_locked/kinesis/proc/range_check(atom/target)
	if(!isturf(mod.wearer.loc))
		return FALSE
	if(ismovable(target) && !isturf(target.loc))
		return FALSE
	if(!can_see(mod.wearer, target, grab_range))
		return FALSE
	return TRUE

/obj/item/mod/module/anomaly_locked/kinesis/proc/launch()
	playsound(grabbed_atom, 'sound/magic/repulse.ogg', 100, TRUE)
	RegisterSignal(grabbed_atom, COMSIG_MOVABLE_IMPACT, PROC_REF(launch_impact))
	var/turf/target_turf = get_turf_in_angle(get_angle(mod.wearer, grabbed_atom), get_turf(src), 10)
	grabbed_atom.throw_at(target_turf, range = grab_range, speed = grabbed_atom.density ? 3 : 4, thrower = mod.wearer, spin = isitem(grabbed_atom))

/obj/item/mod/module/anomaly_locked/kinesis/proc/launch_impact(atom/movable/source, atom/hit_atom, datum/thrownthing/thrownthing)
	UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)
	if(!isobj(source))
		return
	var/obj/S = source
	var/damage_self = TRUE
	var/damage = 8
	if(S.density)
		damage_self = FALSE
		damage = 15
	if(isliving(hit_atom))
		var/mob/living/living_atom = hit_atom
		living_atom.apply_damage(damage, BRUTE)
	else if(isobj(hit_atom))
		var/obj/O = hit_atom
		O.take_damage(damage, BRUTE, MELEE)
	if(damage_self)
		S.take_damage(S.max_integrity / 5, BRUTE, MELEE)

/obj/effect/abstract/kinesis
	var/datum/beam/chain

/obj/effect/abstract/kinesis/Destroy()
	qdel(chain)
	return ..()

/obj/item/mod/module/anomaly_locked/kinesis/prebuilt
	prebuilt = TRUE
	removable = FALSE // No switching it into another suit / no free anomaly core

/obj/item/mod/module/anomaly_locked/kinesis/prebuilt/prototype
	name = "MOD prototype kinesis module"
	complexity = 0
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5

/atom/movable/screen/fullscreen/stretch/cursor_catcher/kinesis
	icon = 'icons/mob/screen_kinesis.dmi'
	icon_state = "kinesis"

/obj/item/mod/module/anomaly_locked/kinesis/plus
	name = "MOD kinesis+ module"
	desc = "A modular plug-in to the forearm, this module was recently redeveloped in secret. \
		The bane of all ne'er-do-wells, the kinesis+ module is a powerful tool that allows the user \
		to manipulate the world around them. Like it's older counterpart, it's capable of manipulating \
		structures, machinery, vehicles, and, thanks to the fruitful efforts of it's creators - living  \
		beings. They can, however, still struggle after an initial burst of inertia."
	complexity = 0
	prebuilt = TRUE
	incapacitated_required = FALSE
	mob_stun_time = 10 SECONDS
