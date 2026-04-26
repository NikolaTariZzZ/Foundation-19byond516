// ==================== SCP-093 AI HOLDER ====================
/datum/ai_holder/simple_animal/melee/scp093
    mauling = TRUE
    vision_range = 14

/datum/say_list/scp093
    emote_hear = list("groans", "growls lowly", "makes a wet gurgling sound")
    emote_see = list("twitches unnaturally", "tilts its head", "lurches forward")

// ==================== SCP-093 MONSTER ====================
/mob/living/simple_animal/hostile/scp093
    name = "Yellow Giant"
    desc = "A towering, thin creature with pale skin and elongated limbs. Its hollow eyes stare through you."
    icon = 'icons/SCP/scp-093.dmi'
    icon_state = "monster"
    icon_living = "monster"
    icon_dead = "monster_dead"
    pixel_x = -48

    maxHealth = 3000
    health = 3000
    attack_delay = 6

    faction = "scp"
    response_help = "touches"
    response_disarm = "pushes"
    response_harm = "strikes"
    attacktext = "smashes"
    mob_size = MOB_LARGE

    status_flags = CANPUSH
    density = TRUE
    anchored = FALSE
    can_pull_size = 5
    a_intent = "harm"

    ai_holder_type = /datum/ai_holder/simple_animal/melee/scp093
    say_list_type = /datum/say_list/scp093

    var/heal_rate = 50
    var/heal_timer
    var/attack_cooldown_time = 4 SECONDS
    var/attack_cooldown

/mob/living/simple_animal/hostile/scp093/Initialize()
    . = ..()
    heal_timer = addtimer(CALLBACK(src, PROC_REF(regen)), 10 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/scp093/Destroy()
    if(heal_timer)
        deltimer(heal_timer)
    return ..()

/mob/living/simple_animal/hostile/scp093/proc/regen()
    if(stat != DEAD)
        health = min(health + heal_rate, maxHealth)
        heal_timer = addtimer(CALLBACK(src, PROC_REF(regen)), 10 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/scp093/death(gibbed, deathmessage, show_dead_message)
    ..()
    icon_state = icon_dead
    visible_message(SPAN_DANGER("[src] lets out a horrible screech and explodes into a shower of black viscera and blood!"))
    playsound(src, 'sounds/effects/splat.ogg', 100, 1)
    new /obj/effect/gibspawner/generic(get_turf(src))
    new /obj/effect/gibspawner/human(get_turf(src))
    var/obj/effect/decal/cleanable/blood/gibs/G = new /obj/effect/decal/cleanable/blood/gibs(get_turf(src))
    G.basecolor = "#000000"
    G.update_icon()

/mob/living/simple_animal/hostile/scp093/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0)
    . = ..()
    if(. && stat == CONSCIOUS)
        if(prob(10))
            var/turf/T = get_turf(src)
            if(T)
                var/obj/effect/decal/cleanable/blood/B = new /obj/effect/decal/cleanable/blood(T)
                B.basecolor = "#000000"
                B.update_icon()

/mob/living/simple_animal/hostile/scp093/do_attack(atom/A, turf/T)
    if(..())
        UnarmedAttack(A)

/mob/living/simple_animal/hostile/scp093/IAttack(atom/A)
    if(attack_cooldown > world.time)
        return ATTACK_ON_COOLDOWN
    return ..()

/mob/living/simple_animal/hostile/scp093/UnarmedAttack(atom/A)
    if(isliving(A))
        var/mob/living/L = A
        if(L.stat == DEAD)
            return
        if(attack_cooldown > world.time)
            to_chat(src, SPAN_WARNING("You can't attack yet."))
            return
        var/damage_amount = rand(60, 100)
        L.apply_damage(damage_amount, BRUTE)
        visible_message(SPAN_DANGER("[src] slashes [L] with tremendous force!"))
        attack_cooldown = world.time + attack_cooldown_time
        if(prob(20) && ishuman(L))
            var/mob/living/carbon/human/H = L
            var/limb_name = pick(BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG)
            var/obj/item/organ/external/limb = H.get_organ(limb_name)
            if(limb)
                limb.fracture()
                visible_message(SPAN_DANGER("[src] crushes [H]'s [limb.name] with tremendous force!"))
        return
    if(isobj(A) || isturf(A))
        visible_message(SPAN_DANGER("[src] smashes through [A]!"))
        playsound(get_turf(A), 'sounds/effects/grillehit.ogg', 50, 1)
        if(istype(A, /turf/simulated/wall))
            var/turf/simulated/wall/W = A
            W.dismantle_wall()
            return
        if(istype(A, /obj/machinery/door))
            var/obj/machinery/door/D = A
            if(istype(D, /obj/machinery/door/blast))
                D:force_open()
            else
                D.set_broken(TRUE)
                D.open(TRUE)
            return
        qdel(A)
        return
    return ..()

/mob/living/simple_animal/hostile/scp093/CanPass(atom/movable/mover, turf/target)
    return TRUE
