// ==================== СНАРЯД ====================
/obj/item/projectile/bone_spear
    name = "Костяной снаряд"
    desc = "Острый, как бритва, осколок кости, летящий на огромной скорости."
    icon = 'icons/SCP/scp-154.dmi'
    icon_state = "bone_spear"
    damage = 100
    damage_type = BRUTE
    armor_penetration = 50
    speed = 0.1

// ==================== ЛУК ====================
/obj/item/gun/projectile/scp154_bow
    name = "Призрачный лук"
    desc = "Большой, нечеткий, бестелесный лук. Тетивы нет, но жест её натягивания даёт тот же эффект."
    icon = 'icons/SCP/scp-154.dmi'
    icon_state = "bow"
    item_state = "bow_held"
    w_class = 5
    slot_flags = 0
    var/obj/item/clothing/gloves/scp154/parent_bracelets
    var/bow_drawn = FALSE

/obj/item/gun/projectile/scp154_bow/Initialize()
    . = ..()
    if(istype(loc, /obj/item/clothing/gloves/scp154))
        parent_bracelets = loc
    update_icon()

/obj/item/gun/projectile/scp154_bow/Destroy()
    if(parent_bracelets)
        parent_bracelets.active_bow = null
        parent_bracelets = null
    return ..()

/obj/item/gun/projectile/scp154_bow/update_icon()
    if(bow_drawn)
        icon_state = "bow_drawn"
    else
        icon_state = "bow"
    var/mob/M = loc
    if(istype(M))
        M.regenerate_icons()

// Z на луке — натянуть или выстрелить
/obj/item/gun/projectile/scp154_bow/attack_self(mob/user)
    if(!ishuman(user) || !parent_bracelets)
        return

    var/mob/living/carbon/human/H = user
    if(H.gloves != parent_bracelets)
        to_chat(user, SPAN_WARNING("Браслеты больше не на вас! Лук исчезает."))
        qdel(src)
        return

    if(bow_drawn)
        bow_drawn = FALSE
        update_icon()
        fire_bone_spear(user)
        return

    bow_drawn = TRUE
    user.visible_message(
        SPAN_WARNING("[user] поднимает призрачный лук и натягивает невидимую тетиву!"),
        SPAN_NOTICE("Вы поднимаете призрачный лук и натягиваете невидимую тетиву. Кости вашей руки начинают вибрировать от напряжения."))
    update_icon()

// Клик по цели — выстрел только если натянут
/obj/item/gun/projectile/scp154_bow/afterattack(atom/target, mob/living/user, flag, params)
    if(!ishuman(user) || !parent_bracelets)
        return

    var/mob/living/carbon/human/H = user
    if(H.gloves != parent_bracelets)
        to_chat(user, SPAN_WARNING("Браслеты больше не на вас! Лук исчезает."))
        qdel(src)
        return

    if(get_dist(user, target) <= 1)
        return

    if(!bow_drawn)
        to_chat(user, SPAN_WARNING("Сначала натяните тетиву."))
        return

    bow_drawn = FALSE
    update_icon()
    fire_bone_spear(user, target)

/obj/item/gun/projectile/scp154_bow/proc/fire_bone_spear(mob/living/carbon/human/user, atom/target = null)
    var/obj/item/organ/external/left_hand = user.get_organ(BP_L_ARM)
    var/obj/item/organ/external/right_hand = user.get_organ(BP_R_ARM)
    var/obj/item/organ/external/active_hand

    if(user.hand)
        active_hand = right_hand
    else
        active_hand = left_hand

    var/left_broken = left_hand && (left_hand.status & ORGAN_BROKEN)
    var/right_broken = right_hand && (right_hand.status & ORGAN_BROKEN)

    if(!left_hand && !right_hand)
        to_chat(user, SPAN_WARNING("У вас нет рук, чтобы выстрелить!"))
        return

    if(left_broken && right_broken)
        to_chat(user, SPAN_WARNING("Обе ваши руки сломаны! Вы не можете выстрелить, пока не исцелитесь."))
        bow_drawn = TRUE
        update_icon()
        return

    if(active_hand && (active_hand.status & ORGAN_BROKEN))
        if(user.hand)
            if(left_hand && !(left_hand.status & ORGAN_BROKEN))
                active_hand = left_hand
                user.visible_message(SPAN_WARNING("[user] перехватывает лук в левую руку."))
            else
                to_chat(user, SPAN_WARNING("Ваша правая рука сломана, а левая тоже недоступна!"))
                bow_drawn = TRUE
                update_icon()
                return
        else
            if(right_hand && !(right_hand.status & ORGAN_BROKEN))
                active_hand = right_hand
                user.visible_message(SPAN_WARNING("[user] перехватывает лук в правую руку."))
            else
                to_chat(user, SPAN_WARNING("Ваша левая рука сломана, а правая тоже недоступна!"))
                bow_drawn = TRUE
                update_icon()
                return

    to_chat(user, SPAN_DANGER("Вы отпускаете призрачную тетиву и кости вашей руки с хрустом вырываются наружу, превращаясь в смертоносный снаряд!"))
    user.emote("scream")

    active_hand.fracture()
    active_hand.brute_dam += 50

    var/obj/item/projectile/bone_spear/arrow = new(get_turf(user))
    arrow.firer = user
    arrow.original = target ? target : get_step(get_turf(user), user.dir)
    arrow.launch(arrow.original, user)

    parent_bracelets.start_healing(user)

