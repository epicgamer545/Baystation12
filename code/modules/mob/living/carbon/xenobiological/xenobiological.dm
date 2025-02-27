/mob/living/carbon/slime
	name = "baby slime"
	icon = 'icons/mob/simple_animal/slimes.dmi'
	icon_state = "grey baby slime"
	pass_flags = PASS_FLAG_TABLE
	speak_emote = list("chirps")

	maxHealth = 150
	health = 150
	gender = NEUTER

	update_icon = 0
	nutrition = 800

	see_in_dark = 8
	update_slimes = 0

	// canstun and canweaken don't affect slimes because they ignore stun and weakened variables
	// for the sake of cleanliness, though, here they are.
	status_flags = CANPARALYSE|CANPUSH

	meat_type = null
	meat_amount = 0
	skin_material = null
	skin_amount = 0
	bone_material = null
	bone_amount = 0

	can_be_buckled = FALSE

	var/toxloss = 0
	var/is_adult = 0
	var/number = 0 // Used to understand when someone is talking to it
	var/cores = 1 // the number of /obj/item/slime_extract's the slime has left inside
	var/mutation_chance = 30 // Chance of mutating, should be between 25 and 35

	var/powerlevel = 0 // 0-10 controls how much electricity they are generating
	var/amount_grown = 0 // controls how long the slime has been overfed, if 10, grows or reproduces

	var/mob/living/Victim = null // the person the slime is currently feeding on
	var/mob/living/Target = null // AI variable - tells the slime to hunt this down
	var/mob/living/Leader = null // AI variable - tells the slime to follow this person

	var/attacked = 0 // Determines if it's been attacked recently. Can be any number, is a cooloff-ish variable
	var/rabid = 0 // If set to 1, the slime will attack and eat anything it comes in contact with
	var/holding_still = 0 // AI variable, cooloff-ish for how long it's going to stay in one place
	var/target_patience = 0 // AI variable, cooloff-ish for how long it's going to follow its target

	var/list/Friends = list() // A list of friends; they are not considered targets for feeding; passed down after splitting

	var/list/speech_buffer = list() // Last phrase said near it and person who said it

	var/mood = "" // To show its face

	var/AIproc = 0 // If it's 0, we need to launch an AI proc

	var/hurt_temperature = T0C-50 // slime keeps taking damage when its bodytemperature is below this
	var/die_temperature = 50 // slime dies instantly when its bodytemperature is below this

	var/colour = "grey"

	var/core_removal_stage = 0 //For removing cores.
	var/datum/reagents/metabolism/ingested

	traits = list(/singleton/trait/malus/water = TRAIT_LEVEL_MODERATE)

/mob/living/carbon/slime/get_ingested_reagents()
	return ingested

/mob/living/carbon/slime/getToxLoss()
	return toxloss

/mob/living/carbon/slime/get_digestion_product()
	return /datum/reagent/slimejelly

/mob/living/carbon/slime/adjustToxLoss(amount)
	toxloss = clamp(toxloss + amount, 0, maxHealth)

/mob/living/carbon/slime/setToxLoss(amount)
	adjustToxLoss(amount-getToxLoss())


/mob/living/carbon/slime/Initialize(mapload, _colour = "grey")
	ingested = new(240, src, CHEM_INGEST)
	verbs += /mob/living/proc/ventcrawl

	colour = _colour
	number = random_id(/mob/living/carbon/slime, 1, 1000)
	SetName("[colour] [is_adult ? "adult" : "baby"] slime ([number])")
	real_name = name
	mutation_chance = rand(25, 35)
	regenerate_icons()
	. = ..()


/mob/living/carbon/slime/movement_delay(singleton/move_intent/using_intent = move_intent)
	if (bodytemperature >= 330.23) // 135 F
		return -1	// slimes become supercharged at high temperatures

	var/tally = ..()

	var/health_deficiency = (maxHealth - health)
	if(health_deficiency >= 30) tally += (health_deficiency / 25)

	if (bodytemperature < 183.222)
		tally += (283.222 - bodytemperature) / 10 * 1.75

	if(reagents)
		if(reagents.has_reagent(/datum/reagent/hyperzine)) // Hyperzine slows slimes down
			tally *= 2

		if(reagents.has_reagent(/datum/reagent/frostoil)) // Frostoil also makes them move VEEERRYYYYY slow
			tally *= 5

	if(health <= 0) // if damaged, the slime moves twice as slow
		tally *= 2

	return tally

/mob/living/carbon/slime/Bump(atom/movable/AM, called)
	if ((!(called) || now_pushing))
		return
	now_pushing = 1

	if(isobj(AM) && !client && powerlevel > 0)
		var/probab = 10
		switch(powerlevel)
			if(1 to 2)	probab = 20
			if(3 to 4)	probab = 30
			if(5 to 6)	probab = 40
			if(7 to 8)	probab = 60
			if(9)		probab = 70
			if(10)		probab = 95
		if(prob(probab))
			if(istype(AM, /obj/structure/window) || istype(AM, /obj/structure/grille))
				if(nutrition <= get_hunger_nutrition())
					if (is_adult || prob(5))
						UnarmedAttack(AM)

	if(ismob(AM))
		var/mob/tmob = AM

		if(is_adult)
			if(istype(tmob, /mob/living/carbon/human))
				if(prob(90))
					now_pushing = 0
					return
		else
			if(istype(tmob, /mob/living/carbon/human))
				now_pushing = 0
				return

	now_pushing = 0

	..()

