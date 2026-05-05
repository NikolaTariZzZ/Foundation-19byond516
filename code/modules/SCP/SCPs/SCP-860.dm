// ============================================================================
// SCP-860 - Blue Key
// ============================================================================

GLOBAL_LIST_EMPTY(scp860_return_spawns)

/obj/item/scp860
	name = "dark blue key"
	desc = "A dark blue key that feels cold to the touch. Numbers occasionally flicker across its surface."
	icon = 'icons/SCP/scp-860.dmi'
	icon_state = "key"
	item_state = "key"
	w_class = ITEM_SIZE_SMALL

	var/use_cooldown = 3 MINUTES
	var/use_cooldown_track = 0

	var/portal_x = 207
	var/portal_y = 179
	var/portal_z = 8

	var/return_x = 0
	var/return_y = 0
	var/return_z = 0
	var/has_return_coords = FALSE

/obj/item/scp860/Initialize(mapload)
	. = ..()
	SCP = new /datum/scp(
		src,
		"dark blue key",
		SCP_SAFE,
		"860"
	)

/obj/item/scp860/afterattack(atom/target, mob/user, proximity_flag)
	if(!proximity_flag)
		return

	if(world.time < use_cooldown_track)
		to_chat(user, SPAN_WARNING("[src] is not ready yet. Wait [round((use_cooldown_track - world.time) / 600)] minutes."))
		return

	if(!istype(target, /obj/machinery/door) && !istype(target, /obj/structure/scp004_door) && !istype(target, /obj/structure/scp860_return_door))
		return

	if(istype(target, /obj/structure/scp860_return_door))
		var/obj/structure/scp860_return_door/RD = target
		if(has_return_coords)
			RD.target_x = return_x
			RD.target_y = return_y
			RD.target_z = return_z

			user.visible_message(
				SPAN_DANGER("[user] inserts [src] into [RD] and turns it..."),
				SPAN_DANGER("You insert [src] and begin turning...")
			)
			playsound(get_turf(user), pick('sounds/effects/clue1.ogg', 'sounds/effects/clue2.ogg'), 50, TRUE)

			if(!do_after(user, 2 SECONDS, RD, bonus_percentage = 50))
				return

			RD.icon_state = "metalopen"
			playsound(get_turf(user), 'sounds/effects/teleport1.ogg', 50, TRUE)

			var/turf/T = locate(RD.target_x, RD.target_y, RD.target_z)
			if(T)
				user.forceMove(T)
				to_chat(user, SPAN_NOTICE("You step through and return to where you came from."))
			else
				to_chat(user, SPAN_WARNING("The doorway leads nowhere..."))

			visible_message(SPAN_WARNING("[RD] fades away."))
			qdel(RD)
			use_cooldown_track = world.time + use_cooldown
		else
			to_chat(user, SPAN_WARNING("[src] doesn't know the way back yet."))
		return

	if(istype(target, /obj/machinery/door))
		var/obj/machinery/door/D = target
		if(!D.density)
			to_chat(user, SPAN_WARNING("[D] is already open."))
			return

	if(istype(target, /obj/structure/scp004_door))
		var/obj/structure/scp004_door/D = target
		if(D.open || D.portal_active)
			to_chat(user, SPAN_WARNING("[D] is already open."))
			return

	user.visible_message(
		SPAN_DANGER("[user] inserts [src] into [target] and begins turning it..."),
		SPAN_DANGER("You insert [src] into [target]. The lock clicks...")
	)

	playsound(get_turf(user), pick('sounds/effects/clue1.ogg', 'sounds/effects/clue2.ogg'), 50, TRUE)

	// Delay for lock turning
	if(!do_after(user, 2 SECONDS, target, bonus_percentage = 50))
		return

	return_x = user.x
	return_y = user.y
	return_z = user.z
	has_return_coords = TRUE

	use_cooldown_track = world.time + use_cooldown

	// Open the door
	if(istype(target, /obj/machinery/door))
		var/obj/machinery/door/D = target
		D.open(1)

	if(istype(target, /obj/structure/scp004_door))
		var/obj/structure/scp004_door/D = target
		D.icon_state = "door_open"
		D.open = TRUE
		D.density = FALSE
		D.opacity = FALSE

	var/obj/effect/portal/scp860_entry/P = new(get_turf(target))
	P.target_x = portal_x
	P.target_y = portal_y
	P.target_z = portal_z

	user.visible_message(
		SPAN_DANGER("The doorway flickers and a dark forest appears beyond!"),
		SPAN_DANGER("A passage opens... The key remembers this spot.")
	)

/obj/item/scp860/examine(mob/user)
	. = ..()
	if(has_return_coords)
		to_chat(user, SPAN_NOTICE("The key remembers: [return_x], [return_y], [return_z]."))
	to_chat(user, SPAN_NOTICE("Destination: [portal_x], [portal_y], [portal_z]."))

