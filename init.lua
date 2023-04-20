-- sway/init.lua
print[[
                          Inventory powered by
 ____                                      ______
/\  _`\                                   /\__  _\
\ \,\L\_\  __  __  __     __     __  __   \/_/\ \/     ___   __  __
 \/_\__ \ /\ \/\ \/\ \  /'__`\  /\ \/\ \     \ \ \   /' _ `\/\ \/\ \
   /\ \L\ \ \ \_/ \_/ \/\ \L\.\_\ \ \_\ \     \_\ \__/\ \/\ \ \ \_/ |__
   \ `\____\ \___x___/'\ \__/.\_\\/`____ \    /\_____\ \_\ \_\ \___//\_\
    \/_____/\/__//__/   \/__/\/_/ `/___/> \   \/_____/\/_/\/_/\/__/ \/_/
                                     /\___/
                                     \/__/
]]
-- See README.md for art credit

local minetest = minetest
do
	-- Before we do anything, disable sfinv, unified_inventory, and i3. (code from i3 at commit bd5ea4e6). Also under MIT,
	--  under Jean-Patrick-Guerrero and contributors. Modified to fit my style guidelines, and to also disable i3
	if minetest.global_exists("sfinv") then
		function sfinv.set_player_inventory_formspec() end
		sfinv.enabled = false
	end
	if minetest.global_exists("unified_inventory") then
		function unified_inventory.set_inventory_formspec() end
	end
	if minetest.global_exists("i3") then
		function i3.set_fs() end
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

local gui = sway.widgets

sway.register_page("sway:crafting", {
	title = S("Crafting"),
	get = function(self, player, context)
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
