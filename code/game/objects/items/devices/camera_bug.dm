#define VANILLA_BUG		0
#define UNIVERSAL_BUG	1
#define NETWORK_BUG		2
#define SABOTAGE_BUG	3
#define ADVANCED_BUG	4
#define AI_BUG			5
#define ADMIN_BUG		6
/*
	Bugtypes:
	Vanilla: Attack cameras to bug them, see only your own bugs
	Universal: Attack cameras to bug them, see all bugs
	Network: See all cameras on network
	Sabotage: Attack cameras to bug them, see only your own bugs, EMP button for bugged cameras
	Advanced: Attack cameras to bug them, see only your own bugs, monitor bugged cameras
	AI: See all cameras on network, monitor bugged cameras
	Admin: See all cameras on network, monitor bugged cameras,
*/


#define BUGMODE_LIST	0
#define BUGMODE_MONITOR	1
#define BUGMODE_TRACK	2



/obj/item/device/camera_bug
	name = "camera bug"
	desc = "For illicit snooping through the camera network."
	icon = 'icons/obj/device.dmi'
	icon_state	= "camera_bug"
	w_class		= 1.0
	item_state	= "camera_bug"
	throw_speed	= 4
	throw_range	= 20
	action_button_name = "check camera bug"

	var/obj/machinery/camera/current = null
	var/obj/item/expansion = null
	var/bugtype = VANILLA_BUG

	var/last_net_update = 0
	var/last_bugtype = VANILLA_BUG
	var/list/bugged_cameras = list()
	var/skip_bugcheck = 0

	var/track_mode = BUGMODE_LIST
	var/last_tracked = 0
	var/refresh_interval = 50

	var/tracked_name = null
	var/atom/tracking = null

	var/last_found = null
	var/last_seen = null

	var/emagged = 0

/obj/item/device/camera_bug/ai
	name = "Supplemental Camera Interface"
	skip_bugcheck = 1
	bugtype = AI_BUG
	verb/show_interface()
		set category="AI Commands"
		set name="Show Camera Monitor"
		interact(usr)
/obj/item/device/camera_bug/pai
	name = "Supplemental Camera Interface"
	skip_bugcheck = 1
	bugtype = AI_BUG
	proc/show_interface()
		set category="pAI Commands"
		set name="Show Camera Monitor"
		interact(usr)

/obj/item/device/camera_bug/New()
	..()
	processing_objects += src

/obj/item/device/camera_bug/Destroy()
	if(expansion)
		qdel(expansion)
		expansion = null
	del(src)
/* Easier to just call del() than this nonsense
	get_cameras()
	for(var/cam_tag in bugged_cameras)
		var/obj/machinery/camera/camera = bugged_cameras[cam_tag]
		if(camera.bug == src)
			camera.bug = null
	bugged_cameras = list()
	if(tracking)
		tracking = null
	..()
*/

/obj/item/device/camera_bug/interact(var/mob/user = usr)
	var/datum/browser/popup = new(user, "camerabug","Camera Bug",550,500,src)
	popup.set_content(menu(get_cameras()))
	popup.open()

/obj/item/device/camera_bug/attack_self(mob/user as mob)
	user.set_machine(src)
	interact(user)

/obj/item/device/camera_bug/check_eye(var/mob/user as mob)
	if(issilicon(user)) return 1
	if (user.stat || loc != user || !user.canmove || user.blinded || !current)
		user.reset_view(null)
		user.unset_machine()
		return null

	var/turf/T = get_turf(user.loc)
	if(T.z != current.z || (!skip_bugcheck && current.bug != src) || !current.can_use())
		user << "\red [src] has lost the signal."
		current = null
		user.reset_view(null)
		user.unset_machine()
		return null

	return 1

/obj/item/device/camera_bug/proc/get_cameras()
	if(bugtype != last_bugtype || ( (bugtype in list(UNIVERSAL_BUG,NETWORK_BUG,AI_BUG,ADMIN_BUG)) && world.time > (last_net_update + 100)))
		bugged_cameras = list()
		last_bugtype = bugtype
		for(var/obj/machinery/camera/camera in cameranet.cameras)
			if(camera.stat || !camera.can_use())
				continue
			switch(bugtype)
				if(VANILLA_BUG,SABOTAGE_BUG,ADVANCED_BUG)
					if(camera.bug == src)
						bugged_cameras[camera.c_tag] = camera
				if(UNIVERSAL_BUG)
					if(camera.bug)
						bugged_cameras[camera.c_tag] = camera
				if(NETWORK_BUG,AI_BUG,ADMIN_BUG)
					if(length(list("SS13","MINE")&camera.network))
						bugged_cameras[camera.c_tag] = camera
	bugged_cameras = sortAssoc(bugged_cameras)
	return bugged_cameras