/mob/living/carbon/slime/Stat()
	. = ..()

	statpanel("Status")
	stat(null, "Health: [round((health / maxHealth) * 100)]%")
	stat(null, "Intent: [a_intent]")

	if (client.statpanel == "Status")
		stat(null, "Nutrition: [nutrition]/[get_max_nutrition()]")
		if(amount_grown >= 10)
			if(is_adult)
				stat(null, "You can reproduce!")
			else
				stat(null, "You can evolve!")

		stat(null,"Power Level: [powerlevel]")

/mob/living/carbon/slime/adjustFireLoss(amount)
	..(-abs(amount)) // Heals them
	return

/mob/living/carbon/slime/bullet_act(obj/item/projectile/Proj)
	if (status_flags & GODMODE)
		return PROJECTILE_FORCE_MISS
	attacked += 10
	..(Proj)
	return 0

/mob/living/carbon/slime/emp_act(severity)
	if (status_flags & GODMODE)
		return
	powerlevel = 0 // oh no, the power!
	..()

/mob/living/carbon/slime/ex_act(severity)
	if (status_flags & GODMODE)
		return
	..()

	var/b_loss = null
	var/f_loss = null
	switch (severity)
		if (EX_ACT_DEVASTATING)
			qdel(src)
			return

		if (EX_ACT_HEAVY)

			b_loss += 60
			f_loss += 60


		if(EX_ACT_LIGHT)
			b_loss += 30

	adjustBruteLoss(b_loss)
	adjustFireLoss(f_loss)

	updatehealth()


/mob/living/carbon/slime/u_equip(obj/item/W as obj)
	return

/mob/living/carbon/slime/attack_ui(slot)
	return

/mob/living/carbon/slime/attack_hand(mob/living/carbon/human/M as mob)

	..()

	if(Victim)
		if(Victim == M)
			if(prob(60))
				visible_message(SPAN_WARNING("\The [M] attempts to wrestle \the [src] off!"))
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)

			else
				visible_message(SPAN_WARNING("\The [M] manages to wrestle \the [src] off!"))
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

				set_confused(2)
				Feedstop()
				UpdateFace()
				step_away(src, M)
			return

		else
			if(prob(30))
				visible_message(SPAN_WARNING("\The [M] attempts to wrestle \the [src] off \the [Victim]!"))
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)

			else
				visible_message(SPAN_WARNING("\The [M] manages to wrestle \the [src] off \the [Victim]!"))
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

				set_confused(2)
				Feedstop()
				UpdateFace()
				step_away(src, M)
			return

	switch(M.a_intent)

		if (I_HELP)
			help_shake_act(M)

		if (I_DISARM)
			var/success = prob(40)
			visible_message(SPAN_WARNING("\The [M] pushes \the [src]![success ? " \The [src] looks momentarily disoriented!" : ""]"))
			if(success)
				set_confused(2)
				UpdateFace()
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
			else
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)

		else

			var/damage = rand(1, 9)

			attacked += 10
			if (prob(90))
				playsound(loc, "punch", 25, 1, -1)
				visible_message(SPAN_DANGER("[M] has punched [src]!"), \
						SPAN_DANGER("[M] has punched [src]!"))

				adjustBruteLoss(damage)
				updatehealth()
			else
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
				visible_message(SPAN_DANGER("[M] has attempted to punch [src]!"))
	return


/mob/living/carbon/slime/use_weapon(obj/item/weapon, mob/user, list/click_params)
	// Handle 'damage' (Except you can't hit a slime)
	if (weapon.force)
		user.setClickCooldown(user.get_attack_speed(weapon))
		user.do_attack_animation(src)
		user.visible_message(
			SPAN_DANGER("\The [user] swings \a [weapon] at \the [src], but it just passes through!"),
			SPAN_DANGER("You swing \the [weapon] at \the [src], but it just passes through!")
		)
		return TRUE

	return ..()


/mob/living/carbon/slime/post_use_item(obj/item/tool, mob/user, interaction_handled, use_call, click_params)
	..()

	// React to attacks
	if (use_call == "weapon")
		attacked += 10
		if (Victim && prob(tool.force * 5))
			Feedstop()
			step_away(src, user)


/mob/living/carbon/slime/restrained()
	return 0

/mob/living/carbon/slime/var/co2overloadtime = null
/mob/living/carbon/slime/var/temperature_resistance = T0C+75

/mob/living/carbon/slime/toggle_throw_mode()
	return

/mob/living/carbon/slime/has_eyes()
	return 0

/mob/living/carbon/slime/check_has_mouth()
	return 0

/mob/living/carbon/slime/proc/gain_nutrition(amount)
	adjust_nutrition(amount)
	if(prob(amount * 2)) // Gain around one level per 50 nutrition
		powerlevel++
		if(powerlevel > 10)
			powerlevel = 10
			adjustToxLoss(-10)

/mob/living/carbon/slime/adjust_nutrition(amt)
	nutrition = clamp(nutrition + amt, 0, get_max_nutrition())
