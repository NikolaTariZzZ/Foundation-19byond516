#define SCP004_EFFECT_GIB    0
#define SCP004_EFFECT_PORTAL 1

/obj/structure/scp004_door
	name = "SCP-004-1"
	desc = "Тяжелая деревянная дверь, обитая ржавыми железными петлями."
	icon = 'icons/SCP/scp-004.dmi'
	icon_state = "door_closed"
	density = TRUE
	anchored = TRUE
	opacity = TRUE
	var/open = FALSE
	var/door_opening = FALSE
	var/portal_active = FALSE
	var/obj/effect/portal/scp004/current_portal = null
	var/obj/effect/portal/scp004/linked_portal = null
	var/portal_timer = null

/obj/structure/scp004_door/Initialize(mapload)
	. = ..()
	update_icon()

/obj/structure/scp004_door/Destroy()
	if(portal_timer)
		deltimer(portal_timer)
	if(current_portal)
		QDEL_NULL(current_portal)
	if(linked_portal)
		QDEL_NULL(linked_portal)
	return ..()

/obj/structure/scp004_door/attackby(obj/item/W, mob/user, params)
	if(!istype(W, /obj/item/key/scp004))
		return
	if(door_opening || portal_active || open)
		return
	var/obj/item/key/scp004/key = W
	try_key(user, key)

/obj/structure/scp004_door/proc/try_key(mob/user, obj/item/key/scp004/key)
	user.visible_message(
		"<span class='notice'>[user] вставляет ключ в замочную скважину.</span>",
		"<span class='notice'>Вы вставляете ключ. Механизм приходит в движение...</span>"
	)
	if(!do_after(user, 2 SECONDS, src))
		return
	if(key.key_effect == SCP004_EFFECT_GIB)
		gib_user(user)
		return
	open_portal(key)

/obj/structure/scp004_door/proc/open_portal(obj/item/key/scp004/key)
	door_opening = TRUE
	open = TRUE
	portal_active = TRUE
	density = FALSE
	opacity = FALSE
	icon_state = "door_open"

	current_portal = new /obj/effect/portal/scp004(loc)
	current_portal.icon = 'icons/SCP/scp-004.dmi'
	current_portal.icon_state = "portal"
	current_portal.set_light(2, 1, "#88CCFF")

	var/turf/T = locate(key.portal_x, key.portal_y, key.portal_z)
	if(T)
		linked_portal = new /obj/effect/portal/scp004(T)
		linked_portal.icon = 'icons/SCP/scp-004.dmi'
		linked_portal.icon_state = "portal"
		linked_portal.set_light(2, 1, "#88CCFF")
		current_portal.linked = linked_portal
		linked_portal.linked = current_portal
		linked_portal.target_x = loc.x
		linked_portal.target_y = loc.y
		linked_portal.target_z = loc.z

	current_portal.target_x = key.portal_x
	current_portal.target_y = key.portal_y
	current_portal.target_z = key.portal_z

	door_opening = FALSE
	visible_message("<span class='warning'>Дверь распахивается, открывая мерцающий проход.</span>")
	portal_timer = addtimer(CALLBACK(src, PROC_REF(auto_close_portal)), 1 MINUTES, TIMER_STOPPABLE)

/obj/structure/scp004_door/proc/auto_close_portal()
	if(current_portal && !QDELETED(current_portal))
		visible_message("<span class='notice'>Проход мерцает и исчезает. Дверь закрывается.</span>")
		QDEL_NULL(current_portal)
	if(linked_portal && !QDELETED(linked_portal))
		QDEL_NULL(linked_portal)
	portal_active = FALSE
	close_door()
	portal_timer = null

/obj/structure/scp004_door/proc/gib_user(mob/user)
	user.visible_message("<span class='danger'>Тело [user] разрывает на куски!</span>")
	user.gib(1, 1, 1)

/obj/structure/scp004_door/proc/close_door()
	icon_state = "door_closing"
	spawn(1 SECONDS)
		icon_state = "door_closed"
		open = FALSE
		density = TRUE
		opacity = TRUE
		update_icon()

/obj/structure/scp004_door/update_icon()
	icon_state = open ? "door_open" : "door_closed"