/obj/item/device/camera_bug/proc/menu(var/list/cameras)
	if(!cameras || !cameras.len)
		return "No bugged cameras found."

	var/html
	switch(track_mode)
		if(BUGMODE_LIST)
			html = "<h3>Select a camera:</h3> <a href='?src=\ref[src];view'>\[Cancel camera view\]</a><hr><table>"
			for(var/entry in cameras)
				var/obj/machinery/camera/C = cameras[entry]
				var/functions = ""
				switch(bugtype)
					if(VANILLA_BUG,UNIVERSAL_BUG) // not network bug
						functions = " - <a href='?src=\ref[src];light=\ref[C]'>\[[C.luminosity?"Deactivate":"Activate"] Light\]</a>"
					if(SABOTAGE_BUG)
						functions = " - <a href='?src=\ref[src];emp=\ref[C]'>\[Disable\]</a> <a href='?src=\ref[src];light=\ref[C]'>\[[C.luminosity?"Deactivate":"Activate"] Light\]</a>"
					//if(ADVANCED_BUG)
					//	functions = " - <a href='?src=\ref[src];monitor=\ref[C]'>\[Monitor\]</a>"
					if(ADVANCED_BUG,AI_BUG)
						functions = " - <a href='?src=\ref[src];monitor=\ref[C]'>\[Monitor\]</a> <a href='?src=\ref[src];light=\ref[C]'>\[[C.luminosity?"Deactivate":"Activate"] Light\]</a>"
					if(ADMIN_BUG)
						if(C.bug == src)
							functions = " - <a href='?src=\ref[src];monitor=\ref[C]'>\[Monitor\]</a>  <a href='?src=\ref[src];light=\ref[C]'>\[[C.luminosity?"Deactivate":"Activate"] Light\]</a> <a href='?src=\ref[src];emp=\ref[C]'>\[Disable\]</a>"
						else
							functions = " - <a href='?src=\ref[src];monitor=\ref[C]'>\[Monitor\]</a>  <a href='?src=\ref[src];light=\ref[C]'>\[[C.luminosity?"Deactivate":"Activate"] Light\]</a>"
				html += "<tr><td><a href='?src=\ref[src];view=\ref[C]'>[entry]</a></td><td>[functions]</td></tr>"

		if(BUGMODE_MONITOR)
			if(current)
				html = "Analyzing Camera '[current.c_tag]' <a href='?\ref[src];mode=0'>\[Select Camera\]</a><br>"
				html += camera_report()
			else
				track_mode = BUGMODE_LIST
				return .(cameras)
		if(BUGMODE_TRACK)
			if(tracking)
				html = "Tracking '[tracked_name]'  <a href='?\ref[src];mode=0'>\[Cancel Tracking\]</a>  <a href='?src=\ref[src];view'>\[Cancel camera view\]</a><br>"
				if(last_found)
					var/time_diff = round((world.time - last_seen) / 150)
					var/obj/machinery/camera/C = bugged_cameras[last_found]
					var/outstring
					if(C)
						outstring = "<a href='?\ref[src];view=\ref[C]'>[last_found]</a>"
					else
						outstring = last_found
					if(!time_diff)
						html += "Last seen near [outstring] (now)<br>"
					else
						// 15 second intervals ~ 1/4 minute
						var/m = round(time_diff/4)
						var/s = (time_diff - 4*m) * 15
						if(!s) s = "00"
						html += "Last seen near [outstring] ([m]:[s] minute\s ago)<br>"
				else
					html += "Not yet seen.<br>"
				if(bugtype == AI_BUG || bugtype == ADMIN_BUG)
					var/mob/living/carbon/human/H = tracking
					var/level = 0
					if(istype(H))
						html += "<br>Suit sensor data:<br>"
						var/obj/item/clothing/under/U = H.w_uniform
						if(istype(U) && U.has_sensor)
							level = U.sensor_mode
						html += health_report(H,level) // In case the above doesn't happen, it's basically "Unavailable"
			else
				track_mode = BUGMODE_LIST
				return .(cameras)
	return html

