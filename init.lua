-- sway/init.lua

do
	-- Before we do anything, disable sfinv and unified_inventory. (code from i3 at
	--  commit bd5ea4e6). Also under MIT, under Jean-Patrick-Guerrero and
	--  contributors. Modified to fit my style guidelines.
	if minetest.global_exists("sfinv") then
		function sfinv.set_player_inventory_formspec() return end
		sfinv.enabled = false
	end
	if minetest.global_exists("unified_inventory") then
		function unified_inventory.set_inventory_formspec() return end
	end
end

dofile(minetest.get_modpath("sway") .. "/api.lua")

--[[ Retain apis
if minetest.global_exists("sfinv") then
	sway._sfinv_upstream = sfinv
	sfinv = sway
end]]

-- Load support for MT game translation.
local S = minetest.get_translator("sway")

local gui = flow.widgets

sway.register_page("sway:crafting", {
	title = S("Crafting"),
	get = function(self, player, context)
		return sway.make_form(player, context, gui.HBox{
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
		}, true)
	end
})
