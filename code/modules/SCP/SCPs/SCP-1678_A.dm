// ============================================================================
// SCP-1678 AI HOLDER
// ============================================================================

/datum/ai_holder/simple_animal/melee/scp1678
	mauling = TRUE
	vision_range = 10

// ============================================================================
// NATURAL WEAPON
// ============================================================================

/obj/item/natural_weapon/scp1678_baton
	name = "police baton"
	attack_verb = list("struck", "hit", "bashed", "beaten")
	hitsound = 'sounds/scp/1678/whistle.ogg'
	damtype = BRUTE
	force = 20
	edge = FALSE
	sharp = FALSE
	armor_penetration = 5

// ============================================================================
// SAY LIST
// ============================================================================

/datum/say_list/scp1678
	speak = list("You are being detained. Do not resist.")
	speak_sounds = list('sounds/scp/1678/whistle.ogg')

// ============================================================================
// SCP-1678 MOB
// ============================================================================

/mob/living/simple_animal/hostile/scp1678
	name = "tall masked figure"
	desc = "A tall figure with fabric scraps covering its face. It carries a police baton."
	icon = 'icons/SCP/scp-1678.dmi'
	icon_state = "1678_A"
	icon_living = "1678_A"
	icon_dead = "1678_A_dead"

	health = 300
	maxHealth = 300

	see_invisible = SEE_INVISIBLE_NOLIGHTING
	see_in_dark = 7

	can_pull_size = 5
	a_intent = "harm"
	can_be_buckled = FALSE

	movement_cooldown = 2
	say_list_type = /datum/say_list/scp1678

	default_pixel_x = -8
	pixel_x = -8
	default_pixel_y = -16
	pixel_y = -16

	ai_holder_type = /datum/ai_holder/simple_animal/melee/scp1678
	melee_attack_delay = 2 SECONDS
	natural_weapon = /obj/item/natural_weapon/scp1678_baton

	var/door_cooldown = 5 SECONDS
	var/attack_cooldown_time = 2 SECONDS

	var/door_cooldown_track = 0
	var/attack_cooldown_track = 0
	var/area/spawn_area
	var/turf/start_turf

/mob/living/simple_animal/hostile/scp1678/Initialize(mapload)
	. = ..()
	pixel_x = default_pixel_x
	pixel_y = default_pixel_y

	SCP = new /datum/scp(
		src,
		"tall masked figure",
		SCP_EUCLID,
		"1678-A",
		SCP_PLAYABLE | SCP_ROLEPLAY
	)
	add_verb(src, /client/proc/scpooc)
	SCP.min_time = 15 MINUTES
	SCP.min_playercount = 10

	spawn_area = get_area(src)
	start_turf = get_turf(src)

/mob/living/simple_animal/hostile/scp1678/Life()
	. = ..()
	if(pixel_x != default_pixel_x || pixel_y != default_pixel_y)
		pixel_x = default_pixel_x
		pixel_y = default_pixel_y

/mob/living/simple_animal/hostile/scp1678/say(message, datum/language/speaking = null, whispering)
	to_chat(src, SPAN_NOTICE("You cannot speak."))
	return 0

/mob/living/simple_animal/hostile/scp1678/verb/Detain()
	set name = "Detain"
	set category = "SCP-1678"
	set desc = "Order someone to stop."

	playsound(src, 'sounds/scp/1678/whistle.ogg', 50, 1)
	visible_message(SPAN_DANGER("[src] blows a whistle and shouts: 'You are being detained. Do not resist!'"))

/mob/living/simple_animal/hostile/scp1678/UnarmedAttack(atom/A)
	if(A.SCP)
		return
	if((world.time - attack_cooldown_track) < attack_cooldown_time)
		return

	if(ishuman(A))
		var/mob/living/carbon/human/target = A
		if(target.stat == DEAD)
			return
		playsound(src, 'sounds/scp/1678/whistle.ogg', 50, 1)
		visible_message(SPAN_DANGER("[src] blows a whistle and strikes [target] with the baton!"))
		target.apply_damage(20, BRUTE)
		target.Weaken(3)
		attack_cooldown_track = world.time
		return

	if(istype(A, /obj/machinery/door))
		OpenDoor(A)
		attack_cooldown_track = world.time
		return

	..()

/mob/living/simple_animal/hostile/scp1678/Bump(atom/A)
	. = ..()
	if(A == src || stunned || weakened)
		return
	if(istype(A, /obj/machinery/door))
		OpenDoor(A)
		return
	if(isliving(A) && canClick())
		UnarmedAttack(A)

/mob/living/simple_animal/hostile/scp1678/proc/OpenDoor(obj/machinery/door/A)
	if((world.time - door_cooldown_track) < door_cooldown)
		return
	if(!istype(A) || !A.density || !A.Adjacent(src))
		return

	if(istype(A, /obj/machinery/door/blast))
		visible_message(SPAN_WARNING("[src] stares at [A], unable to force it open."))
		door_cooldown_track = world.time + door_cooldown
		return

	var/open_time = 8 SECONDS

	A.visible_message(SPAN_WARNING("[src] slowly forces open [A]..."))
	door_cooldown_track = world.time + open_time

	if(!do_after(src, open_time, A))
		return

	A.set_broken(TRUE)
	A.open(1)
	playsound(src, 'sounds/scp/1678/whistle.ogg', 50, 1)

/mob/living/simple_animal/hostile/scp1678/death(gibbed, deathmessage, show_dead_message)
	visible_message(SPAN_DANGER("[src] collapses. The whistle dies out."))
	pixel_x = default_pixel_x
	pixel_y = default_pixel_y
	return ..()