/obj/structure/scp004_door/examine(mob/user)
	. = ..()
	if(portal_active)
		. += "<span class='notice'>В проёме мерцает проход.</span>"
	else if(open)
		. += "<span class='notice'>Дверь открыта.</span>"
	else
		. += "<span class='notice'>Заперта.</span>"

/obj/structure/scp004_door/attack_hand(mob/user)
	if(portal_active)
		to_chat(user, "<span class='notice'>В проёме проход. Можно войти.</span>")
	else if(open)
		to_chat(user, "<span class='notice'>Дверь открыта.</span>")
	else
		to_chat(user, "<span class='warning'>Дверь заперта. Нужен подходящий ключ.</span>")

/obj/item/key/scp004
	name = "Ржавый ключ"
	desc = "Старый ржавый ключ без опознавательных знаков."
	icon = 'icons/SCP/scp-004.dmi'
	icon_state = "key"
	abstract_type = /obj/item/key/scp004
	w_class = ITEM_SIZE_TINY
	var/key_effect = SCP004_EFFECT_GIB
	var/key_id = 0
	var/portal_x = 0
	var/portal_y = 0
	var/portal_z = 0

/obj/item/key/scp004/examine(mob/user)
	. = ..()
	if(user.client?.holder)
		if(key_effect == SCP004_EFFECT_PORTAL)
			. += "<span class='admin'>ADMIN: Ключ №[key_id] — ПОРТАЛ ([portal_x],[portal_y],[portal_z])</span>"
		else
			. += "<span class='admin'>ADMIN: Ключ №[key_id] — ГИБ</span>"

/obj/item/key/scp004/key_1
	name = "Ржавый ключ I"
	key_id = 1

/obj/item/key/scp004/key_2
	name = "Ржавый ключ II"
	key_id = 2

/obj/item/key/scp004/key_3
	name = "Ржавый ключ III"
	key_id = 3

/obj/item/key/scp004/key_4
	name = "Ржавый ключ IV"
	key_id = 4

/obj/item/key/scp004/key_5
	name = "Ржавый ключ V"
	key_id = 5

/obj/item/key/scp004/key_6
	name = "Ржавый ключ VI"
	key_id = 6
	key_effect = SCP004_EFFECT_PORTAL
	portal_x = 219
	portal_y = 105
	portal_z = 2

/obj/item/key/scp004/key_7
	name = "Ржавый ключ VII"
	key_id = 7

/obj/item/key/scp004/key_8
	name = "Ржавый ключ VIII"
	key_id = 8

/obj/item/key/scp004/key_9
	name = "Ржавый ключ IX"
	key_id = 9

/obj/item/key/scp004/key_10
	name = "Ржавый ключ X"
	key_id = 10

/obj/item/key/scp004/key_11
	name = "Ржавый ключ XI"
	key_id = 11

/obj/item/key/scp004/key_12
	name = "Ржавый ключ XII"
	key_id = 12
	key_effect = SCP004_EFFECT_PORTAL
	portal_x = 50
	portal_y = 50
	portal_z = 5

/obj/effect/portal/scp004
	name = "портал"
	desc = "Мерцающий проход."
	icon = 'icons/SCP/scp-004.dmi'
	icon_state = "portal"
	anchored = TRUE
	mouse_opacity = 1
	density = FALSE
	layer = 10
	var/target_x = 1
	var/target_y = 1
	var/target_z = 2
	var/obj/effect/portal/scp004/linked = null
	var/last_teleport_time = 0
	var/teleport_cooldown = 5

/obj/effect/portal/scp004/Destroy()
	if(linked && !QDELETED(linked))
		var/obj/effect/portal/scp004/L = linked
		linked = null
		L.linked = null
		qdel(L)
	return ..()

/obj/effect/portal/scp004/Crossed(atom/movable/AM)
	if(!isliving(AM))
		return
	if(world.time < last_teleport_time + teleport_cooldown)
		return
	var/mob/living/L = AM
	var/turf/T = locate(target_x, target_y, target_z)
	if(!T || T == loc)
		return
	last_teleport_time = world.time
	if(linked && !QDELETED(linked))
		linked.last_teleport_time = world.time
	L.forceMove(T)
	to_chat(L, "<span class='notice'>Вы проходите сквозь проход...</span>")

/obj/effect/portal/scp004/attack_hand(mob/user)
	return

#undef SCP004_EFFECT_GIB
#undef SCP004_EFFECT_PORTAL
