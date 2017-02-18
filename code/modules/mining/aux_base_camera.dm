//Aux base construction console
/mob/camera/aiEye/remote/base_construction
	name = "construction holo-drone"
	move_on_shuttle = 1 //Allows any curious crew to watch the base after it leaves. (This is safe as the base cannot be modified once it leaves)
	icon = 'icons/obj/mining.dmi'
	icon_state = "construction_drone"
	var/area/starting_area

mob/camera/aiEye/remote/base_construction/New(loc)
	starting_area = get_area(loc)
	..()

/mob/camera/aiEye/remote/base_construction/setLoc(var/t)
	var/area/curr_area = get_area(t)
	if(curr_area == starting_area || istype(curr_area, /area/shuttle/auxillary_base))
		return ..()
	//While players are only allowed to build in the base area, but consoles starting outside the base can move into the base area to begin work.

/mob/camera/aiEye/remote/base_construction/relaymove(mob/user, direct)
	dir = direct //This camera eye is visible as a drone, and needs to keep the dir updated
	..()

/obj/item/weapon/rcd/internal //Base console's internal RCD. Roundstart consoles are filled, rebuilt cosoles start empty.
	name = "internal RCD"
	max_matter = 600 //Bigger container and faster speeds due to being specialized and stationary.
	no_ammo_message = "<span class='warning'>Internal matter exhausted. Please add additional materials.</span>"
	walldelay = 10
	grilledelay = 5
	windowdelay = 5
	airlockdelay = 20
	decongirderdelay = 10
	deconwalldelay = 20
	deconfloordelay = 30
	deconwindowdelay = 20
	deconairlockdelay = 20

/obj/machinery/computer/camera_advanced/base_construction
	name = "base contruction console"
	desc = "An industrial computer integrated with a camera-assisted rapid construction device."
	networks = list("SS13")
	var/obj/item/weapon/rcd/internal/RCD //Internal RCD. The computer passes user commands to this in order to avoid massive copypaste.
	circuit = /obj/item/weapon/circuitboard/computer/base_construction
	off_action = new/datum/action/innate/camera_off/base_construction
	var/datum/action/innate/aux_base/switch_mode/switch_mode_action = new //Action for switching the RCD's build modes
	var/datum/action/innate/aux_base/build/build_action = new //Action for using the RCD
	var/datum/action/innate/aux_base/airlock_type/airlock_mode_action = new //Action for setting the airlock type
	var/datum/action/innate/aux_base/window_type/window_action = new //Action for setting the window type
	var/datum/action/innate/aux_base/place_fan/fan_action = new //Action for spawning fans
	var/fans_remaining = 0 //Number of fans in stock.
	var/datum/action/innate/aux_base/install_turret/turret_action = new //Action for spawning turrets
	var/turret_stock = 0 //Turrets in stock
	var/obj/machinery/computer/shuttle/auxillary_base/found_aux_console //Tracker for the Aux base console, so the eye can always find it.

	icon_screen = "mining"
	icon_keyboard = "rd_key"

/obj/machinery/computer/camera_advanced/base_construction/New()
	..()
	RCD = new /obj/item/weapon/rcd/internal(src)

/obj/machinery/computer/camera_advanced/base_construction/Initialize(mapload)
	..()
	if(mapload) //Map spawned consoles have a filled RCD and stocked special structures
		RCD.matter = RCD.max_matter
		fans_remaining = 4
		turret_stock = 4

/obj/machinery/computer/camera_advanced/base_construction/CreateEye()

	var/spawn_spot
	if(!found_aux_console)
		found_aux_console = locate(/obj/machinery/computer/shuttle/auxillary_base) in machines

		if(found_aux_console)
			spawn_spot = found_aux_console
	else
		spawn_spot = src


	eyeobj = new /mob/camera/aiEye/remote/base_construction(get_turf(spawn_spot))
	eyeobj.origin = src


/obj/machinery/computer/camera_advanced/base_construction/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/weapon/rcd_ammo) || istype(W, /obj/item/stack/sheet))
		RCD.attackby(W, user, params) //If trying to feed the console more materials, pass it along to the RCD.
	else
		return ..()

/obj/machinery/computer/camera_advanced/base_construction/GrantActions(mob/living/user)
	off_action.target = user
	off_action.Grant(user)
	switch_mode_action.target = src
	switch_mode_action.Grant(user)
	build_action.target = src
	build_action.Grant(user)
	airlock_mode_action.target = src
	airlock_mode_action.Grant(user)
	window_action.target = src
	window_action.Grant(user)
	fan_action.target = src
	fan_action.Grant(user)
	turret_action.target = src
	turret_action.Grant(user)
	eyeobj.invisibility = 0 //When the eye is in use, make it visible to players so they know when someone is building.


/datum/action/innate/aux_base //Parent aux base action
	var/mob/living/C //Mob using the action
	var/mob/camera/aiEye/remote/base_construction/remote_eye //Console's eye mob
	var/obj/machinery/computer/camera_advanced/base_construction/B //Console itself