/obj/item/device/camera_bug/proc/camera_report()
	// this should only be called if current exists
	var/dat = ""

	if(current && current.can_use())
		dat += "Light is <a href='?\ref[src];light=\ref[current]'>[current.luminosity?"on":"off"]</a><hr>"
		var/list/seen = current.can_see()
		var/list/names = list()
		var/empty = 1
		for(var/obj/machinery/singularity/S in seen) // god help you if you see more than one
			if(S.name in names)
				names[S.name]++
				dat += "[S.name] ([names[S.name]])"
			else
				names[S.name] = 1
				dat += "[S.name]"
			var/stage = round(S.current_size / 2)+1
			dat += " (Stage [stage])"
			dat += " <a href='?\ref[src];track=\ref[S]'>\[Track\]</a><br>"
			empty = 0

		for(var/obj/mecha/M in seen)
			if(M.name in names)
				names[M.name]++
				dat += "[M.name] ([names[M.name]])"
			else
				names[M.name] = 1
				dat += "[M.name]"
			dat += " <a href='?\ref[src];track=\ref[M]'>\[Track\]</a><br>"
			empty = 0

		for(var/mob/living/M in seen)
			if(!prob(M.alpha)) continue
			if(M.digitalcamo) continue
			if(M.name in names)
				names[M.name]++
				dat += "[M.name] ([names[M.name]])"
			else
				names[M.name] = 1
				dat += "[M.name]"
			if(M.buckled && !M.lying)
				dat += " (Sitting)"
			if(M.lying)
				dat += " (Laying down)"
			dat += " <a href='?\ref[src];track=\ref[M]'>\[Track\]</a><br>"
			empty = 0
		if(empty)
			dat += "No motion detected."
		return dat
	else
		return "Camera Offline<br>"

/obj/item/device/camera_bug/proc/health_report(var/mob/living/M, var/sensor_mode)
	if(sensor_mode < 1)
		return "Unavailable"
	var/turf/pos = get_turf(M)
	if(pos.z != 1)
		return "Unavailable"

	var/life_status = "[M.stat > 1 ? "<span class='bad'>Deceased</span>" : "<span class='good'>Living</span>"]"

	var/damage_report
	if(sensor_mode > 1)
		var/dam1 = round(M.getOxyLoss(),1)
		var/dam2 = round(M.getToxLoss(),1)
		var/dam3 = round(M.getFireLoss(),1)
		var/dam4 = round(M.getBruteLoss(),1)
		damage_report = "(<font color='teal'>[dam1]</font>/<font color='green'>[dam2]</font>/<font color='orange'>[dam3]</font>/<font color='red'>[dam4]</font>)"

	switch(sensor_mode)
		if(1)
			return life_status
		if(2)
			return "[life_status] [damage_report]"
		if(3)
			var/area/player_area = get_area(M)
			return "[life_status] [damage_report]<br>[format_text(player_area.name)] ([pos.x], [pos.y])"

/obj/item/device/camera_bug/Topic(var/href,var/list/href_list)
	if(usr != loc)
		usr.unset_machine()
		usr.reset_view(null)
		usr << browse(null, "window=camerabug")
		return
	usr.set_machine(src)
	if("mode" in href_list)
		track_mode = text2num(href_list["mode"])
	if("monitor" in href_list)
		var/obj/machinery/camera/C = locate(href_list["monitor"])
		if(C)
			track_mode = BUGMODE_MONITOR
			current = C
			if(!isAI(usr))
				usr.reset_view(null)
			interact()
	if("track" in href_list)
		var/atom/A = locate(href_list["track"])
		if(A)
			tracking = A
			tracked_name = A.name
			last_found = current.c_tag
			last_seen = world.time
			track_mode = BUGMODE_TRACK
	if("emp" in href_list)
		var/obj/machinery/camera/C = locate(href_list["emp"])
		if(istype(C) && C.bug == src)
			C.emp_act(1)
			C.bug = null
			bugged_cameras -= C.c_tag
		interact()
		return
	if("close" in href_list)
		if(!isAI(usr))
			usr.reset_view(null)
		usr.unset_machine()
		current = null
		return // I do not <- I do not remember what I was going to write in this comment -Sayu, sometime later
	if("view" in href_list)
		var/obj/machinery/camera/C = locate(href_list["view"])
		if(istype(C))
			if(!C.can_use())
				usr << "\red Something's wrong with that camera.  You can't get a feed."
				return
			var/turf/T = get_turf(loc)
			if(!T || C.z != T.z)
				usr << "\red You can't get a signal."
				return
			current = C
			spawn(6)
				if(src.check_eye(usr))
					usr.reset_view(C)
					interact()
				else
					usr.unset_machine()
					if(!isAI(usr))
						usr.reset_view(null)
					usr << browse(null, "window=camerabug")
			return
		else
			usr.unset_machine()
			if(!isAI(usr))
				usr.reset_view(null)
	if("light" in href_list)
		var/obj/machinery/camera/C = locate(href_list["light"])
		if(istype(C) && C.can_use())
			C.toggle_light()

	interact()

