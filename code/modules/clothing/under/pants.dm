/obj/item/clothing/under/pants
	icon = 'icons/obj/clothing/under/pants.dmi'
	gender = PLURAL
	body_parts_covered = LOWER_TORSO|LEGS
	displays_id = FALSE

	sprite_sheets = list(
		"Human" = 'icons/mob/clothing/under/pants.dmi',
		"Vox" = 'icons/mob/clothing/species/vox/under/pants.dmi',
		"Drask" = 'icons/mob/clothing/species/drask/under/pants.dmi',
		"Grey" = 'icons/mob/clothing/species/grey/under/pants.dmi',
		"Kidan" = 'icons/mob/clothing/species/kidan/under/pants.dmi'
		)


/obj/item/clothing/under/pants/equipped(mob/user, slot)
	if(ishuman(user) && slot == ITEM_SLOT_JUMPSUIT)
		var/mob/living/carbon/human/H = user
		if(H.undershirt != "Nude")
			var/additional_body_parts = UPPER_TORSO|ARMS
			body_parts_covered |= additional_body_parts
			return ..()
	body_parts_covered = LOWER_TORSO|LEGS
	..()

/obj/item/clothing/under/pants/classicjeans
	name = "classic jeans"
	desc = "You feel cooler already."
	icon_state = "jeansclassic"
	item_color = "jeansclassic"

/obj/item/clothing/under/pants/mustangjeans
	name = "Must Hang jeans"
	desc = "Made in the finest space jeans factory this side of Alpha Centauri."
	icon_state = "jeansmustang"
	item_color = "jeansmustang"

/obj/item/clothing/under/pants/blackjeans
	name = "black jeans"
	desc = "Only for those who can pull it off."
	icon_state = "jeansblack"
	item_color = "jeansblack"

/obj/item/clothing/under/pants/youngfolksjeans
	name = "Young Folks jeans"
	desc = "For those tired of boring old jeans. Relive the passion of your youth!"
	icon_state = "jeansyoungfolks"
	item_color = "jeansyoungfolks"

/obj/item/clothing/under/pants/white
	name = "white pants"
	desc = "Plain white pants. Boring."
	icon_state = "whitepants"
	item_color = "whitepants"

/obj/item/clothing/under/pants/red
	name = "red pants"
	desc = "Bright red pants. Overflowing with personality."
	icon_state = "redpants"
	item_color = "redpants"

/obj/item/clothing/under/pants/black
	name = "black pants"
	desc = "These pants are dark, like your soul."
	icon_state = "blackpants"
	item_color = "blackpants"

/obj/item/clothing/under/pants/tan
	name = "tan pants"
	desc = "Some tan pants. You look like a white collar worker with these on."
	icon_state = "tanpants"
	item_color = "tanpants"

/obj/item/clothing/under/pants/blue
	name = "blue pants"
	desc = "Stylish blue pants. These go well with a lot of clothes."
	icon_state = "bluepants"
	item_color = "bluepants"

/obj/item/clothing/under/pants/track
	name = "track pants"
	desc = "A pair of track pants, for the athletic."
	icon_state = "trackpants"
	item_color = "trackpants"

/obj/item/clothing/under/pants/jeans
	name = "jeans"
	desc = "A nondescript pair of tough blue jeans."
	icon_state = "jeans"
	item_color = "jeans"

/obj/item/clothing/under/pants/khaki
	name = "khaki pants"
	desc = "A pair of dust beige khaki pants."
	icon_state = "khaki"
	item_color = "khaki"

/obj/item/clothing/under/pants/camo
	name = "camo pants"
	desc = "A pair of woodland camouflage pants. Probably not the best choice for a space station."
	icon_state = "camopants"
	item_color = "camopants"


//Shorts ARE pants, right?
/obj/item/clothing/under/pants/shorts
	name = "athletic shorts"
	desc = "95% Polyester, 5% Spandex!"
	body_parts_covered = LOWER_TORSO

/obj/item/clothing/under/pants/shorts/red
	icon_state = "redshorts"
	item_color = "redshorts"

/obj/item/clothing/under/pants/shorts/green
	icon_state = "greenshorts"
	item_color = "greenshorts"

/obj/item/clothing/under/pants/shorts/blue
	icon_state = "blueshorts"
	item_color = "blueshorts"

/obj/item/clothing/under/pants/shorts/black
	icon_state = "blackshorts"
	item_color = "blackshorts"

/obj/item/clothing/under/pants/shorts/grey
	icon_state = "greyshorts"
	item_color = "greyshorts"