/datum/action/innate/aux_base/Activate()
	if(!target)
		return TRUE
	C = owner
	remote_eye = C.remote_control
	B = target
	if(!B.RCD) //The console must always have an RCD.
		B.RCD = new /obj/item/weapon/rcd/internal(src) //If the RCD is lost somehow, make a new (empty) one!

/datum/action/innate/aux_base/proc/check_spot()
//Check a loction to see if it is inside the aux base at the station. Camera visbility checks omitted so as to not hinder construction.
	var/turf/build_target = get_turf(remote_eye)
	var/area/build_area = get_area(build_target)

	if(!istype(build_area, /area/shuttle/auxillary_base))
		owner << "<span class='warning'>You can only build within the mining base!</span>"
		return FALSE


	if(build_target.z != ZLEVEL_STATION)
		owner << "<span class='warning'>The mining base has launched and can no longer be modified.</span>"
		return FALSE

	return TRUE

/datum/action/innate/camera_off/base_construction
	name = "Log out"

/datum/action/innate/camera_off/base_construction/Activate()
	if(!owner || !owner.remote_control)
		return

	var/mob/camera/aiEye/remote/base_construction/remote_eye =owner.remote_control

	var/obj/machinery/computer/camera_advanced/base_construction/origin = remote_eye.origin
	origin.switch_mode_action.Remove(target)
	origin.build_action.Remove(target)
	origin.airlock_mode_action.Remove(target)
	origin.window_action.Remove(target)
	origin.fan_action.Remove(target)
	origin.turret_action.Remove(target)
	remote_eye.invisibility = INVISIBILITY_MAXIMUM //Hide the eye when not in use.

	..()

//*******************FUNCTIONS*******************

/datum/action/innate/aux_base/build
	name = "Build"
	button_icon_state = "build"

/datum/action/innate/aux_base/build/Activate()
	if(..())
		return

	if(!check_spot())
		return


	var/atom/movable/rcd_target
	var/turf/target_turf = get_turf(remote_eye)

	//Find airlocks
	rcd_target = locate(/obj/machinery/door/airlock) in target_turf

	if(!rcd_target)
		rcd_target = locate (/obj/structure) in target_turf

	if(!rcd_target || !rcd_target.anchored)
		rcd_target = target_turf

	owner.changeNext_move(CLICK_CD_RANGE)
	B.RCD.afterattack(rcd_target, owner, TRUE) //Activate the RCD and force it to work remotely!
	playsound(target_turf, 'sound/items/Deconstruct.ogg', 60, 1)

/datum/action/innate/aux_base/switch_mode
	name = "Switch Mode"
	button_icon_state = "builder_mode"

/datum/action/innate/aux_base/switch_mode/Activate()
	if(..())
		return

	var/list/buildlist = list("Walls and Floors" = 1,"Airlocks" = 2,"Deconstruction" = 3,"Windows and Grilles" = 4)
	var/buildmode = input("Set construction mode.", "Base Console", null) in buildlist
	B.RCD.mode = buildlist[buildmode]
	owner << "Build mode is now [buildmode]."

/datum/action/innate/aux_base/airlock_type
	name = "Select Airlock Type"
	button_icon_state = "airlock_select"

datum/action/innate/aux_base/airlock_type/Activate()
	if(..())
		return

	B.RCD.change_airlock_setting()


datum/action/innate/aux_base/window_type
	name = "Select Window Type"
	button_icon_state = "window_select"

datum/action/innate/aux_base/window_type/Activate()
	if(..())
		return
	B.RCD.toggle_window_type()

datum/action/innate/aux_base/place_fan
	name = "Place Tiny Fan"
	button_icon_state = "build_fan"

datum/action/innate/aux_base/place_fan/Activate()
	if(..())
		return

	var/turf/fan_turf = get_turf(remote_eye)

	if(!B.fans_remaining)
		owner << "<span class='warning'>[B] is out of fans!</span>"
		return

	if(!check_spot())
		return

	if(fan_turf.density)
		owner << "<span class='warning'>Fans may only be placed on a floor.</span>"
		return

	new /obj/structure/fans/tiny(fan_turf)
	B.fans_remaining--
	owner << "<span class='notice'>Tiny fan placed. [B.fans_remaining] remaining.</span>"
	playsound(fan_turf, 'sound/machines/click.ogg', 50, 1)

datum/action/innate/aux_base/install_turret
	name = "Install Plasma Anti-Wildlife Turret"
	button_icon_state = "build_turret"

datum/action/innate/aux_base/install_turret/Activate()
	if(..())
		return

	if(!check_spot())
		return

	if(!B.turret_stock)
		owner << "<span class='warning'>Unable to construct additional turrets.</span>"
		return

	var/turf/turret_turf = get_turf(remote_eye)

	if(is_blocked_turf(turret_turf))
		owner << "<span class='warning'>Location is obtructed by something. Please clear the location and try again.</span>"
		return

	new /obj/machinery/porta_turret/aux_base(turret_turf)
	B.turret_stock--
	owner << "<span class='notice'>Turret installation complete!</span>"
	playsound(turret_turf, 'sound/items/drill_use.ogg', 65, 1)