// Выпал из рук — исчезает
/obj/item/gun/projectile/scp154_bow/dropped(mob/user)
    if(parent_bracelets)
        to_chat(user, SPAN_NOTICE("Призрачный лук исчезает, втягиваясь обратно в браслеты."))
    . = ..()
    qdel(src)

// Попытка надеть в другой слот — исчезает
/obj/item/gun/projectile/scp154_bow/equipped(mob/user, slot)
    if(slot == slot_l_hand || slot == slot_r_hand)
        return ..()
    if(parent_bracelets)
        to_chat(user, SPAN_WARNING("Призрачный лук не может существовать вне ваших рук и исчезает."))
    qdel(src)

// ==================== БРАСЛЕТЫ ====================
/obj/item/clothing/gloves/scp154
    name = "Pair of bronze bracelets"
    desc = "Пара простых бронзовых браслетов. На вид безобидны, но от них исходит странное тепло."
    icon = 'icons/SCP/scp-154.dmi'
    icon_state = "bracelets"
    item_state = "bracelets"
    var/heal_timer_id
    var/mob/living/carbon/human/current_wearer
    var/active_bow = null

/obj/item/clothing/gloves/scp154/equipped(mob/user, slot)
    . = ..()
    if(slot == slot_gloves)
        current_wearer = user
        to_chat(user, SPAN_NOTICE("Браслеты плотно обхватывают ваши запястья. Вы чувствуете, как сила течет по вашим рукам."))
        user.regenerate_icons()
    else
        stop_healing()
        current_wearer = null

/obj/item/clothing/gloves/scp154/dropped(mob/user)
    . = ..()
    if(current_wearer)
        stop_healing()
        current_wearer = null
    if(user)
        user.regenerate_icons()

/obj/item/clothing/gloves/scp154/proc/stop_healing()
    if(heal_timer_id)
        deltimer(heal_timer_id)
        heal_timer_id = null
    if(current_wearer)
        to_chat(current_wearer, SPAN_WARNING("Связь с браслетами прерывается, и исцеляющая энергия рассеивается."))

// Alt+Click на надетых браслетах — призвать/убрать лук
/obj/item/clothing/gloves/scp154/AltClick(mob/user)
    . = ..()
    if(!ishuman(user))
        return

    var/mob/living/carbon/human/H = user
    if(H.gloves != src)
        return

    if(active_bow)
        QDEL_NULL(active_bow)
        to_chat(H, SPAN_NOTICE("Призрачный лук исчезает, втягиваясь обратно в браслеты."))
        return

    active_bow = new /obj/item/gun/projectile/scp154_bow(src)
    H.put_in_active_hand(active_bow)
    to_chat(H, SPAN_NOTICE("Браслеты начинают светиться! В вашей руке материализуется призрачный лук, сотканный из чистой энергии."))

// Verb — запасной способ призыва/убирания лука
/obj/item/clothing/gloves/scp154/verb/summon_bow()
    set name = "Summon SCP-154 Bow"
    set desc = "Призвать или убрать призрачный лук."
    set category = "Object"
    set src in usr

    if(!ishuman(usr))
        return

    var/mob/living/carbon/human/H = usr
    if(H.gloves != src)
        to_chat(H, SPAN_WARNING("Вы должны носить браслеты на руках."))
        return

    if(active_bow)
        QDEL_NULL(active_bow)
        to_chat(H, SPAN_NOTICE("Призрачный лук исчезает, втягиваясь обратно в браслеты."))
        return

    active_bow = new /obj/item/gun/projectile/scp154_bow(src)
    H.put_in_active_hand(active_bow)
    to_chat(H, SPAN_NOTICE("Браслеты начинают светиться! В вашей руке материализуется призрачный лук, сотканный из чистой энергии."))

/obj/item/clothing/gloves/scp154/proc/start_healing(mob/living/carbon/human/user)
    if(heal_timer_id)
        deltimer(heal_timer_id)
    to_chat(user, SPAN_NOTICE("Браслеты начинают вибрировать, направляя энергию на восстановление ваших рук. Это займет около 20 секунд."))
    heal_timer_id = addtimer(CALLBACK(src, .proc/heal_bones), 20 SECONDS, TIMER_STOPPABLE)

/obj/item/clothing/gloves/scp154/proc/heal_bones()
    heal_timer_id = null
    if(!current_wearer)
        return
    var/mob/living/carbon/human/H = current_wearer
    if(H.gloves != src)
        to_chat(H, SPAN_WARNING("Восстановление прервано: браслеты больше не на вас."))
        return

    to_chat(H, SPAN_NOTICE("Энергия браслетов наполняет ваши руки. Кости встают на место."))

    var/list/arms = list(H.get_organ(BP_L_ARM), H.get_organ(BP_R_ARM))
    for(var/obj/item/organ/external/arm in arms)
        if(arm)
            arm.status &= ~ORGAN_BROKEN

    H.regenerate_icons()