/obj/item/device/camera_bug/process()
	if(track_mode == BUGMODE_LIST || (world.time < (last_tracked + refresh_interval)))
		return
	last_tracked = world.time
	if(track_mode == BUGMODE_TRACK ) // search for user
		// Note that it will be tricked if your name appears to change.
		// This is not optimal but it is better than tracking you relentlessly despite everything.
		if(!tracking)
			src.updateSelfDialog()
			return
		if(!prob(tracking.alpha))
			src.updateSelfDialog()
			return

		if(tracking.name != tracked_name) // Hiding their identity, tricksy
			var/mob/M = tracking
			if(istype(M))
				if(M.digitalcamo)
					src.updateSelfDialog()
					return
				if(!(tracked_name == "Unknown" && findtext(tracking.name,"Unknown"))) // we saw then disguised before
					if(!(tracked_name == M.real_name && findtext(tracking.name,M.real_name))) // or they're still ID'd
						src.updateSelfDialog()//But if it's neither of those cases
						return // you won't find em on the cameras
			else
				src.updateSelfDialog()
				return

		var/list/tracking_cams = list()
		var/list/b_cams = get_cameras()
		for(var/entry in b_cams)
			tracking_cams += b_cams[entry]
		var/list/target_region = view(tracking)

		for(var/obj/machinery/camera/C in (target_region & tracking_cams))
			if(!can_see(C,tracking)) // target may have xray, that doesn't make them visible to cameras
				continue
			if(C.can_use())
				last_found = C.c_tag
				last_seen = world.time
				break
	src.updateSelfDialog()

/obj/item/device/camera_bug/attackby(var/obj/item/W as obj,var/mob/living/user as mob)
	if(istype(W,/obj/item/weapon/screwdriver) && expansion)
		expansion.loc = get_turf(loc)
		user << "You unscrew [expansion]."
		user.put_in_inactive_hand(expansion)
		expansion = null
		bugtype = VANILLA_BUG
		skip_bugcheck = 0
		track_mode = BUGMODE_LIST
		tracking = null
		return

	if(expansion || !W)
		user << "There is already \an [expansion] in [src]."
		return ..(W,user)

	// I am not sure that this list is or should be final
	// really I do not know what to do here.
	var/static/list/expandables = list(
		/obj/item/weapon/research = ADMIN_BUG, // could have been anything spawn-only

		// these are all so hackish I am sorry

		/obj/item/device/analyzer = UNIVERSAL_BUG,
		/obj/item/weapon/stock_parts/subspace/analyzer = UNIVERSAL_BUG,

		/obj/item/device/assembly/igniter = SABOTAGE_BUG,
		/obj/item/device/assembly/infra = SABOTAGE_BUG, // ir blaster to disable camera
		/obj/item/weapon/stock_parts/subspace/amplifier = SABOTAGE_BUG,

		/obj/item/device/radio = NETWORK_BUG,
		/obj/item/device/assembly/signaler = NETWORK_BUG,
		/obj/item/weapon/stock_parts/subspace/transmitter = NETWORK_BUG,

		/obj/item/device/detective_scanner = ADVANCED_BUG,
		/obj/item/weapon/stock_parts/scanning_module = ADVANCED_BUG
		)

	for(var/entry in expandables)
		if(istype(W,entry))
			if(bugtype > VANILLA_BUG)
				user << "You cannot modify [src]."
				return
			bugtype = expandables[entry]
			user.drop_item()
			W.loc = src
			expansion = W
			user << "You add [W] to [src]."
			get_cameras() // the tracking code will want to know the new camera list
			if(bugtype in list(UNIVERSAL_BUG,NETWORK_BUG,AI_BUG,ADMIN_BUG))
				skip_bugcheck = 1
			return

	user << "[W] won't fit in [src]."
	..()

#undef VANILLA_BUG
#undef UNIVERSAL_BUG
#undef NETWORK_BUG
#undef SABOTAGE_BUG
#undef ADVANCED_BUG
#undef AI_BUG
#undef ADMIN_BUG

#undef BUGMODE_LIST
#undef BUGMODE_MONITOR
#undef BUGMODE_TRACK