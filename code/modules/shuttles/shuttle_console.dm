/obj/machinery/computer/shuttle_control
	name = "shuttle control console"
	icon = 'icons/obj/machines/computer.dmi'
	icon_keyboard = "atmos_key"
	icon_screen = "shuttle"
	base_type = /obj/machinery/computer/shuttle_control
	machine_name = "basic shuttle console"
	machine_desc = "A simple control system for small spacecraft, allowing automated movement from one navigation point to another."

	/// Used to coordinate data in shuttle controller. Set by `sync_shuttle()`.
	var/shuttle_tag
	var/hacked = 0   // Has been emagged, no access restrictions.

	var/ui_template = "shuttle_control_console.tmpl"


/obj/machinery/computer/shuttle_control/Initialize(mapload)
	. = ..()
	if (!shuttle_tag)
		sync_shuttle()


/obj/machinery/computer/shuttle_control/on_update_icon()
	icon_screen = shuttle_tag ? initial(icon_screen) : "shuttle_error"
	..()


/// Sets `shuttle_tag` to a new value based on the computer's current area, or to `null` if the area is not a valid shuttle.
/obj/machinery/computer/shuttle_control/proc/sync_shuttle()
	shuttle_tag = null
	var/area/current_area = get_area(src)
	for (var/shuttle_name in SSshuttle.shuttles)
		var/datum/shuttle/shuttle = SSshuttle.shuttles[shuttle_name]
		if (!(current_area in shuttle.shuttle_area))
			continue
		if (!is_valid_shuttle(SSshuttle.shuttles[shuttle_name]))
			break
		shuttle_tag = shuttle_name
		break


/// Determines whether the given shuttle datum is valid for this computer.
/obj/machinery/computer/shuttle_control/proc/is_valid_shuttle(datum/shuttle/shuttle)
	return !istype(shuttle, /datum/shuttle/autodock/overmap)


/obj/machinery/computer/shuttle_control/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/obj/machinery/computer/shuttle_control/proc/get_ui_data(datum/shuttle/autodock/shuttle)
	var/shuttle_state
	switch(shuttle.moving_status)
		if(SHUTTLE_IDLE) shuttle_state = "idle"
		if(SHUTTLE_WARMUP) shuttle_state = "warmup"
		if(SHUTTLE_INTRANSIT) shuttle_state = "in_transit"

	var/shuttle_status
	switch (shuttle.process_state)
		if(IDLE_STATE)
			var/cannot_depart = shuttle.current_location.cannot_depart(shuttle)
			if (shuttle.in_use)
				shuttle_status = "Busy."
			else if(cannot_depart)
				shuttle_status = cannot_depart
			else
				shuttle_status = "Standing-by at \the [shuttle.get_location_name()]."

		if(WAIT_LAUNCH, FORCE_LAUNCH)
			shuttle_status = "Shuttle has received command and will depart shortly."
		if(WAIT_ARRIVE)
			shuttle_status = "Proceeding to \the [shuttle.get_destination_name()]."
		if(WAIT_FINISH)
			shuttle_status = "Arriving at destination now."

	return list(
		"shuttle_status" = shuttle_status,
		"shuttle_state" = shuttle_state,
		"has_docking" = shuttle.shuttle_docking_controller? 1 : 0,
		"docking_status" = shuttle.shuttle_docking_controller? shuttle.shuttle_docking_controller.get_docking_status() : null,
		"docking_override" = shuttle.shuttle_docking_controller? shuttle.shuttle_docking_controller.override_enabled : null,
		"can_launch" = shuttle.can_launch(),
		"can_cancel" = shuttle.can_cancel(),
		"can_force" = shuttle.can_force(),
		"timeleft" = max(round((shuttle.arrive_time - world.time) / 10, 1), 0),
		"docking_codes" = shuttle.docking_codes
	)

// This is a subset of the actual checks; contains those that give messages to the user.
/obj/machinery/computer/shuttle_control/proc/can_move(datum/shuttle/autodock/shuttle, user)
	var/cannot_depart = shuttle.current_location.cannot_depart(shuttle)
	if(cannot_depart)
		to_chat(user, SPAN_WARNING(cannot_depart))
		return FALSE
	if(!shuttle.next_location.is_valid(shuttle))
		to_chat(user, SPAN_WARNING("Destination zone is invalid or obstructed."))
		return FALSE
	return TRUE

/obj/machinery/computer/shuttle_control/proc/handle_topic_href(datum/shuttle/autodock/shuttle, list/href_list, user)
	if(!istype(shuttle))
		return TOPIC_NOACTION

	if(href_list["move"])
		if(can_move(shuttle, user))
			shuttle.launch(src)
			return TOPIC_REFRESH
		return TOPIC_HANDLED

	if(href_list["force"])
		if(can_move(shuttle, user))
			shuttle.force_launch(src)
			return TOPIC_REFRESH
		return TOPIC_HANDLED

	if(href_list["cancel"])
		shuttle.cancel_launch(src)
		return TOPIC_REFRESH

	if(href_list["set_codes"])
		var/newcode = input("Input new docking codes", "Docking codes", shuttle.docking_codes) as text|null
		if (newcode && CanInteract(usr, GLOB.default_state))
			shuttle.set_docking_codes(uppertext(newcode))
		return TOPIC_REFRESH

/obj/machinery/computer/shuttle_control/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	var/datum/shuttle/autodock/shuttle = SSshuttle.shuttles[shuttle_tag]
	if (!istype(shuttle))
		to_chat(user,SPAN_WARNING("Unable to establish link with the shuttle."))
		return

	var/list/data = get_ui_data(shuttle)

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, ui_template, "[shuttle_tag] Shuttle Control", 470, 450)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/computer/shuttle_control/OnTopic(user, href_list)
	return handle_topic_href(SSshuttle.shuttles[shuttle_tag], href_list, user)

/obj/machinery/computer/shuttle_control/emag_act(remaining_charges, mob/user)
	if (!hacked)
		req_access = list()
		hacked = 1
		to_chat(user, "You short out the console's ID checking system. It's now available to everyone!")
		return 1

/obj/machinery/computer/shuttle_control/bullet_act(obj/item/projectile/Proj)
	visible_message("\The [Proj] ricochets off \the [src]!")

/obj/machinery/computer/shuttle_control/ex_act()
	return

/obj/machinery/computer/shuttle_control/emp_act()
	SHOULD_CALL_PARENT(FALSE)
	return
