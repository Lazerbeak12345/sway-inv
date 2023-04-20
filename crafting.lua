local minetest, sway = minetest, sway

-- Load support for MT game translation.
local S = minetest.get_translator("sway")

local gui = sway.widgets

sway.register_page("sway:crafting", {
	title = S("Crafting"),
	get = function(_, player, context)
		return gui.sway.Form{
			player = player,
			context = context,
			show_inv = true,
			gui.HBox{
				align_h = "center",
				gui.List{
					inventory_location = "current_player",
					list_name = "craft",
					w = 3, h = 3
				},
				gui.Image{
					w = 1, h = 1,
					texture_name = "sway_crafting_arrow.png"
				},
				gui.List{
					inventory_location = "current_player",
					list_name = "craftpreview",
					w = 1, h = 1
				},
				gui.Listring{
					inventory_location = "current_player",
					list_name = "main"
				},
				gui.Listring{
					inventory_location = "current_player",
					list_name = "craft"
				}
			}
		}
	end
})