// ============================================================================
// SCP-860 ENTRY PORTAL
// ============================================================================

/obj/effect/portal/scp860_entry
	name = "dark portal"
	desc = "A shimmering passageway leading to an unknown forest."
	icon = 'icons/SCP/scp-860.dmi'
	icon_state = "portal"
	anchored = TRUE
	mouse_opacity = 1
	density = FALSE
	layer = 10
	var/target_x = 1
	var/target_y = 1
	var/target_z = 2
	var/last_teleport_time = 0
	var/teleport_cooldown = 5
	var/portal_lifetime = 60 SECONDS
	var/door_spawned = FALSE

/obj/effect/portal/scp860_entry/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(close_portal)), portal_lifetime)

/obj/effect/portal/scp860_entry/proc/close_portal()
	visible_message(SPAN_WARNING("[src] flickers and vanishes."))
	qdel(src)

/obj/effect/portal/scp860_entry/Crossed(atom/movable/AM)
	if(!isliving(AM))
		return
	if(world.time < last_teleport_time + teleport_cooldown)
		return
	var/mob/living/L = AM
	var/turf/T = locate(target_x, target_y, target_z)
	if(!T || T == loc)
		return
	last_teleport_time = world.time
	playsound(loc, 'sounds/effects/teleport1.ogg', 50, TRUE)
	L.forceMove(T)
	to_chat(L, SPAN_NOTICE("You step through the portal into a dark forest..."))

	if(!door_spawned)
		door_spawned = TRUE
		spawn_return_door()

/obj/effect/portal/scp860_entry/proc/spawn_return_door()
	if(!LAZYLEN(GLOB.scp860_return_spawns))
		return

	var/turf/spawn_turf = pick(GLOB.scp860_return_spawns)
	new /obj/structure/scp860_return_door(spawn_turf)
	visible_message(SPAN_WARNING("A strange metal door materializes in the forest!"))

/obj/effect/portal/scp860_entry/attack_hand(mob/user)
	return

// ============================================================================
// SCP-860 RETURN DOOR
// ============================================================================

/obj/structure/scp860_return_door
	name = "metal door"
	desc = "A mysterious metal door standing alone. A faint blue light glows around its frame. It has no handle — only a keyhole."
	icon = 'icons/obj/doors/material_doors.dmi'
	icon_state = "metal"
	density = TRUE
	anchored = TRUE
	opacity = TRUE
	var/target_x = 0
	var/target_y = 0
	var/target_z = 0

/obj/structure/scp860_return_door/attack_hand(mob/user)
	to_chat(user, SPAN_WARNING("[src] has no handle. It can only be opened with the key."))

/obj/structure/scp860_return_door/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/scp860))
		return
	..()

// ============================================================================
// SCP-860-1 HAZARDOUS SMOKE
// ============================================================================

/obj/effect/scp860_smoke
	name = "strange smoke"
	desc = "A thick, blue-tinted smoke that burns the skin and clouds the mind."
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	anchored = TRUE
	mouse_opacity = 0
	layer = ABOVE_HUMAN_LAYER
	alpha = 180
	var/last_damage_time = 0
	var/damage_cooldown = 3 SECONDS

/obj/effect/scp860_smoke/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/scp860_smoke/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/scp860_smoke/Process()
	if(world.time < last_damage_time + damage_cooldown)
		return

	var/mob/living/carbon/human/H = locate() in get_turf(src)
	if(!H)
		return

	last_damage_time = world.time
	H.take_overall_damage(3, 0)
	H.adjustToxLoss(1)
	if(H.reagents)
		H.reagents.add_reagent(/datum/reagent/medicine/amnestics/classa, 0.5)

/obj/effect/scp860_smoke/Crossed(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.take_overall_damage(5, 0)
		H.adjustToxLoss(2)
		if(H.reagents)
			H.reagents.add_reagent(/datum/reagent/medicine/amnestics/classa, 3)

/obj/effect/scp860_smoke/attack_hand(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		to_chat(H, SPAN_DANGER("You reach into the smoke. It burns!"))
		H.take_overall_damage(8, 0)
		H.adjustToxLoss(3)
		if(H.reagents)
			H.reagents.add_reagent(/datum/reagent/medicine/amnestics/classa, 5)

// ============================================================================
// SCP-860 RETURN DOOR LANDMARK
// ============================================================================

/obj/effect/landmark/scp860_return
	name = "SCP-860 return door spawn"
	icon_state = "x3"
	invisibility = 101

/obj/effect/landmark/scp860_return/Initialize(mapload)
	. = ..()
	if(!mapload)
		return INITIALIZE_HINT_QDEL
	GLOB.scp860_return_spawns += loc
	return INITIALIZE_HINT_LATELOAD

/obj/effect/landmark/scp860_return/LateInitialize()
	return
