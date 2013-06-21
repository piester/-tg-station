

/obj/item/clothing/under/actorsuit
	name = "actor's jumpsuit"
	desc = "Used to adjust your appearance while on the holodeck."
	icon_state = "black"
	item_state = "bl_suit"
	color = "black"

	var/list/jumpsuit_choices = list("None")
	var/obj/item/clothing/under/jumpsuit = null
	var/list/suit_choices = list("None")
	var/obj/item/clothing/suit/suit = null
	var/list/hat_choices = list("None")
	var/obj/item/clothing/head/hat = null
	var/list/glove_choices = list("None")
	var/obj/item/clothing/gloves/glove = null
	var/list/shoe_choices = list("None")
	var/obj/item/clothing/shoes/shoe = null
	var/list/mask_choices = list("None")
	var/obj/item/clothing/mask/mask = null
	var/list/eye_choices = list("None")
	var/obj/item/clothing/glasses/eye = null

	var/global/list/forbidden = list(/obj/item/clothing/under/actorsuit, /obj/item/clothing/under/chameleon,/obj/item/clothing/under/chameleon/all,
		/obj/item/clothing/mask/facehugger, /obj/item/clothing/mask/horsehead, /obj/item/clothing/suit/space/space_ninja, /obj/item/clothing/gloves/space_ninja,
		/obj/item/clothing/head/helmet/space/space_ninja,/obj/item/clothing/mask/gas/voice/space_ninja)

	New()
		..()
		for(var/U in typesof(/obj/item/clothing/under) - forbidden)
			var/obj/item/clothing/C = new U
			jumpsuit_choices += C
		for(var/U in typesof(/obj/item/clothing/suit) - forbidden)
			var/obj/item/clothing/C = new U
			suit_choices += C
		for(var/U in typesof(/obj/item/clothing/head) - forbidden)
			var/obj/item/clothing/C = new U
			hat_choices += C
		for(var/U in typesof(/obj/item/clothing/gloves) - forbidden)
			var/obj/item/clothing/C = new U
			glove_choices += C
		for(var/U in typesof(/obj/item/clothing/shoes) - forbidden)
			var/obj/item/clothing/C = new U
			shoe_choices += C
		for(var/U in typesof(/obj/item/clothing/mask) - forbidden)
			var/obj/item/clothing/C = new U
			mask_choices += C
		for(var/U in typesof(/obj/item/clothing/glasses) - forbidden)
			var/obj/item/clothing/C = new U
			eye_choices += C
		processing_objects.Add(src)
		return

	emp_act(severity)
		for(var/obj/item/clothing/C in list(suit,hat,glove,shoe,mask,eye))
			derez(C)
		jumpsuit = null
		colorchange()
	Del()
		for(var/obj/item/clothing/C in list(suit,hat,glove,shoe,mask,eye))
			derez(C)
		..()


	proc/derez(var/obj/item/clothing/C)
		if(!C) return
		var/mob/M = C.loc
		if(istype(M))
			M.u_equip(C)
			M.update_icons()	//so their overlays update
		del C

	verb/clothing_interface()
		set name = "Holographic Clothing Interface"
		set category = "Object"
		set src in usr
		if(!istype(get_area(loc),/area/holodeck))
			usr << "The advanced functions of this jumpsuit only work on the holodeck!"
			return
		interact()

	process()
		var/mob/living/carbon/human/H = loc
		if(!istype(H) || src != H.w_uniform || !istype(get_area(loc),/area/holodeck))
			var/changes = 0
			for(var/obj/item/clothing/C in list(suit,hat,glove,shoe,mask,eye))
				derez(C)
				changes++
			if(jumpsuit)
				jumpsuit = null
				colorchange()
				changes++
			if(changes)
				visible_message("The holographic clothes fade away!")
		else
			for(var/obj/item/clothing/C in list(suit,hat,glove,shoe,mask,eye))
				if(!istype(get_area(C),/area/holodeck))
					C.visible_message("[C] fades away!")
					derez(C)

	proc/colorchange()
		var/mob/living/carbon/human/H = loc
		if(jumpsuit)
			desc = jumpsuit.desc
			name = jumpsuit.name
			icon_state = jumpsuit.icon_state
			item_state = jumpsuit.item_state
			color = jumpsuit.color
			if(istype(H))
				H.update_inv_w_uniform()	//so our overlays update.
		else
			desc = initial(desc)
			name = initial(name)
			icon_state = initial(icon_state)
			item_state = initial(item_state)
			color = initial(color)
			if(istype(H))
				H.update_inv_w_uniform()	//so our overlays update.

	interact()
		var/mob/living/carbon/human/H = usr
		if(usr != loc || !istype(H) || src != H.w_uniform) return
		if(!istype(get_area(loc),/area/holodeck))
			usr << browse(null,"window=clothing_actor")
			return
		var/dat = {"
			<a href='?src=\ref[src];select=jumpsuit'>Suit appearance</a>: [jumpsuit?"[jumpsuit]":"normal"]<BR>
			<a href='?src=\ref[src];select=suit'>Armor</a>: [suit?"[suit]":"none"]<BR>
			<a href='?src=\ref[src];select=glove'>Gloves</a>: [glove?"[glove]":"none"]<BR>
			<a href='?src=\ref[src];select=shoe'>Shoes</a>: [shoe?"[shoe]":"none"]<BR>
			<a href='?src=\ref[src];select=hat'>Hat</a>: [hat?"[hat]":"none"]<BR>
			<a href='?src=\ref[src];select=mask'>Mask</a>: [mask?"[mask]":"none"]<BR>
			<a href='?src=\ref[src];select=eye'>Glasses</a>: [eye?"[eye]":"none"]"}

		var/datum/browser/popup = new(usr, "clothing_actor", "Holographic Clothing Interface")
		popup.set_content(dat)
		popup.open()

	Topic(var/href,var/list/href_list)
		var/mob/living/carbon/human/H = usr
		if(usr != loc || !istype(H) || src != H.w_uniform) return
		if(!istype(get_area(loc),/area/holodeck))
			usr << browse(null,"window=clothing_actor")
			return
		switch(href_list["select"])
			if("jumpsuit")
				var/obj/item/clothing/result = input(usr,"Select a jumpsuit style:","Select a jumpsuit", "None") as null|anything in jumpsuit_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				jumpsuit = null
				if(istype(result,/obj))
					jumpsuit = result
				colorchange()
			if("suit")
				var/obj/item/clothing/result = input(usr,"Select a suit style:","Select a suit", "None") as null|anything in suit_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				derez(suit)

				if(istype(result,/obj))
					suit = new result.type
					H.drop_from_inventory(H.wear_suit)
					H.equip_to_slot_if_possible(suit,slot_wear_suit)

			if("glove")
				var/obj/item/clothing/result = input(usr,"Select a glove style:","Select gloves", "None") as null|anything in glove_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				derez(glove)

				if(istype(result,/obj))
					glove = new result.type
					H.drop_from_inventory(H.gloves)
					H.equip_to_slot_if_possible(glove,slot_gloves)
			if("shoe")
				var/obj/item/clothing/result = input(usr,"Select a shoe style:","Select shoes", "None") as null|anything in shoe_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				derez(shoe)

				if(istype(result,/obj))
					shoe = new result.type
					H.drop_from_inventory(H.shoes)
					H.equip_to_slot_if_possible(shoe,slot_shoes)
			if("hat")
				var/obj/item/clothing/result = input(usr,"Select a hat style:","Select a hat", "None") as null|anything in hat_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				derez(hat)

				if(istype(result,/obj))
					hat = new result.type
					H.drop_from_inventory(H.head)
					H.equip_to_slot_if_possible(hat,slot_head)
			if("mask")
				var/obj/item/clothing/result = input(usr,"Select a mask style:","Select a mask", "None") as null|anything in mask_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				derez(mask)

				if(istype(result,/obj))
					mask = new result.type
					H.drop_from_inventory(H.wear_mask)
					H.equip_to_slot_if_possible(mask,slot_wear_mask)
			if("eye")
				var/obj/item/clothing/result = input(usr,"Select an eyewear style:","Select eyewear", "None") as null|anything in eye_choices
				if(!result || usr != loc || src != H.w_uniform || !istype(get_area(loc),/area/holodeck)) return
				derez(eye)

				if(istype(result,/obj))
					eye = new result.type
					H.drop_from_inventory(H.glasses)
					H.equip_to_slot_if_possible(eye,slot_glasses)
		interact()