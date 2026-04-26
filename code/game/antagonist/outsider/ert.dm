GLOBAL_DATUM_INIT(ert, /datum/antagonist/ert, new)

/datum/antagonist/ert
	id = MODE_ERT
	role_text = "MTF Nine-Tailed Fox - Epsilon-11 Agent"
	role_text_plural = "MTF Nine-Tailed Fox - Epsilon-11 Agents"
	welcome_text = "As Agent of the Epsilon-11 taskforce, you only answer to your leader, nobody else."
	antag_text = "You are an <b>anti</b> antagonist! Within the rules, \
		try to save the site and its inhabitants from the ongoing crisis. \
		Try to make sure other players have <i>fun</i>! If you are confused or at a loss, always adminhelp, \
		and before taking extreme actions, please try to also contact the administration! \
		Think through your actions and make the roleplay immersive! <b>Please remember all \
		rules aside from those without explicit exceptions apply to the MTF.</b>"
	leader_welcome_text = "You shouldn't see this"
	landmark_id = "Response Team"
	id_type = /obj/item/card/id/mtf

	flags = ANTAG_OVERRIDE_JOB | ANTAG_HAS_LEADER | ANTAG_CHOOSE_NAME | ANTAG_RANDOM_EXCEPTED
	antaghud_indicator = "hudloyalist"

	hard_cap = 5
	hard_cap_round = 7
	initial_spawn_req = 5
	initial_spawn_target = 7
	show_objectives_on_creation = 0
	var/reason = ""

/datum/antagonist/ert/create_default(mob/source)
	var/mob/living/carbon/human/M = ..()
	if(istype(M)) M.age = rand(25,45)

/datum/antagonist/ert/New()
	..()
	leader_welcome_text = "As leader of Mobile Task Force Epsilon-11, you answer only to the O5 Council, and have authority to override the Site staff where it is necessary to achieve your mission goals. It is recommended that you attempt to cooperate with the site staff where possible, however."

/datum/antagonist/ert/greet(datum/mind/player)
	if(!..())
		return
	to_chat(player.current, "The Mobile Task Force works for the O5 Council; your job is to contain loose SCPs and eliminate infiltrators. There is a code red alert at [station_name()], you are tasked to go and fix the problem.")
	to_chat(player.current, "You should first gear up and discuss a plan with your team. More members may be joining, don't move out before you're ready.")

/datum/antagonist/ert/equip(mob/living/carbon/human/player)
	player.add_language(LANGUAGE_ENGLISH)
	dressup_human(player, outfits_decls_by_type_[/decl/hierarchy/outfit/mtf/epsilon_11/agent], TRUE)

	// Добавляем тактические голосовые команды
	add_verb(player, /mob/proc/mtf_classd_spotted_emote)
	add_verb(player, /mob/proc/mtf_you_stop_emote)
	add_verb(player, /mob/proc/mtf_come_out_bastard_emote)
	add_verb(player, /mob/proc/mtf_target_terminated_emote)
	add_verb(player, /mob/proc/mtf_classd_terminated_emote)
	add_verb(player, /mob/proc/mtf_statue_spotted_emote)
	add_verb(player, /mob/proc/mtf_plague_doctor_spotted_emote)
	add_verb(player, /mob/proc/mtf_hey_halt_emote)
	add_verb(player, /mob/proc/mtf_come_out_die_emote)

	// Регистрируем эмоуты в системе, чтобы работали через *ключ
	for(var/emote_type in typesof(/datum/emote/mtf))
		if(emote_type == /datum/emote/mtf)
			continue
		var/datum/emote/E = GLOB.all_emotes[emote_type]
		if(E)
			player.set_emote(E.key, E)

	return 1
