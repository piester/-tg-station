/obj/item/weapon/folder
	name = "folder"
	desc = "A folder."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "folder"
	w_class = 2
	pressure_resistance = 2

/obj/item/weapon/folder/blue
	desc = "A blue folder."
	icon_state = "folder_blue"

/obj/item/weapon/folder/red
	desc = "A red folder."
	icon_state = "folder_red"

/obj/item/weapon/folder/yellow
	desc = "A yellow folder."
	icon_state = "folder_yellow"

/obj/item/weapon/folder/white
	desc = "A white folder."
	icon_state = "folder_white"


/obj/item/weapon/folder/update_icon()
	overlays.Cut()
	if(contents.len)
		overlays += "folder_paper"


/obj/item/weapon/folder/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/weapon/paper) || istype(W, /obj/item/weapon/photo))
		user.drop_item()
		W.loc = src
		user << "<span class='notice'>You put [W] into [src].</span>"
		update_icon()
	else if(istype(W, /obj/item/weapon/pen))
		var/n_name = copytext(sanitize(input(user, "What would you like to label the folder?", "Folder Labelling", null) as text), 1, MAX_NAME_LEN)
		if((in_range(src,user) && user.stat == CONSCIOUS))
			name = "folder[(n_name ? "- '[n_name]'" : null)]"


/obj/item/weapon/folder/attack_self(mob/user)
	var/dat = "<title>[name]</title>"

	for(var/obj/item/weapon/paper/P in src)
		dat += "<A href='?src=\ref[src];remove=\ref[P]'>Remove</A> - <A href='?src=\ref[src];read=\ref[P]'>[P.name]</A><BR>"
	for(var/obj/item/weapon/photo/Ph in src)
		dat += "<A href='?src=\ref[src];remove=\ref[Ph]'>Remove</A> - [Ph.name]<BR>"
	user << browse(dat, "window=folder")
	onclose(user, "folder")
	add_fingerprint(usr)


/obj/item/weapon/folder/Topic(href, href_list)
	..()
	if(usr.stat || usr.restrained())
		return

	if(usr.contents.Find(src))

		if(href_list["remove"])
			var/obj/item/P = locate(href_list["remove"])
			if(istype(P) && P.loc == src)
				P.loc = usr.loc
				usr.put_in_hands(P)

		if(href_list["read"])
			var/obj/item/weapon/paper/P = locate(href_list["read"])
			if(istype(P) && P.loc == src)
				P.examine()

		//Update everything
		attack_self(usr)
		update_icon()

/obj/item/weapon/folder/fire_act(air,temp,volume)
	if(prob(25))
		del src
	else if(contents.len)
		var/obj/item/I = pick(contents)
		if(I)
			I.fire_act(air,temp,volume)
